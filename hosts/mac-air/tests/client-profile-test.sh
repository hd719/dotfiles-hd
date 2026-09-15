#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DIR="$(cd "$TEST_DIR/../../.." && pwd -P)"
REAL_CHEZMOI_BIN="${CHEZMOI_BIN:-$HOME/.local/bin/chezmoi}"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-air-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT
FAKE_BIN="$TEST_ROOT/bin"
TEST_HOME="$TEST_ROOT/home"
LOG="$TEST_ROOT/commands.log"
mkdir -p "$FAKE_BIN" "$TEST_HOME/.local/share/nvim/lazy" "$TEST_HOME/.local/share/nvim/site"
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
for tool in bookokrat fastfetch hunk lsd marksman rg tree-sitter; do
  printf '#!/bin/sh\nexit 0\n' > "$FAKE_BIN/$tool"
done
cat > "$FAKE_BIN/nvim" <<'FAKE'
#!/bin/sh
printf 'nvim profile=%s %s\n' "${DOTFILES_NVIM_PROFILE:-}" "$*" >> "$COMMAND_LOG"
if [ "${MUTATE_LOCK:-0}" = 1 ]; then
  printf 'modified by restore\n' > "$HOME/.config/nvim/lazy-lock.json"
fi
exit "${NVIM_STATUS:-0}"
FAKE
for tool in vagrant mise docker colima ssh launchctl softwareupdate uv npm pnpm herdr; do
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
grep -Fq 'chezmoi mac-air --apply' "$LOG" || fail 'Air profile was not applied'
[[ "$(head -n 1 "$LOG")" == 'chezmoi mac-air --preview' ]] || fail 'preview order'

# Exercise the actual shared package/editor template against disposable state.
[[ -x "$REAL_CHEZMOI_BIN" ]] || fail 'Chezmoi binary required'
mkdir -p "$TEST_HOME/.config/homebrew" "$TEST_HOME/.config/nvim"
ln -s "$REPO_DIR/hosts/mac-air/Brewfile" "$TEST_HOME/.config/homebrew/Brewfile"
cp "$REPO_DIR/config/nvim/lazy-lock.json" "$TEST_HOME/.config/nvim/lazy-lock.json"
"$REAL_CHEZMOI_BIN" --source "$REPO_DIR/chezmoi/source" \
  --config "$REPO_DIR/chezmoi/profiles/mac-air.toml" --destination "$TEST_HOME" \
  --persistent-state "$TEST_ROOT/chezmoi.boltdb" execute-template \
  < "$REPO_DIR/chezmoi/source/run_onchange_after_30-install-thin-tools.sh.tmpl" \
  > "$TEST_ROOT/install-tools.sh"
bash -n "$TEST_ROOT/install-tools.sh"
install_tools() {
  HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" COMMAND_LOG="$LOG" MUTATE_LOCK=1 \
    bash "$TEST_ROOT/install-tools.sh"
}
install_tools
grep -Fq "brew bundle install --no-upgrade --file $TEST_HOME/.config/homebrew/Brewfile" \
  "$LOG" || fail 'Air Brewfile was not installed'
grep -Fq 'nvim profile=thin --headless +Lazy! restore +qa' "$LOG" \
  || fail 'thin editor was not restored'
grep -Fq "install({'markdown','markdown_inline'})" "$LOG" \
  || fail 'Markdown parsers were not restored'
cmp -s "$REPO_DIR/config/nvim/lazy-lock.json" "$TEST_HOME/.config/nvim/lazy-lock.json" \
  || fail 'plugin restore changed the lockfile'
if NVIM_STATUS=1 install_tools; then fail 'editor failure passed installation'; fi
cmp -s "$REPO_DIR/config/nvim/lazy-lock.json" "$TEST_HOME/.config/nvim/lazy-lock.json" \
  || fail 'failed restore changed the lockfile'

