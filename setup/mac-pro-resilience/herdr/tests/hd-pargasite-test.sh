#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HD_PARGASITE="$SCRIPT_DIR/../pargasite/hd-pargasite.sh"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/hd-pargasite-test.XXXXXX")"
trap 'rm -rf "$TEST_DIR"' EXIT

BIN_DIR="$TEST_DIR/bin"
LOG_FILE="$TEST_DIR/commands.log"
mkdir -p "$BIN_DIR"

cat > "$BIN_DIR/herdr" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf 'herdr %s\n' "$*" >> "$HD_PARGASITE_TEST_LOG"

case "${1:-} ${2:-}" in
  "api snapshot")
    ;;
  "workspace list")
    printf '%s\n' '{"result":{"workspaces":[{"workspace_id":"pargasite-old","label":"pargasite"}]}}'
    ;;
  "workspace create")
    printf '%s\n' '{"result":{"workspace":{"workspace_id":"pargasite-new"},"root_pane":{"tab_id":"tab-backend","pane_id":"pane-backend"}}}'
    ;;
  "workspace close"|"workspace focus"|"tab rename"|"pane run")
    ;;
  "tab create")
    label=""
    while [ "$#" -gt 0 ]; do
      if [ "$1" = "--label" ]; then
        label="$2"
        break
      fi
      shift
    done
    printf '{"result":{"root_pane":{"pane_id":"pane-%s"}}}\n' "$label"
    ;;
  *)
    printf 'unexpected herdr command: %s\n' "$*" >&2
    exit 1
    ;;
esac
EOF

# Both exit nonzero on a cold start: no Docker daemon and no listening proxy.
cat > "$BIN_DIR/docker" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF

cat > "$BIN_DIR/lsof" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF

chmod +x "$BIN_DIR/herdr" "$BIN_DIR/docker" "$BIN_DIR/lsof"

HOME="$TEST_DIR/home" \
  PATH="$BIN_DIR:/usr/bin:/bin" \
  HD_NO_ATTACH=1 \
  HERDR_ENV=1 \
  HERDR_WORKSPACE_ID=pargasite-old \
  HD_PARGASITE_TEST_LOG="$LOG_FILE" \
  "$HD_PARGASITE" >/dev/null

create_line="$(grep -nFx 'herdr workspace create --label pargasite --no-focus' "$LOG_FILE" | cut -d: -f1)"
focus_line="$(grep -nFx 'herdr workspace focus pargasite-new' "$LOG_FILE" | cut -d: -f1)"
close_line="$(grep -nFx 'herdr workspace close pargasite-old' "$LOG_FILE" | cut -d: -f1)"

if [ "$create_line" -ge "$focus_line" ] || [ "$focus_line" -ge "$close_line" ]; then
  printf 'hd-parg must create and focus the replacement before closing its current workspace\n' >&2
  exit 1
fi

grep -Fq 'res-plat-be' "$LOG_FILE"
grep -Fq 'res-plat-proxy-rsc' "$LOG_FILE"
grep -Fq 'res-parg-client' "$LOG_FILE"
grep -Fq 'res-parg-arc' "$LOG_FILE"

printf 'hd-pargasite test: ok\n'
