#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
RESET="$REPO_DIR/config/herdr/reset-server.sh"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/reset-server-test.XXXXXX")"
trap 'rm -rf "$TEST_DIR"' EXIT

BIN_DIR="$TEST_DIR/bin"
HOME_DIR="$TEST_DIR/home"
LOG_FILE="$TEST_DIR/commands.log"
OUT_FILE="$TEST_DIR/stdout.log"
ERR_FILE="$TEST_DIR/stderr.log"
mkdir -p "$BIN_DIR" "$HOME_DIR"

JQ_BIN="$(command -v jq)" || {
  printf 'reset-server test: jq is required\n' >&2
  exit 1
}

# Three workspaces, so an inside-Herdr run has its own plus two others.
cat > "$BIN_DIR/herdr" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf 'herdr %s\n' "$*" >> "$RESET_TEST_LOG"

case "$1 ${2:-}" in
  "api snapshot")
    if [[ "${RESET_TEST_SERVER:-running}" == stopped ]]; then
      exit 1
    fi
    printf '%s\n' '{"result":{"snapshot":{"protocol":20}}}'
    ;;
  "workspace list")
    printf '%s\n' '{"result":{"workspaces":[{"workspace_id":"ws-mine"},{"workspace_id":"ws-other"},{"workspace_id":"ws-third"}]}}'
    ;;
  "workspace create")
    printf '%s\n' '{"result":{"workspace":{"workspace_id":"ws-home"},"root_pane":{"tab_id":"ws-home:t1","pane_id":"ws-home:p1"}}}'
    ;;
  "workspace close"|"server stop")
    ;;
  *)
    printf 'unexpected herdr command: %s\n' "$*" >&2
    exit 1
    ;;
esac
EOF

chmod +x "$BIN_DIR/herdr"

# Run the reset with the stub on PATH. Extra arguments become environment
# assignments for env, then any trailing script options.
run_reset() {
  : > "$LOG_FILE"
  env -u HERDR_ENV -u HERDR_WORKSPACE_ID \
    PATH="$BIN_DIR:/usr/bin:/bin" \
    HOME="$HOME_DIR" \
    JQ_BIN="$JQ_BIN" \
    RESET_TEST_LOG="$LOG_FILE" \
    "$@" >"$OUT_FILE" 2>"$ERR_FILE"
}

line_of() {
  grep -nFx "$1" "$LOG_FILE" | cut -d: -f1
}

# set -e never aborts on a command whose status is inverted by !, so every
# negative assertion has to fail explicitly or it proves nothing.
refute() {
  local needle="$1"
  local file="$2"
  local reason="$3"
  if grep -Fq "$needle" "$file"; then
    printf '%s\n' "$reason" >&2
    exit 1
  fi
}

# Outside Herdr: every workspace closes and the server stops.
run_reset "$RESET"
grep -Fxq "herdr workspace create --label home --cwd $HOME_DIR --focus" "$LOG_FILE"
grep -Fxq 'herdr workspace close ws-mine' "$LOG_FILE"
grep -Fxq 'herdr workspace close ws-other' "$LOG_FILE"
grep -Fxq 'herdr workspace close ws-third' "$LOG_FILE"
grep -Fxq 'herdr server stop' "$LOG_FILE"
refute 'workspace close ws-home' "$LOG_FILE" 'the fresh home workspace must never be closed'

# Inside Herdr: the server must survive so this client keeps running, and the
# workspace owning the shell must be the last one closed.
run_reset HERDR_ENV=1 HERDR_WORKSPACE_ID=ws-mine "$RESET"
refute 'server stop' "$LOG_FILE" 'an inside-Herdr reset must not stop the server'
refute 'workspace close ws-home' "$LOG_FILE" 'the fresh home workspace must never be closed'

create_line="$(grep -n 'workspace create' "$LOG_FILE" | cut -d: -f1)"
own_line="$(line_of 'herdr workspace close ws-mine')"
other_line="$(line_of 'herdr workspace close ws-other')"
third_line="$(line_of 'herdr workspace close ws-third')"

if [ "$create_line" -ge "$other_line" ]; then
  printf 'the home workspace must exist before anything is closed\n' >&2
  exit 1
fi
if [ "$own_line" -le "$other_line" ] || [ "$own_line" -le "$third_line" ]; then
  printf 'the workspace owning this shell must be closed last\n' >&2
  exit 1
fi

# Inside Herdr without a workspace ID, closing blindly would kill this client.
if run_reset HERDR_ENV=1 "$RESET"; then
  printf 'reset must refuse when Herdr does not report the current workspace\n' >&2
  exit 1
fi
grep -Fq 'did not report which workspace' "$ERR_FILE"
refute 'workspace close' "$LOG_FILE" 'a refused reset must not close anything'
refute 'workspace create' "$LOG_FILE" 'a refused reset must not create anything'

# A stopped server has nothing to reset.
if run_reset RESET_TEST_SERVER=stopped "$RESET"; then
  printf 'reset must refuse when the server is not running\n' >&2
  exit 1
fi
grep -Fq 'not running' "$ERR_FILE"
refute 'workspace create' "$LOG_FILE" 'a stopped server must not be reset'

# --dry-run reports the plan and changes nothing.
run_reset "$RESET" --dry-run
grep -Fq 'Would close Herdr workspace: ws-mine' "$OUT_FILE"
grep -Fq 'Would stop Herdr.' "$OUT_FILE"
refute 'workspace create' "$LOG_FILE" '--dry-run must not create a workspace'
refute 'workspace close' "$LOG_FILE" '--dry-run must not close a workspace'
refute 'server stop' "$LOG_FILE" '--dry-run must not stop the server'

# The dry run has to describe the inside-Herdr ending too.
run_reset HERDR_ENV=1 HERDR_WORKSPACE_ID=ws-mine "$RESET" --dry-run
grep -Fq 'Would leave the server running' "$OUT_FILE"
refute 'Would stop Herdr.' "$OUT_FILE" 'an inside-Herdr dry run must not promise to stop the server'

printf 'reset-server test: ok\n'
