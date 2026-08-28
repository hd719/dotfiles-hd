#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DIR="$(cd "$TEST_DIR/../../.." && pwd -P)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-work-goodmorning-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

SHARED_FUNCTIONS="$REPO_DIR/config/zsh/mac/development-functions.zsh"
WORK_MODULE="$REPO_DIR/hosts/mac-work/goodmorning.zsh"
WORK_PROFILE="$REPO_DIR/hosts/mac-work/.zshrc"
TEST_HOME="$TEST_ROOT/home"
FAKE_BIN="$TEST_ROOT/bin"
WORK_REPO="$TEST_HOME/Developer/Resilience/resilience-platform"
GIT_LOG="$TEST_ROOT/git.log"
BREW_LOG="$TEST_ROOT/brew.log"
MARKER_FILE="$TEST_ROOT/resilience-homebrew-upgrade"
mkdir -p "$WORK_REPO/.git" "$FAKE_BIN"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_eq() {
  [[ "$1" == "$2" ]] || fail "$3 (expected '$1', got '$2')"
}

assert_contains() {
  grep -Fq -- "$2" "$1" || fail "expected '$2' in $1"
}

assert_not_contains() {
  ! grep -Fq -- "$2" "$1" || fail "did not expect '$2' in $1"
}

cat >"$FAKE_BIN/git" <<'FAKE_GIT'
#!/bin/sh
printf '%s\n' "$*" >>"$FAKE_GIT_LOG"
if [ "$3" = status ] && [ -n "${FAKE_GIT_STATUS:-}" ]; then
  printf '%s\n' "$FAKE_GIT_STATUS"
fi
exit 0
FAKE_GIT

cat >"$FAKE_BIN/brew" <<'FAKE_BREW'
#!/bin/sh
printf '%s\n' "$*" >>"$FAKE_BREW_LOG"
if [ "${FAKE_BREW_FAIL:-}" = "$1" ]; then
  exit 1
fi
if [ "$1" = outdated ]; then
  printf '%s\n' "${FAKE_BREW_OUTDATED:-}"
fi
exit 0
FAKE_BREW
chmod +x "$FAKE_BIN/git" "$FAKE_BIN/brew"

/bin/zsh -n "$WORK_MODULE" "$WORK_PROFILE"
assert_contains "$WORK_MODULE" '_goodmorning_sync_dotfiles'
assert_contains "$WORK_PROFILE" 'hosts/mac-work/goodmorning.zsh'
assert_contains "$WORK_PROFILE" 'hosts/mac-work/herdr/'
assert_not_contains "$WORK_PROFILE" 'hosts/mac-work/resilience/'

output="$(
  HOME="$TEST_HOME" \
    PATH="$FAKE_BIN:/usr/bin:/bin" \
    FAKE_GIT_LOG="$GIT_LOG" \
    FAKE_GIT_STATUS=' M tracked-file' \
    /bin/zsh -dfc \
    'source "$1"; _resilience_update_repo "$2" "Test Repo"' \
    zsh "$WORK_MODULE" "$WORK_REPO" 2>&1 || true
)"
[[ "$output" == *'working tree is not clean'* ]] \
  || fail 'dirty work repository should be rejected'
assert_contains "$GIT_LOG" 'status --porcelain'
assert_not_contains "$GIT_LOG" checkout
assert_not_contains "$GIT_LOG" pull

: >"$GIT_LOG"
HOME="$TEST_HOME" \
  PATH="$FAKE_BIN:/usr/bin:/bin" \
  FAKE_GIT_LOG="$GIT_LOG" \
  FAKE_GIT_STATUS='' \
  /bin/zsh -dfc \
  'source "$1"; _resilience_update_repo "$2" "Test Repo"' \
  zsh "$WORK_MODULE" "$WORK_REPO" >/dev/null
assert_contains "$GIT_LOG" 'checkout dev'
assert_contains "$GIT_LOG" 'pull --ff-only origin dev'

assert_eq 259200 "$(
  /bin/zsh -dfc 'source "$1"; _resilience_brew_cooldown_seconds' \
    zsh "$WORK_MODULE"
)" 'work Homebrew cooldown is 72 hours'

printf '1000000\n' >"$MARKER_FILE"
actual="$(
  /bin/zsh -dfc '
    source "$1"
    source "$2"
    _now_epoch_ms() { print -r -- 4600000 }
    _resilience_brew_cooldown_remaining_seconds "$3" 7200
  ' zsh "$SHARED_FUNCTIONS" "$WORK_MODULE" "$MARKER_FILE"
)"
assert_eq 3600 "$actual" 'Homebrew cooldown reports remaining seconds'

HOME="$TEST_HOME" \
  PATH="$FAKE_BIN:/usr/bin:/bin" \
  FAKE_BREW_LOG="$BREW_LOG" \
  FAKE_BREW_OUTDATED=formula \
  /bin/zsh -dfc '
    source "$1"
    source "$2"
    _now_epoch_ms() { print -r -- 5000000 }
    _resilience_run_homebrew_upgrade "$3"
  ' zsh "$SHARED_FUNCTIONS" "$WORK_MODULE" "$MARKER_FILE" >/dev/null
for command in update 'outdated --greedy' 'upgrade --greedy' cleanup autoremove; do
  assert_contains "$BREW_LOG" "$command"
done
assert_contains "$MARKER_FILE" 5000000

rm -f "$MARKER_FILE"
: >"$BREW_LOG"
if HOME="$TEST_HOME" \
  PATH="$FAKE_BIN:/usr/bin:/bin" \
  FAKE_BREW_LOG="$BREW_LOG" \
  FAKE_BREW_FAIL=update \
  /bin/zsh -dfc '
    source "$1"
    source "$2"
    _resilience_run_homebrew_upgrade "$3"
  ' zsh "$SHARED_FUNCTIONS" "$WORK_MODULE" "$MARKER_FILE" >/dev/null 2>&1; then
  fail 'failed Homebrew update should return nonzero'
fi
[[ ! -e "$MARKER_FILE" ]] || fail 'failed update should not write its marker'

output="$(
  /bin/zsh -dfc '
    source "$1"
    source "$2"
    shift 2
    _goodmorning_sync_dotfiles() { return 0 }
    _resilience_host_is_virtual() { return 1 }
    _resilience_brew_cooldown_remaining_seconds() { print -r -- 60 }
    _resilience_run_homebrew_upgrade() { print -r -- brew-run }
    gda() { return 0 }
    goodMorning "$@"
  ' zsh "$SHARED_FUNCTIONS" "$WORK_MODULE"
)"
[[ "$output" == *'60s remain in the 72-hour cooldown'* ]] \
  || fail 'default goodMorning should respect the Homebrew cooldown'
[[ "$output" != *brew-run* ]] \
  || fail 'default goodMorning should not bypass the cooldown'

output="$(
  /bin/zsh -dfc '
    source "$1"
    source "$2"
    shift 2
    _goodmorning_sync_dotfiles() { return 0 }
    _resilience_host_is_virtual() { return 1 }
    _resilience_brew_cooldown_remaining_seconds() { print -r -- 60 }
    _resilience_run_homebrew_upgrade() { print -r -- brew-run }
    gda() { return 0 }
    goodMorning "$@"
  ' zsh "$SHARED_FUNCTIONS" "$WORK_MODULE" --force-brew
)"
[[ "$output" == *brew-run* ]] \
  || fail '--force-brew should bypass the cooldown'

printf 'Work Mac goodMorning tests passed.\n'
