#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DIR="$(cd "$TEST_DIR/../../.." && pwd -P)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-air-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT
FAKE_BIN="$TEST_ROOT/bin"
TEST_HOME="$TEST_ROOT/home"
LOG="$TEST_ROOT/commands.log"
mkdir -p "$FAKE_BIN" "$TEST_HOME"
: > "$LOG"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

cat > "$FAKE_BIN/uname" <<'FAKE'
#!/bin/sh
printf 'Darwin\n'
FAKE
cat > "$FAKE_BIN/brew" <<'FAKE'
#!/bin/sh
printf 'brew %s\n' "$*" >> "$COMMAND_LOG"
exit "${BREW_STATUS:-0}"
FAKE
cat > "$FAKE_BIN/chezmoi-bootstrap" <<'FAKE'
#!/bin/sh
printf 'chezmoi %s\n' "$*" >> "$COMMAND_LOG"
if [ "${FAIL_PREVIEW:-0}" = 1 ] && [ "$2" = --preview ]; then exit 1; fi
FAKE
cat > "$FAKE_BIN/chezmoi-doctor" <<'FAKE'
#!/bin/sh
printf 'chezmoi-doctor %s\n' "$*" >> "$COMMAND_LOG"
FAKE
for tool in vagrant mise docker colima ssh launchctl softwareupdate uv npm pnpm; do
  cat > "$FAKE_BIN/$tool" <<'FAKE'
#!/bin/sh
printf 'FORBIDDEN %s %s\n' "${0##*/}" "$*" >> "$COMMAND_LOG"
exit 99
FAKE
done
chmod +x "$FAKE_BIN"/*

bootstrap() {
  HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" COMMAND_LOG="$LOG" \
    DOTFILES_CHEZMOI_BOOTSTRAP="$FAKE_BIN/chezmoi-bootstrap" \
    DOTFILES_AIR_DOCTOR=/usr/bin/true CHEZMOI_BIN="$TEST_ROOT/missing-chezmoi" \
    bash "$REPO_DIR/hosts/mac-air/bootstrap.sh" "$@"
}
bootstrap --dry-run >/dev/null
[[ ! -s "$LOG" ]] || fail 'dry-run mutated or called package tools'
if bootstrap --apply >/dev/null 2>&1; then fail 'arrival gate was bypassed'; fi
[[ ! -s "$LOG" ]] || fail 'arrival gate allowed mutations'
if DOTFILES_MAC_AIR_ARRIVED=1 FAIL_PREVIEW=1 bootstrap --apply >/dev/null 2>&1; then
  fail 'failed preview did not block apply'
fi
! grep -q '^brew ' "$LOG" || fail 'packages installed before reviewed preview'
: > "$LOG"
DOTFILES_MAC_AIR_ARRIVED=1 bootstrap --apply >/dev/null
grep -Fq "brew bundle install --no-upgrade --file $REPO_DIR/hosts/mac-air/Brewfile" \
  "$LOG" || fail 'client Brewfile was not installed'
grep -Fq 'chezmoi mac-air --apply' "$LOG" || fail 'Air profile was not applied'
[[ "$(head -n 1 "$LOG")" == 'chezmoi mac-air --preview' ]] || fail 'preview order'

for app in ChatGPT Ghostty Obsidian Tailscale; do mkdir -p "$TEST_ROOT/apps/$app.app"; done
doctor() {
  HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" COMMAND_LOG="$LOG" \
    DOTFILES_CHEZMOI_DOCTOR="$FAKE_BIN/chezmoi-doctor" \
    DOTFILES_APPLICATIONS_DIR="$TEST_ROOT/apps" \
    bash "$REPO_DIR/hosts/mac-air/doctor.sh"
}
doctor >/dev/null
if BREW_STATUS=1 doctor >/dev/null 2>&1; then fail 'missing packages passed doctor'; fi
rmdir "$TEST_ROOT/apps/ChatGPT.app"
if doctor >/dev/null 2>&1; then fail 'missing client passed doctor'; fi
ln -s "$REPO_DIR/hosts/mac-air/.zshrc" "$TEST_HOME/.zshrc"
HOME="$TEST_HOME" HOMEBREW_PREFIX="$TEST_ROOT" PATH="$FAKE_BIN:/usr/bin:/bin" \
  TERM=xterm-256color COMMAND_LOG="$LOG" /bin/zsh -lic \
    '[[ "$DOTFILES_MAC_PROFILE" == mac-air ]] && (( ! $+functions[uvm-up] ))'
! grep -Fq FORBIDDEN "$LOG" || fail 'Air invoked a development or VM tool'
! grep -Eq '^(brew|cask) "(vagrant|vagrant-vmware-utility|vmware-fusion|docker|colima|mise|neovim|postgresql)' \
  "$REPO_DIR/hosts/mac-air/Brewfile" || fail 'Air installs a local development environment'
printf 'MacBook Air client profile tests passed.\n'
