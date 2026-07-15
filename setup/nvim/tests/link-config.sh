#!/usr/bin/env bash
# Stop on command errors, unset variables, and failures hidden in pipelines.
set -euo pipefail

# Exercise the public Neovim linker in a disposable HOME. A fixed date makes
# same-second backup collisions deterministic without touching live config.
SOURCE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
LINKER="$SOURCE_ROOT/setup/nvim/link-config.sh"
REAL_BASH="$(command -v bash)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/nvim-link-config.XXXXXX")"
FAKE_HOME="$TMP_ROOT/home"
FAKE_BIN="$TMP_ROOT/bin"
TEST_REPO="$TMP_ROOT/repo"
TARGET="$FAKE_HOME/.config/nvim"
BACKUP="$TARGET.backup-20260715-150000"
failures=0

trap 'rm -rf "$TMP_ROOT"' EXIT
mkdir -p "$FAKE_BIN" "$TEST_REPO/config/nvim" "$TARGET" "$BACKUP"
printf '%s\n' '-- shared config' >"$TEST_REPO/config/nvim/init.lua"
printf '%s\n' 'new conflict' >"$TARGET/init.lua"
printf '%s\n' 'older backup' >"$BACKUP/init.lua"

{
  printf '#!%s\n' "$REAL_BASH"
  printf '%s\n' 'printf "%s\n" "20260715-150000"'
} >"$FAKE_BIN/date"
chmod +x "$FAKE_BIN/date"

expect() {
  local label="$1"
  shift
  if ! "$@"; then
    echo "FAIL: $label" >&2
    failures=$((failures + 1))
  fi
}

run_linker() {
  HOME="$FAKE_HOME" \
    PATH="$FAKE_BIN:$PATH" \
    DOTFILES_DIR="$TEST_REPO" \
    "$REAL_BASH" "$LINKER"
}

run_linker
expect "link points at this checkout" test "$(readlink "$TARGET")" = "$TEST_REPO/config/nvim"
expect "linked target resolves to a directory" test -d "$TARGET"
expect "older same-second backup remains intact" test "$(<"$BACKUP/init.lua")" = "older backup"
expect "new conflict receives a numeric sibling" \
  test "$(<"$BACKUP-1/init.lua")" = "new conflict"

# A correct rerun keeps the link and both backups without creating another one.
run_linker
expect "rerun keeps the exact link" test "$(readlink "$TARGET")" = "$TEST_REPO/config/nvim"
expect "rerun creates no second numeric backup" test ! -e "$BACKUP-2"

if ((failures > 0)); then
  echo "$failures Neovim linker regression test(s) failed." >&2
  exit 1
fi

echo "Neovim linker regression tests: ok"
