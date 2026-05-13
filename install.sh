#!/usr/bin/env bash
# machine0-dotfiles — bootstrap script.
#
# Symlinks all dotfiles into $HOME via GNU Stow, installs the system profile
# snippet, and prints post-install actions. Safe to run multiple times
# (stow -R re-stows).
#
# Prereqs: git, stow, zsh, neovim, kitty, waybar, dunst, tmux already emerged.
# See README.md for the full fresh-install sequence.

set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
info() { printf '==> %s\n' "$*"; }
ok() { printf '    %s\n' "$*"; }

[ -d "$DOTFILES" ] || die "$DOTFILES does not exist — clone the repo first."
command -v stow >/dev/null || die "GNU stow not installed (emerge app-admin/stow)."
command -v git  >/dev/null || die "git not installed."

info "Stowing user dotfiles into \$HOME"
cd "$DOTFILES"
stow -v -R -t "$HOME" hypr kitty waybar dunst nvim tmux zsh noctalia bin razer-effects
ok "user dotfiles linked"

info "Installing system profile snippet"
if [ -f "$DOTFILES/system/profile.d-mpoletiek.sh" ]; then
    if sudo -n true 2>/dev/null; then
        sudo install -o root -g root -m 0644 \
            "$DOTFILES/system/profile.d-mpoletiek.sh" \
            /etc/profile.d/mpoletiek.sh
        ok "/etc/profile.d/mpoletiek.sh installed"
    else
        ok "(skipped; no passwordless sudo — run manually:)"
        printf '    sudo install -o root -g root -m 0644 %s /etc/profile.d/mpoletiek.sh\n' \
            "$DOTFILES/system/profile.d-mpoletiek.sh"
    fi
fi

info "Ensuring ~/.cache/zsh exists (for compinit)"
mkdir -p "$HOME/.cache/zsh"
ok "done"

cat <<'POST'

============================================================
Stow complete. Remaining manual actions:
============================================================

1. Apply portage USE flags (if not already set):
     sudo cp ~/dotfiles/system/package.use/*  /etc/portage/package.use/
     sudo emerge --ask --changed-use gui-wm/hyprland media-fonts/nerdfonts

2. Fonts:
     fc-cache -fv

2b. System themes (Plymouth + GRUB + wallpaper):
     bash ~/dotfiles/system/install-themes.sh
     # Rebuilds initramfs and grub.cfg. Reboot to see Plymouth splash.

3. Shell:
     chsh -s /usr/bin/zsh       # if not already zsh
     # Open a new zsh — zinit self-installs and pulls all plugins.
     # Run `p10k configure` if you want to change the prompt (optional —
     # ~/.p10k.zsh is already in the repo).

4. Hyprland plugins (hyprexpo):
     hyprpm add https://github.com/hyprwm/hyprland-plugins
     hyprpm update
     hyprpm enable hyprexpo
     hyprpm reload -n

5. tmux plugins:
     tmux
     # inside tmux: prefix + I  (capital i) to install plugins

6. Neovim plugins:
     nvim
     # lazy.nvim will auto-install all plugins based on lazy-lock.json

7. Restart Hyprland (or at minimum: hyprctl reload) to pick up live config.

POST
