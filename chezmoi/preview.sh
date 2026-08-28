#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/lib.sh"
load_profile "${1:-}"
validate_profile_os
[[ -x "$CHEZMOI_BIN" ]] || die "chezmoi is missing: run bootstrap.sh"
[[ "${DOTFILES_CHEZMOI_REQUIRE_REVIEWED:-0}" != 1 ]] \
  || require_canonical_checkout
validate_profile_layout

preview_state_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-chezmoi-preview.XXXXXX")"
STATE_DIR="$preview_state_dir"
ACTIVE_MARKER="$STATE_DIR/$PROFILE-active"
trap 'rm -rf -- "$preview_state_dir"' EXIT

printf 'profile: %s\nsource: %s\ndestination: %s\n\nmanaged links:\n' \
  "$PROFILE" "$SOURCE_DIR" "$DEST_DIR"
while IFS='|' read -r relative source; do
  [[ -n "$relative" ]] || continue
  printf '  %s -> %s\n' "$(target_path "$relative")" "$(expected_source "$source")"
done < "$PROFILE_MANIFEST"

printf '\nchezmoi dry run:\n'
if [[ -n "$PROFILE_ANCESTORS" ]]; then
  while IFS='|' read -r ancestor source _mode; do
    ancestor_target="$(target_path "$ancestor")"
    if [[ -L "$ancestor_target" ]]; then
      [[ "$(readlink "$ancestor_target")" == "$(expected_source "$source")" ]] \
        || die "unexpected $PROFILE ancestor link: $ancestor_target"
      printf '  would replace parent link with managed directory: %s\n' \
        "$ancestor_target"
    elif [[ ! -e "$ancestor_target" && ! -L "$ancestor_target" ]]; then
      printf '  would create managed directory: %s\n' "$ancestor_target"
    elif [[ ! -d "$ancestor_target" ]]; then
      die "$PROFILE ancestor must be absent, a symlink, or a directory: $ancestor_target"
    fi
  done < "$PROFILE_ANCESTORS"

  preview_targets=()
  while IFS='|' read -r relative _source; do
    covered=0
    while IFS='|' read -r ancestor source _mode; do
      ancestor_target="$(target_path "$ancestor")"
      if [[ -L "$ancestor_target" ]]; then
        [[ "$(readlink "$ancestor_target")" == "$(expected_source "$source")" ]] \
          || die "unexpected $PROFILE ancestor link: $ancestor_target"
        case "$relative" in
          "$ancestor"/*) covered=1 ;;
        esac
      elif [[ -e "$ancestor_target" && ! -d "$ancestor_target" ]]; then
        die "$PROFILE ancestor must be absent, a symlink, or a directory: $ancestor_target"
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

if [[ "${DOTFILES_CHEZMOI_CONFIG_ONLY_PREVIEW:-0}" != 1 ]]; then
  printf '\nmissing package actions:\n'
  case "$PROFILE" in
    ubuntu)
      if [[ -x "$HOME/.local/bin/mise" ]]; then
        MISE_CONFIG_FILE="$REPO_DIR/hosts/ubuntu-dev/mise.toml" \
          "$HOME/.local/bin/mise" ls --missing || true
      else
        printf '  install mise, then install tools from hosts/ubuntu-dev/mise.toml\n'
      fi
      command -v mdformat >/dev/null 2>&1 \
        || printf '  install pinned mdformat bundle\n'
      ;;
    mac-thin)
      if command -v brew >/dev/null 2>&1; then
        HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --verbose \
          --file "$REPO_DIR/hosts/mac-thin/Brewfile" || true
      else
        printf '  Homebrew is required before the approved apply\n'
      fi
      ;;
    mac-mini)
      printf '  none; the first Mac mini cutover is configuration-only\n'
      ;;
    mac-pro)
      if command -v brew >/dev/null 2>&1; then
        HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --verbose \
          --file "$REPO_DIR/hosts/shared/macos/Brewfile" || true
        HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --verbose \
          --file "$REPO_DIR/hosts/mac-pro/Brewfile" || true
      else
        printf '  Homebrew is required before the approved apply\n'
      fi
      ;;
    mac-work)
      if command -v brew >/dev/null 2>&1; then
        HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --verbose \
          --file "$REPO_DIR/hosts/mac-work/resilience/Brewfile" || true
      else
        printf '  Homebrew is required before the approved apply\n'
      fi
      ;;
  esac
else
  printf '\npackage checks: skipped (configuration-only preview)\n'
fi
