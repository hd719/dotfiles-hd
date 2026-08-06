#!/usr/bin/env bash
set -euo pipefail

[[ "$HOME" == "/home/hamel" ]] || {
  printf 'FAIL unexpected home: %s\n' "$HOME" >&2
  exit 1
}

source_dir="${CHEZMOI_SOURCE_DIR:-/tmp/chezmoi-source}"
chezmoi_bin="$HOME/.local/bin/chezmoi"
failures=0

pass() { printf 'PASS  %s\n' "$*"; }
fail() { printf 'FAIL  %s\n' "$*" >&2; failures=$((failures + 1)); }

if [[ -z "$($chezmoi_bin --source "$source_dir" status)" ]]; then
  pass "chezmoi target state is clean"
else
  fail "chezmoi reports drift"
fi

while IFS= read -r target; do
  [[ -e "$target" ]] || { fail "missing managed target: $target"; continue; }
  [[ ! -L "$target" ]] || fail "managed target is a symlink: $target"
done < <(
  $chezmoi_bin --source "$source_dir" \
    managed --include files,symlinks --path-style absolute
)

if zsh -n "$HOME/.zshrc"; then
  pass "Zsh syntax"
else
  fail "Zsh syntax"
fi

if git config --global --includes --get alias.st | grep -Fxq status; then
  pass "portable Git aliases"
else
  fail "portable Git aliases"
fi

if [[ "$(git config --global user.name)" == "Chezmoi Canary" ]] \
  && [[ "$(git config --global user.email)" == "canary@invalid.example" ]]; then
  pass "machine-owned Git identity preserved"
else
  fail "machine-owned Git identity changed"
fi

for command_name in mise nvim rg fd fzf starship zoxide fastfetch bookokrat hunk codex; do
  [[ "$command_name" == "mise" ]] \
    && command_path="$HOME/.local/bin/mise" \
    || command_path="$(MISE_NOT_FOUND_AUTO_INSTALL=0 "$HOME/.local/bin/mise" which "$command_name" 2>/dev/null || true)"
  [[ -x "$command_path" ]] \
    && pass "tool available: $command_name" \
    || fail "tool missing: $command_name"
done

if command -v lsd >/dev/null; then
  pass "system tool available: lsd"
else
  fail "system tool missing: lsd"
fi

if TERM=xterm-ghostty clear >/dev/null 2>&1; then
  pass "Ghostty terminfo available"
else
  fail "Ghostty terminfo missing"
fi

if TERM=xterm-256color zsh -lic 'alias ll >/dev/null' >/dev/null 2>&1; then
  pass "LSD shell aliases available"
else
  fail "LSD shell aliases missing"
fi

if [[ -x "$HOME/.config/herdr/reset-server.sh" ]]; then
  pass "Herdr reset command preserved"
else
  fail "Herdr reset command missing"
fi

[[ ! -e "$HOME/.config/btop/btop.log" ]] || fail "btop.log was rendered"
[[ ! -e "$HOME/.config/fastfetch/legacy" ]] || fail "Fastfetch legacy files were rendered"
[[ ! -e "$HOME/.ssh/known_hosts" ]] || fail "known_hosts was created"
if find "$HOME/.ssh" -maxdepth 1 -type f ! -name config -print -quit | grep -q .; then
  fail "an SSH identity or state file was created"
else
  pass "no SSH identity or state managed"
fi

((failures == 0)) || exit 1
printf 'PASS  disposable Ubuntu chezmoi canary\n'
