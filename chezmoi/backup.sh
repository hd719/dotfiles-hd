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
active_state=absent
if [[ -e "$ACTIVE_MARKER" || -L "$ACTIVE_MARKER" ]]; then
  [[ -f "$ACTIVE_MARKER" && ! -L "$ACTIVE_MARKER" ]] \
    || die "activation marker is not a regular file: $ACTIVE_MARKER"
  active_state=present
  cp -p "$ACTIVE_MARKER" "$backup_dir/activation-marker"
fi
printf 'profile\t%s\nhost\t%s\ncommit\t%s\nactive\t%s\n' \
  "$PROFILE" "$(hostname)" "$(git -C "$REPO_DIR" rev-parse HEAD)" \
  "$active_state" \
  > "$backup_dir/metadata.tsv"

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

if [[ -n "$PROFILE_ANCESTORS" ]]; then
  ancestor_manifest="$backup_dir/ancestors.tsv"
  ancestor_files="$backup_dir/ancestor-links"
  mkdir -p "$ancestor_files"
  chmod 700 "$ancestor_files"
  while IFS='|' read -r relative source managed_mode; do
    [[ -n "$relative" && "$managed_mode" =~ ^[0-7]{3,4}$ ]] \
      || die "invalid ancestor allowlist entry: $relative"
    target="$(target_path "$relative")"
    expected="$(expected_source "$source")"
    type=''
    link=''
    original_mode=''
    if [[ -L "$target" ]]; then
      type=symlink
      link="$(readlink "$target")"
      [[ "$link" == "$expected" ]] \
        || die "unexpected ancestor link: $target"
      saved="$ancestor_files/$relative"
      mkdir -p "$(dirname "$saved")"
      cp -a "$target" "$saved"
    elif [[ -d "$target" ]]; then
      type=directory
      original_mode="$(path_mode "$target")"
    elif [[ ! -e "$target" && ! -L "$target" ]]; then
      type=absent
    else
      die "ancestor must be absent, a symlink, or a directory: $target"
    fi
    printf '%s|%s|%s|%s\n' \
      "$relative" "$type" "$link" "$original_mode" \
      >> "$ancestor_manifest"
  done < "$PROFILE_ANCESTORS"
  [[ -r "$ancestor_manifest" \
    && "$(wc -l < "$ancestor_manifest" | tr -d ' ')" -gt 0 ]] \
    || die "ancestor backup manifest is empty"
fi

printf 'backup ready: %s\n' "$backup_dir" >&2
printf '%s\n' "$backup_dir"
