#!/usr/bin/env bash

set -euo pipefail

CHEZMOI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DIR="$(cd "$CHEZMOI_DIR/.." && pwd -P)"
SOURCE_DIR="$CHEZMOI_DIR/source"
PROFILES_DIR="$CHEZMOI_DIR/profiles"
DEST_DIR="${CHEZMOI_DESTINATION:-$HOME}"
STATE_DIR="${CHEZMOI_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-hd/chezmoi}"
BACKUP_ROOT="${CHEZMOI_BACKUP_ROOT:-${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-hd/chezmoi-backups}"
CHEZMOI_BIN="${CHEZMOI_BIN:-$HOME/.local/bin/chezmoi}"
EXPECTED_REPO_ORIGIN_SSH="git@github.com:hd719/dotfiles-hd.git"
EXPECTED_REPO_ORIGIN_HTTPS="https://github.com/hd719/dotfiles-hd.git"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

load_profile() {
  PROFILE="${1:-}"
  case "$PROFILE" in
    ubuntu|mac-thin|mac-pro|mac-mini|work-mac) ;;
    *) die "profile must be ubuntu, mac-thin, mac-pro, mac-mini, or work-mac" ;;
  esac
  PROFILE_CONFIG="$PROFILES_DIR/$PROFILE.toml"
  PROFILE_MANIFEST="$PROFILES_DIR/$PROFILE.paths"
  PROFILE_ANCESTORS="$PROFILES_DIR/$PROFILE.ancestors"
  [[ -f "$PROFILE_ANCESTORS" ]] || PROFILE_ANCESTORS=''
  ACTIVE_MARKER="$STATE_DIR/$PROFILE-active"
  [[ -f "$PROFILE_CONFIG" && -f "$PROFILE_MANIFEST" ]] \
    || die "incomplete profile: $PROFILE"
}

activate_profile() {
  local temporary_marker="$ACTIVE_MARKER.tmp.$$"

  mkdir -p "$STATE_DIR"
  printf 'profile=%s\ncommit=%s\n' \
    "$PROFILE" "$(git -C "$REPO_DIR" rev-parse HEAD)" > "$temporary_marker"
  chmod 600 "$temporary_marker"
  mv "$temporary_marker" "$ACTIVE_MARKER"
}

validate_profile_os() {
  [[ "${DOTFILES_CHEZMOI_TEST:-0}" == 1 ]] && return
  case "$PROFILE:$(uname -s)" in
    ubuntu:Linux|mac-thin:Darwin|mac-pro:Darwin|mac-mini:Darwin|work-mac:Darwin) ;;
    *) die "$PROFILE does not match $(uname -s)" ;;
  esac
}

require_canonical_checkout() {
  [[ "${DOTFILES_CHEZMOI_TEST:-0}" == 1 ]] && return
  [[ "$REPO_DIR" == "$HOME/Developer/dotfiles-hd" ]] \
    || die "apply requires $HOME/Developer/dotfiles-hd"
  [[ "$DEST_DIR" == "$HOME" ]] || die "apply destination must be HOME"
  [[ "$BACKUP_ROOT" == "${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-hd/chezmoi-backups" ]] \
    || die "apply backup root must use the documented host-local path"
  repo_origin="$(git -C "$REPO_DIR" remote get-url origin 2>/dev/null)"
  case "$repo_origin" in
    "$EXPECTED_REPO_ORIGIN_SSH"|"$EXPECTED_REPO_ORIGIN_HTTPS") ;;
    *) die "apply requires canonical origin hd719/dotfiles-hd" ;;
  esac
  [[ "$(git -C "$REPO_DIR" branch --show-current)" == master ]] \
    || die "apply requires reviewed master"
  [[ -z "$(git -C "$REPO_DIR" status --porcelain)" ]] \
    || die "apply requires a clean checkout"
  git -C "$REPO_DIR" show-ref --verify --quiet refs/remotes/origin/master \
    || die "origin/master is missing; run scripts/sync-dotfiles.sh first"
  [[ "$(git -C "$REPO_DIR" rev-parse HEAD)" == \
    "$(git -C "$REPO_DIR" rev-parse origin/master)" ]] \
    || die "master does not match origin/master; run scripts/sync-dotfiles.sh first"
}

cm() {
  mkdir -p "$STATE_DIR"
  "$CHEZMOI_BIN" \
    --source "$SOURCE_DIR" \
    --config "$PROFILE_CONFIG" \
    --destination "$DEST_DIR" \
    --persistent-state "$STATE_DIR/$PROFILE.boltdb" \
    "$@"
}

expected_source() {
  case "$1" in
    @absolute:*) printf '%s\n' "${1#@absolute:}" ;;
    *) printf '%s\n' "$REPO_DIR/$1" ;;
  esac
}

target_path() {
  case "$1" in
    /*|*'..'*) die "unsafe profile target: $1" ;;
    *) printf '%s\n' "$DEST_DIR/$1" ;;
  esac
}

path_mode() {
  if [[ "$(uname -s)" == Darwin ]]; then
    stat -f '%Lp' "$1"
  else
    stat -c '%a' "$1"
  fi
}

file_checksum() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}
