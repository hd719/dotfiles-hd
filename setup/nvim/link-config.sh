#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd -P)}"
SOURCE="$DOTFILES_DIR/config/nvim"
TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

if [[ ! -d "$SOURCE" ]]; then
  echo "Missing Neovim config source: $SOURCE" >&2
  exit 1
fi

mkdir -p "$(dirname "$TARGET")"

if [[ -L "$TARGET" && "$(readlink "$TARGET")" == "$SOURCE" ]]; then
  echo "Already linked: $TARGET -> $SOURCE"
  exit 0
fi

if [[ -e "$TARGET" || -L "$TARGET" ]]; then
  BACKUP="$TARGET.backup-$(date +%Y%m%d-%H%M%S)"
  mv "$TARGET" "$BACKUP"
  echo "Backed up: $TARGET -> $BACKUP"
fi

ln -s "$SOURCE" "$TARGET"

if [[ ! -L "$TARGET" || "$(readlink "$TARGET")" != "$SOURCE" ]]; then
  echo "Failed to link: $TARGET" >&2
  exit 1
fi

echo "Linked: $TARGET -> $SOURCE"
