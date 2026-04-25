#!/usr/bin/env bash
#
# Pre-render all PNG assets for the Everforest Plymouth theme.
# Plymouth's initramfs renderer has no Pango/Freetype, so every piece
# of text is baked into a PNG here, once, at install time.
#
# Inputs:
#   $1 — wallpaper source (default: ../../wallpapers/forthethrone.jpg)
#   $2 — output directory (default: this script's directory)
#
# Requires: ImageMagick (magick) and a Nerd Font installed.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WALLPAPER="${1:-$SCRIPT_DIR/../../wallpapers/forthethrone.jpg}"
OUT="${2:-$SCRIPT_DIR}"

die() { echo "error: $*" >&2; exit 1; }

[ -f "$WALLPAPER" ] || die "wallpaper not found: $WALLPAPER"
command -v magick >/dev/null || die "ImageMagick not installed"
command -v fc-match >/dev/null || die "fontconfig not installed (need fc-match)"

# Everforest palette
BG="#2d353b"
FG="#d3c6aa"
DIM="#9da9a0"
ACCENT="#a7c080"
ACCENT2="#83c092"
WARN="#dbbc7f"
FAIL="#e67e80"

# Target display resolution — bake letterbox bars at native pixel grid so
# Plymouth/SDDM/GRUB don't have to scale at runtime. Detection priority:
#   1. RES env override   (RES=5120x1440 ./build-assets.sh)
#   2. Active Hyprland monitor (most accurate when in session)
#   3. Highest mode of any "connected" DRM connector
#   4. Fall back to 1080p
TARGET_W=1920; TARGET_H=1080

if [ -n "${RES:-}" ] && [[ "$RES" =~ ^([0-9]+)x([0-9]+)$ ]]; then
    TARGET_W="${BASH_REMATCH[1]}"; TARGET_H="${BASH_REMATCH[2]}"
elif command -v hyprctl >/dev/null && \
     hypr=$(hyprctl monitors -j 2>/dev/null) && [ -n "$hypr" ]; then
    # First active monitor's width x height
    if [[ "$hypr" =~ \"width\":[[:space:]]*([0-9]+).*?\"height\":[[:space:]]*([0-9]+) ]]; then
        TARGET_W="${BASH_REMATCH[1]}"; TARGET_H="${BASH_REMATCH[2]}"
    fi
else
    # Walk DRM looking for connected connectors only; pick largest mode by area
    best_area=0
    for status_file in /sys/class/drm/*/status; do
        [ -r "$status_file" ] || continue
        [ "$(cat "$status_file" 2>/dev/null)" = "connected" ] || continue
        modes_file="$(dirname "$status_file")/modes"
        [ -r "$modes_file" ] || continue
        while read -r mode; do
            [[ "$mode" =~ ^([0-9]+)x([0-9]+)$ ]] || continue
            mw="${BASH_REMATCH[1]}"; mh="${BASH_REMATCH[2]}"
            area=$((mw * mh))
            if [ "$area" -gt "$best_area" ]; then
                best_area="$area"; TARGET_W="$mw"; TARGET_H="$mh"
            fi
        done < "$modes_file"
    done
fi

W="$TARGET_W"; H="$TARGET_H"

# ImageMagick on this system isn't built with fontconfig — resolve to an
# absolute font path via fc-match.
resolve_font() {
    local family="$1"
    fc-match -f '%{file}' "$family" 2>/dev/null
}
FONT="$(resolve_font 'JetBrainsMono Nerd Font:weight=bold')"
[ -f "$FONT" ] || FONT="$(resolve_font 'DejaVu Sans Mono:weight=bold')"
[ -f "$FONT" ] || die "no usable font found via fc-match"

FONT_REG="$(resolve_font 'JetBrainsMono Nerd Font')"
[ -f "$FONT_REG" ] || FONT_REG="$FONT"

echo "==> Generating Everforest Plymouth assets in $OUT"
echo "    wallpaper: $WALLPAPER (${W}x${H})"
echo "    font:      $FONT"

# 1. Background — pre-fitted to native screen res with Lanczos resampling.
#    Black letterbox baked in (matches Noctalia fillColor #000000).
#    Slight darkening for text legibility — NO blur (keeps it crisp).
magick "$WALLPAPER" \
    -strip \
    -filter Lanczos \
    -resize "${W}x${H}" \
    -background black \
    -gravity center \
    -extent "${W}x${H}" \
    -modulate 75,95,100 \
    -quality 95 \
    "$OUT/background.png"

# 1b. Sharper variant with no darkening — for SDDM and GRUB which have
#     their own dim overlays/menu chrome.
magick "$WALLPAPER" \
    -strip \
    -filter Lanczos \
    -resize "${W}x${H}" \
    -background black \
    -gravity center \
    -extent "${W}x${H}" \
    -quality 92 \
    "$OUT/background-sharp.jpg"

# 2. Vignette overlay — light radial darkening from edges (keep subtle)
magick -size "${W}x${H}" radial-gradient:'rgba(0,0,0,0)-rgba(0,0,0,0.35)' \
    "$OUT/vignette.png"

# 3. Title — hostname-style label
HOSTNAME_LABEL="$(hostname 2>/dev/null || echo machine0)"
magick -background none \
    -font "$FONT" -pointsize 56 -fill "$FG" \
    -gravity center label:"$HOSTNAME_LABEL" \
    "$OUT/title.png"

# 4. Subtitle
magick -background none \
    -font "$FONT_REG" -pointsize 18 -fill "$DIM" \
    -gravity center label:"gentoo · linux" \
    "$OUT/subtitle.png"

# 5. Prompt label
magick -background none \
    -font "$FONT_REG" -pointsize 16 -fill "$FG" \
    -gravity center label:"enter passphrase" \
    "$OUT/prompt.png"

# 6. Dot — filled circle in accent green (~14px)
magick -size 14x14 xc:none \
    -fill "$ACCENT" -draw 'circle 7,7 7,1' \
    "$OUT/dot.png"

# 7. Bullet — slightly larger, lighter accent
magick -size 18x18 xc:none \
    -fill "$ACCENT2" -draw 'circle 9,9 9,2' \
    "$OUT/bullet.png"

# 7b. Lock icon — drawn vector-ish via primitives, ~64x80
#     Body: rounded rect; shackle: open ring on top.
magick -size 80x96 xc:none \
    -stroke "$ACCENT" -strokewidth 6 -fill none \
    -draw 'arc 20,8 60,52 180,360' \
    -stroke none -fill "$ACCENT" \
    -draw 'roundrectangle 8,44 72,88 8,8' \
    -fill "$BG" \
    -draw 'circle 40,64 40,70' \
    -draw 'rectangle 38,64 42,76' \
    "$OUT/lock.png"

# 8. Progress bar track + fill (4px tall, 600px wide)
magick -size 600x4 xc:"$DIM" -alpha set -channel A -evaluate set 35% \
    "$OUT/bar_track.png"
magick -size 600x4 \
    gradient:"$ACCENT-$ACCENT2" \
    "$OUT/bar_fill.png"

# 9. Underline for password field (subtle accent line)
magick -size 280x2 xc:"$ACCENT2" -alpha set -channel A -evaluate set 60% \
    "$OUT/entry_underline.png"

# 10. Error variant of underline (auth failure flash)
magick -size 280x2 xc:"$FAIL" -alpha set -channel A -evaluate set 80% \
    "$OUT/entry_underline_err.png"

echo "==> Done. Files:"
ls -lh "$OUT"/*.png 2>/dev/null | awk '{printf "    %-32s %s\n", $9, $5}'
