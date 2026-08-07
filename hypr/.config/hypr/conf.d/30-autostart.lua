-- Autostart - ordered for correct init sequence
--
-- The converter hoisted every comment above the exec block; they have been
-- put back next to the commands they document, because the ordering here is
-- deliberate, not incidental.

hl.on("hyprland.start", function()
    -- 1. dbus environment must be updated before any app that depends on portals
    hl.exec_cmd("dbus-update-activation-environment --all DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP")

    -- 2. Audio stack — sequenced so pipewire-pulse starts after pipewire+wireplumber
    -- are actually up. Otherwise pulse-only clients (Spotify) can race and fall
    -- back to raw ALSA, which breaks MPRIS-coordinated track advancement.
    hl.exec_cmd("pipewire")
    hl.exec_cmd("sleep 0.5 && wireplumber")
    hl.exec_cmd("sleep 1 && pipewire-pulse")

    -- 3. Polkit agent (needed before GUI apps request auth)
    hl.exec_cmd("/usr/libexec/hyprpolkitagent")

    -- 4. Sunset. Wallpaper + idle are now managed by noctalia-shell.
    -- hl.exec_cmd("hyprpaper")   -- rollback: noctalia owns wallpaper via Modules/Background
    -- hl.exec_cmd("hypridle")    -- rollback: noctalia IdleService handles DPMS/lock/suspend
    -- hl.exec_cmd("hyprsunset")  -- rollback: noctalia NightLightService spawns wlsunset

    -- 5. Status bar (noctalia-shell via noctalia-qs; waybar kept for rollback)
    hl.exec_cmd("sh -c 'ulimit -c unlimited; cd \"$HOME\"; exec qs --no-detailed-logs -c noctalia-shell 2> \"$HOME/.cache/noctalia.stderr.log\"'")
    -- hl.exec_cmd("waybar")

    -- 6. Clipboard history watchers (install `cliphist` to use SUPER+V picker)
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- 7. XDG portals (after dbus env is populated)
    hl.exec_cmd("sleep 1 && /usr/libexec/xdg-desktop-portal-hyprland")
    hl.exec_cmd("sleep 2 && /usr/libexec/xdg-desktop-portal")

    -- 8. Apps: none autostarted. Launch manually after login for a clean slate.
    -- Scratchpad (SUPER+S) is empty on boot until you open apps that match the
    -- special:magic windowrule. Spotify, if used, should be launched by hand to
    -- avoid racing pipewire-pulse startup (causes MPRIS/ALSA fallback issues).
    -- Bluetooth Applet
    hl.exec_cmd("blueman-applet")
end)
