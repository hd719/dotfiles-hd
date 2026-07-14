#!/usr/bin/env bash
#
# hd-be.sh - Herdr port of tm-be.sh.
# Workspace "rsw-backend" running the Docker backend services.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/hd-lib.sh
source "$SCRIPT_DIR/../lib/hd-lib.sh"

hd_require
hd_ensure_server

read -r WS TAB1 PANE1 <<< "$(hd_workspace_reset rsw-backend)"
hd_rename_tab "$TAB1" docker
hd_run "$PANE1" "cd ~/Developer/Resilience/resilience-platform && bash docker/rsw-initup latest"

hd_focus_attach "$WS"
