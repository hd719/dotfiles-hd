#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DIR="$(cd "$TEST_DIR/../../.." && pwd -P)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-studio-vm-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

FAKE_BIN="$TEST_ROOT/bin"
TEST_HOME="$TEST_ROOT/home"
VAGRANT_LOG="$TEST_ROOT/vagrant.log"
mkdir -p "$FAKE_BIN" "$TEST_HOME"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  grep -Fq -- "$2" "$1" || fail "expected '$2' in $1"
}

assert_not_contains() {
  ! grep -Fq -- "$2" "$1" || fail "did not expect '$2' in $1"
}

cat > "$FAKE_BIN/vagrant" <<'FAKE_VAGRANT'
#!/usr/bin/env bash
printf 'cwd=%s vagrant_cwd=%s gui=%s provider=%s clone=%s args=%s\n' \
  "$PWD" \
  "${VAGRANT_CWD:-unset}" \
  "${UBUNTU_VM_GUI:-unset}" \
  "${VAGRANT_DEFAULT_PROVIDER:-unset}" \
  "${VAGRANT_VMWARE_CLONE_DIRECTORY:-unset}" \
  "$*" >> "${VAGRANT_TEST_LOG:?}"
if [[ "${1:-}" == ssh ]]; then
  printf '192.0.2.10\n'
fi
FAKE_VAGRANT
chmod +x "$FAKE_BIN/vagrant"

output="$({
  HOME="$TEST_HOME" \
    PATH="$FAKE_BIN:/usr/bin:/bin" \
    DOTFILES_UBUNTU_VAGRANT_DIR="$REPO_DIR/hosts/ubuntu-dev" \
    VAGRANT_TEST_LOG="$VAGRANT_LOG" \
    /bin/zsh -dfc '
      source "$1"
      uvm-up
      uvm-stop
      uvm-suspend
      uvm-resume
      uvm-status
      uvm-ip
      uvm-destroy
    ' zsh "$REPO_DIR/hosts/mac-studio/vm.zsh"
} 2>&1)" || fail "$output"

assert_contains "$VAGRANT_LOG" \
  "cwd=$REPO_DIR/hosts/ubuntu-dev vagrant_cwd=$REPO_DIR/hosts/ubuntu-dev gui=1 provider=vmware_desktop"
for args in up halt suspend resume status 'ssh -c hostname -I' destroy; do
  assert_contains "$VAGRANT_LOG" "args=$args"
done
assert_contains "$VAGRANT_LOG" 'sudo -n -u hamel'
assert_not_contains "$VAGRANT_LOG" 'destroy -f'
[[ "$output" == *"Remove this VM's three registered Git public keys"* ]] \
  || fail 'destroy should print the Git-key removal reminder'

assert_contains "$REPO_DIR/hosts/mac-studio/.zshrc" \
  'source "$HOME/Developer/dotfiles-hd/hosts/mac-studio/vm.zsh"'
for expected in 'Host ubuntu-vm' 'HostName 127.0.0.1' 'ForwardAgent no' \
  'StrictHostKeyChecking yes'; do
  assert_contains "$REPO_DIR/hosts/mac-studio/ssh/ubuntu-vagrant.conf" "$expected"
done

printf 'Mac Studio VM lifecycle tests passed.\n'
