#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing Ulauncher + binding Super+Space (Spotlight-style)"

# 1) Install Ulauncher from the official PPA
if ! command -v ulauncher >/dev/null 2>&1; then
  echo "==> Adding Ulauncher PPA and installing..."
  sudo apt update -y
  sudo apt install -y software-properties-common
  sudo add-apt-repository -y ppa:agornostal/ulauncher
  sudo apt update -y
  sudo apt install -y ulauncher
else
  echo "==> Ulauncher already installed, skipping."
fi

# 2) Create an autostart entry so it launches on login
AUTOSTART_DIR="$HOME/.config/autostart"
AUTOSTART_FILE="$AUTOSTART_DIR/ulauncher.desktop"
mkdir -p "$AUTOSTART_DIR"

cat > "$AUTOSTART_FILE" <<'EOF'
[Desktop Entry]
Type=Application
Name=Ulauncher
Comment=Application launcher for Linux
Exec=ulauncher --hide-window
OnlyShowIn=GNOME;Unity;Pantheon;Deepin;XFCE;LXQt;KDE;
X-GNOME-Autostart-enabled=true
EOF

echo "==> Autostart file written to $AUTOSTART_FILE"

# 3) Free Super+Space (GNOME uses it by default for input source switching)
#    We'll disable those to avoid conflicts.
echo "==> Unbinding GNOME input-source shortcuts that use Super+Space"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "[]"

# 4) Create/merge a GNOME custom keybinding for Super+Space -> ulauncher-toggle
SCHEMA="org.gnome.settings-daemon.plugins.media-keys"
BASE_KEY="custom-keybindings"

# Read existing list (could be "@as []" or an array of paths)
existing=$(gsettings get $SCHEMA $BASE_KEY)

# Function: find next available customN path
next_idx=0
while true; do
  candidate="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${next_idx}/"
  if [[ "$existing" != *"$candidate"* ]]; then
    new_path="$candidate"
    break
  fi
  next_idx=$((next_idx+1))
done

echo "==> Using keybinding slot: $new_path"

# Merge the new path into the array
if [[ "$existing" == "@as []" || "$existing" == "[]" ]]; then
  new_list="['$new_path']"
else
  # Insert before the closing bracket
  new_list="${existing%]*}, '$new_path']"
fi
gsettings set $SCHEMA $BASE_KEY "$new_list"

# Write the triplet keys for our new custom binding
KB_SCHEMA_PATH="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$new_path"
gsettings set "$KB_SCHEMA_PATH" name 'Ulauncher'
gsettings set "$KB_SCHEMA_PATH" command 'ulauncher-toggle'
gsettings set "$KB_SCHEMA_PATH" binding '<Super>space'

echo "==> Bound <Super>space to ulauncher-toggle"

# 5) Friendly summary
echo ""
echo "✅ Ulauncher installed and set to autostart."
echo "✅ <Super>Space (⌘+Space) now toggles Ulauncher."
echo "ℹ️  Log out and back in (Wayland) if the hotkey doesn’t respond immediately."
