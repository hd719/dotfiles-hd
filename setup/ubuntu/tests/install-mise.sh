#!/usr/bin/env bash
# Stop on command errors, unset variables, and failures hidden in pipelines.
set -euo pipefail

# This offline integration test gives the Ubuntu installer a disposable HOME,
# PATH, os-release file, and package manager. It cannot touch the real machine,
# use sudo, or reach the network.
SOURCE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
INSTALLER="$SOURCE_ROOT/setup/ubuntu/install-mise.sh"
SHARED_BOOTSTRAP="$SOURCE_ROOT/setup/mise/bootstrap.sh"
REAL_BASH="$(command -v bash)"
REAL_ENV="$(command -v env)"
REAL_RM="$(command -v rm)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/ubuntu-install-mise.XXXXXX")"
failures=0

cleanup() {
  "$REAL_RM" -rf "$TMP_ROOT"
}
trap cleanup EXIT

# Keep a missing production command failure direct so a beginner knows which
# file this regression harness expects.
if [[ ! -f "$INSTALLER" ]]; then
  echo "missing production script: $INSTALLER" >&2
  exit 1
fi

if [[ ! -f "$SHARED_BOOTSTRAP" ]]; then
  echo "missing shared mise bootstrap: $SHARED_BOOTSTRAP" >&2
  exit 1
fi

write_stub() {
  local path="$1"
  shift

  {
    printf '#!%s\n' "$REAL_BASH"
    printf '%s\n' "$@"
  } >"$path"
  chmod +x "$path"
}

