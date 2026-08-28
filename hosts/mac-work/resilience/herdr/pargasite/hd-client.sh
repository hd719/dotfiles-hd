#!/usr/bin/env bash
#
# hd-client.sh - Herdr port of tm-client.sh.
# Workspace "parg-client" running the client-suite app.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/hd-lib.sh
source "$SCRIPT_DIR/../lib/hd-lib.sh"

hd_require
hd_ensure_server

read -r WS TAB1 PANE1 <<< "$(hd_workspace_reset parg-client)"
hd_rename_tab "$TAB1" client-suite
hd_run "$PANE1" "res-parg-client"

hd_focus_attach "$WS"
