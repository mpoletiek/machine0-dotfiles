#!/usr/bin/env bash
#
# machine0-dotfiles — system theme installer.
#
# Idempotent. Installs:
#   - wallpaper to ~/Pictures/wallpapers/ (the canonical path SDDM/Noctalia use)
#   - Plymouth Everforest theme to /usr/share/plymouth/themes/everforest/
#   - GRUB Stylish theme to /boot/grub/themes/Stylish/
#   - Rebuilds initramfs for the running kernel
#   - Regenerates grub.cfg
#
# Run after `install.sh`. Requires sudo.
#

set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
SYS="$DOTFILES/system"

info() { printf '==> %s\n' "$*"; }
ok()   { printf '    %s\n' "$*"; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

[ -d "$SYS" ] || die "$SYS not found"
command -v magick >/dev/null || die "ImageMagick not installed (emerge media-gfx/imagemagick)"
command -v plymouth-set-default-theme >/dev/null || die "plymouth not installed"
command -v dracut >/dev/null || die "dracut not installed"

# /boot is mounted noauto in fstab — every step in this script that touches
# /boot (GRUB theme install, initramfs build, grub-mkconfig) needs it
# mounted. Do it once, up front, and bail cleanly on failure.
ensure_boot_mounted() {
    if mountpoint -q /boot; then
        ok "/boot already mounted"
        return 0
    fi
    info "Mounting /boot"
    sudo mount /boot || die "failed to mount /boot — fix fstab or mount manually"
    ok "/boot mounted"
}
ensure_boot_mounted

# 1. Wallpaper to canonical home path
info "Installing wallpaper to ~/Pictures/wallpapers/"
mkdir -p "$HOME/Pictures/wallpapers"
install -m 0644 "$SYS/wallpapers/forthethrone.jpg" \
    "$HOME/Pictures/wallpapers/forthethrone.jpg"
ok "wallpaper installed"

# 2. Plymouth theme — generate assets, then copy to system location
info "Building Plymouth assets from wallpaper"
bash "$SYS/plymouth/everforest/build-assets.sh" \
    "$SYS/wallpapers/forthethrone.jpg" \
    "$SYS/plymouth/everforest"
ok "assets built"

info "Installing Plymouth theme to /usr/share/plymouth/themes/everforest/"
sudo install -d -m 0755 /usr/share/plymouth/themes/everforest
sudo install -m 0644 \
    "$SYS/plymouth/everforest/everforest.plymouth" \
    "$SYS/plymouth/everforest/everforest.script" \
    "$SYS/plymouth/everforest"/*.png \
    /usr/share/plymouth/themes/everforest/
ok "theme installed"

# Sync the pre-rendered native-resolution wallpaper into the SDDM theme and
# GRUB Stylish theme so all three render the same crisp source.
SHARP="$SYS/plymouth/everforest/background-sharp.jpg"
if [ -f "$SHARP" ]; then
    info "Syncing native-res wallpaper into SDDM and GRUB themes"
    sudo install -m 0644 "$SHARP" \
        /usr/share/sddm/themes/everforest-warrior/background.jpg
    cp "$SHARP" "$SYS/grub/themes/Stylish/background.jpg"
    cp "$SHARP" "$SYS/sddm/themes/everforest-warrior/background.jpg"
    ok "background synced"
fi

info "Setting Everforest as default Plymouth theme"
sudo plymouth-set-default-theme everforest
ok "default theme set"

# 3. SDDM theme + config (delegated to its own installer)
if [ -x "$SYS/sddm/install.sh" ]; then
    info "Running SDDM installer"
    bash "$SYS/sddm/install.sh"
    ok "SDDM installed"
else
    ok "(no $SYS/sddm/install.sh — skipping)"
fi

# 4. GRUB theme
info "Installing GRUB Stylish theme to /boot/grub/themes/"
sudo install -d -m 0755 /boot/grub/themes/Stylish
sudo cp -r "$SYS/grub/themes/Stylish/." /boot/grub/themes/Stylish/
ok "GRUB theme installed"

# 5. Install dracut.conf.d drop-ins — needed BEFORE the dracut rebuild below
#    so Plymouth + label.so + NVIDIA modeset actually land in the initramfs.
info "Installing dracut.conf.d drop-ins → /etc/dracut.conf.d/"
sudo install -d -m 0755 /etc/dracut.conf.d
for f in "$SYS"/dracut.conf.d/*.conf; do
    [ -f "$f" ] || continue
    base="$(basename "$f")"
    # Prefer machine-local override if present
    if [ -f "$f.local" ]; then
        src="$f.local"
        info "Using machine-local dracut conf: $base.local"
    elif grep -q '<[A-Z][A-Z_-]*>' "$f"; then
        ok "skipping $base — placeholder in template (create $base.local for this host)"
        continue
    else
        src="$f"
    fi
    dst="/etc/dracut.conf.d/$base"
    if [ -f "$dst" ] && ! cmp -s "$src" "$dst" && [ ! -f "$dst.pre-dotfiles" ]; then
        sudo cp -a "$dst" "$dst.pre-dotfiles"
        ok "backed up $dst → $dst.pre-dotfiles"
    fi
    sudo install -m 0644 "$src" "$dst"
    ok "installed $dst"
done

# 6. Rebuild initramfs for running kernel
KVER="$(uname -r)"
INITRAMFS="/boot/initramfs-${KVER}.img"
info "Rebuilding initramfs for $KVER"
mountpoint -q /boot || die "/boot lost its mount — refusing to write initramfs to overlay"
sudo dracut --kver "$KVER" --force "$INITRAMFS"
ok "$INITRAMFS regenerated"

# 7. Install /etc/default/grub from machine-local snapshot.
#    Load-bearing: GRUB_THEME, GRUB_GFXMODE, GRUB_GFXPAYLOAD_LINUX=keep, and
#    GRUB_CMDLINE_LINUX_DEFAULT="quiet splash rd.plymouth=1 nvidia-drm.modeset=1"
#    — without the last line, Plymouth never activates.
#
#    Machine-specific GRUB_CMDLINE_LINUX (LUKS UUID, root UUID, swap UUID,
#    keyfile path) lives in default-grub.local (gitignored). The repo template
#    default-grub holds <PLACEHOLDER> values that would brick boot if installed
#    directly, so this step is skipped with a warning when .local is missing.
GRUB_DEFAULT_LOCAL="$SYS/grub/default-grub.local"
GRUB_DEFAULT_DST="/etc/default/grub"
if [ -f "$GRUB_DEFAULT_LOCAL" ]; then
    info "Installing /etc/default/grub from machine-local snapshot"
    if [ -f "$GRUB_DEFAULT_DST" ] && ! cmp -s "$GRUB_DEFAULT_LOCAL" "$GRUB_DEFAULT_DST" \
            && [ ! -f "$GRUB_DEFAULT_DST.pre-dotfiles" ]; then
        sudo cp -a "$GRUB_DEFAULT_DST" "$GRUB_DEFAULT_DST.pre-dotfiles"
        ok "backed up $GRUB_DEFAULT_DST → $GRUB_DEFAULT_DST.pre-dotfiles"
    fi
    sudo install -m 0644 "$GRUB_DEFAULT_LOCAL" "$GRUB_DEFAULT_DST"
    ok "/etc/default/grub installed"
else
    info "Skipping /etc/default/grub install"
    ok "(no $GRUB_DEFAULT_LOCAL — copy default-grub to default-grub.local"
    ok " and fill in real UUIDs/keyfile path for this host first)"
fi

# 8. Regenerate grub.cfg
info "Regenerating /boot/grub/grub.cfg"
mountpoint -q /boot || die "/boot lost its mount — refusing to write grub.cfg"
sudo grub-mkconfig -o /boot/grub/grub.cfg
ok "grub.cfg regenerated"

cat <<'POST'

============================================================
Theme install complete.
============================================================

Reboot to see the new Plymouth splash.

To preview without rebooting:
    sudo plymouthd --debug --no-daemon &
    sudo plymouth --show-splash
    sudo plymouth ask-for-password --prompt='enter passphrase'
    sudo plymouth quit

To regenerate Plymouth assets only (after wallpaper change):
    bash ~/dotfiles/system/plymouth/everforest/build-assets.sh
    sudo cp ~/dotfiles/system/plymouth/everforest/*.png \
        /usr/share/plymouth/themes/everforest/
    sudo dracut --kver $(uname -r) --force /boot/initramfs-$(uname -r).img
POST