expect() {
  local label="$1"
  shift

  if ! "$@"; then
    echo "FAIL: $label" >&2
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

expect_success() {
  local label="$1"

  if ((RUN_STATUS != 0)); then
    echo "FAIL: $label (status $RUN_STATUS)" >&2
    printf '%s\n' "$RUN_OUTPUT" >&2
    failures=$((failures + 1))
  fi
}

expect_control_trace() {
  local label="$1"
  shift
  local expected="$STATE_DIR/expected-control.trace"
  local actual="$STATE_DIR/actual-control.trace"

  printf '%s\n' "$@" >"$expected"
  grep -E '^(apt-get|extrepo|bootstrap) ' "$EVENT_LOG" >"$actual" || true

  if ! cmp -s "$expected" "$actual"; then
    echo "FAIL: $label" >&2
    echo "expected control flow:" >&2
    sed 's/^/  /' "$expected" >&2
    echo "actual control flow:" >&2
    if [[ -s "$actual" ]]; then
      sed 's/^/  /' "$actual" >&2
    else
      echo "  <none>" >&2
    fi
    failures=$((failures + 1))
  fi
}

expect_no_event() {
  local label="$1"
  local pattern="$2"

  if grep -Eq -- "$pattern" "$EVENT_LOG"; then
    echo "FAIL: $label (unexpected pattern: $pattern)" >&2
    sed 's/^/  /' "$EVENT_LOG" >&2
    failures=$((failures + 1))
  fi
}

expect_mise_lifecycle() {
  local label="$1"
  local bootstrap_line go_line install_line reshim_line

  bootstrap_line="$(grep -nEm1 '^bootstrap personal$' "$EVENT_LOG" | cut -d: -f1 || true)"
  go_line="$(grep -nEm1 '^mise install --yes go$' "$EVENT_LOG" | cut -d: -f1 || true)"
  install_line="$(grep -nEm1 '^mise install --yes$' "$EVENT_LOG" | cut -d: -f1 || true)"
  reshim_line="$(grep -nEm1 '^mise reshim$' "$EVENT_LOG" | cut -d: -f1 || true)"

  if [[ -z "$bootstrap_line" || -z "$go_line" || -z "$install_line" || -z "$reshim_line" ]] \
    || ! ((bootstrap_line < go_line && go_line < install_line && install_line < reshim_line)); then
    echo "FAIL: $label" >&2
    sed 's/^/  /' "$EVENT_LOG" >&2
    failures=$((failures + 1))
  fi
}

make_fake_machine() {
  local name="$1"
  local ubuntu_version="$2"
  local mise_state="$3"
  local command_name command_path

  MACHINE_ROOT="$TMP_ROOT/$name"
  FAKE_HOME="$MACHINE_ROOT/home"
  FAKE_BIN="$MACHINE_ROOT/bin"
  STATE_DIR="$MACHINE_ROOT/state"
  TEST_REPO="$MACHINE_ROOT/dotfiles"
  EVENT_LOG="$STATE_DIR/events.log"
  OS_RELEASE="$STATE_DIR/os-release"
  EXTREPO_ENABLED="$STATE_DIR/extrepo-enabled"
  EXTREPO_TEMPLATE="$STATE_DIR/extrepo-template"
  MISE_TEMPLATE="$STATE_DIR/mise-template"

  mkdir -p \
    "$FAKE_HOME" \
    "$FAKE_BIN" \
    "$STATE_DIR" \
    "$TEST_REPO/config/mise" \
    "$TEST_REPO/setup/mise"
  : >"$EVENT_LOG"
  printf 'ID=ubuntu\nVERSION_ID="%s"\n' "$ubuntu_version" >"$OS_RELEASE"
  printf '[tools]\nnode = "26.1.0"\n' >"$TEST_REPO/config/mise/config.toml"

  # These commands are harmless harness utilities used by the installer and
  # shared linker. Package and privilege commands are controlled stubs below.
  for command_name in cat chmod cmp cp cut date dirname grep ln mkdir mv pwd readlink sed; do
    command_path="$(command -v "$command_name" 2>/dev/null || true)"
    [[ -n "$command_path" ]] && ln -s "$command_path" "$FAKE_BIN/$command_name"
  done
  # The real shared script uses `#!/usr/bin/env bash`; expose Bash without
  # exposing any package manager or network command from the host machine.
  ln -s "$REAL_BASH" "$FAKE_BIN/bash"

  # This wrapper proves the Ubuntu script calls the shared command from the
  # DOTFILES_DIR checkout, passes the explicit personal scope, and lets that
  # shared command perform the real link behavior inside disposable HOME.
  write_stub "$TEST_REPO/setup/mise/bootstrap.sh" \
    'printf "bootstrap %s\n" "$*" >>"$TEST_EVENT_LOG"' \
    'exec "$TEST_SHARED_BOOTSTRAP" "$@"'

  # Fake mise records lifecycle calls. It never downloads a runtime.
  write_stub "$MISE_TEMPLATE" \
    'printf "mise %s\n" "$*" >>"$TEST_EVENT_LOG"' \
    'case "${1:-}" in' \
    '  --version|-v|version) echo "2026.7.6 linux-arm64" ;;' \
    'esac'

  # extrepo is unavailable until APT installs it. Enabling the mise repository
  # leaves a marker that the later `apt-get install mise` step must observe.
  write_stub "$EXTREPO_TEMPLATE" \
    'printf "extrepo %s\n" "$*" >>"$TEST_EVENT_LOG"' \
    '[[ "$*" == "enable mise" ]] || exit 91' \
    ': >"$TEST_EXTREPO_ENABLED"'

  # The APT stub models only the five allowed package-manager events. It also
  # materializes extrepo and mise at the same points a real install would.
  write_stub "$FAKE_BIN/apt-get" \
    'printf "apt-get %s\n" "$*" >>"$TEST_EVENT_LOG"' \
    'case "$*" in' \
    '  update) ;;' \
    '  "install -y extrepo")' \
    '    cp "$TEST_EXTREPO_TEMPLATE" "$TEST_FAKE_BIN/extrepo"' \
    '    chmod +x "$TEST_FAKE_BIN/extrepo"' \
    '    ;;' \
    '  "install -y mise")' \
    '    [[ -f "$TEST_EXTREPO_ENABLED" ]] || exit 92' \
    '    cp "$TEST_MISE_TEMPLATE" "$TEST_FAKE_BIN/mise"' \
    '    chmod +x "$TEST_FAKE_BIN/mise"' \
    '    ;;' \
    '  *) exit 93 ;;' \
    'esac'

  # sudo performs no privilege change in the disposable machine. It simply
  # forwards the command so the controlled apt/extrepo stubs receive it.
  write_stub "$FAKE_BIN/sudo" 'exec "$@"'

  # Report a regular non-root account, matching the Ubuntu VM setup path.
  write_stub "$FAKE_BIN/id" \
    'if [[ "${1:-}" == "-u" ]]; then echo 1000; else echo hamel; fi'

  if [[ "$mise_state" == "existing" ]]; then
    cp "$MISE_TEMPLATE" "$FAKE_BIN/mise"
    chmod +x "$FAKE_BIN/mise"
  fi
}

run_installer() {
  set +e
  RUN_OUTPUT="$(
    "$REAL_ENV" -u XDG_CONFIG_HOME \
      HOME="$FAKE_HOME" \
      PATH="$FAKE_BIN" \
      DOTFILES_DIR="$TEST_REPO" \
      DOTFILES_OS_RELEASE_FILE="$OS_RELEASE" \
      TEST_EVENT_LOG="$EVENT_LOG" \
      TEST_EXTREPO_ENABLED="$EXTREPO_ENABLED" \
      TEST_EXTREPO_TEMPLATE="$EXTREPO_TEMPLATE" \
      TEST_MISE_TEMPLATE="$MISE_TEMPLATE" \
      TEST_FAKE_BIN="$FAKE_BIN" \
      TEST_SHARED_BOOTSTRAP="$SHARED_BOOTSTRAP" \
      "$REAL_BASH" "$INSTALLER" "$@" 2>&1
  )"
  RUN_STATUS=$?
  set -e
}

