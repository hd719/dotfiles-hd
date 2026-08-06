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

backup_dir="$($script_dir/backup.sh "$PROFILE")"
printf 'rollback command: %s/rollback.sh %s %s\n' \
  "$script_dir" "$PROFILE" "$backup_dir"

cm apply --force --no-tty
second_apply="$(cm apply --force --no-tty --verbose 2>&1)"
[[ -z "$second_apply" ]] || {
  printf '%s\n' "$second_apply" >&2
  die "second apply was not a no-op; roll back with $backup_dir"
}
[[ -z "$(cm status)" ]] || die "chezmoi reports drift; roll back with $backup_dir"
cm verify --exclude=scripts
"$script_dir/doctor.sh" "$PROFILE"
