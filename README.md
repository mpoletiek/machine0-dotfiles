# machine0-dotfiles

Personal configuration for a Gentoo + Hyprland + NVIDIA ultrawide workstation.
Managed via GNU Stow — each top-level directory is a "package" that mirrors
`$HOME` and is symlinked into place.

Theme: **Everforest dark medium** (sage `#a7c080` accent on `#2d353b` surface)
across kitty, tmux, nvim, hyprland, hyprlock, noctalia, and the dormant
waybar/dunst fallbacks.

## What's in here

| Package | Contents |
|---------|----------|
| `hypr/` | `~/.config/hypr/` — hyprland.conf entry point, `conf.d/*.conf` modular config, hyprsunset (active); hypridle, hyprlock, hyprpaper kept dormant for rollback (noctalia owns idle/lock/wallpaper) |
| `noctalia/` | `~/.config/noctalia/` — active shell config: colors.json (theme), settings.json (bar/launcher/panels), plugins.json + plugins/ (air-quality, calendar-widget, github-feed, notes-scratchpad, screen-recorder, screenshot, timer, weather-indicator) |
| `kitty/` | `~/.config/kitty/kitty.conf` — terminal with JetBrainsMono Nerd Font, splits, scrollback-in-nvim, shell integration |
| `tmux/` | `~/.tmux.conf` — prefix `C-a`, vi mode, tpm, sessionx, continuum auto-restore |
| `zsh/` | `~/.zshrc` + `~/.p10k.zsh` — zinit, p10k, fast-syntax-highlighting, autosuggestions, fzf-tab, atuin, zoxide, direnv, modern CLI aliases |
| `nvim/` | `~/.config/nvim/` — init.lua + lua/config/ + lua/plugins/ + lazy-lock.json (pinned plugin versions). Theme: neanias/everforest-nvim |
| `waybar/` | `~/.config/waybar/` — **dormant** (replaced by noctalia-shell). Themed for rollback-readiness. |
| `dunst/` | `~/.config/dunst/dunstrc` — **dormant** (notifications now owned by noctalia). Themed for rollback. |
| `bin/` | `~/.local/bin/*` — small helper scripts |
| `system/` | Root-owned files snapshot — installed by `install.sh` + `install-themes.sh`, not symlinked. Contents below. |
| `system/profile.d-mpoletiek.sh` | → `/etc/profile.d/mpoletiek.sh` (shell env for login shells) |
| `system/package.use/` + `package.accept_keywords/` | → `/etc/portage/package.use/` + `/etc/portage/package.accept_keywords/` (portage fragments) |
| `system/wallpapers/forthethrone.jpg` | Canonical wallpaper source — Plymouth, SDDM, GRUB, and Noctalia all derive from this one file |
| `system/plymouth/everforest/` | → `/usr/share/plymouth/themes/everforest/` — theme def + script + pre-rendered PNGs; `build-assets.sh` regenerates PNGs at native resolution from the wallpaper |
| `system/grub/themes/Stylish/` | → `/boot/grub/themes/Stylish/` — themed GRUB menu (Stylish) with background synced from the wallpaper |
| `system/grub/default-grub` | Template for `/etc/default/grub` — holds `GRUB_THEME`, `GRUB_GFXMODE` (native ultrawide first), `GRUB_CMDLINE_LINUX_DEFAULT="quiet splash rd.plymouth=1 nvidia-drm.modeset=1"`, and `<PLACEHOLDER>` UUIDs/keyfile path. Copy to `default-grub.local` (gitignored) and fill in real values per host before running `install-themes.sh`. |
| `system/sddm/themes/everforest-warrior/` | → `/usr/share/sddm/themes/everforest-warrior/` — greeter QML + background + Everforest palette |
| `system/sddm/sddm.conf.d/10-theme.conf` | → `/etc/sddm.conf.d/10-theme.conf` — selects the theme, remembers last user/session |
| `system/sddm/conf.d-xdm` | → `/etc/conf.d/xdm` — sets `DISPLAYMANAGER=sddm` for OpenRC's `xdm` init script |
| `system/dracut.conf.d/` | → `/etc/dracut.conf.d/` — pulls `plymouth`, `label.so`, fonts, NVIDIA modeset drivers, and LUKS/GPG modules into the initramfs. Without these, Plymouth silently no-ops at boot. |
| `system/install-themes.sh` | Orchestrates the full Plymouth + GRUB + SDDM + dracut install. Mounts `/boot`, renders assets, installs themes, rebuilds initramfs, regenerates `grub.cfg`. Idempotent. |

## Fresh-machine restore

Assumes Gentoo is installed with NVIDIA drivers, Hyprland, and network access.

### 1. Base packages

