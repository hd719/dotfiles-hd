#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DIR="$(cd "$TEST_DIR/../.." && pwd -P)"

tests=(
  hosts/shared/macos/tests/bootstrap-test.sh
  hosts/mac-thin/tests/thin-bootstrap-test.sh
  hosts/mac-thin/tests/vm-lifecycle-test.sh
  hosts/mac-studio/tests/vm-lifecycle-test.sh
  hosts/mac-work/tests/goodmorning-test.sh
  hosts/mac-work/herdr/tests/hd-lib-test.sh
  hosts/mac-work/herdr/tests/hd-pargasite-test.sh
  hosts/mac-work/herdr/tests/hd-stop-test.sh
  config/zsh/shared/tests/herdr-reset-test.sh
  hosts/ubuntu-dev/tests/lean-setup.sh
)

for test_path in "${tests[@]}"; do
  printf 'TEST %s\n' "$test_path"
  bash "$REPO_DIR/$test_path"
done

printf 'Host tests passed.\n'
