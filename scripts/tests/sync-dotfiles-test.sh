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

git -C "$THIN" switch -q -c agent/test
printf 'feature\n' > "$THIN/feature.txt"
git -C "$THIN" add feature.txt
git -C "$THIN" commit -qm feature
git -C "$THIN" push -q -u origin agent/test

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

printf 'sync-dotfiles tests passed.\n'
