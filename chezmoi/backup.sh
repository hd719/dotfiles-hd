#!/usr/bin/env bash
set -euo pipefail
umask 077

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/lib.sh"
load_profile "${1:-}"
validate_profile_os
require_canonical_checkout

stamp="$(date +%Y%m%d-%H%M%S)"
backup_dir="$BACKUP_ROOT/$stamp-$PROFILE"
suffix=0
mkdir -p "$BACKUP_ROOT"
chmod 700 "$BACKUP_ROOT"
while [[ -e "$backup_dir" ]]; do
  suffix=$((suffix + 1))
  backup_dir="$BACKUP_ROOT/$stamp-$PROFILE.$suffix"
done
files_dir="$backup_dir/files"
manifest="$backup_dir/manifest.tsv"
mkdir -p "$files_dir"
chmod 700 "$backup_dir" "$files_dir"
printf 'profile\t%s\ncommit\t%s\n' \
  "$PROFILE" "$(git -C "$REPO_DIR" rev-parse HEAD)" > "$backup_dir/metadata.tsv"

while IFS='|' read -r relative _source; do
  [[ -n "$relative" ]] || continue
  target="$(target_path "$relative")"
  copy="$files_dir/$relative"
  type=absent
  link=''
  mode=''
  checksum=''
  if [[ -L "$target" ]]; then
    type=symlink
    link="$(readlink "$target")"
  elif [[ -f "$target" ]]; then
    type=file
    mode="$(path_mode "$target")"
    checksum="$(file_checksum "$target")"
  elif [[ -d "$target" ]]; then
    type=directory
    mode="$(path_mode "$target")"
  elif [[ -e "$target" ]]; then
    die "unsupported target type: $target"
  fi
  if [[ "$type" != absent ]]; then
    mkdir -p "$(dirname "$copy")"
    cp -a "$target" "$copy"
  fi
  printf '%s|%s|%s|%s|%s\n' \
    "$relative" "$type" "$link" "$mode" "$checksum" >> "$manifest"
done < "$PROFILE_MANIFEST"

[[ -r "$manifest" && "$(wc -l < "$manifest" | tr -d ' ')" -gt 0 ]] \
  || die "backup manifest is empty"
printf 'backup ready: %s\n' "$backup_dir" >&2
printf '%s\n' "$backup_dir"
