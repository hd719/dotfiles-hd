#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DIR="$(cd "$TEST_DIR/../../.." && pwd -P)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-vm-lifecycle-test.XXXXXX")"
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

cat >"$FAKE_BIN/vagrant" <<'FAKE_VAGRANT'
#!/usr/bin/env bash
printf 'cwd=%s vagrant_cwd=%s gui=%s provider=%s clone=%s args=%s\n' \
  "$PWD" \
  "${VAGRANT_CWD:-unset}" \
  "${UBUNTU_VM_GUI:-unset}" \
  "${VAGRANT_DEFAULT_PROVIDER:-unset}" \
  "${VAGRANT_VMWARE_CLONE_DIRECTORY:-unset}" \
  "$*" >>"${VAGRANT_TEST_LOG:?}"
if [[ "${1:-}" == ssh ]]; then
  printf '192.0.2.10\n'
fi
FAKE_VAGRANT
chmod +x "$FAKE_BIN/vagrant"

output="$(
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
    ' zsh "$REPO_DIR/hosts/mac-thin/vm.zsh"
)"

assert_contains "$VAGRANT_LOG" \
  "cwd=$REPO_DIR/hosts/ubuntu-dev vagrant_cwd=$REPO_DIR/hosts/ubuntu-dev gui=1 provider=vmware_desktop"
for args in up halt suspend resume status 'ssh -c hostname -I' destroy; do
  assert_contains "$VAGRANT_LOG" "args=$args"
done
assert_contains "$VAGRANT_LOG" 'sudo -n -u hamel'
assert_not_contains "$VAGRANT_LOG" 'destroy -f'
[[ "$output" == *"Remove this VM's three registered Git public keys"* ]] \
  || fail 'destroy should print the Git-key removal reminder'

assert_not_contains "$REPO_DIR/hosts/mac-thin/vm.zsh" \
  'Ubuntu 64-bit Arm 25.10.vmwarevm'
assert_contains "$REPO_DIR/config/zsh/mac/personal/aliases.zsh" \
  "alias u='ssh ubuntu-vm'"
assert_contains "$REPO_DIR/config/zsh/mac/personal/aliases.zsh" \
  "alias mini='ssh mac-mini-lan'"
for expected in 'Host ubuntu-vm' 'HostName 127.0.0.1' 'ForwardAgent no' \
  'StrictHostKeyChecking yes'; do
  assert_contains "$REPO_DIR/hosts/mac-thin/ssh/ubuntu-vagrant.conf" "$expected"
done
for expected in \
  'config.vm.box_version = "202606.01.0"' \
  'config.vm.box_architecture = "arm64"' \
  'config.vm.box_check_update = false' \
  'vmware.base_mac = "00:0C:29:10:D0:E6"' \
  '"DOTFILES_GIT_REF" => dotfiles_git_ref' \
  'config.vm.synced_folder ".", "/vagrant", disabled: true' \
  'id: "ssh"' \
  'host_ip: "127.0.0.1"' \
  'config.vm.disk :disk, size: 250 * 1024**3, primary: true'; do
  assert_contains "$REPO_DIR/hosts/ubuntu-dev/Vagrantfile" "$expected"
done
assert_contains "$REPO_DIR/hosts/mac-thin/Brewfile" 'cask "vagrant"'
assert_contains "$REPO_DIR/hosts/mac-thin/Brewfile" \
  'cask "vagrant-vmware-utility"'
assert_contains "$REPO_DIR/hosts/mac-thin/bootstrap.sh" \
  'VAGRANT_VMWARE_PLUGIN_VERSION="3.0.5"'
assert_contains "$REPO_DIR/hosts/mac-thin/bootstrap.sh" \
  'vagrant plugin install vagrant-vmware-desktop'
assert_contains "$REPO_DIR/hosts/mac-thin/bootstrap.sh" \
  '--plugin-version "$VAGRANT_VMWARE_PLUGIN_VERSION"'

printf 'VM lifecycle tests passed.\n'
