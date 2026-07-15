#!/usr/bin/env bash
# Stop on command errors, unset variables, and failures hidden in pipelines.
set -euo pipefail

# This is an offline integration test for the public mise setup command. It
# gives the script a disposable HOME, dotfiles checkout, and PATH so no real
# toolchain, config, package manager, or network connection can be touched.
SOURCE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
BOOTSTRAP="$SOURCE_ROOT/setup/mise/bootstrap.sh"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/mise-bootstrap.XXXXXX")"
TEST_REPO="$TMP_ROOT/repo"
FAKE_BIN="$TMP_ROOT/bin"
STATE_DIR="$TMP_ROOT/state"
REAL_BASH="$(command -v bash)"
REAL_ENV="$(command -v env)"
REAL_RM="$(command -v rm)"
failures=0

cleanup() {
  "$REAL_RM" -rf "$TMP_ROOT"
}
trap cleanup EXIT

# Keep a missing production command failure direct so a beginner knows which
# file this regression harness expects.
if [[ ! -f "$BOOTSTRAP" ]]; then
  echo "missing production script: $BOOTSTRAP" >&2
  exit 1
fi

mkdir -p "$TEST_REPO/config/mise" "$FAKE_BIN" "$STATE_DIR"
printf '%s\n' \
  '[tools]' \
  'node = "26.1.0"' \
  'go = "1.26.3"' \
  >"$TEST_REPO/config/mise/config.toml"

write_stub() {
  local name="$1"
  shift

  {
    printf '#!%s\n' "$REAL_BASH"
    printf '%s\n' "$@"
  } >"$FAKE_BIN/$name"
  chmod +x "$FAKE_BIN/$name"
}

# Only harmless filesystem commands are exposed. There is deliberately no
# curl, brew, apt, or snap command, so this shared seam cannot install mise or
# reach the network; each operating system must provide mise first.
for command_name in date dirname ln mkdir mv pwd readlink; do
  ln -s "$(command -v "$command_name")" "$FAKE_BIN/$command_name"
done

# Return one fixed timestamp so backup names have an independent, exact value.
"$REAL_RM" -f "$FAKE_BIN/date"
write_stub date 'printf "%s\n" "20260715-143015"'

# The fake mise records the public lifecycle calls without downloading tools.
write_stub mise 'printf "%s\n" "$*" >>"$TEST_MISE_TRACE"'

expect() {
  local label="$1"
  shift

  if ! "$@"; then
    echo "FAIL: $label" >&2
    failures=$((failures + 1))
  fi
}

expect_success() {
  local label="$1"

  if ((RUN_STATUS != 0)); then
    echo "FAIL: $label (status $RUN_STATUS)" >&2
    printf '%s\n' "$RUN_OUTPUT" >&2
    failures=$((failures + 1))
  fi
}

expect_status() {
  local label="$1"
  local wanted="$2"

  if ((RUN_STATUS != wanted)); then
    echo "FAIL: $label (wanted status $wanted, got $RUN_STATUS)" >&2
    printf '%s\n' "$RUN_OUTPUT" >&2
    failures=$((failures + 1))
  fi
}

expect_trace() {
  local label="$1"
  shift
  local expected="$STATE_DIR/expected-trace"

  printf '%s\n' "$@" >"$expected"
  if ! cmp -s "$expected" "$TRACE_LOG"; then
    echo "FAIL: $label" >&2
    echo "expected mise calls:" >&2
    sed 's/^/  /' "$expected" >&2
    echo "actual mise calls:" >&2
    if [[ -f "$TRACE_LOG" ]]; then
      sed 's/^/  /' "$TRACE_LOG" >&2
    else
      echo "  <none>" >&2
    fi
    failures=$((failures + 1))
  fi
}

reset_machine() {
  local name="$1"

  FAKE_HOME="$TMP_ROOT/home-$name"
  NODE_BIN="$FAKE_HOME/.local/share/mise/installs/node/26.1.0/bin"
  TRACE_LOG="$STATE_DIR/$name-mise.trace"
  RUN_XDG_CONFIG_HOME=""
  mkdir -p "$FAKE_HOME" "$NODE_BIN"
  : >"$TRACE_LOG"

  # These sentinels make the historical npm/npx deletion bug observable.
  printf '%s\n' 'npm-sentinel-26.1.0' >"$NODE_BIN/npm"
  printf '%s\n' 'npx-sentinel-26.1.0' >"$NODE_BIN/npx"
  chmod +x "$NODE_BIN/npm" "$NODE_BIN/npx"
  cp "$NODE_BIN/npm" "$STATE_DIR/$name-npm.before"
  cp "$NODE_BIN/npx" "$STATE_DIR/$name-npx.before"
}

