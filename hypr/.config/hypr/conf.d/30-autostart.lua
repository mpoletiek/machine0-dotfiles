
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --all DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP")

    hl.exec_cmd("pipewire")
    hl.exec_cmd("sleep 0.5 && wireplumber")
    hl.exec_cmd("sleep 1 && pipewire-pulse")

    hl.exec_cmd("/usr/libexec/hyprpolkitagent")


    hl.exec_cmd("sh -c 'ulimit -c unlimited; cd \"$HOME\"; exec /home/mpoletiek/.local/bin/noctalia-v5 2> \"$HOME/.cache/noctalia-v5.stderr.log\"'")


    hl.exec_cmd("sleep 1 && /usr/libexec/xdg-desktop-portal-hyprland")
    hl.exec_cmd("sleep 2 && /usr/libexec/xdg-desktop-portal")

    hl.exec_cmd("blueman-applet")

    -- Animated wallpaper on DP-3 (mpvpaper; HWDEC mode set in the script).
    -- The script waits for noctalia's wallpaper surface on DP-3 so mpvpaper
    -- stacks above it, and re-launches itself if noctalia restarts.
    hl.exec_cmd("/home/mpoletiek/Tools/animated-wallpaper.sh start >> $HOME/.cache/mpvpaper.log 2>&1")

    -- LAN sshfs shares; retries hosts still booting, logs to ~/.cache/lan-mount.log
    hl.exec_cmd("/home/mpoletiek/Tools/lan-autostart.sh")
end)
