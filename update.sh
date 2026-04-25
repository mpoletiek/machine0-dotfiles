#!/usr/bin/env bash
# Re-stow everything after adding a new package directory.
# Idempotent — safe to run any time.

set -euo pipefail
DOTFILES="${DOTFILES:-$HOME/dotfiles}"

cd "$DOTFILES"
# Discover package dirs (any top-level dir that contains a . anywhere below)
pkgs=()
for d in */; do
    name="${d%/}"
    [ "$name" = "system" ] && continue
    pkgs+=("$name")
done

echo "==> Re-stowing: ${pkgs[*]}"
stow -v -R -t "$HOME" "${pkgs[@]}"
echo "==> Done."
