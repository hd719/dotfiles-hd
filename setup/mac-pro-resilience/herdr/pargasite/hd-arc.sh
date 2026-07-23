#!/usr/bin/env bash
#
# hd-arc.sh - Herdr port of tm-arc.sh.
# Workspace "parg-arc" running the arc app.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/hd-lib.sh
source "$SCRIPT_DIR/../lib/hd-lib.sh"

hd_require
hd_ensure_server

read -r WS TAB1 PANE1 <<< "$(hd_workspace_reset parg-arc)"
hd_rename_tab "$TAB1" arc
hd_run "$PANE1" "res-parg-arc"

hd_focus_attach "$WS"
