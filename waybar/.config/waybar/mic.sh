#!/usr/bin/env bash
# Waybar custom/mic — mic indicator using explicit \u unicode escapes so
# glyphs survive editor round-trips.

# Nerd Font glyphs (JetBrainsMono Nerd Font)
ICON_ON=$(printf  '\uf130')   # nf-fa-microphone
ICON_OFF=$(printf '\uf131')   # nf-fa-microphone-slash

# Escape a string for safe embedding in JSON.
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

vol_line=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)
if [[ -z "$vol_line" ]]; then
    printf '{"text":"%s no mic","tooltip":"No default audio source","class":"muted"}\n' "$ICON_OFF"
    exit 0
fi

vol_pct=$(awk '{printf "%d", $2 * 100 + 0.5}' <<<"$vol_line")
[[ "$vol_line" == *"MUTED"* ]] && muted=1 || muted=0

name=$(wpctl inspect @DEFAULT_AUDIO_SOURCE@ 2>/dev/null \
         | awk -F'"' '/node\.description/ {print $2; exit}')
[[ -z "$name" ]] && name="unknown"

# Shortened label for the bar, full name for tooltip
short="${name:0:22}"

if (( muted == 1 )); then
    text="$ICON_OFF muted  $short"
    tip="Mic: $name
Status: MUTED (vol ${vol_pct}%)
Left-click: unmute   Right-click: cycle input   Scroll: volume"
    class="muted"
else
    text="$ICON_ON ${vol_pct}%  $short"
    tip="Mic: $name
Volume: ${vol_pct}%
Left-click: mute   Right-click: cycle input   Scroll: volume"
    class="active"
fi

printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' \
    "$(json_escape "$text")" \
    "$(json_escape "$tip")" \
    "$class"