```bash
sudo emerge --ask \
    app-admin/stow dev-vcs/git app-shells/zsh \
    app-shells/fzf app-shells/zoxide app-shells/atuin \
    sys-apps/eza sys-apps/bat sys-apps/fd \
    sys-process/btop x11-terms/kitty \
    app-editors/neovim app-misc/tmux \
    x11-misc/dunst gui-apps/waybar \
    media-gfx/imagemagick app-misc/brightnessctl app-misc/ddcutil \
    x11-misc/cliphist gui-apps/wl-clipboard

# Boot + login stack (GRUB, Plymouth, SDDM, dracut)
sudo emerge --ask \
    sys-boot/grub sys-boot/grub-themes-gentoo \
    sys-boot/plymouth sys-boot/plymouth-openrc-plugin \
    sys-kernel/dracut x11-misc/sddm
```

`waybar` and `dunst` are kept installed as fallbacks but not autostarted —
noctalia-shell handles the bar and notifications today.

### 2. Enable GURU overlay

Required for direnv, nerdfonts, and the upstream quickshell that we replace
with our fork.

```bash
sudo emerge --ask app-eselect/eselect-repository
sudo eselect repository enable guru
sudo emaint sync -r guru
sudo emerge --ask app-shells/direnv
```

### 3. Clone this repo

```bash
cd ~
git clone git@github.com:mpoletiek/machine0-dotfiles.git dotfiles
```

### 4. Apply portage USE flags + keyword fragments from the repo

```bash
sudo cp ~/dotfiles/system/package.use/*              /etc/portage/package.use/
sudo cp ~/dotfiles/system/package.accept_keywords/*  /etc/portage/package.accept_keywords/
sudo emerge --ask --changed-use gui-wm/hyprland media-fonts/nerdfonts
```

### 5. Run the bootstrap

```bash
cd ~/dotfiles
./install.sh
```

`install.sh` runs `stow` to symlink all user configs into `$HOME`, installs the
system profile snippet, and prints follow-up manual actions. Stowed packages:
`hypr kitty waybar dunst nvim tmux zsh noctalia bin`.

### 6. Install Plymouth + GRUB + SDDM themes

```bash
bash ~/dotfiles/system/install-themes.sh
```

This single script:

- copies the wallpaper to `~/Pictures/wallpapers/forthethrone.jpg`
- renders Plymouth PNGs at native resolution (auto-detects via hyprctl / DRM,
  or override with `RES=5120x1440 ./install-themes.sh`)
- installs `/usr/share/plymouth/themes/everforest/` and sets it default
- installs `/usr/share/sddm/themes/everforest-warrior/`,
  `/etc/sddm.conf.d/10-theme.conf`, and `/etc/conf.d/xdm`
- installs `/boot/grub/themes/Stylish/` (mounts `/boot` first — `/boot` is
  `noauto` in fstab)
- installs `/etc/dracut.conf.d/{10-i18n,50-luks-gpg,60-plymouth-text}.conf`
  — the `plymouth` dracut module + NVIDIA modeset drivers + label.so live here.
  **Without these drop-ins the rebuilt initramfs has no Plymouth support.**
- installs `/etc/default/grub` — carries `GRUB_THEME`,
  `GRUB_GFXMODE=5120x1440x32,...`, and the
  `quiet splash rd.plymouth=1 nvidia-drm.modeset=1` kernel cmdline.
  Any pre-existing file is backed up to `/etc/default/grub.pre-dotfiles`.
- rebuilds the initramfs for the running kernel (`dracut --force`)
- regenerates `/boot/grub/grub.cfg`

Re-runnable. Pre-existing `/etc/conf.d/xdm`, dracut drop-ins, and
`/etc/default/grub` are backed up once to `*.pre-dotfiles` on first overwrite.

### 7. Enable the display manager (OpenRC)

```bash
sudo rc-update add xdm default
# Either reboot, or from a TTY (not inside your current graphical session):
sudo rc-service xdm start
```

If `/etc/rc.conf` has a `DISPLAYMANAGER=` line, remove it — the init script
prefers `rc.conf` over `/etc/conf.d/xdm` when both are set. `install-themes.sh`
warns if it detects the conflict.

### 8. Build noctalia-qs (the shell runtime)

noctalia-shell requires a fork of quickshell — upstream `gui-apps/quickshell`
will not work and must not be installed in parallel.

```bash
mkdir -p ~/Devspace
git clone --branch v0.0.12 https://github.com/noctalia-dev/noctalia-qs ~/Devspace/noctalia-qs
cd ~/Devspace/noctalia-qs
cmake -GNinja -B build \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DDISTRIBUTOR="Local build (~/Devspace)"
cmake --build build
sudo cmake --install build
```

