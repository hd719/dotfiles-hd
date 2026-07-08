#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Developer/dotfiles-hd}"
HERDR_SRC_DIR="$DOTFILES_DIR/config/herdr"
HERDR_DEST_DIR="$HOME/.config/herdr"

backup_path() {
  local path="$1"
  local backup="$path.bak.$(date +%Y%m%d%H%M%S)"

  echo "Backing up $path -> $backup"
  mv "$path" "$backup"
}

link_path() {
  local src="$1"
  local dest="$2"

  if [[ ! -e "$src" ]]; then
    echo "Missing source: $src" >&2
    exit 1
  fi

  mkdir -p "$(dirname "$dest")"

  if [[ -L "$dest" ]]; then
    local current
    current="$(readlink "$dest")"
    if [[ "$current" == "$src" ]]; then
      echo "Already linked: $dest -> $src"
      return 0
    fi

    echo "Replacing symlink: $dest"
    rm "$dest"
  elif [[ -e "$dest" ]]; then
    backup_path "$dest"
  fi

  ln -s "$src" "$dest"
  echo "Linked: $dest -> $src"
}

main() {
  link_path "$HERDR_SRC_DIR/config.toml" "$HERDR_DEST_DIR/config.toml"
  echo "Herdr dotfiles bootstrap complete."
}

main "$@"

