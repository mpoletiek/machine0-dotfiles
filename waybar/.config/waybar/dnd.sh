#!/usr/bin/env bash
# Waybar DND/notifications module — JSON output with \u escapes for glyphs.

# Nerd Font glyphs (JetBrainsMono Nerd Font)
ICON_ACTIVE=$(printf '\uf0f3')   # nf-fa-bell
ICON_PAUSED=$(printf '\uf1f6')   # nf-fa-bell_slash

paused=$(dunstctl is-paused 2>/dev/null)
count=$(dunstctl count waiting 2>/dev/null || echo 0)

if [[ "$paused" == "true" ]]; then
    printf '{"text":"%s","tooltip":"Notifications paused (DND on) — click to resume","class":"dnd-on","alt":"paused"}\n' \
        "$ICON_PAUSED"
else
    printf '{"text":"%s","tooltip":"Notifications active (%s queued) — click to pause","class":"dnd-off","alt":"active"}\n' \
        "$ICON_ACTIVE" "$count"
fi