run_bootstrap() {
  local -a environment

  # An empty RUN_XDG_CONFIG_HOME tests the normal ~/.config destination. A
  # non-empty value tests the standard XDG override used on Linux and macOS.
  if [[ -n "$RUN_XDG_CONFIG_HOME" ]]; then
    environment=(
      "$REAL_ENV"
      "HOME=$FAKE_HOME"
      "PATH=$FAKE_BIN:$NODE_BIN"
      "DOTFILES_DIR=$TEST_REPO"
      "XDG_CONFIG_HOME=$RUN_XDG_CONFIG_HOME"
      "TEST_MISE_TRACE=$TRACE_LOG"
    )
  else
    environment=(
      "$REAL_ENV" -u XDG_CONFIG_HOME
      "HOME=$FAKE_HOME"
      "PATH=$FAKE_BIN:$NODE_BIN"
      "DOTFILES_DIR=$TEST_REPO"
      "TEST_MISE_TRACE=$TRACE_LOG"
    )
  fi

  set +e
  RUN_OUTPUT="$("${environment[@]}" "$REAL_BASH" "$BOOTSTRAP" "$@" 2>&1)"
  RUN_STATUS=$?
  set -e
}

expect_node_commands_preserved() {
  local label="$1"
  local name="$2"

  expect "$label: npm remains byte-identical" \
    cmp -s "$STATE_DIR/$name-npm.before" "$NODE_BIN/npm"
  expect "$label: npx remains byte-identical" \
    cmp -s "$STATE_DIR/$name-npx.before" "$NODE_BIN/npx"
}

# These are the cross-OS personal-machine contract, not sample versions. gopls
# must appear before Go because mise builds PATH in config order; its dedicated
# bin directory then wins over any old gopls left inside a Go installation.
CANONICAL_CONFIG="$SOURCE_ROOT/config/mise/config.toml"
expect "canonical config pins Bun" grep -Fxq 'bun = "1.3.14"' "$CANONICAL_CONFIG"
expect "canonical config pins gopls" \
  grep -Fxq '"go:golang.org/x/tools/gopls" = "0.23.0"' "$CANONICAL_CONFIG"
expect "canonical config pins Go" grep -Fxq 'go = "1.26.3"' "$CANONICAL_CONFIG"
expect "canonical config pins Node" grep -Fxq 'node = "26.1.0"' "$CANONICAL_CONFIG"
expect "canonical config pins Python" grep -Fxq 'python = "3.14.5"' "$CANONICAL_CONFIG"

gopls_line="$(grep -nFm1 '"go:golang.org/x/tools/gopls"' "$CANONICAL_CONFIG" | cut -d: -f1)"
go_line="$(grep -nEm1 '^go[[:space:]]*=' "$CANONICAL_CONFIG" | cut -d: -f1)"
expect "gopls precedes Go so the pinned language server wins on PATH" \
  test "$gopls_line" -lt "$go_line"

# Scenario 1: scope is mandatory. Refusing an unnamed machine prevents this
# personal runtime config from drifting into the narrower work-Mac runbook.
reset_machine "missing-scope"
mkdir -p "$FAKE_HOME/.config/mise"
printf '%s\n' 'work-owned' >"$FAKE_HOME/.config/mise/config.toml"
run_bootstrap
expect_status "missing machine scope is a usage error" 2
expect "missing scope leaves work-owned config untouched" \
  test "$(<"$FAKE_HOME/.config/mise/config.toml")" = "work-owned"
expect "missing scope never invokes mise" test ! -s "$TRACE_LOG"
expect_node_commands_preserved "missing scope" "missing-scope"

# Scenario 2: `work` is rejected before any mutation. The only supported scope
# is the explicit `personal` path shared by Hamel's personal Mac and Ubuntu.
reset_machine "work-scope"
mkdir -p "$FAKE_HOME/.config/mise"
printf '%s\n' 'work-owned' >"$FAKE_HOME/.config/mise/config.toml"
run_bootstrap work
expect_status "work machine scope is rejected" 2
expect "work scope leaves work-owned config untouched" \
  test "$(<"$FAKE_HOME/.config/mise/config.toml")" = "work-owned"
expect "work scope never invokes mise" test ! -s "$TRACE_LOG"
expect_node_commands_preserved "work scope" "work-scope"

