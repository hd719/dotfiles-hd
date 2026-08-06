#!/usr/bin/env bash
set -euo pipefail
umask 077

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/lib.sh"
load_profile "${1:-}"
validate_profile_os
backup_dir="${2:-}"
[[ -d "$backup_dir" && -r "$backup_dir/manifest.tsv" ]] \
  || die "usage: rollback.sh PROFILE BACKUP_DIRECTORY"
case "$backup_dir/" in
  "$BACKUP_ROOT"/*/) ;;
  *) die "backup is outside $BACKUP_ROOT" ;;
esac
grep -Fqx $'profile\t'"$PROFILE" "$backup_dir/metadata.tsv" \
  || die "backup profile mismatch"
active_state="$(awk -F $'\t' '$1 == "active" { print $2 }' \
  "$backup_dir/metadata.tsv")"
case "$active_state" in
  absent|present) ;;
  *) die "backup activation state is invalid" ;;
esac

replaced="$backup_dir/replaced-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$replaced"
while IFS='|' read -r relative type link mode checksum; do
  target="$(target_path "$relative")"
  displaced="$replaced/$relative"
  if [[ -e "$target" || -L "$target" ]]; then
    mkdir -p "$(dirname "$displaced")"
    mv "$target" "$displaced"
  fi
  if [[ "$type" != absent ]]; then
    saved="$backup_dir/files/$relative"
    [[ -e "$saved" || -L "$saved" ]] || die "missing saved target: $relative"
    mkdir -p "$(dirname "$target")"
    cp -a "$saved" "$target"
  fi

  case "$type" in
    absent) [[ ! -e "$target" && ! -L "$target" ]] ;;
    symlink) [[ -L "$target" && "$(readlink "$target")" == "$link" ]] ;;
    file)
      [[ -f "$target" && ! -L "$target" ]]
      [[ "$(file_checksum "$target")" == "$checksum" ]]
      ;;
    directory) [[ -d "$target" && ! -L "$target" ]] ;;
    *) die "unsupported manifest type: $type" ;;
  esac || die "restore verification failed: $target"
  [[ "$type" == absent || "$type" == symlink || "$(path_mode "$target")" == "$mode" ]] \
    || die "restored mode mismatch: $target"
done < "$backup_dir/manifest.tsv"

if [[ -e "$ACTIVE_MARKER" || -L "$ACTIVE_MARKER" ]]; then
  mkdir -p "$replaced/activation"
  mv "$ACTIVE_MARKER" "$replaced/activation/$PROFILE-active"
fi
if [[ "$active_state" == present ]]; then
  saved_marker="$backup_dir/activation-marker"
  [[ -f "$saved_marker" && ! -L "$saved_marker" ]] \
    || die "missing saved activation marker"
  mkdir -p "$STATE_DIR"
  cp -p "$saved_marker" "$ACTIVE_MARKER"
  cmp -s "$saved_marker" "$ACTIVE_MARKER" \
    || die "activation marker restore verification failed"
fi

printf 'rollback restored: %s\n' "$backup_dir"
printf 'displaced chezmoi state retained at: %s\n' "$replaced"
if [[ "$active_state" == present ]]; then
  printf 'chezmoi ownership restored to its pre-apply active state.\n'
else
  printf 'chezmoi ownership stopped; the previous writer is active again.\n'
fi