Installs `qs` and `quickshell` to `/usr/local/bin/` so they take PATH
precedence over any future `gui-apps/quickshell` install.

### 9. Fetch the noctalia-shell QML tree

The shell's QML is *not* in this repo (regenerated per release). Pull the
tarball into `~/.config/quickshell/noctalia-shell/`:

```bash
mkdir -p ~/.config/quickshell/noctalia-shell
curl -sL https://github.com/noctalia-dev/noctalia-shell/releases/latest/download/noctalia-latest.tar.gz \
    | tar -xz --strip-components=1 -C ~/.config/quickshell/noctalia-shell
```

### 10. Follow-up manual actions

```bash
# Fonts
fc-cache -fv

# Shell
chsh -s /usr/bin/zsh
# Open a new terminal — zinit self-installs on first zsh launch and pulls all
# declared plugins. Takes ~30s the first time.

# tmux plugins: inside tmux, press prefix + I (capital i)
# Neovim plugins: run `nvim`, lazy.nvim auto-installs per lazy-lock.json.
# (First nvim launch will install neanias/everforest-nvim.)

# Reload the live Hyprland config
hyprctl reload
```

### 11. Verification checklist

**Boot chain (GRUB → Plymouth → SDDM):**
- [ ] GRUB menu renders the Stylish theme (not the unthemed default menu)
- [ ] `grep GRUB_THEME /etc/default/grub` → `/boot/grub/themes/Stylish/theme.txt`
- [ ] `grep GRUB_CMDLINE_LINUX_DEFAULT /etc/default/grub` contains `quiet splash rd.plymouth=1 nvidia-drm.modeset=1`
- [ ] `plymouth-set-default-theme` → `everforest`
- [ ] `lsinitrd /boot/initramfs-$(uname -r).img | grep -E 'plymouth|label\.so'` → both present
- [ ] Reboot: Plymouth splash appears between GRUB and SDDM (Everforest background, sage progress dots, no kernel log spam)
- [ ] SDDM greeter renders the everforest-warrior theme with JetBrainsMono
- [ ] `rc-service xdm status` → started; `rc-update show default | grep xdm` → present

**Userland (stow + Hyprland + Noctalia):**
- [ ] `fc-match "JetBrainsMono Nerd Font"` → resolves to `JetBrainsMonoNerdFont-Regular.ttf`
- [ ] `echo $SHELL` → `/usr/bin/zsh`
- [ ] A fresh zsh shows p10k prompt with git / language modules
- [ ] `ll` (eza alias) renders icons
- [ ] `nvim` opens, `:Lazy` shows all plugins installed and Everforest is active
- [ ] `qs --version` → reports `noctalia-qs` (not upstream quickshell)
- [ ] Noctalia bar renders on the ultrawide with Everforest sage accents
- [ ] `SUPER+SPACE` opens noctalia launcher (apps + window search)
- [ ] `SUPER+V` opens a floating kitty popup with fzf clipboard history
- [ ] `SUPER+L` triggers noctalia lockscreen
- [ ] `SUPER+A` toggles control center; `SUPER+X` toggles session menu
- [ ] `notify-send "test" "hi"` → noctalia notification appears
- [ ] Plugin keys work: `SUPER+T` (timer), `SUPER+SHIFT+M` (notes), `SUPER+SHIFT+R` (recorder), `SUPER+CTRL+PRINT` (clipboard screenshot)
- [ ] `tmux` shows Everforest-themed status with session name + current-pane command

## Day-2 ops

### Making changes

All `~/.config/*` paths and the home dotfiles are symlinks into this repo.
Edit in place — you're editing the repo file.

```bash
vim ~/.config/hypr/conf.d/60-binds.conf   # edits ~/dotfiles/hypr/.config/hypr/conf.d/60-binds.conf
cd ~/dotfiles
git diff
git add -p
git commit -m "hypr: add bind for X"
git push
```

### Adding a new dotfile

```bash
mkdir -p ~/dotfiles/newapp/.config/newapp
mv ~/.config/newapp/* ~/dotfiles/newapp/.config/newapp/
rmdir ~/.config/newapp
cd ~/dotfiles
stow -v -R -t ~ newapp
```

If you create the symlink by hand instead of `stow`, the **relative path must
use one `../`** — e.g. `~/.config/newapp -> ../dotfiles/newapp/.config/newapp`.
Two `../` resolves to `/home/dotfiles/...` which doesn't exist. Confirm with
`readlink ~/.config/newapp` and `cat newfile_in_target` to verify.

Or run `./update.sh` to re-stow everything.

### Updating noctalia-shell

