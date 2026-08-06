#!/usr/bin/env bash
set -euo pipefail
umask 077

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/lib.sh"
load_profile "${1:-}"
validate_profile_os
backup_dir="${2:-}"
rollback_mode="${3:-apply}"
[[ $# -le 3 && -d "$backup_dir" && -r "$backup_dir/manifest.tsv" ]] \
  || die "usage: rollback.sh PROFILE BACKUP_DIRECTORY [--preview]"
case "$rollback_mode" in
  apply|--preview) ;;
  *) die "usage: rollback.sh PROFILE BACKUP_DIRECTORY [--preview]" ;;
esac
backup_root_real="$(cd "$BACKUP_ROOT" && pwd -P)"
backup_dir="$(cd "$backup_dir" && pwd -P)"
case "$backup_dir/" in
  "$backup_root_real"/*/) ;;
  *) die "backup is outside $BACKUP_ROOT" ;;
esac
grep -Fqx $'profile\t'"$PROFILE" "$backup_dir/metadata.tsv" \
  || die "backup profile mismatch"
grep -Fqx $'host\t'"$(hostname)" "$backup_dir/metadata.tsv" \
  || die "backup host mismatch"
active_state="$(awk -F $'\t' '$1 == "active" { print $2 }' \
  "$backup_dir/metadata.tsv")"
case "$active_state" in
  absent|present) ;;
  *) die "backup activation state is invalid" ;;
esac

if ! diff -q \
  <(cut -d '|' -f 1 "$PROFILE_MANIFEST" | LC_ALL=C sort) \
  <(cut -d '|' -f 1 "$backup_dir/manifest.tsv" | LC_ALL=C sort) \
  >/dev/null; then
  die "backup manifest does not match the $PROFILE allowlist"
fi

ancestor_manifest=''
if [[ -n "$PROFILE_ANCESTORS" ]]; then
  ancestor_manifest="$backup_dir/ancestors.tsv"
  [[ -r "$ancestor_manifest" ]] \
    || die "missing ancestor backup manifest"
  if ! diff -q \
    <(cut -d '|' -f 1 "$PROFILE_ANCESTORS" | LC_ALL=C sort) \
    <(cut -d '|' -f 1 "$ancestor_manifest" | LC_ALL=C sort) \
    >/dev/null; then
    die "ancestor backup does not match the $PROFILE allowlist"
  fi
  while IFS='|' read -r relative type link mode; do
    saved="$backup_dir/ancestor-links/$relative"
    case "$type" in
      symlink)
        [[ -n "$link" && -z "$mode" && -L "$saved" ]] \
          || die "invalid ancestor symlink backup: $relative"
        [[ "$(readlink "$saved")" == "$link" ]] \
          || die "saved ancestor link mismatch: $relative"
        ;;
      directory)
        [[ -z "$link" && "$mode" =~ ^[0-7]{3,4}$ \
          && ! -e "$saved" && ! -L "$saved" ]] \
          || die "invalid ancestor directory backup: $relative"
        ;;
      *) die "unsupported ancestor backup type: $type" ;;
    esac
    if [[ "$rollback_mode" == --preview ]]; then
      printf 'would restore ancestor: %s (%s)\n' \
        "$(target_path "$relative")" "$type"
    fi
  done < "$ancestor_manifest"
fi

while IFS='|' read -r relative type link mode checksum; do
  target="$(target_path "$relative")"
  saved="$backup_dir/files/$relative"
  case "$type" in
    absent)
      [[ -z "$link$mode$checksum" && ! -e "$saved" && ! -L "$saved" ]] \
        || die "invalid absent backup entry: $relative"
      ;;
    symlink)
      [[ -n "$link" && -z "$mode$checksum" && -L "$saved" ]] \
        || die "invalid symlink backup entry: $relative"
      [[ "$(readlink "$saved")" == "$link" ]] \
        || die "saved symlink mismatch: $relative"
      ;;
    file)
      [[ -z "$link" && -n "$mode" && -n "$checksum" \
        && -f "$saved" && ! -L "$saved" ]] \
        || die "invalid file backup entry: $relative"
      [[ "$(file_checksum "$saved")" == "$checksum" \
        && "$(path_mode "$saved")" == "$mode" ]] \
        || die "saved file verification failed: $relative"
      ;;
    directory)
      [[ -z "$link$checksum" && -n "$mode" \
        && -d "$saved" && ! -L "$saved" ]] \
        || die "invalid directory backup entry: $relative"
      [[ "$(path_mode "$saved")" == "$mode" ]] \
        || die "saved directory mode mismatch: $relative"
      ;;
    *) die "unsupported manifest type: $type" ;;
  esac
  if [[ "$rollback_mode" == --preview ]]; then
    printf 'would restore: %s (%s)\n' "$target" "$type"
  fi
done < "$backup_dir/manifest.tsv"

if [[ "$active_state" == present ]]; then
  saved_marker="$backup_dir/activation-marker"
  [[ -f "$saved_marker" && ! -L "$saved_marker" ]] \
    || die "missing saved activation marker"
fi

if [[ "$rollback_mode" == --preview ]]; then
  printf 'rollback preview passed: %s\n' "$backup_dir"
  exit 0
fi

replaced="$backup_dir/replaced-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$replaced"

under_saved_symlink_ancestor() {
  local relative="$1" ancestor type _link _mode
  [[ -n "$ancestor_manifest" ]] || return 1
  while IFS='|' read -r ancestor type _link _mode; do
    [[ "$type" == symlink ]] || continue
    case "$relative" in
      "$ancestor"/*) return 0 ;;
    esac
  done < "$ancestor_manifest"
  return 1
}

if [[ -n "$ancestor_manifest" ]]; then
  while IFS='|' read -r relative type link _mode; do
    [[ "$type" == symlink ]] || continue
    target="$(target_path "$relative")"
    displaced="$replaced/ancestor-state/$relative"
    if [[ -e "$target" || -L "$target" ]]; then
      mkdir -p "$(dirname "$displaced")"
      mv "$target" "$displaced"
    fi
    saved="$backup_dir/ancestor-links/$relative"
    mkdir -p "$(dirname "$target")"
    cp -a "$saved" "$target"
    [[ -L "$target" && "$(readlink "$target")" == "$link" ]] \
      || die "ancestor restore verification failed: $target"
  done < "$ancestor_manifest"
fi

while IFS='|' read -r relative type link mode checksum; do
  under_saved_symlink_ancestor "$relative" && continue
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

if [[ -n "$ancestor_manifest" ]]; then
  while IFS='|' read -r relative type _link mode; do
    [[ "$type" == directory ]] || continue
    target="$(target_path "$relative")"
    [[ -d "$target" && ! -L "$target" ]] \
      || die "ancestor directory restore failed: $target"
    chmod "$mode" "$target"
    [[ "$(path_mode "$target")" == "$mode" ]] \
      || die "ancestor directory mode restore failed: $target"
  done < "$ancestor_manifest"
fi

if [[ -e "$ACTIVE_MARKER" || -L "$ACTIVE_MARKER" ]]; then
  mkdir -p "$replaced/activation"
  mv "$ACTIVE_MARKER" "$replaced/activation/$PROFILE-active"
fi
if [[ "$active_state" == present ]]; then
  mkdir -p "$STATE_DIR"
  cp -p "$saved_marker" "$ACTIVE_MARKER"
  cmp -s "$saved_marker" "$ACTIVE_MARKER" \
    || die "activation marker restore verification failed"
fi

if [[ "$PROFILE" == ubuntu && "$active_state" == absent ]]; then
  legacy_linker="$REPO_DIR/setup/ubuntu/link-dotfiles.sh"
  [[ -x "$legacy_linker" ]] || die "missing Ubuntu legacy linker: $legacy_linker"
  HOME="$DEST_DIR" \
    DOTFILES_CHEZMOI_ACTIVE_MARKER="$ACTIVE_MARKER" \
    "$legacy_linker"
  printf 'Ubuntu legacy links restored.\n'
fi

printf 'rollback restored: %s\n' "$backup_dir"
printf 'displaced chezmoi state retained at: %s\n' "$replaced"
if [[ "$active_state" == present ]]; then
  printf 'chezmoi ownership restored to its pre-apply active state.\n'
else
  printf 'chezmoi ownership stopped; the previous writer is active again.\n'
fi
