#!/usr/bin/env bash
# Stop on command errors, unset variables, and failures hidden in pipelines.
set -euo pipefail

# Model a rerun where tmux already has plugins and a same-second config backup.
# The Ubuntu linker must preserve both while linking only user-owned config.
SOURCE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
LINKER="$SOURCE_ROOT/setup/ubuntu/link-configs.sh"
REAL_BASH="$(command -v bash)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/ubuntu-link-configs.XXXXXX")"
FAKE_HOME="$TMP_ROOT/home"
FAKE_BIN="$TMP_ROOT/bin"
TEST_REPO="$TMP_ROOT/repo"
CONFIG_HOME="$FAKE_HOME/.config"
failures=0

trap 'rm -rf "$TMP_ROOT"' EXIT

for app in btop fastfetch bat wtf ghostty; do
  mkdir -p "$TEST_REPO/config/$app"
  printf '%s\n' "$app-shared" >"$TEST_REPO/config/$app/config"
done
mkdir -p \
  "$TEST_REPO/config/tmux/scripts" \
  "$TEST_REPO/setup/ubuntu" \
  "$CONFIG_HOME/tmux/plugins/tpm"
printf '%s\n' 'shared-tmux' >"$TEST_REPO/config/tmux/tmux.conf"
printf '%s\n' 'shared-script' >"$TEST_REPO/config/tmux/scripts/status.sh"
printf '%s\n' 'shared-zshrc' >"$TEST_REPO/setup/ubuntu/.zshrc"
printf '%s\n' 'local-zshrc' >"$FAKE_HOME/.zshrc"
printf '%s\n' 'plugin-state' >"$CONFIG_HOME/tmux/plugins/tpm/sentinel"
printf '%s\n' 'new-local-tmux' >"$CONFIG_HOME/tmux/tmux.conf"
mkdir -p "$CONFIG_HOME/tmux/tmux.conf.backup-20260715-151500"
printf '%s\n' 'older-tmux-backup' \
  >"$CONFIG_HOME/tmux/tmux.conf.backup-20260715-151500/value"

mkdir -p "$FAKE_BIN"
{
  printf '#!%s\n' "$REAL_BASH"
  printf '%s\n' 'printf "%s\n" "20260715-151500"'
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

if [[ ! -f "$LINKER" ]]; then
  echo "missing production script: $LINKER" >&2
  exit 1
fi

run_linker() {
  HOME="$FAKE_HOME" \
    PATH="$FAKE_BIN:$PATH" \
    XDG_CONFIG_HOME="$CONFIG_HOME" \
    DOTFILES_DIR="$TEST_REPO" \
    "$REAL_BASH" "$LINKER"
}

run_linker

for app in btop fastfetch bat wtf ghostty; do
  expect "$app is linked as a whole config directory" \
    test "$(readlink "$CONFIG_HOME/$app")" = "$TEST_REPO/config/$app"
  expect "$app link resolves to a directory" test -d "$CONFIG_HOME/$app"
done

expect "tmux live directory remains real" test -d "$CONFIG_HOME/tmux"
expect "tmux live directory is never a symlink" test ! -L "$CONFIG_HOME/tmux"
expect "tmux plugin runtime state survives" \
  test "$(<"$CONFIG_HOME/tmux/plugins/tpm/sentinel")" = "plugin-state"
expect "only tmux.conf is linked" \
  test "$(readlink "$CONFIG_HOME/tmux/tmux.conf")" = "$TEST_REPO/config/tmux/tmux.conf"
expect "tmux scripts are linked without replacing plugins" \
  test "$(readlink "$CONFIG_HOME/tmux/scripts")" = "$TEST_REPO/config/tmux/scripts"
expect "older same-second tmux backup remains intact" \
  test "$(<"$CONFIG_HOME/tmux/tmux.conf.backup-20260715-151500/value")" = "older-tmux-backup"
expect "new tmux conflict receives a numeric sibling" \
  test "$(<"$CONFIG_HOME/tmux/tmux.conf.backup-20260715-151500-1")" = "new-local-tmux"
expect "Ubuntu zshrc is linked from this checkout" \
  test "$(readlink "$FAKE_HOME/.zshrc")" = "$TEST_REPO/setup/ubuntu/.zshrc"
expect "existing zshrc is preserved in a sibling backup" \
  test "$(<"$FAKE_HOME/.zshrc.backup-20260715-151500")" = "local-zshrc"

# Matching links are no-ops and do not produce a second backup on rerun.
run_linker
expect "rerun creates no second tmux backup" \
  test ! -e "$CONFIG_HOME/tmux/tmux.conf.backup-20260715-151500-2"
expect "rerun creates no second zshrc backup" \
  test ! -e "$FAKE_HOME/.zshrc.backup-20260715-151500-1"

# Migrate the unsafe whole-directory tmux link created by older setup versions.
# Any plugins stored through that link are copied into the new local directory.
mkdir -p "$TEST_REPO/config/tmux/plugins/tpm"
printf '%s\n' 'legacy-linked-plugin' \
  >"$TEST_REPO/config/tmux/plugins/tpm/legacy-sentinel"
FAKE_HOME="$TMP_ROOT/migration-home"
CONFIG_HOME="$FAKE_HOME/.config"
mkdir -p "$CONFIG_HOME"
ln -s "$TEST_REPO/config/tmux" "$CONFIG_HOME/tmux"
run_linker
expect "legacy whole-directory tmux link becomes a real directory" \
  test -d "$CONFIG_HOME/tmux"
expect "migrated tmux directory is not a symlink" test ! -L "$CONFIG_HOME/tmux"
expect "plugins behind the legacy link are preserved locally" \
  test "$(<"$CONFIG_HOME/tmux/plugins/tpm/legacy-sentinel")" = "legacy-linked-plugin"
expect "legacy whole-directory link remains as a timestamped backup" \
  test -L "$CONFIG_HOME/tmux.backup-20260715-151500"
expect "migrated tmux.conf uses the narrow link" \
  test "$(readlink "$CONFIG_HOME/tmux/tmux.conf")" = "$TEST_REPO/config/tmux/tmux.conf"

if ((failures > 0)); then
  echo "$failures Ubuntu config-linker regression test(s) failed." >&2
  exit 1
fi

echo "Ubuntu config-linker regression tests: ok"
