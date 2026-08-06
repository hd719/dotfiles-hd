#!/usr/bin/env bash
#
# hd-platform.sh - Herdr port of tm-platform.sh.
# Workspace "platform" with tabs: backend, frontend, hasura.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/hd-lib.sh
source "$SCRIPT_DIR/../lib/hd-lib.sh"

hd_require
hd_ensure_server

# Kill any lingering processes on common ports used by this project.
# This prevents EADDRINUSE errors when restarting.
for port in 9001 9002 3000 3001 8080 9695; do
  lsof -ti :"$port" | xargs kill -9 2>/dev/null || true
done

# Wait a moment after cleanup.
sleep 1

# Reset the "platform" workspace; its first tab becomes "backend".
read -r WS TAB1 PANE1 <<< "$(hd_workspace_reset platform)"
hd_rename_tab "$TAB1" backend
hd_run "$PANE1" "res-plat-be"

# Frontend tab.
PANE_FE="$(hd_tab "$WS" frontend)"
hd_run "$PANE_FE" "res-plat-fe"

# Hasura tab. Wait until Hasura answers on :8080 before launching the console
# (the stack can take a few minutes to come up).
PANE_HAS="$(hd_tab "$WS" hasura)"
hd_run "$PANE_HAS" 'until curl -sf http://localhost:8080/v1/version >/dev/null 2>&1; do echo "waiting for hasura on :8080..."; sleep 5; done; res-plat-hasura'

# Focus and attach.
hd_focus_attach "$WS"
