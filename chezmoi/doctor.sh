#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/lib.sh"
load_profile "${1:-}"
validate_profile_os
failures=0
pass() { printf 'PASS  %s\n' "$*"; }
fail() { printf 'FAIL  %s\n' "$*" >&2; failures=$((failures + 1)); }

if [[ -n "$PROFILE_ANCESTORS" ]]; then
  status_exclude=dirs
  verify_exclude=scripts,dirs
  [[ "${DOTFILES_CHEZMOI_TEST:-0}" == 1 ]] && status_exclude=scripts,dirs
else
  status_exclude=''
  verify_exclude=scripts
  [[ "${DOTFILES_CHEZMOI_TEST:-0}" == 1 ]] && status_exclude=scripts
fi
if [[ -n "$status_exclude" ]]; then
  status_output="$(cm status --exclude="$status_exclude")"
else
  status_output="$(cm status)"
fi
[[ -z "$status_output" ]] \
  && pass 'chezmoi status clean' || fail 'chezmoi reports drift'
cm verify --exclude="$verify_exclude" >/dev/null \
  && pass 'managed targets verified' || fail 'managed targets differ'

if [[ "${DOTFILES_CHEZMOI_TEST:-0}" != 1 && "$PROFILE" == ubuntu ]]; then
  [[ -f "$ACTIVE_MARKER" && ! -L "$ACTIVE_MARKER" ]] \
    && pass 'Ubuntu chezmoi ownership active' \
    || fail 'Ubuntu chezmoi ownership marker missing'
fi

while IFS='|' read -r relative source; do
  [[ -n "$relative" ]] || continue
  target="$(target_path "$relative")"
  expected="$(expected_source "$source")"
  [[ -L "$target" && "$(readlink "$target")" == "$expected" ]] \
    && pass "$relative" || fail "link mismatch: $relative"
done < "$PROFILE_MANIFEST"

managed="$(cm managed --include=symlinks --path-style=relative)"
printf '%s\n' "$managed" | grep -Eq \
  '(^|/)(\.env|auth\.json|authorized_keys|known_hosts|Library/LaunchAgents|Library/Preferences|\.config/btop/btop\.log|\.config/fastfetch/legacy|\.config/mise/state\.toml|\.hermes/session\.json)(/|$)' \
  && fail 'secret, service, or mutable state is managed' \
  || pass 'secrets, services, and mutable state excluded'

if [[ "${DOTFILES_CHEZMOI_TEST:-0}" != 1 ]]; then
  "$REPO_DIR/config/git/configure-aliases.sh" --check >/dev/null \
    && pass 'portable Git include' || fail 'portable Git include'
  if [[ "$PROFILE" != mac-work ]]; then
    if command -v zsh >/dev/null 2>&1 && zsh -n "$DEST_DIR/.zshrc"; then
      pass 'shell entrypoint syntax'
    else
      fail 'shell entrypoint syntax'
    fi
  fi
fi

((failures == 0)) || exit 1
printf 'PASS  %s production chezmoi profile\n' "$PROFILE"
