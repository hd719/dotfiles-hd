#!/usr/bin/env bash
#
# hd-calc.sh - Herdr port of tm-calc.sh.
# Workspace "parg-calc" running the cyber-risk-calculator app.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/hd-lib.sh
source "$SCRIPT_DIR/../lib/hd-lib.sh"

hd_require
hd_ensure_server

read -r WS TAB1 PANE1 <<< "$(hd_workspace_reset parg-calc)"
hd_rename_tab "$TAB1" calculator
hd_run "$PANE1" "res-parg-calc"

hd_focus_attach "$WS"
