#!/usr/bin/env bash
# Stop on command errors, unset variables, and failures hidden in pipelines.
set -euo pipefail

usage() {
  echo "Usage: $0 personal" >&2
  echo "This command is only for Hamel's personal macOS and Ubuntu machines." >&2
}

# Requiring the explicit scope keeps the personal runtime pins away from the
# narrower Resilience work-Mac setup, where each work repo owns its toolchain.
if [[ $# -ne 1 || "$1" != "personal" ]]; then
  usage
  exit 2
fi

# BASH_SOURCE finds this checkout even when the command is run elsewhere.
# DOTFILES_DIR remains overridable so a QA clone can be tested safely.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd -P)}"
SOURCE="$DOTFILES_DIR/config/mise"
TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/mise"

if [[ ! -f "$SOURCE/config.toml" ]]; then
  echo "Missing mise config source: $SOURCE/config.toml" >&2
  exit 1
fi

if ! command -v mise >/dev/null 2>&1; then
  echo "mise is required before this shared bootstrap can run." >&2
  echo "Install it with Homebrew on macOS or setup/ubuntu/install-mise.sh on Ubuntu." >&2
  exit 1
fi

mkdir -p "$(dirname "$TARGET")"

next_backup_path() {
  local path="$1"
  local base="$path.backup-$(date +%Y%m%d-%H%M%S)"
  local candidate="$base"
  local suffix=1

  # Two setup attempts can begin during the same second. Keep incrementing a
  # sibling suffix so `mv` never nests a new backup inside an older directory.
  while [[ -e "$candidate" || -L "$candidate" ]]; do
    candidate="$base-$suffix"
    suffix=$((suffix + 1))
  done

  printf '%s\n' "$candidate"
}

# A matching whole-directory link is already correct. Otherwise, move the
# existing path beside itself so setup never destroys machine-local config.
if [[ -L "$TARGET" && "$(readlink "$TARGET")" == "$SOURCE" ]]; then
  echo "Already linked: $TARGET -> $SOURCE"
else
  if [[ -e "$TARGET" || -L "$TARGET" ]]; then
    BACKUP="$(next_backup_path "$TARGET")"
    mv "$TARGET" "$BACKUP"
    echo "Backed up: $TARGET -> $BACKUP"
  fi

  ln -s "$SOURCE" "$TARGET"
  echo "Linked: $TARGET -> $SOURCE"
fi

# Verify the exact destination before mise reads or installs anything.
if [[ ! -L "$TARGET" || "$(readlink "$TARGET")" != "$SOURCE" || ! -d "$TARGET" ]]; then
  echo "Failed to link mise config: $TARGET" >&2
  exit 1
fi

# Global mise config is implicitly trusted. gopls uses mise's Go backend, so
# install the pinned Go runtime first on a completely fresh machine. The second
# command converges every configured tool; reshim refreshes their commands.
# `-C` prevents a project-local mise.toml in the caller's current directory from
# overriding this personal machine config during setup.
mise -C "$TARGET" install --yes go
mise -C "$TARGET" install --yes
mise -C "$TARGET" reshim

echo "mise personal toolchain is ready."
