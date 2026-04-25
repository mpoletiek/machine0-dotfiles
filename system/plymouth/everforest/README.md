# Everforest Plymouth Theme

Modern, minimal Plymouth boot splash that matches the SDDM `everforest-warrior` theme,
Hyprland's `col.active_border` gradient, and Noctalia's accent palette.

## Design

- **Background**: `forthethrone.jpg` from `system/wallpapers/`, darkened + softly blurred
  for legibility, with a radial vignette overlay.
- **Title / subtitle**: pre-rendered to PNG at install time via ImageMagick. Plymouth's
  initramfs renderer has no Pango/Freetype, so all text is baked in.
- **Spinner**: three accent-green dots, phase-shifted breathing animation.
- **Progress bar**: thin gradient bar (a7c080 → 83c092). Driven by OpenRC service
  status updates from `plymouth-openrc-plugin` (each service tick advances the bar).
- **LUKS prompt**: pre-rendered "enter passphrase" label, animated bullets, accent
  underline. Auth failure flashes a red underline.

## Files

| File | Purpose |
|------|---------|
| `everforest.plymouth` | Plymouth manifest |
| `everforest.script`   | Animation logic |
| `build-assets.sh`     | Regenerates all PNG assets from the wallpaper |
| `*.png`               | Generated assets (committed for parity across rebuilds) |

## Install

From the dotfiles root:

```sh
bash system/install-themes.sh
```

This will:
1. Build the Plymouth PNG assets from `system/wallpapers/forthethrone.jpg`
2. Install the theme to `/usr/share/plymouth/themes/everforest/`
3. Set it as default
4. Rebuild `/boot/initramfs-$(uname -r).img`
5. Regenerate `/boot/grub/grub.cfg`

## Tuning

Edit the variables at the top of `build-assets.sh` to change colors, then re-run.
The script regenerates idempotently — colors, palette, and font live in one place.

## Why pre-rendered?

Gentoo's default Plymouth + dracut combo ships only `libpng` in the initramfs renderer
(verified: `ldd /usr/lib64/plymouth/script.so` shows libpng16 only — no pango,
no freetype, no fontconfig). Dynamic `Image.Text(...)` calls fail silently in this
environment. Bundled themes like `solar` and `glow` use only PNG sprites for the
same reason.
