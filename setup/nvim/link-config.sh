#!/usr/bin/env bash
# Stop on command errors (-e), unset variables (-u), and failures hidden inside
# pipelines (pipefail).
set -euo pipefail

# Safely link the live Neovim config to this repo. A correct link is a no-op;
# any conflicting path is backed up before it is replaced.
# BASH_SOURCE locates this file independently of the caller's current directory.
# Environment overrides support alternate clones and XDG config locations.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd -P)}"
SOURCE="$DOTFILES_DIR/config/nvim"
TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

if [[ ! -d "$SOURCE" ]]; then
  echo "Missing Neovim config source: $SOURCE" >&2
  exit 1
fi

mkdir -p "$(dirname "$TARGET")"

# This early success makes reruns idempotent: an already-correct link is untouched.
if [[ -L "$TARGET" && "$(readlink "$TARGET")" == "$SOURCE" ]]; then
  echo "Already linked: $TARGET -> $SOURCE"
  exit 0
fi

# `-e` catches files and directories; `-L` also catches dangling symlinks.
# Back either one up so an existing local config is never destroyed.
if [[ -e "$TARGET" || -L "$TARGET" ]]; then
  BACKUP="$TARGET.backup-$(date +%Y%m%d-%H%M%S)"
  mv "$TARGET" "$BACKUP"
  echo "Backed up: $TARGET -> $BACKUP"
fi

ln -s "$SOURCE" "$TARGET"

# Verify the exact target so the script cannot report success for a wrong link.
if [[ ! -L "$TARGET" || "$(readlink "$TARGET")" != "$SOURCE" ]]; then
  echo "Failed to link: $TARGET" >&2
  exit 1
fi

echo "Linked: $TARGET -> $SOURCE"
