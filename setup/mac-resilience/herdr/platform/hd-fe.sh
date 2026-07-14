#!/usr/bin/env bash
#
# hd-fe.sh - Herdr port of tm-fe.sh.
# Workspace "rsw-frontend" running the workbench web app.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/hd-lib.sh
source "$SCRIPT_DIR/../lib/hd-lib.sh"

hd_require
hd_ensure_server

read -r WS TAB1 PANE1 <<< "$(hd_workspace_reset rsw-frontend)"
hd_rename_tab "$TAB1" frontend
hd_run "$PANE1" "cd ~/Developer/Resilience/resilience-platform/apps/resilience-security-workbench-web && yarn dev"

hd_focus_attach "$WS"
