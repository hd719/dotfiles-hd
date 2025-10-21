#!/usr/bin/env bash
set -euo pipefail

echo "==> Omakub-style workspaces & navigation (Ubuntu GNOME)"

# --- Sanity ---
command -v gsettings >/dev/null || { echo "gsettings not found. Are you on GNOME?"; exit 1; }

# --- Backup a few keys (lightweight) ---
BACKUP="$HOME/dconf-backup-$(date +%Y%m%d-%H%M%S).ini"
echo "==> Backing up relevant keys to $BACKUP"
{
  echo "[org/gnome/desktop/wm/preferences]"
  echo "num-workspaces=$(gsettings get org.gnome.desktop.wm.preferences num-workspaces || echo 4)"
  echo
  echo "[org/gnome/mutter]"
  echo "dynamic-workspaces=$(gsettings get org.gnome.mutter dynamic-workspaces || echo true)"
  echo
  echo "[org/gnome/desktop/wm/keybindings]"
  for k in switch-to-workspace-{1..10} move-to-workspace-{1..10}; do
    echo "$k=$(gsettings get org.gnome.desktop.wm.keybindings $k 2>/dev/null || echo \"@as []\")"
  done
  echo
  echo "[org/gnome/shell/keybindings]"
  for k in switch-to-application-{1..10}; do
    echo "$k=$(gsettings get org.gnome.shell.keybindings $k 2>/dev/null || echo \"@as []\")"
  done
} > "$BACKUP" || true

# --- Fixed workspaces like Omakub ---
echo "==> Setting fixed workspaces = 6"
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.desktop.wm.preferences num-workspaces 6

# --- Free Super+Number from app switching + move app switching to Ctrl+Number ---
echo "==> Freeing Super+Number (dock apps) and remapping apps to Ctrl+1..9"
for i in {1..9}; do
  gsettings set org.gnome.shell.keybindings "switch-to-application-$i" "['<Control>$i']"
done

# --- Dash-to-Dock: disable its Super hotkeys so it won't steal Super+Number ---
echo "==> Disabling Dash-to-Dock hot-keys"
gsettings set org.gnome.shell.extensions.dash-to-dock hot-keys false || true
# (If you're on the Ubuntu fork, this key may not exist—ignore errors.)

# --- Bind Super+Number to switch workspaces; Shift+Super+Number to move windows ---
echo "==> Binding Super+Number to SWITCH to workspace"
for i in {1..6}; do
  gsettings set org.gnome.desktop.wm.keybindings "switch-to-workspace-$i" "['<Super>$i']"
done

echo "==> Binding Super+Shift+Number to MOVE windows to workspace"
for i in {1..6}; do
  gsettings set org.gnome.desktop.wm.keybindings "move-to-workspace-$i" "['<Shift><Super>$i']"
done

# --- Helpful tiling/windowing bindings (explicit) ---
echo "==> Ensuring basic window-tiling shortcuts are set"
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-left  "['<Shift><Super>Left']"
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-right "['<Shift><Super>Right']"
gsettings set org.gnome.desktop.wm.keybindings toggle-maximized      "['<Super>Up']"
gsettings set org.gnome.desktop.wm.keybindings begin-move            "['<Super>F7']"
gsettings set org.gnome.desktop.wm.keybindings begin-resize          "['<Super>F8']"
gsettings set org.gnome.mutter.keybindings toggle-tiled-left         "['<Super>Left']"
gsettings set org.gnome.mutter.keybindings toggle-tiled-right        "['<Super>Right']"

# --- Packages: Tweaks + Extensions + Extension Manager ---
echo "==> Installing helpful packages (Tweaks, Extensions, Extension Manager)"
if command -v apt >/dev/null; then
  sudo apt update -y
  sudo apt install -y gnome-tweaks gnome-shell-extensions gnome-shell-extension-manager chrome-gnome-shell || true
else
  echo "apt not found; skipping package install."
fi

# --- Extensions: Tiling Assistant (optional) + Space Bar (workspaces UI) ---
if command -v extension-manager >/dev/null 2>&1; then
  echo "==> Installing/Enabling extensions via Extension Manager CLI"

  # Tiling Assistant (optional)
  TA_UUID="tiling-assistant@leleat-on-github"
  set +e
  extension-manager install "$TA_UUID" >/dev/null 2>&1
  extension-manager enable  "$TA_UUID" >/dev/null 2>&1
  set -e

  # Space Bar (WORKSPACES BAR you confirmed works)
  SB_UUID="space-bar@luchrioh"
  set +e
  extension-manager install "$SB_UUID" >/dev/null 2>&1
  extension-manager enable  "$SB_UUID" >/dev/null 2>&1
  set -e
else
  echo "==> Extension Manager CLI not found."
  echo "   - Install manually if desired:"
  echo "     * Tiling Assistant: https://extensions.gnome.org/extension/3733/tiling-assistant/"
  echo "     * Space Bar:        https://extensions.gnome.org/extension/5090/space-bar/"
fi

echo "==> Done."
echo "   - Workspaces: fixed 6"
echo "   - Switch: Super+1..6"
echo "   - Move window: Super+Shift+1..6"
echo "   - Dock apps: Ctrl+1..9"
echo "   - Space Bar extension enabled for numbered workspaces"
echo "   * Log out/in (Wayland) to ensure all bindings and extensions take effect."


# - **What:** Updated “Omakub-style” GNOME setup script that: fixes 6 workspaces, maps `Super+1..6` to switch and `Shift+Super+1..6` to move, **moves dock app switching to `Ctrl+1..9`**, disables Dash-to-Dock hotkeys, and **installs & enables the Space Bar extension** (`space-bar@luchrioh`) for numbered workspace UI. Tiling Assistant stays optional.
# - **How:** Uses `gsettings` for keybindings/settings and `extension-manager` CLI to install/enable extensions when available.
# - **Why:** Matches Omakub’s fast, keyboard-first workflow on Ubuntu in a VMware (Mac M3) VM.

# ---

# ### Updated script
# Save as `omakub-gnome-setup.sh`, then run:
# `chmod +x omakub-gnome-setup.sh && ./omakub-gnome-setup.sh`
