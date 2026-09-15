#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DIR="$(cd "$TEST_DIR/../../.." && pwd -P)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-studio-vm-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT
FAKE_BIN="$TEST_ROOT/bin"
TEST_HOME="$TEST_ROOT/home"
PROJECT="$TEST_ROOT/ubuntu"
VAGRANT_LOG="$TEST_ROOT/vagrant.log"
mkdir -p "$FAKE_BIN" "$TEST_HOME" "$PROJECT"
PROJECT="$(cd "$PROJECT" && pwd -P)"
: > "$PROJECT/Vagrantfile"
: > "$VAGRANT_LOG"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

cat > "$FAKE_BIN/vagrant" <<'FAKE'
#!/usr/bin/env bash
printf 'cwd=%s provider=%s gui=%s args=%s\n' \
  "$PWD" "$VAGRANT_DEFAULT_PROVIDER" "${UBUNTU_VM_GUI:-unset}" "$*" \
  >> "${VAGRANT_TEST_LOG:?}"
if [[ "$*" == 'status --machine-readable' ]]; then
  [[ "${VM_STATE:-poweroff}" != error ]] || exit 1
  printf '1,default,state,%s\n' "${VM_STATE:-poweroff}"
fi
# The VMware provider can provision a powered-off restored guest on resume
# when its action_provision sentinel is missing or records its old machine ID.
if [[ "$1" == resume && "$*" != 'resume --no-provision' ]]; then
  printf 'UNSAFE automatic provisioning on resume\n' >> "${VAGRANT_TEST_LOG:?}"
fi
FAKE
chmod +x "$FAKE_BIN/vagrant"

run_shell() {
  HOME="$TEST_HOME" PATH="$FAKE_BIN:/usr/bin:/bin" \
    DOTFILES_UBUNTU_VAGRANT_DIR="$PROJECT" VAGRANT_TEST_LOG="$VAGRANT_LOG" \
    /bin/zsh -dfc 'source "$1"; eval "$2"' zsh \
    "$REPO_DIR/hosts/mac-studio/vm.zsh" "$1"
}
run_shell ':'
[[ ! -s "$VAGRANT_LOG" ]] || fail 'loading helpers invoked Vagrant'

for action in uvm-up uvm-resume; do
  if run_shell "$action" >/dev/null; then fail "$action allowed a missing VM"; fi
done
[[ ! -s "$VAGRANT_LOG" ]] || fail 'missing metadata reached Vagrant'

mkdir -p "$PROJECT/.vagrant/machines/default/vmware_desktop"
printf 'preserved-vm\n' > "$PROJECT/.vagrant/machines/default/vmware_desktop/id"
for state in not_created unknown error; do
  for action in uvm-up uvm-resume; do
    if VM_STATE="$state" run_shell "$action" >/dev/null; then
      fail "$action allowed unavailable state $state"
    fi
  done
done
! grep -Eq 'args=(up|resume)' "$VAGRANT_LOG" || fail 'unavailable VM was started'

: > "$VAGRANT_LOG"
run_shell 'uvm-up; uvm-stop; uvm-suspend; uvm-resume; uvm-status; uvm-ip'
for args in 'up --no-provision' halt suspend 'resume --no-provision' status 'ssh -c hostname -I'; do
  grep -Fq "args=$args" "$VAGRANT_LOG" || fail "missing command: $args"
done
grep -Fq "cwd=$PROJECT provider=vmware_desktop gui=1 args=up --no-provision" \
  "$VAGRANT_LOG" || fail 'start did not preserve provider, project and GUI settings'
! grep -Fq 'args=provision' "$VAGRANT_LOG" || fail 'automatic provisioning'
! grep -Fq 'UNSAFE' "$VAGRANT_LOG" || fail 'resume allowed automatic provisioning'
! grep -Fq destroy "$VAGRANT_LOG" || fail 'unexpected deletion'
run_shell '(( ! $+functions[uvm-destroy] ))' || fail 'destroy shortcut remains'
printf 'Mac Studio dormant VM lifecycle tests passed.\n'
