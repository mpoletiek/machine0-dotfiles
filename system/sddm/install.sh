#!/usr/bin/env bash
# Install SDDM theme + config for this machine.
#
# Copies:
#   themes/everforest-warrior/ → /usr/share/sddm/themes/everforest-warrior/
#   sddm.conf.d/10-theme.conf  → /etc/sddm.conf.d/10-theme.conf
#   conf.d-xdm                 → /etc/conf.d/xdm   (sets DISPLAYMANAGER=sddm)
#
# Does NOT enable the xdm service or stop any running session — run the
# post-install commands printed at the end.
#
# Re-runnable: overwrites destination files in place.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_SRC="$HERE/themes/everforest-warrior"
THEME_DST="/usr/share/sddm/themes/everforest-warrior"
CONF_SRC="$HERE/sddm.conf.d/10-theme.conf"
CONF_DST="/etc/sddm.conf.d/10-theme.conf"
XDM_SRC="$HERE/conf.d-xdm"
XDM_DST="/etc/conf.d/xdm"

info() { printf '==> %s\n' "$*"; }
ok()   { printf '    %s\n' "$*"; }

if [ "$(id -u)" -ne 0 ]; then
    exec sudo -E "$0" "$@"
fi

[ -d "$THEME_SRC" ] || { echo "missing source: $THEME_SRC" >&2; exit 1; }

info "Installing theme → $THEME_DST"
install -d -m 0755 "$THEME_DST"
install -m 0644 "$THEME_SRC"/metadata.desktop "$THEME_DST/"
install -m 0644 "$THEME_SRC"/theme.conf       "$THEME_DST/"
install -m 0644 "$THEME_SRC"/Main.qml         "$THEME_DST/"
install -m 0644 "$THEME_SRC"/background.jpg   "$THEME_DST/"
[ -f "$THEME_SRC/README.md" ] && install -m 0644 "$THEME_SRC/README.md" "$THEME_DST/"
ok "theme deployed"

info "Installing SDDM config → $CONF_DST"
install -d -m 0755 /etc/sddm.conf.d
install -m 0644 "$CONF_SRC" "$CONF_DST"
ok "sddm.conf.d entry installed"

info "Setting DISPLAYMANAGER=sddm in $XDM_DST"
# Back up the original once, the first time we touch it.
if [ -f "$XDM_DST" ] && [ ! -f "$XDM_DST.pre-dotfiles" ]; then
    cp -a "$XDM_DST" "$XDM_DST.pre-dotfiles"
    ok "backed up original to $XDM_DST.pre-dotfiles"
fi
install -m 0644 "$XDM_SRC" "$XDM_DST"
ok "xdm conf installed"

# Warn if /etc/rc.conf overrides DISPLAYMANAGER (the xdm init script honors
# rc.conf over /etc/conf.d/xdm if both are set).
if grep -Eq '^\s*DISPLAYMANAGER=' /etc/rc.conf 2>/dev/null; then
    echo "!! /etc/rc.conf defines DISPLAYMANAGER — that overrides /etc/conf.d/xdm."
    echo "   Remove or update that line so SDDM is actually used."
fi

cat <<'POST'

============================================================
SDDM theme + config installed. Remaining manual actions:
============================================================

1. Enable the display manager at boot (OpenRC):
     sudo rc-update add xdm default

2. Switch now (from a TTY, not from inside the current graphical session):
     sudo rc-service xdm start

   Or reboot.

3. If the greeter appears unthemed, check logs:
     journalctl -u sddm          # if using journal
     # or: tail /var/log/sddm.log /var/log/sddm-greeter.log

4. To enable autologin: uncomment the [Autologin] block in
   /etc/sddm.conf.d/10-theme.conf and restart SDDM.

POST
