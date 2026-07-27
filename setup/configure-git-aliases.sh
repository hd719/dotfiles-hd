#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd -P)"
ALIASES_CONFIG="$ROOT_DIR/config/git/aliases.gitconfig"
MODE="${1:---check}"
STAMP="${DOTFILES_STAMP:-$(date +%Y%m%d-%H%M%S)}"
BACKUP_SEPARATOR="${DOTFILES_BACKUP_SEPARATOR:--}"

usage() {
  printf 'Usage: %s --check|--apply\n' "${0##*/}"
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

next_backup_path() {
  local source_path="$1"
  local candidate="${source_path}.backup${BACKUP_SEPARATOR}${STAMP}"
  local suffix=1

  while [[ -e "$candidate" || -L "$candidate" ]]; do
    candidate="${source_path}.backup${BACKUP_SEPARATOR}${STAMP}.${suffix}"
    suffix=$((suffix + 1))
  done

  printf '%s\n' "$candidate"
}

global_config_path() {
  local xdg_config_home="${XDG_CONFIG_HOME:-$HOME/.config}"

  if [[ -e "$HOME/.gitconfig" || -L "$HOME/.gitconfig" ]]; then
    printf '%s\n' "$HOME/.gitconfig"
  elif [[ -e "$xdg_config_home/git/config" || -L "$xdg_config_home/git/config" ]]; then
    printf '%s\n' "$xdg_config_home/git/config"
  else
    printf '%s\n' "$HOME/.gitconfig"
  fi
}

include_is_configured() {
  git config --global --get-all include.path 2>/dev/null \
    | grep -Fxq "$ALIASES_CONFIG"
}

check_aliases() {
  include_is_configured \
    && [[ "$(git config --global --includes --get alias.st 2>/dev/null || true)" == "status" ]]
}

[[ -f "$ALIASES_CONFIG" ]] || fail "missing aliases config: $ALIASES_CONFIG"
command -v git >/dev/null 2>&1 || fail "git is not available"

case "$MODE" in
  --check)
    check_aliases || fail "portable Git aliases are not included from $ALIASES_CONFIG"
    printf 'Portable Git aliases included from %s\n' "$ALIASES_CONFIG"
    ;;
  --apply)
    if ! include_is_configured; then
      global_config="$(global_config_path)"
      if [[ -L "$global_config" ]]; then
        [[ -f "$global_config" ]] || fail "global Git config is a dangling link: $global_config"
        backup="$(next_backup_path "$global_config")"
        cp -pL "$global_config" "$backup"
        rm "$global_config"
        cp -p "$backup" "$global_config"
        printf 'Migrated symlinked Git config to a machine-owned file; backup: %s\n' "$backup"
      elif [[ -f "$global_config" ]]; then
        backup="$(next_backup_path "$global_config")"
        cp -p "$global_config" "$backup"
        printf 'Backed up Git config: %s\n' "$backup"
      elif [[ -e "$global_config" ]]; then
        fail "global Git config is not a regular file: $global_config"
      fi

      mkdir -p "$(dirname "$global_config")"
      git config --file "$global_config" --add include.path "$ALIASES_CONFIG"
    fi

    check_aliases || fail "portable Git aliases did not become active"
    printf 'Portable Git aliases included from %s\n' "$ALIASES_CONFIG"
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
