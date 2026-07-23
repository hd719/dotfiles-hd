#!/usr/bin/env bash
#
# hd-ed.sh - Herdr port of tm-ed.sh.
# Workspace "rsw-proxy" with tabs: proxy-web, proxy-client.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/hd-lib.sh
source "$SCRIPT_DIR/../lib/hd-lib.sh"

hd_require
hd_ensure_server

read -r WS TAB1 PANE1 <<< "$(hd_workspace_reset rsw-proxy)"
hd_rename_tab "$TAB1" proxy-web
hd_run "$PANE1" "cd ~/Developer/Resilience/resilience-platform/apps/resilience-security-workbench-proxy && yarn workbench-proxy"

PANE_CLIENT="$(hd_tab "$WS" proxy-client)"
hd_run "$PANE_CLIENT" "cd ~/Developer/Resilience/resilience-platform/apps/resilience-security-workbench-proxy && yarn client-portal-proxy"

hd_focus_attach "$WS"
