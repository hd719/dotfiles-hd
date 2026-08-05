#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HD_STOP="$SCRIPT_DIR/../hd-stop.sh"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/hd-stop-test.XXXXXX")"
trap 'rm -rf "$TEST_DIR"' EXIT

BIN_DIR="$TEST_DIR/bin"
HOME_DIR="$TEST_DIR/home"
STATE_DIR="$HOME_DIR/.config/herdr"
LOG_FILE="$TEST_DIR/commands.log"
mkdir -p "$BIN_DIR" "$STATE_DIR"

cat > "$BIN_DIR/herdr" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'herdr %s\n' "$*" >> "$HD_STOP_TEST_LOG"
case "$*" in
  "api snapshot")
    [[ "${HD_STOP_TEST_SERVER:-running}" != stopped ]]
    ;;
  "workspace list")
    printf '%s\n' '{"result":{"workspaces":[{"workspace_id":"w1"},{"workspace_id":"w2"}]}}'
    ;;
  "workspace create --label home --cwd $HOME --focus")
    printf '%s\n' '{"result":{"workspace":{"workspace_id":"fresh-home"}}}'
    ;;
  "workspace close w1"|"workspace close w2"|"server stop")
    ;;
  *)
    printf 'unexpected herdr command: %s\n' "$*" >&2
    exit 1
    ;;
esac
EOF

cat > "$BIN_DIR/launchctl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'launchctl %s\n' "$*" >> "$HD_STOP_TEST_LOG"
while [[ "$1" != -- ]]; do shift; done
shift
"$@"
EOF

cat > "$BIN_DIR/lsof" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF

chmod +x "$BIN_DIR/herdr" "$BIN_DIR/launchctl" "$BIN_DIR/lsof"
printf 'saved layout\n' > "$STATE_DIR/session.json"
printf 'saved history\n' > "$STATE_DIR/session-history.json"

HOME="$HOME_DIR" \
  PATH="$BIN_DIR:/usr/bin:/bin" \
  HD_STOP_TEST_LOG="$LOG_FILE" \
  HERDR_CONFIG_PATH="$STATE_DIR/config.toml" \
  "$HD_STOP" >/dev/null

grep -Fq 'launchctl submit' "$LOG_FILE"
grep -Fxq 'herdr workspace create --label home --cwd '"$HOME_DIR"' --focus' "$LOG_FILE"
grep -Fxq 'herdr workspace close w1' "$LOG_FILE"
grep -Fxq 'herdr workspace close w2' "$LOG_FILE"
grep -Fxq 'herdr server stop' "$LOG_FILE"

: > "$LOG_FILE"
HOME="$HOME_DIR" \
  PATH="$BIN_DIR:/usr/bin:/bin" \
  HD_STOP_TEST_LOG="$LOG_FILE" \
  HD_STOP_TEST_SERVER=stopped \
  HERDR_CONFIG_PATH="$STATE_DIR/config.toml" \
  "$HD_STOP" >/dev/null

! grep -Fq 'launchctl ' "$LOG_FILE"
test ! -e "$STATE_DIR/session.json"
test ! -e "$STATE_DIR/session-history.json"

printf 'hd-stop test: ok\n'
