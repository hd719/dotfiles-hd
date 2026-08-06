#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/lib.sh"
load_profile "${1:-}"
validate_profile_os
[[ -x "$CHEZMOI_BIN" ]] || die "chezmoi is missing: run bootstrap.sh"

printf 'profile: %s\nsource: %s\ndestination: %s\n\nmanaged links:\n' \
  "$PROFILE" "$SOURCE_DIR" "$DEST_DIR"
while IFS='|' read -r relative source; do
  [[ -n "$relative" ]] || continue
  printf '  %s -> %s\n' "$(target_path "$relative")" "$(expected_source "$source")"
done < "$PROFILE_MANIFEST"

printf '\nchezmoi dry run:\n'
if [[ "$PROFILE" == mac-mini ]]; then
  while IFS='|' read -r ancestor source _mode; do
    ancestor_target="$(target_path "$ancestor")"
    if [[ -L "$ancestor_target" ]]; then
      [[ "$(readlink "$ancestor_target")" == "$(expected_source "$source")" ]] \
        || die "unexpected Mac mini ancestor link: $ancestor_target"
      printf '  would replace parent link with managed directory: %s\n' \
        "$ancestor_target"
    elif [[ ! -d "$ancestor_target" ]]; then
      die "Mac mini ancestor must be a symlink or directory: $ancestor_target"
    fi
  done < "$PROFILE_ANCESTORS"

  preview_targets=()
  while IFS='|' read -r relative _source; do
    covered=0
    while IFS='|' read -r ancestor source _mode; do
      ancestor_target="$(target_path "$ancestor")"
      if [[ -L "$ancestor_target" ]]; then
        [[ "$(readlink "$ancestor_target")" == "$(expected_source "$source")" ]] \
          || die "unexpected Mac mini ancestor link: $ancestor_target"
        case "$relative" in
          "$ancestor"/*) covered=1 ;;
        esac
      elif [[ ! -d "$ancestor_target" ]]; then
        die "Mac mini ancestor must be a symlink or directory: $ancestor_target"
      fi
    done < "$PROFILE_ANCESTORS"
    if ((covered == 0)); then
      preview_targets+=("$(target_path "$relative")")
    fi
  done < "$PROFILE_MANIFEST"
  cm apply --exclude=dirs --dry-run --verbose --no-pager --no-tty \
    "${preview_targets[@]}"
else
  cm apply --dry-run --verbose --no-pager --no-tty
fi

printf '\nmissing package actions:\n'
case "$PROFILE" in
  ubuntu)
    if [[ -x "$HOME/.local/bin/mise" ]]; then
      MISE_CONFIG_FILE="$REPO_DIR/setup/ubuntu/mise.toml" \
        "$HOME/.local/bin/mise" ls --missing || true
    else
      printf '  install mise, then install tools from setup/ubuntu/mise.toml\n'
    fi
    command -v mdformat >/dev/null 2>&1 \
      || printf '  install pinned mdformat bundle\n'
    ;;
  mac-thin)
    if command -v brew >/dev/null 2>&1; then
      HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --verbose \
        --file "$REPO_DIR/setup/mac-thin/Brewfile" || true
    else
      printf '  Homebrew is required before the approved apply\n'
    fi
    ;;
  mac-mini)
    printf '  none; the first Mac mini cutover is configuration-only\n'
    ;;
  work-mac)
    if command -v brew >/dev/null 2>&1; then
      HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --verbose \
        --file "$REPO_DIR/setup/mac-pro-resilience/Brewfile" || true
    else
      printf '  Homebrew is required before the approved apply\n'
    fi
    ;;
esac
