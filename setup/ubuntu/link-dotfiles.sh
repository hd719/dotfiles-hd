#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd -P)"

backup_path() {
  local target="$1"
  local backup
  local suffix=0

  backup="${target}.backup.$(date +%Y%m%d-%H%M%S)"
  while [[ -e "$backup" || -L "$backup" ]]; do
    suffix=$((suffix + 1))
    backup="${target}.backup.$(date +%Y%m%d-%H%M%S).$suffix"
  done

  mv "$target" "$backup"
  printf 'Backed up %s to %s\n' "$target" "$backup"
}

safe_link() {
  local source="$1"
  local target="$2"

  mkdir -p "$(dirname "$target")"
  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    return
  fi
  if [[ -e "$target" || -L "$target" ]]; then
    backup_path "$target"
  fi
  ln -s "$source" "$target"
  printf 'Linked %s -> %s\n' "$target" "$source"
}

ensure_directory() {
  local directory="$1"

  if [[ -L "$directory" || (-e "$directory" && ! -d "$directory") ]]; then
    backup_path "$directory"
  fi
  mkdir -p "$directory"
}

legacy_lsd_aliases="$HOME/.config/zsh/lsd-aliases.zsh"
legacy_shared_aliases="$HOME/.config/zsh/aliases.zsh"

ensure_directory "$HOME/.config/ghostty"
ensure_directory "$HOME/.config/herdr"
ensure_directory "$HOME/.config/hunk"

if [[ -L "$legacy_lsd_aliases" ]] \
  && [[ "$(readlink "$legacy_lsd_aliases")" == "$ROOT_DIR/config/zsh/lsd-aliases.zsh" ]]; then
  rm "$legacy_lsd_aliases"
fi
if [[ -L "$legacy_shared_aliases" ]] \
  && [[ "$(readlink "$legacy_shared_aliases")" == "$ROOT_DIR/config/zsh/aliases.zsh" ]]; then
  rm "$legacy_shared_aliases"
fi

safe_link "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
safe_link "$SCRIPT_DIR/ghostty.conf" "$HOME/.config/ghostty/config"
safe_link "$ROOT_DIR/config/starship/starship.toml" "$HOME/.config/starship.toml"
safe_link "$ROOT_DIR/config/git/.gitignore_global" "$HOME/.gitignore_global"
safe_link "$SCRIPT_DIR/ssh/config" "$HOME/.ssh/config"
safe_link "$ROOT_DIR/config/bookokrat" "$HOME/.config/bookokrat"
safe_link "$ROOT_DIR/config/btop" "$HOME/.config/btop"
safe_link "$ROOT_DIR/config/fastfetch" "$HOME/.config/fastfetch"
safe_link "$ROOT_DIR/config/herdr/config.toml" "$HOME/.config/herdr/config.toml"
safe_link "$ROOT_DIR/config/hunk/config.toml" "$HOME/.config/hunk/config.toml"
safe_link "$ROOT_DIR/config/tmux" "$HOME/.config/tmux"
safe_link "$SCRIPT_DIR/bin/codex" "$HOME/.local/bin/codex"

git config --global core.editor nvim
git config --global core.excludesfile "$HOME/.gitignore_global"
