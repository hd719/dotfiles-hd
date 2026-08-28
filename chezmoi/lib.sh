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
    ubuntu|mac-thin|mac-pro|mac-mini|mac-work) ;;
    *) die "profile must be ubuntu, mac-thin, mac-pro, mac-mini, or mac-work" ;;
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
    ubuntu:Linux|mac-thin:Darwin|mac-pro:Darwin|mac-mini:Darwin|mac-work:Darwin) ;;
    *) die "$PROFILE does not match $(uname -s)" ;;
  esac
}

require_canonical_checkout() {
  [[ "${DOTFILES_CHEZMOI_TEST:-0}" == 1 ]] && return
  local repo_origin reviewed_ref tracking_ref
  reviewed_ref="${DOTFILES_CHEZMOI_REVIEWED_REF:-master}"
  git check-ref-format --branch "$reviewed_ref" >/dev/null 2>&1 \
    || die "invalid reviewed branch: $reviewed_ref"
  [[ "$reviewed_ref" == master || "$PROFILE" == ubuntu ]] \
    || die "custom reviewed branches are limited to the Ubuntu canary"
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
  [[ "$(git -C "$REPO_DIR" branch --show-current)" == "$reviewed_ref" ]] \
    || die "apply requires reviewed $reviewed_ref"
  [[ -z "$(git -C "$REPO_DIR" status --porcelain)" ]] \
    || die "apply requires a clean checkout"
  tracking_ref="refs/remotes/origin/$reviewed_ref"
  git -C "$REPO_DIR" show-ref --verify --quiet "$tracking_ref" \
    || die "origin/$reviewed_ref is missing; fetch the reviewed branch first"
  [[ "$(git -C "$REPO_DIR" rev-parse HEAD)" == \
    "$(git -C "$REPO_DIR" rev-parse "$tracking_ref")" ]] \
    || die "$reviewed_ref does not match origin/$reviewed_ref"
}

validate_profile_layout() {
  local relative source managed_mode target expected parent parent_relative

  if [[ -n "$PROFILE_ANCESTORS" ]]; then
    while IFS='|' read -r relative source managed_mode; do
      target="$(target_path "$relative")"
      expected="$(expected_source "$source")"
      [[ "$managed_mode" =~ ^[0-7]{3,4}$ ]] \
        || die "invalid $PROFILE ancestor mode: $relative"
      if [[ -L "$target" ]]; then
        [[ "$(readlink "$target")" == "$expected" ]] \
          || die "unexpected $PROFILE ancestor link: $target"
      elif [[ -e "$target" ]]; then
        [[ -d "$target" ]] \
          || die "$PROFILE ancestor must be absent, a symlink, or a directory: $target"
      fi
    done < "$PROFILE_ANCESTORS"
  fi

  while IFS='|' read -r relative _source; do
    parent="$(dirname "$(target_path "$relative")")"
    while [[ "$parent" != "$DEST_DIR" ]]; do
      parent_relative="${parent#"$DEST_DIR/"}"
      if [[ -L "$parent" ]]; then
        if [[ -z "$PROFILE_ANCESTORS" ]] \
          || ! cut -d '|' -f 1 "$PROFILE_ANCESTORS" \
            | grep -Fqx "$parent_relative"; then
          die "unapproved $PROFILE symlink parent: $parent"
        fi
      elif [[ -e "$parent" ]]; then
        [[ -d "$parent" ]] \
          || die "$PROFILE requires an existing parent directory: $parent"
      elif [[ -n "$PROFILE_ANCESTORS" ]] \
        && cut -d '|' -f 1 "$PROFILE_ANCESTORS" \
          | grep -Fqx "$parent_relative"; then
        :
      elif [[ "$PROFILE" == mac-mini ]]; then
        die "$PROFILE requires an approved parent directory: $parent"
      fi
      parent="$(dirname "$parent")"
    done
  done < "$PROFILE_MANIFEST"
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
