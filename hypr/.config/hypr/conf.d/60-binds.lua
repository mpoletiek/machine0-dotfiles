

hl.bind(mainMod .. " + return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("/usr/bin/noctalia msg panel-toggle launcher"))

hl.bind(mainMod .. " + SHIFT + CTRL + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))

hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + M", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

hl.bind(mainMod .. " + CTRL + R", hl.dsp.exec_cmd("hyprctl reload"))

hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "d" }))

hl.bind(mainMod .. " + R", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
    hl.bind("left", hl.dsp.window.resize({ x = -40, y = 0, relative = true }), { repeating = true })
    hl.bind("right", hl.dsp.window.resize({ x = 40, y = 0, relative = true }), { repeating = true })
    hl.bind("up", hl.dsp.window.resize({ x = 0, y = -40, relative = true }), { repeating = true })
    hl.bind("down", hl.dsp.window.resize({ x = 0, y = 40, relative = true }), { repeating = true })
    hl.bind("escape", hl.dsp.submap("reset"))
    hl.bind("return", hl.dsp.submap("reset"))
end)

hl.bind(mainMod .. " + 1", hl.dsp.focus({ workspace = 1 }))
hl.bind(mainMod .. " + 2", hl.dsp.focus({ workspace = 2 }))
hl.bind(mainMod .. " + 3", hl.dsp.focus({ workspace = 3 }))
hl.bind(mainMod .. " + 4", hl.dsp.focus({ workspace = 4 }))
hl.bind(mainMod .. " + 5", hl.dsp.focus({ workspace = 5 }))
hl.bind(mainMod .. " + 6", hl.dsp.focus({ workspace = 6 }))
hl.bind(mainMod .. " + 7", hl.dsp.focus({ workspace = 7 }))
hl.bind(mainMod .. " + 8", hl.dsp.focus({ workspace = 8 }))
hl.bind(mainMod .. " + 9", hl.dsp.focus({ workspace = 9 }))
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))

hl.bind(mainMod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = 1, follow = false }))
hl.bind(mainMod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = 2, follow = false }))
hl.bind(mainMod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = 3, follow = false }))
hl.bind(mainMod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = 4, follow = false }))
hl.bind(mainMod .. " + SHIFT + 5", hl.dsp.window.move({ workspace = 5, follow = false }))
hl.bind(mainMod .. " + SHIFT + 6", hl.dsp.window.move({ workspace = 6, follow = false }))
hl.bind(mainMod .. " + SHIFT + 7", hl.dsp.window.move({ workspace = 7, follow = false }))
hl.bind(mainMod .. " + SHIFT + 8", hl.dsp.window.move({ workspace = 8, follow = false }))
hl.bind(mainMod .. " + SHIFT + 9", hl.dsp.window.move({ workspace = 9, follow = false }))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10, follow = false }))

hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))


hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize())

hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("/usr/bin/noctalia msg panel-toggle clipboard"))

hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("hex=$(hyprpicker -a -f hex) && wl-copy \"$hex\" && notify-send \"Color picked\" \"$hex\""))

hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("/usr/bin/noctalia msg notification-clear-active"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("/usr/bin/noctalia msg notification-clear-active"))
hl.bind(mainMod .. " + CTRL + N", hl.dsp.exec_cmd("/usr/bin/noctalia msg panel-toggle control-center notifications"))
hl.bind(mainMod .. " + ALT + N", hl.dsp.exec_cmd("/usr/bin/noctalia msg notification-invoke-latest"))
hl.bind(mainMod .. " + SHIFT + CTRL + N", hl.dsp.exec_cmd("/usr/bin/noctalia msg notification-dnd-toggle"))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute   @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute   @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

hl.bind("PRINT", hl.dsp.exec_cmd("f=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S)_grimblast.png && grimblast --notify copysave active \"$f\" && imv \"$f\""), { locked = true })
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("f=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S)_grimblast.png && grimblast --notify copysave area    \"$f\" && imv \"$f\""), { locked = true })
hl.bind(mainMod .. " + CTRL + PRINT", hl.dsp.exec_cmd("/usr/bin/noctalia msg screenshot-region"), { locked = true })

hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("/usr/bin/noctalia msg session lock"), { locked = true })
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("/usr/bin/noctalia msg session lock-and-suspend"), { locked = true })
hl.bind(mainMod .. " + BACKSPACE", hl.dsp.exec_cmd("kitty --class kittyscreensaver cmatrix"), { locked = true })

hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("/usr/bin/noctalia msg panel-toggle control-center"))
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd("/usr/bin/noctalia msg caffeine-toggle"))
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd("/usr/bin/noctalia msg panel-toggle session"))
hl.bind(mainMod .. " + SHIFT + X", hl.dsp.exec_cmd("/usr/bin/noctalia msg settings-toggle"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("/usr/bin/noctalia msg panel-toggle wallpaper"))

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("notify-send Noctalia 'This optional plugin is not enabled.'"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("notify-send Noctalia 'This optional plugin is not enabled.'"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("/usr/bin/noctalia msg plugin noctalia/screen_recorder:service all toggle"))
