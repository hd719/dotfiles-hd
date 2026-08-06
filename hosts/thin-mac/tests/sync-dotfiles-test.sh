#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYNC_SCRIPT="$(cd "$SCRIPT_DIR/.." && pwd)/sync-dotfiles.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-sync-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

REMOTE="$TEST_ROOT/origin.git"
SEED="$TEST_ROOT/seed"
THIN="$TEST_ROOT/thin"
UBUNTU="$TEST_ROOT/ubuntu"
MINI="$TEST_ROOT/mini"
SSH_LOG="$TEST_ROOT/ssh.log"
FAKE_SSH="$TEST_ROOT/ssh"

git init --bare -q "$REMOTE"
git init -q -b master "$SEED"
git -C "$SEED" config user.name test
git -C "$SEED" config user.email test@example.com
printf 'baseline\n' > "$SEED/tracked.txt"
git -C "$SEED" add tracked.txt
git -C "$SEED" commit -qm baseline
git -C "$SEED" remote add origin "$REMOTE"
git -C "$SEED" push -q -u origin master
git --git-dir="$REMOTE" symbolic-ref HEAD refs/heads/master

git clone -q "$REMOTE" "$THIN"
git clone -q "$REMOTE" "$UBUNTU"
git clone -q "$REMOTE" "$MINI"
for repo_dir in "$THIN" "$UBUNTU" "$MINI"; do
  git -C "$repo_dir" config user.name test
  git -C "$repo_dir" config user.email test@example.com
done

git -C "$THIN" switch -q -c agent/thin-merged
printf 'feature\n' > "$THIN/feature.txt"
git -C "$THIN" add feature.txt
git -C "$THIN" commit -qm 'thin feature'
git -C "$THIN" push -q -u origin agent/thin-merged

git -C "$UBUNTU" switch -q -c agent/ubuntu-merged
printf 'ubuntu feature\n' > "$UBUNTU/ubuntu.txt"
git -C "$UBUNTU" add ubuntu.txt
git -C "$UBUNTU" commit -qm 'ubuntu feature'
git -C "$UBUNTU" push -q -u origin agent/ubuntu-merged

git -C "$MINI" switch -q -c agent/mini-merged
printf 'mini feature\n' > "$MINI/mini.txt"
git -C "$MINI" add mini.txt
git -C "$MINI" commit -qm 'mini feature'
git -C "$MINI" push -q -u origin agent/mini-merged

git -C "$SEED" fetch -q origin \
  agent/thin-merged agent/ubuntu-merged agent/mini-merged
git -C "$SEED" merge -q --no-ff origin/agent/thin-merged -m 'merge thin feature'
git -C "$SEED" merge -q --no-ff origin/agent/ubuntu-merged -m 'merge ubuntu feature'
git -C "$SEED" merge -q --no-ff origin/agent/mini-merged -m 'merge mini feature'
printf 'merged\n' >> "$SEED/tracked.txt"
git -C "$SEED" commit -qam merged
git -C "$SEED" push -q origin master

cat > "$FAKE_SSH" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -o)
      shift 2
      ;;
    -*)
      shift
      ;;
    *)
      break
      ;;
  esac
done

host="$1"
shift
printf '%s\n' "$host" >> "$DOTFILES_TEST_SSH_LOG"

case ",${DOTFILES_TEST_FAIL_HOSTS:-}," in
  *",$host,"*) exit 255 ;;
esac

exec "$@"
EOF
chmod +x "$FAKE_SSH"

DOTFILES_SYNC_THIN_REPO="$THIN" \
DOTFILES_SYNC_UBUNTU_REPO="$UBUNTU" \
DOTFILES_SYNC_MINI_REPO="$MINI" \
DOTFILES_SYNC_SSH_BIN="$FAKE_SSH" \
DOTFILES_TEST_SSH_LOG="$SSH_LOG" \
DOTFILES_TEST_FAIL_HOSTS="ubuntu-vm-ts" \
  "$SYNC_SCRIPT" > "$TEST_ROOT/happy-path.out"

expected_head="$(git -C "$SEED" rev-parse HEAD)"
for repo_dir in "$THIN" "$UBUNTU" "$MINI"; do
  [[ "$(git -C "$repo_dir" branch --show-current)" == master ]]
  [[ "$(git -C "$repo_dir" rev-parse HEAD)" == "$expected_head" ]]
  [[ -z "$(git -C "$repo_dir" status --porcelain)" ]]
