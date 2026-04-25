# Everforest Warrior — SDDM theme

Matches the Hyprland/Hyprlock look in this dotfiles repo: Everforest palette,
JetBrainsMono Nerd Font, rounded corners, `forthethrone.jpg` backdrop.

## Layout

- `Main.qml` — greeter UI (Qt 6 / QtQuick; no external QML modules required).
- `theme.conf` — user-tunable colors, font, background path.
- `metadata.desktop` — SDDM theme manifest.
- `background.jpg` — carried in-tree because SDDM runs as the `sddm` user and
  can't read `/home/mpoletiek` before login. Swap with another wallpaper in
  place if desired (keep the same filename or update `theme.conf`).

## Install

Run `../../install.sh` from the parent directory to deploy the theme to
`/usr/share/sddm/themes/everforest-warrior/` and point SDDM at it.

## Tweaking

Edit `theme.conf` — values are read by `Main.qml` through SDDM's `config`
object. No QML changes needed for palette, font, dim opacity, or background
image. For layout or component changes, edit `Main.qml`.

## Notes on behavior

- SDDM has no global "default session" knob; the theme relies on
  `[Users] RememberLastSession=true` in `sddm.conf.d/10-theme.conf`. On first
  boot pick `Hyprland (with D-Bus)` once and SDDM will remember.
- Glyphs in the greeter (user, lock, arrow, power icons) require a Nerd Font.
  If JetBrainsMono Nerd Font isn't installed system-wide, the greeter falls
  back to the system monospace and the glyphs render as tofu.
