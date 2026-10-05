#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Developer/dotfiles-hd}"

backup_and_link() {
  local src="$1"
  local dest="$2"
  local backup

  if [[ ! -e "$src" ]]; then
    echo "Missing source: $src" >&2
    exit 1
  fi

  mkdir -p "$(dirname "$dest")"

  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    echo "Already linked: $dest -> $src"
    return 0
  fi

  if [[ -e "$dest" || -L "$dest" ]]; then
    backup="$dest.backup-$(date +%Y%m%d-%H%M%S)"
    mv "$dest" "$backup"
    echo "Backed up: $dest -> $backup"
  fi

  ln -s "$src" "$dest"
  echo "Linked: $dest -> $src"
}

for source in \
  "$DOTFILES_DIR/config/bookokrat" \
  "$DOTFILES_DIR/config/ghostty/config" \
  "$DOTFILES_DIR/config/herdr/config.toml" \
  "$DOTFILES_DIR/config/hunk/config.toml" \
  "$DOTFILES_DIR/config/nvim" \
  "$DOTFILES_DIR/config/yazi/theme.toml" \
  "$DOTFILES_DIR/config/yazi/yazi.toml"
do
  if [[ ! -e "$source" ]]; then
    echo "Missing source: $source" >&2
    exit 1
  fi
done

if [[ -L "$HOME/.config/yazi" || ( -e "$HOME/.config/yazi" && ! -d "$HOME/.config/yazi" ) ]]; then
  echo "Yazi config parent must be a real directory: $HOME/.config/yazi" >&2
  exit 1
fi

backup_and_link \
  "$DOTFILES_DIR/config/bookokrat" \
  "$HOME/.config/bookokrat"
backup_and_link \
  "$DOTFILES_DIR/config/ghostty/config" \
  "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
backup_and_link \
  "$DOTFILES_DIR/config/herdr/config.toml" \
  "$HOME/.config/herdr/config.toml"
backup_and_link \
  "$DOTFILES_DIR/config/hunk/config.toml" \
  "$HOME/.config/hunk/config.toml"
backup_and_link "$DOTFILES_DIR/config/nvim" "$HOME/.config/nvim"
mkdir -p "$HOME/.config/yazi"
chmod 700 "$HOME/.config/yazi"
backup_and_link "$DOTFILES_DIR/config/yazi/theme.toml" "$HOME/.config/yazi/theme.toml"
backup_and_link "$DOTFILES_DIR/config/yazi/yazi.toml" "$HOME/.config/yazi/yazi.toml"

echo "Resilience terminal/editor links are ready."
