# razer-effects

Custom OpenRazer effects for the BlackWidow V3 Pro. Stowed into
`~/Devspace/razer-effects/` so `ripple.py` is launched from there at Hyprland
login (see `hypr/.config/hypr/conf.d/30-autostart.conf`, exec-once #9).

## Scripts

| File             | Purpose                                                     |
| ---------------- | ----------------------------------------------------------- |
| `ripple.py`      | Main effect — green base + RAM/CPU bars + audio VU + disk I/O + keypress ripples |
| `rainbow_wave.py`| Hello-world: scrolling rainbow across the matrix            |
| `probe_evdev.py` | Diagnostic — which `/dev/input/event*` fires on keypress    |
| `probe_audio.py` | Diagnostic — measure per-band FFT magnitudes from `parec`   |

## Post-stow setup (per machine)

The `.venv/` is intentionally not tracked. After stowing, create it:

```bash
cd ~/Devspace/razer-effects
python -m venv --system-site-packages .venv
.venv/bin/pip install evdev
```

`--system-site-packages` is required so the venv inherits `openrazer` and
`numpy` from the Gentoo system Python.

## Runtime requirements

- `sys-apps/openrazer` (kernel modules + daemon)
- `media-sound/pipewire` with `pipewire-pulse` (provides `parec` for audio FFT)
- Membership in `plugdev` (read `/dev/input/event*` for keypress capture)
- `openrazer-daemon` running (D-Bus session activated; auto-starts on first
  client call)

## Hyprland integration

Already wired up in `30-autostart.conf`:

```
exec-once = sh -c 'sleep 3 && exec ~/Devspace/razer-effects/.venv/bin/python ~/Devspace/razer-effects/ripple.py >> "$HOME/.cache/razer-ripple.log" 2>&1'
```

The 3-second sleep covers D-Bus activation race between `openrazer-daemon`
and kernel HID enumeration of the keyboard.

## Stopping / restarting

```bash
# stop (graceful — restores spectrum cycling)
pgrep -f "Devspace/razer-effects/.venv/bin/python" | xargs -r kill

# launch manually (same line as the Hyprland autostart)
~/Devspace/razer-effects/.venv/bin/python ~/Devspace/razer-effects/ripple.py
```
