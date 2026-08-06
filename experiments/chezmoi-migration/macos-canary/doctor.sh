#!/bin/bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
source_dir="$script_dir/source"
repo_dir="$(CDPATH= cd -- "$source_dir/../../../.." && pwd -P)"
bin="$HOME/.local/bin/chezmoi"
failures=0

pass() { printf 'PASS  %s\n' "$*"; }
fail() { printf 'FAIL  %s\n' "$*" >&2; failures=$((failures + 1)); }

[[ "$(uname -s)" == Darwin && "$(uname -m)" == arm64 ]] \
  && pass "Apple Silicon macOS" || fail "Apple Silicon macOS required"
[[ -z "$("$bin" --source "$source_dir" status)" ]] \
  && pass "chezmoi target state is clean" || fail "chezmoi reports drift"

while IFS='|' read -r target expected; do
  [[ -L "$target" && "$(readlink "$target")" == "$expected" ]] \
    && pass "$target -> $expected" || fail "link mismatch: $target"
done <<EOF
$HOME/.zshrc|$repo_dir/setup/mac-thin/.zshrc
$HOME/.config/bookokrat|$repo_dir/config/bookokrat
$HOME/.config/git/aliases.gitconfig|$repo_dir/config/git/aliases.gitconfig
$HOME/.config/homebrew/Brewfile|$repo_dir/experiments/chezmoi-migration/macos-canary/Brewfile
$HOME/Library/Application Support/com.mitchellh.ghostty/config|$repo_dir/config/ghostty/config
$HOME/.config/herdr/config.toml|$repo_dir/config/herdr/config.toml
$HOME/.config/hunk/config.toml|$repo_dir/config/hunk/config.toml
$HOME/.config/nvim|$repo_dir/config/nvim
$HOME/.config/starship.toml|$repo_dir/config/starship/starship.toml
$HOME/.terminfo/78/xterm-ghostty|/Applications/Ghostty.app/Contents/Resources/terminfo/78/xterm-ghostty
EOF

[[ "$(<"$HOME/.config/herdr/session")" == "runtime state" ]] \
  && pass "Herdr mutable state preserved" || fail "Herdr mutable state changed"
[[ "$(<"$HOME/.config/hunk/state.json")" == '{"state":"machine-owned"}' ]] \
  && pass "Hunk mutable state preserved" || fail "Hunk mutable state changed"
git config --global --includes --get alias.st 2>/dev/null | grep -Fxq status \
  && pass "portable Git aliases" || fail "portable Git aliases"
[[ "$(git config --global user.name)" == "Mac Canary" ]] \
  && [[ "$(git config --global user.email)" == "canary@invalid.example" ]] \
  && pass "machine-owned Git identity preserved" || fail "Git identity changed"
zsh -n "$HOME/.zshrc" && pass "Zsh syntax" || fail "Zsh syntax"
TERM=xterm-ghostty clear >/dev/null 2>&1 \
  && pass "Ghostty terminfo" || fail "Ghostty terminfo"

if HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --no-upgrade \
  --file "$HOME/.config/homebrew/Brewfile" >/dev/null; then
  pass "canary Brewfile satisfied"
else
  fail "canary Brewfile has missing dependencies"
fi
for command_name in bookokrat gh herdr hunk lsd marksman nvim rg starship tree-sitter zoxide; do
  command -v "$command_name" >/dev/null 2>&1 \
    && pass "$command_name available" || fail "$command_name missing"
done
if TERM=xterm-ghostty zsh -lic \
  'alias ll >/dev/null; [[ "$DOTFILES_NVIM_PROFILE" == thin ]]; [[ "$EDITOR" == nvim ]]'; then
  pass "fresh thin-profile shell"
else
  fail "fresh thin-profile shell"
fi
if /Applications/Ghostty.app/Contents/MacOS/ghostty \
  +validate-config >/dev/null 2>&1; then
  pass "Ghostty config"
else
  fail "Ghostty config"
fi
if DOTFILES_NVIM_PROFILE=thin nvim --headless \
  "+lua assert(vim.fn.maparg(' e','n',false,true).desc=='File explorer'); assert(require('snacks').config.dashboard.enabled==true); assert(vim.treesitter.language.add('markdown')); assert(vim.treesitter.language.add('markdown_inline'))" \
  '+qa!' >/dev/null 2>&1; then
  pass "thin-profile Neovim and Markdown parsers"
else
  fail "thin-profile Neovim or Markdown parsers"
fi

managed="$("$bin" --source "$source_dir" managed --path-style absolute)"
printf '%s\n' "$managed" | grep -Eq '/\.ssh/|/Library/Preferences/|/Library/LaunchAgents/' \
  && fail "excluded path is managed" || pass "secrets, preferences, and services excluded"

((failures == 0)) || exit 1
printf 'PASS  disposable thin-Mac chezmoi canary\n'
