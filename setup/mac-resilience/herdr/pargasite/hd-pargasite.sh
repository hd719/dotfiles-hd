#!/usr/bin/env bash
#
# hd-pargasite.sh - Herdr port of tm-pargasite.sh.
# Workspace "pargasite" with tabs: plat-backend, plat-proxy, client-suite, arc.
# Pargasite depends on Platform's backend + proxy, so those are started (or
# detected as already running) before the app tabs.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/hd-lib.sh
source "$SCRIPT_DIR/../lib/hd-lib.sh"

hd_require
hd_ensure_server

read -r WS TAB1 PANE1 <<< "$(hd_workspace_reset pargasite)"

# Tab 1: Platform Backend (required dependency).
# Check if Docker containers are actually running (not just a stale workspace).
BACKEND_RUNNING=$(docker ps --filter "name=rsw-" --format "{{.Names}}" 2>/dev/null | wc -l | tr -d ' ')
BACKEND_STARTED=0
hd_rename_tab "$TAB1" plat-backend
if [ "$BACKEND_RUNNING" -gt 0 ]; then
  hd_run "$PANE1" "echo 'Platform backend containers already running ($BACKEND_RUNNING containers)'"
  hd_run "$PANE1" 'docker ps --filter "name=rsw-" --format "table {{.Names}}\t{{.Status}}"'
  hd_run "$PANE1" "echo ''"
  hd_run "$PANE1" "echo 'Backend is ready. Skipping res-plat-be.'"
else
  hd_run "$PANE1" "res-plat-be"
  BACKEND_STARTED=1
fi

# Tab 2: Platform Proxy (required dependency).
# Check if proxy process is running on port 9001 (workbench) or 9002 (client portal).
PROXY_RUNNING=$(lsof -ti:9001,9002 2>/dev/null | wc -l | tr -d ' ')
PROXY_STARTED=0
PANE_PROXY="$(hd_tab "$WS" plat-proxy)"
if [ "$PROXY_RUNNING" -gt 0 ]; then
  hd_run "$PANE_PROXY" "echo 'Platform proxy already running on ports 9001/9002'"
  hd_run "$PANE_PROXY" "lsof -i:9001,9002 | grep LISTEN"
  hd_run "$PANE_PROXY" "echo ''"
  hd_run "$PANE_PROXY" "echo 'Proxy is ready. Skipping res-plat-proxy-rsc.'"
else
  hd_run "$PANE_PROXY" "res-plat-proxy-rsc"
  PROXY_STARTED=1
fi

# Determine startup delay: only wait if we started backend or proxy.
if [ "$BACKEND_STARTED" -eq 1 ] || [ "$PROXY_STARTED" -eq 1 ]; then
  STARTUP_DELAY="sleep 15"  # Wait for backend/proxy to initialize.
else
  STARTUP_DELAY="echo 'Backend and proxy already running, starting immediately...'"
fi

# Tab 3: Client Suite (port 3003).
PANE_CLIENT="$(hd_tab "$WS" client-suite)"
hd_run "$PANE_CLIENT" "$STARTUP_DELAY && res-parg-client"

# Tab 4: Arc (port 4004).
PANE_ARC="$(hd_tab "$WS" arc)"
hd_run "$PANE_ARC" "$STARTUP_DELAY && res-parg-arc"

# Focus and attach.
hd_focus_attach "$WS"
