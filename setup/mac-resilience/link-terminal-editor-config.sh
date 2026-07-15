#!/usr/bin/env bash
# Stop on command errors (-e), unset variables (-u), and failures hidden inside
# pipelines (pipefail).
set -euo pipefail

# This work-Mac wrapper validates all three config sources first, then links
# only the scoped Ghostty, Herdr, and Neovim configuration.
# Callers may point at another clone; otherwise use the normal local repo path.
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Developer/dotfiles-hd}"

# Point a live config at its repo source without data loss. A correct link is a
# no-op; any conflict is moved to a timestamped backup before replacement.
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

# Validate every source before changing any destination, so a bad clone cannot
# leave the laptop only partly linked.
for source in \
  "$DOTFILES_DIR/config/ghostty/config" \
  "$DOTFILES_DIR/config/herdr/config.toml" \
  "$DOTFILES_DIR/config/nvim"
do
  if [[ ! -e "$source" ]]; then
    echo "Missing source: $source" >&2
    exit 1
  fi
done

backup_and_link \
  "$DOTFILES_DIR/config/ghostty/config" \
  "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
backup_and_link \
  "$DOTFILES_DIR/config/herdr/config.toml" \
  "$HOME/.config/herdr/config.toml"
# `NAME=value command` passes this clone path only to the child process. Reuse
# the shared linker because it honors XDG_CONFIG_HOME and verifies the final link.
DOTFILES_DIR="$DOTFILES_DIR" "$DOTFILES_DIR/setup/nvim/link-config.sh"

echo "Resilience terminal/editor links are ready."