```bash
# Re-fetch latest tarball
curl -sL https://github.com/noctalia-dev/noctalia-shell/releases/latest/download/noctalia-latest.tar.gz \
    | tar -xz --strip-components=1 -C ~/.config/quickshell/noctalia-shell

# Rebuild noctalia-qs against latest tag
cd ~/Devspace/noctalia-qs
git fetch --tags
git checkout $(git describe --tags --abbrev=0)
cmake --build build && sudo cmake --install build

# Restart shell
pkill -f 'qs -c noctalia-shell'
hyprctl dispatch exec 'qs -c noctalia-shell'
```

### Updating system themes after a wallpaper change

Swap `system/wallpapers/forthethrone.jpg` for the new image (keep the filename
or update the path in `install-themes.sh` + the SDDM/GRUB theme configs), then:

```bash
bash ~/dotfiles/system/install-themes.sh
# Reboot to see the new Plymouth splash. SDDM + GRUB pick up the new
# background synced from plymouth/everforest/background-sharp.jpg.
```

`install-themes.sh` is idempotent — safe to rerun any time the wallpaper,
dracut drop-ins, `/etc/default/grub` snapshot, or theme assets change. It
always rebuilds the initramfs for the running kernel and regenerates
`grub.cfg`.

### Machine-specific overrides

Create `~/.config/hypr/conf.d/99-local.conf` (already gitignored via the pattern
`99-local.conf`) for tweaks that shouldn't be shared across machines. The main
`hyprland.conf` has a commented `source = ~/.config/hypr/conf.d/99-local.conf`
line — uncomment it to pick up local overrides.

## What is deliberately NOT in the repo

- Shell history (`.zsh_history`, `.bash_history`)
- Plugin runtime (`.zinit/`, `.tmux/plugins/`, `.local/share/nvim/`, hyprpm build cache) — all regenerate from their respective lock files / declarations
- noctalia-shell QML tree at `~/.config/quickshell/noctalia-shell/` — bootstrapped from upstream tarball per release
- noctalia-qs build directory (`~/Devspace/noctalia-qs/build/`)
- Chromium / Discord / app-specific profile data
- Any `.env` or secret material
- LUKS / GPG key material (`<HOSTNAME>-luks-key.gpg`) — stays on the machine's
  boot partition; never in the repo. The keyfile path is referenced in
  `system/dracut.conf.d/50-luks-gpg.conf` and in `default-grub.local`
  (gitignored). This will move to a hardware-backed flow later; update both
  files when it does.
- Machine-specific GRUB UUIDs and keyfile path (`default-grub.local`) — see
  `system/grub/default-grub` for the template.
- `hyprland.conf.bak` and other `*.bak` safety copies

See `.gitignore` and `.stow-global-ignore` for the full lists.

## Architecture notes

### Hyprland config split
The entry point `hyprland.conf` only sources `conf.d/00-monitors.conf` →
`70-rules.conf`. Each module is focused on one concern (monitors, env,
autostart, look, input, binds, rules). The autostart is sequenced — dbus and
audio plumbing first, then portals, then the shell, then nothing else (clean
slate by design — apps are launched manually after login).

### Why noctalia-qs and not upstream quickshell
noctalia-shell uses Wayland protocol extensions (`ext-background-effect-v1`)
that aren't in upstream `gui-apps/quickshell`. The fork is a drop-in `qs`/
`quickshell` binary built from `~/Devspace/noctalia-qs` and installed to
`/usr/local/bin/` so it wins PATH order if upstream ever sneaks in. Verify the
running binary with `qs --version` — it should say `noctalia-qs`, not
`quickshell`.

### Window navigation
No Alt+Tab daemon. Window-finding paths:
- `SUPER+arrows` — directional focus (instant, no overlay)
- `SUPER+SPACE` — noctalia launcher fuzzy-searches apps and open window titles
- `SUPER+1..0` — direct workspace jump
- `SUPER+S` — scratchpad special workspace toggle

### Clipboard picker (SUPER+V)
A floating kitty window running `cliphist list | fzf | cliphist decode |
wl-copy`. Themed automatically by kitty's Everforest palette. The window-class
`clipboard-picker` is sized 50% × 50% and centered via a windowrule in
`70-rules.conf`. No separate launcher daemon needed.

### Zsh plugin management
zinit self-bootstraps from a git clone in `.zshrc` — no packaging dependency.
Plugins are declared inline and pulled on first shell launch.
fast-syntax-highlighting loads last (required for correct interaction with
autosuggestions).

### Nvim plugins
Managed via lazy.nvim. `lazy-lock.json` is committed, so restores produce
byte-identical plugin trees. Theme: `neanias/everforest-nvim` (Lua port,
contrast=hard, transparent_mode on so the kitty bg shows through).
