#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/lib.sh"
load_profile "${1:-}"
validate_profile_os
require_canonical_checkout
validate_profile_layout