# Scenario 3: a fresh personal machine receives one whole-directory link, then
# installs and reshims the pinned runtimes. mise's global config is implicitly
# trusted, so setup must not add an unnecessary trust exception.
reset_machine "fresh"
run_bootstrap personal
expect_success "fresh personal bootstrap succeeds"
TARGET="$FAKE_HOME/.config/mise"
expect "fresh setup links the whole mise config directory" test -L "$TARGET"
expect "fresh link points at this checkout" \
  test "$(readlink "$TARGET")" = "$TEST_REPO/config/mise"
expect "config.toml is visible through the directory link" \
  cmp -s "$TARGET/config.toml" "$TEST_REPO/config/mise/config.toml"
expect_trace "fresh setup installs Go before its gopls tool, then completes the lifecycle" \
  "install --yes go" \
  "install --yes" \
  "reshim"
expect_node_commands_preserved "fresh setup" "fresh"

# Scenario 4: an existing directory is never deleted. It moves to one exact
# timestamped sibling backup before the shared directory is linked.
reset_machine "conflict"
TARGET="$FAKE_HOME/.config/mise"
mkdir -p "$TARGET"
printf '%s\n' 'legacy-config' >"$TARGET/config.toml"
run_bootstrap personal
expect_success "conflicting config is backed up safely"
BACKUP="$TARGET.backup-20260715-143015"
expect "conflict creates the timestamped sibling backup" test -d "$BACKUP"
expect "backup preserves the previous config bytes" \
  test "$(<"$BACKUP/config.toml")" = "legacy-config"
expect "conflict is replaced by the exact repo link" \
  test "$(readlink "$TARGET")" = "$TEST_REPO/config/mise"
expect_node_commands_preserved "conflict setup" "conflict"

# Scenario 5: rerunning setup keeps the correct link and the single original
# backup. Lifecycle commands still run so a later config edit installs its new
# pins; mise itself makes those calls idempotent.
: >"$TRACE_LOG"
run_bootstrap personal
expect_success "second personal bootstrap succeeds"
expect "rerun keeps the exact link" \
  test "$(readlink "$TARGET")" = "$TEST_REPO/config/mise"
expect "rerun keeps the original backup" test -d "$BACKUP"
expect "rerun does not create a nested backup" \
  test ! -e "$BACKUP.backup-20260715-143015"
expect_trace "rerun repeats only the safe mise lifecycle" \
  "install --yes go" \
  "install --yes" \
  "reshim"
expect_node_commands_preserved "idempotent rerun" "conflict"

# Scenario 6: a backup from the same second must never become a directory that
# receives the new backup as a nested child. Add a numeric sibling suffix.
reset_machine "backup-collision"
TARGET="$FAKE_HOME/.config/mise"
mkdir -p "$TARGET" "$TARGET.backup-20260715-143015"
printf '%s\n' 'new-legacy-config' >"$TARGET/config.toml"
printf '%s\n' 'older-backup' >"$TARGET.backup-20260715-143015/config.toml"
run_bootstrap personal
expect_success "same-second backup collision succeeds safely"
expect "existing backup remains byte-identical" \
  test "$(<"$TARGET.backup-20260715-143015/config.toml")" = "older-backup"
expect "new conflict receives a numeric sibling backup" \
  test "$(<"$TARGET.backup-20260715-143015-1/config.toml")" = "new-legacy-config"
expect "collision path still produces the exact repo link" \
  test "$(readlink "$TARGET")" = "$TEST_REPO/config/mise"
expect_node_commands_preserved "backup collision" "backup-collision"

# Scenario 7: XDG_CONFIG_HOME changes only the live destination. The source and
# lifecycle stay identical, and ~/.config remains untouched.
reset_machine "xdg"
RUN_XDG_CONFIG_HOME="$FAKE_HOME/custom-config"
mkdir -p "$FAKE_HOME/.config/mise"
printf '%s\n' 'default-config-must-stay' >"$FAKE_HOME/.config/mise/config.toml"
run_bootstrap personal
expect_success "XDG personal bootstrap succeeds"
TARGET="$RUN_XDG_CONFIG_HOME/mise"
expect "XDG destination is a whole-directory link" test -L "$TARGET"
expect "XDG link points at this checkout" \
  test "$(readlink "$TARGET")" = "$TEST_REPO/config/mise"
expect "XDG setup leaves the default destination untouched" \
  test "$(<"$FAKE_HOME/.config/mise/config.toml")" = "default-config-must-stay"
expect_trace "XDG setup runs the same lifecycle" \
  "install --yes go" \
  "install --yes" \
  "reshim"
expect_node_commands_preserved "XDG setup" "xdg"

if ((failures > 0)); then
  echo "$failures mise bootstrap regression test(s) failed." >&2
  exit 1
fi

echo "mise bootstrap regression tests: ok"
