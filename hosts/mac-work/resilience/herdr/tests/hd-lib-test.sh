#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HD_LIB="$SCRIPT_DIR/../lib/hd-lib.sh"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/hd-lib-test.XXXXXX")"
trap 'rm -rf "$TEST_DIR"' EXIT

BIN_DIR="$TEST_DIR/bin"
LOG_FILE="$TEST_DIR/commands.log"
ERR_FILE="$TEST_DIR/stderr.log"
mkdir -p "$BIN_DIR"

cat > "$BIN_DIR/herdr" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf 'herdr %s\n' "$*" >> "$HD_LIB_TEST_LOG"

case "$*" in
  "api snapshot")
    case "${HD_LIB_TEST_SERVER:-ok}" in
      mismatch)
        printf '%s\n' '{"id":"cli:api:snapshot","error":{"code":"protocol_mismatch","message":"client protocol 20 is newer than server protocol 19; restart the Herdr server before using this command."}}'
        exit 1
        ;;
      cold)
        # Answers only once `herdr server` has been started.
        if [ ! -e "$HD_LIB_TEST_LOG.started" ]; then
          printf 'failed to connect to the Herdr socket\n' >&2
          exit 1
        fi
        printf '%s\n' '{"result":{"snapshot":{"protocol":20}}}'
        ;;
      down)
        printf 'failed to connect to the Herdr socket\n' >&2
        exit 1
        ;;
      *)
        printf '%s\n' '{"result":{"snapshot":{"protocol":20}}}'
        ;;
    esac
    ;;
  "server")
    : > "$HD_LIB_TEST_LOG.started"
    ;;
  *)
    printf 'unexpected herdr command: %s\n' "$*" >&2
    exit 1
    ;;
esac
EOF

chmod +x "$BIN_DIR/herdr"

# Run hd_ensure_server against the stub with the given server state.
run_ensure() {
  env PATH="$BIN_DIR:/usr/bin:/bin" \
    HD_LIB_TEST_LOG="$LOG_FILE" \
    HD_LIB_TEST_SERVER="$1" \
    HD_SERVER_WAIT_ATTEMPTS=3 \
    bash -c 'set -euo pipefail; source "$0"; hd_ensure_server' "$HD_LIB"
}

reset_state() {
  : > "$LOG_FILE"
  : > "$ERR_FILE"
  rm -f "$LOG_FILE.started"
}

# A live server is used as-is; no second server is started.
reset_state
run_ensure ok >/dev/null 2>"$ERR_FILE"
grep -Fxq 'herdr api snapshot' "$LOG_FILE"
! grep -Fxq 'herdr server' "$LOG_FILE"

# A cold start launches the headless server and then succeeds.
reset_state
run_ensure cold >/dev/null 2>"$ERR_FILE"
grep -Fxq 'herdr server' "$LOG_FILE"

# A protocol mismatch never becomes ready, so report the CLI's own message
# immediately instead of starting a doomed second server and waiting it out.
reset_state
start="$SECONDS"
if run_ensure mismatch >/dev/null 2>"$ERR_FILE"; then
  printf 'hd_ensure_server must fail on a protocol mismatch\n' >&2
  exit 1
fi
elapsed="$((SECONDS - start))"

grep -Fq 'protocol_mismatch' "$ERR_FILE"
grep -Fq 'restart the Herdr server' "$ERR_FILE"
! grep -Fq 'did not become ready' "$ERR_FILE"
! grep -Fxq 'herdr server' "$LOG_FILE"
if [ "$elapsed" -ge 3 ]; then
  printf 'hd_ensure_server waited %ss on a protocol mismatch; it must fail fast\n' "$elapsed" >&2
  exit 1
fi

# An unreachable server still times out, but now surfaces the last probe.
reset_state
if run_ensure down >/dev/null 2>"$ERR_FILE"; then
  printf 'hd_ensure_server must fail when the server never answers\n' >&2
  exit 1
fi
grep -Fq 'did not become ready' "$ERR_FILE"
grep -Fq 'failed to connect to the Herdr socket' "$ERR_FILE"

printf 'hd-lib test: ok\n'
