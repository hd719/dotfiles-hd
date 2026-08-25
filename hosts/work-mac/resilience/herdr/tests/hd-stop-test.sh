#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HD_STOP="$SCRIPT_DIR/../hd-stop.sh"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/hd-stop-test.XXXXXX")"
trap 'rm -rf "$TEST_DIR"' EXIT

BIN_DIR="$TEST_DIR/bin"
STATE_DIR="$TEST_DIR/home/.config/herdr"
LOG_FILE="$TEST_DIR/commands.log"
mkdir -p "$BIN_DIR" "$STATE_DIR"
printf 'saved session\n' > "$STATE_DIR/session.json"
printf 'saved history\n' > "$STATE_DIR/session-history.json"

cat > "$BIN_DIR/herdr" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'herdr %s\n' "$*" >> "$HD_STOP_TEST_LOG"
case "$*" in
  "api snapshot")
    if [[ "${HD_STOP_TEST_SERVER:-running}" == mismatch ]]; then
      printf '%s\n' '{"error":{"code":"protocol_mismatch","message":"client protocol 20 is newer than server protocol 19"}}'
      exit 1
    fi
    [[ "${HD_STOP_TEST_SERVER:-running}" != stopped ]]
    ;;
  "server stop")
    [[ -z "${HD_STOP_TEST_STOP_FAIL:-}" ]]
    ;;
  *)
    printf 'unexpected herdr command: %s\n' "$*" >&2
    exit 1
    ;;
esac
EOF

cat > "$BIN_DIR/lsof" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF

chmod +x "$BIN_DIR/herdr" "$BIN_DIR/lsof"

HOME="$TEST_DIR/home" \
  PATH="$BIN_DIR:/usr/bin:/bin" \
  HD_STOP_TEST_LOG="$LOG_FILE" \
  "$HD_STOP" >/dev/null

grep -Fxq 'herdr api snapshot' "$LOG_FILE"
grep -Fxq 'herdr server stop' "$LOG_FILE"
! grep -Fq 'herdr workspace ' "$LOG_FILE"
! grep -Fq 'launchctl ' "$LOG_FILE"
test -e "$STATE_DIR/session.json"
test -e "$STATE_DIR/session-history.json"

: > "$LOG_FILE"
HOME="$TEST_DIR/home" \
  PATH="$BIN_DIR:/usr/bin:/bin" \
  HD_STOP_TEST_LOG="$LOG_FILE" \
  HD_STOP_TEST_SERVER=stopped \
  "$HD_STOP" >/dev/null

grep -Fxq 'herdr api snapshot' "$LOG_FILE"
! grep -Fxq 'herdr server stop' "$LOG_FILE"

: > "$LOG_FILE"
HOME="$TEST_DIR/home" \
  PATH="$BIN_DIR:/usr/bin:/bin" \
  HD_DRY_RUN=1 \
  HD_STOP_TEST_LOG="$LOG_FILE" \
  "$HD_STOP" >/dev/null

grep -Fxq 'herdr api snapshot' "$LOG_FILE"
! grep -Fxq 'herdr server stop' "$LOG_FILE"

# A protocol-mismatched server is still running, so it must be stopped rather
# than reported as absent. Stopping it is how the mismatch gets resolved.
: > "$LOG_FILE"
HOME="$TEST_DIR/home" \
  PATH="$BIN_DIR:/usr/bin:/bin" \
  HD_STOP_TEST_LOG="$LOG_FILE" \
  HD_STOP_TEST_SERVER=mismatch \
  "$HD_STOP" >/dev/null

grep -Fxq 'herdr api snapshot' "$LOG_FILE"
grep -Fxq 'herdr server stop' "$LOG_FILE"

printf 'hd-stop test: ok\n'
