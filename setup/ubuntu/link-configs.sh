#!/usr/bin/env bash
# Stop on command errors, unset variables, and failures hidden in pipelines.
set -euo pipefail

if [[ $# -ne 0 ]]; then
  echo "Usage: $0" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd -P)}"
SOURCE_ROOT="$DOTFILES_DIR/config"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
LAST_BACKUP=""

next_backup_path() {
  local path="$1"
  local base="$path.backup-$(date +%Y%m%d-%H%M%S)"
  local candidate="$base"
  local suffix=1

  while [[ -e "$candidate" || -L "$candidate" ]]; do
    candidate="$base-$suffix"
    suffix=$((suffix + 1))
  done

  printf '%s\n' "$candidate"
}

backup_path() {
  local path="$1"
  LAST_BACKUP="$(next_backup_path "$path")"
  mv "$path" "$LAST_BACKUP"
  echo "Backed up: $path -> $LAST_BACKUP"
}

link_path() {
  local source="$1"
  local target="$2"

  if [[ ! -e "$source" ]]; then
    echo "Skipping missing config source: $source"
    return
  fi

  mkdir -p "$(dirname "$target")"
  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    echo "Already linked: $target -> $source"
  else
    if [[ -e "$target" || -L "$target" ]]; then
      backup_path "$target"
    fi
    ln -s "$source" "$target"
    echo "Linked: $target -> $source"
  fi

  if [[ ! -L "$target" || "$(readlink "$target")" != "$source" ]]; then
    echo "Failed to link config: $target" >&2
    exit 1
  fi
  if [[ -d "$source" && ! -d "$target" ]] || [[ -f "$source" && ! -f "$target" ]]; then
    echo "Linked config has the wrong type: $target" >&2
    exit 1
  fi
}

prepare_tmux_directory() {
  local tmux_dir="$CONFIG_HOME/tmux"
  local backup

  # Older setup revisions linked the whole directory. Move that link aside so
  # plugins and other tmux runtime state can live locally from now on.
  if [[ -L "$tmux_dir" ]]; then
    backup_path "$tmux_dir"
    backup="$LAST_BACKUP"
    mkdir -p "$tmux_dir"
    if [[ -d "$backup/plugins" ]]; then
      cp -a "$backup/plugins" "$tmux_dir/plugins"
      echo "Preserved tmux plugins from: $backup/plugins"
    fi
  elif [[ -e "$tmux_dir" && ! -d "$tmux_dir" ]]; then
    backup_path "$tmux_dir"
    mkdir -p "$tmux_dir"
  else
    mkdir -p "$tmux_dir"
  fi
}

main() {
  local app

  mkdir -p "$CONFIG_HOME"
  for app in btop fastfetch bat wtf ghostty; do
    link_path "$SOURCE_ROOT/$app" "$CONFIG_HOME/$app"
  done

  # Never replace ~/.config/tmux: its plugins are machine-local runtime state.
  prepare_tmux_directory
  link_path "$SOURCE_ROOT/tmux/tmux.conf" "$CONFIG_HOME/tmux/tmux.conf"
  link_path "$SOURCE_ROOT/tmux/scripts" "$CONFIG_HOME/tmux/scripts"

  # A real login shell must activate the same mise-managed runtimes that setup
  # just installed. Back up any existing user file before linking this checkout.
  link_path "$DOTFILES_DIR/setup/ubuntu/.zshrc" "$HOME/.zshrc"

  echo "Ubuntu dotfiles config links are ready."
}

main