for app in ChatGPT Ghostty Obsidian Tailscale; do mkdir -p "$TEST_ROOT/apps/$app.app"; done
doctor() {
  HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" COMMAND_LOG="$LOG" \
    DOTFILES_CHEZMOI_DOCTOR="$FAKE_BIN/chezmoi-doctor" \
    DOTFILES_APPLICATIONS_DIR="$TEST_ROOT/apps" \
    bash "$REPO_DIR/hosts/mac-air/doctor.sh"
}
doctor >/dev/null
if NVIM_STATUS=1 doctor >/dev/null 2>&1; then fail 'broken editor passed doctor'; fi
if BREW_STATUS=1 doctor >/dev/null 2>&1; then fail 'missing packages passed doctor'; fi
rmdir "$TEST_ROOT/apps/ChatGPT.app"
if doctor >/dev/null 2>&1; then fail 'missing client passed doctor'; fi
ln -s "$REPO_DIR/hosts/mac-air/.zshrc" "$TEST_HOME/.zshrc"
HOME="$TEST_HOME" HOMEBREW_PREFIX="$TEST_ROOT" PATH="$FAKE_BIN:/usr/bin:/bin" \
  TERM=xterm-256color COMMAND_LOG="$LOG" /bin/zsh -lic \
    '[[ "$DOTFILES_MAC_PROFILE" == mac-air && "$DOTFILES_NVIM_PROFILE" == thin ]] &&
     [[ "$EDITOR" == nvim && "$VISUAL" == nvim && "$GIT_EDITOR" == nvim ]] &&
     [[ "$aliases[hdiff]" == "hunk diff" && "$aliases[v]" == nvim ]] &&
     (( ! $+functions[uvm-up] && ! $+aliases[hu] && ! $+aliases[u] ))'
! grep -Fq FORBIDDEN "$LOG" || fail 'Air invoked a development or VM tool'
! grep -Eq '^(brew|cask) "(vagrant|vagrant-vmware-utility|vmware-fusion|docker|colima|mise|postgresql)' \
  "$REPO_DIR/hosts/mac-air/Brewfile" || fail 'Air installs a local development environment'

# Run the actual bootstrap/Chezmoi path from an empty home, not just its
# rendered installer. Package managers and editor execution remain stubbed.
fresh_home="$TEST_ROOT/fresh-home"
fresh_log="$TEST_ROOT/fresh.log"
mkdir -p "$fresh_home"
: > "$fresh_log"
fresh_bootstrap() {
  HOME="$fresh_home" PATH="$FAKE_BIN:$PATH" COMMAND_LOG="$fresh_log" \
    DOTFILES_CHEZMOI_TEST=1 DOTFILES_MAC_AIR_ARRIVED=1 \
    CHEZMOI_BIN="$REAL_CHEZMOI_BIN" DOTFILES_AIR_DOCTOR=/usr/bin/true \
    bash "$REPO_DIR/hosts/mac-air/bootstrap.sh" --apply \
      > "$TEST_ROOT/fresh-apply.log"
}
fresh_bootstrap
[[ "$(readlink "$fresh_home/.config/nvim")" == "$REPO_DIR/config/nvim" ]] \
  || fail 'fresh Air did not receive the note editor configuration'
[[ "$(readlink "$fresh_home/.config/homebrew/Brewfile")" == "$REPO_DIR/hosts/mac-air/Brewfile" ]] \
  || fail 'fresh Air selected the wrong packages'
[[ -d "$fresh_home/.config/fastfetch" && ! -L "$fresh_home/.config/fastfetch" ]] \
  || fail 'fresh Air did not prepare its managed parent directory'
grep -Fq 'rollback command:' "$TEST_ROOT/fresh-apply.log" || fail 'fresh Air has no rollback'
[[ "$(grep -c '^brew bundle install ' "$fresh_log")" == 1 ]] \
  || fail 'fresh Air package installation did not run exactly once'
fresh_bootstrap
[[ "$(grep -c '^brew bundle install ' "$fresh_log")" == 1 ]] \
  || fail 'unchanged Air apply repeated package installation'
! grep -Fq FORBIDDEN "$fresh_log" || fail 'fresh Air invoked a VM or development tool'
printf 'MacBook Air client profile tests passed.\n'