done
grep -Fxq ubuntu-vm-ts "$SSH_LOG"
grep -Fxq ubuntu-vm "$SSH_LOG"
grep -Fq 'All dotfiles repos match.' "$TEST_ROOT/happy-path.out"

git -C "$THIN" switch -q -c agent/dirty-guard
printf 'guard\n' > "$THIN/guard.txt"
git -C "$THIN" add guard.txt
git -C "$THIN" commit -qm guard
git -C "$THIN" push -q -u origin agent/dirty-guard
printf 'active work\n' >> "$UBUNTU/tracked.txt"

printf 'next merge\n' >> "$SEED/tracked.txt"
git -C "$SEED" commit -qam next
git -C "$SEED" push -q origin master

thin_before="$(git -C "$THIN" rev-parse HEAD)"
ubuntu_before="$(git -C "$UBUNTU" rev-parse HEAD)"
mini_before="$(git -C "$MINI" rev-parse HEAD)"

if DOTFILES_SYNC_THIN_REPO="$THIN" \
  DOTFILES_SYNC_UBUNTU_REPO="$UBUNTU" \
  DOTFILES_SYNC_MINI_REPO="$MINI" \
  DOTFILES_SYNC_SSH_BIN="$FAKE_SSH" \
  DOTFILES_TEST_SSH_LOG="$SSH_LOG" \
    "$SYNC_SCRIPT" > "$TEST_ROOT/dirty-guard.out" 2>&1; then
  printf 'Expected dirty Ubuntu preflight to fail\n' >&2
  exit 1
fi

[[ "$(git -C "$THIN" branch --show-current)" == agent/dirty-guard ]]
[[ "$(git -C "$THIN" rev-parse HEAD)" == "$thin_before" ]]
[[ "$(git -C "$UBUNTU" rev-parse HEAD)" == "$ubuntu_before" ]]
[[ "$(git -C "$MINI" rev-parse HEAD)" == "$mini_before" ]]
grep -Fq 'Ubuntu repo is dirty' "$TEST_ROOT/dirty-guard.out"

git -C "$UBUNTU" restore tracked.txt
git -C "$THIN" switch -q master
git -C "$THIN" pull -q --ff-only origin master
git -C "$UBUNTU" switch -q -c agent/remote-unmerged
printf 'unmerged\n' > "$UBUNTU/unmerged.txt"
git -C "$UBUNTU" add unmerged.txt
git -C "$UBUNTU" commit -qm unmerged
git -C "$UBUNTU" push -q -u origin agent/remote-unmerged

thin_before="$(git -C "$THIN" rev-parse HEAD)"
ubuntu_before="$(git -C "$UBUNTU" rev-parse HEAD)"
mini_before="$(git -C "$MINI" rev-parse HEAD)"

if DOTFILES_SYNC_THIN_REPO="$THIN" \
  DOTFILES_SYNC_UBUNTU_REPO="$UBUNTU" \
  DOTFILES_SYNC_MINI_REPO="$MINI" \
  DOTFILES_SYNC_SSH_BIN="$FAKE_SSH" \
  DOTFILES_TEST_SSH_LOG="$SSH_LOG" \
    "$SYNC_SCRIPT" > "$TEST_ROOT/unmerged-guard.out" 2>&1; then
  printf 'Expected unmerged Ubuntu branch preflight to fail\n' >&2
  exit 1
fi

[[ "$(git -C "$THIN" branch --show-current)" == master ]]
[[ "$(git -C "$UBUNTU" branch --show-current)" == agent/remote-unmerged ]]
[[ "$(git -C "$THIN" rev-parse HEAD)" == "$thin_before" ]]
[[ "$(git -C "$UBUNTU" rev-parse HEAD)" == "$ubuntu_before" ]]
[[ "$(git -C "$MINI" rev-parse HEAD)" == "$mini_before" ]]
grep -Fq \
  'Ubuntu branch agent/remote-unmerged is not merged into origin/master' \
  "$TEST_ROOT/unmerged-guard.out"

printf 'sync-dotfiles tests passed.\n'
