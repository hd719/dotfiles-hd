#!/bin/zsh
mkdir -p ~/gnome-keybindings-backup
dconf dump /org/gnome/settings-daemon/plugins/media-keys/ > ~/gnome-keybindings-backup/media-keys.dconf
dconf dump /org/gnome/desktop/wm/keybindings/ > ~/gnome-keybindings-backup/wm-keybindings.dconf
dconf dump /org/gnome/shell/keybindings/ > ~/gnome-keybindings-backup/shell-keybindings.dconf
dconf dump /org/gnome/mutter/keybindings/ > ~/gnome-keybindings-backup/mutter-keybindings.dconf
dconf dump /org/gnome/settings-daemon/plugins/ > ~/gnome-keybindings-backup/plugins-all.dconf