expect_shared_link() {
  local label="$1"
  local target="$FAKE_HOME/.config/mise"

  expect "$label: destination is a whole-directory link" test -L "$target"
  expect "$label: destination points at this DOTFILES_DIR checkout" \
    test "$(readlink "$target" 2>/dev/null || true)" = "$TEST_REPO/config/mise"
  expect "$label: linked config is readable" \
    cmp -s "$target/config.toml" "$TEST_REPO/config/mise/config.toml"
}

expect_no_config_backups() {
  local label="$1"
  local target="$FAKE_HOME/.config/mise"
  local -a backups

  shopt -s nullglob
  backups=("$target".backup-*)
  shopt -u nullglob
  expect "$label" test "${#backups[@]}" -eq 0
}

# Scenario 1: this public adapter intentionally takes no arguments. Rejecting
# extras before any mutation prevents ambiguous install modes from appearing.
make_fake_machine "unexpected-argument" "26.04" existing
run_installer personal
expect_status "unexpected argument is a usage error" 2
expect_no_event "usage failure does not install packages or bootstrap runtimes" \
  '^(apt-get|extrepo|bootstrap|mise) '
expect "usage failure does not create config" test ! -e "$FAKE_HOME/.config/mise"

# Scenario 2: older Ubuntu releases are outside this tested adapter. The shared
# bootstrap and package manager remain untouched when the OS gate fails.
make_fake_machine "old-ubuntu" "25.10" existing
run_installer
expect "Ubuntu older than 26.04 is rejected" test "$RUN_STATUS" -ne 0
expect_no_event "OS rejection happens before all mutations" \
  '^(apt-get|extrepo|bootstrap|mise) '

# The documented floor is 26.04, not merely major version 26. Reject an earlier
# 26.x development snapshot before package or config mutations.
make_fake_machine "early-26" "26.03" existing
run_installer
expect "Ubuntu 26.03 is rejected" test "$RUN_STATUS" -ne 0
expect_no_event "26.03 rejection happens before all mutations" \
  '^(apt-get|extrepo|bootstrap|mise) '

# An executable name alone is not proof that mise works. A broken user shim can
# shadow /usr/bin/mise even after APT, so stop with a repair message instead of
# mutating packages and pretending the shadow was fixed.
make_fake_machine "broken-mise" "26.04" existing
write_stub "$FAKE_BIN/mise" \
  'printf "mise %s\n" "$*" >>"$TEST_EVENT_LOG"' \
  'exit 70'
run_installer
expect "broken existing mise is rejected" test "$RUN_STATUS" -ne 0
expect_no_event "broken mise does not mutate APT, extrepo, or config" \
  '^(apt-get|extrepo|bootstrap) '
expect "broken mise leaves config absent" test ! -e "$FAKE_HOME/.config/mise"

# Scenario 3: when mise already works, Ubuntu must not mutate APT or extrepo.
# It still converges the shared personal config and every pinned runtime.
make_fake_machine "existing-mise" "26.04" existing
run_installer
expect_success "existing mise path succeeds"
expect_control_trace "existing mise skips every package-manager command" \
  "bootstrap personal"
expect_mise_lifecycle "existing mise runs the shared lifecycle in order"
expect_shared_link "existing mise"

# The second run repeats only mise's safe, idempotent convergence calls. A
# correct link is retained and no timestamped backup appears.
: >"$EVENT_LOG"
run_installer
expect_success "second existing-mise run succeeds"
expect_control_trace "existing-mise rerun still skips package-manager commands" \
  "bootstrap personal"
expect_mise_lifecycle "existing-mise rerun repeats the shared lifecycle"
expect_shared_link "existing-mise rerun"
expect_no_config_backups "existing-mise rerun creates no config backup"

# Scenario 4: a fresh Ubuntu machine uses the official extrepo-backed APT path.
# The exact order matters: extrepo must exist before enabling the repository,
# and APT must refresh that repository before installing mise.
make_fake_machine "fresh-mise" "26.04" missing
run_installer
expect_success "fresh mise path succeeds"
expect_control_trace "fresh mise follows the exact APT/extrepo/bootstrap order" \
  "apt-get update" \
  "apt-get install -y extrepo" \
  "extrepo enable mise" \
  "apt-get update" \
  "apt-get install -y mise" \
  "bootstrap personal"
expect_mise_lifecycle "fresh mise runs the shared lifecycle after installation"
expect_shared_link "fresh mise"

# Once the CLI and link exist, rerunning the fresh-machine path must not touch
# APT or extrepo again.
: >"$EVENT_LOG"
run_installer
expect_success "second fresh-mise run succeeds"
expect_control_trace "fresh-mise rerun performs no package-manager mutations" \
  "bootstrap personal"
expect_mise_lifecycle "fresh-mise rerun repeats the shared lifecycle"
expect_shared_link "fresh-mise rerun"
expect_no_config_backups "fresh-mise rerun creates no config backup"

if ((failures > 0)); then
  echo "$failures Ubuntu mise installer regression test(s) failed." >&2
  exit 1
fi

echo "Ubuntu mise installer regression tests: ok"
