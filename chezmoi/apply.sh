#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "$script_dir/lib.sh"
load_profile "${1:-}"
validate_profile_os
require_canonical_checkout
[[ "${DOTFILES_CHEZMOI_APPROVED:-0}" == 1 ]] \
  || die "set DOTFILES_CHEZMOI_APPROVED=1 after approving this host and preview"
[[ "$PROFILE" != mac-mini || "${DOTFILES_MAC_MINI_CONFIG_ONLY:-0}" == 1 ]] \
  || die "Mac mini requires DOTFILES_MAC_MINI_CONFIG_ONLY=1"
[[ "$PROFILE" != work-mac || "${DOTFILES_WORK_MAC_OPT_IN:-0}" == 1 ]] \
  || die "work Mac requires DOTFILES_WORK_MAC_OPT_IN=1"

if [[ "$PROFILE" == mac-mini ]]; then
  while IFS='|' read -r relative _source; do
    parent="$(dirname "$(target_path "$relative")")"
    while [[ "$parent" != "$DEST_DIR" ]]; do
      [[ -d "$parent" && ! -L "$parent" ]] \
        || die "Mac mini requires an existing real parent directory: $parent"
      parent="$(dirname "$parent")"
    done
  done < "$PROFILE_MANIFEST"
fi

backup_dir="$($script_dir/backup.sh "$PROFILE")"
"$script_dir/rollback.sh" "$PROFILE" "$backup_dir" --preview
printf 'rollback command: %s/rollback.sh %s %s\n' \
  "$script_dir" "$PROFILE" "$backup_dir"

activation_preexisting=0
if [[ -e "$ACTIVE_MARKER" || -L "$ACTIVE_MARKER" ]]; then
  [[ -f "$ACTIVE_MARKER" && ! -L "$ACTIVE_MARKER" ]] \
    || die "activation marker is not a regular file: $ACTIVE_MARKER"
  activation_preexisting=1
fi

if [[ "$PROFILE" == mac-mini ]]; then
  cm apply --exclude=dirs --force --no-tty
  second_apply="$(cm apply --exclude=dirs --force --no-tty --verbose 2>&1)"
else
  cm apply --force --no-tty
  second_apply="$(cm apply --force --no-tty --verbose 2>&1)"
fi
[[ -z "$second_apply" ]] || {
  printf '%s\n' "$second_apply" >&2
  die "second apply was not a no-op; roll back with $backup_dir"
}
if [[ "$PROFILE" == mac-mini ]]; then
  [[ -z "$(cm status --exclude=dirs)" ]] \
    || die "chezmoi reports drift; roll back with $backup_dir"
  cm verify --exclude=scripts,dirs
else
  [[ -z "$(cm status)" ]] \
    || die "chezmoi reports drift; roll back with $backup_dir"
  cm verify --exclude=scripts
fi

if [[ "$PROFILE" == ubuntu ]]; then
  activate_profile
fi

if ! "$script_dir/doctor.sh" "$PROFILE"; then
  if [[ "$PROFILE" == ubuntu && "$activation_preexisting" == 0 ]]; then
    failed_marker="$ACTIVE_MARKER.failed.$(date +%Y%m%d-%H%M%S)-$$"
    mv "$ACTIVE_MARKER" "$failed_marker"
    printf 'Ubuntu activation withdrawn after doctor failure: %s\n' \
      "$failed_marker" >&2
  fi
  die "profile doctor failed; roll back with $backup_dir"
fi
