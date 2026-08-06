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
$HOME/.zshrc|$repo_dir/setup/mac-mini/.zshrc
$HOME/.config/bookokrat|$repo_dir/config/bookokrat
$HOME/.config/btop/btop.conf|$repo_dir/config/btop/btop.conf
$HOME/.config/btop/themes|$repo_dir/config/btop/themes
$HOME/.config/fastfetch/config.jsonc|$repo_dir/config/fastfetch/config.jsonc
$HOME/.config/fastfetch/logo-anon-glitch.txt|$repo_dir/config/fastfetch/logo-anon-glitch.txt
$HOME/.config/fastfetch/logo-anon.txt|$repo_dir/config/fastfetch/logo-anon.txt
$HOME/.config/git/aliases.gitconfig|$repo_dir/config/git/aliases.gitconfig
$HOME/.config/homebrew/Brewfile|$repo_dir/experiments/chezmoi-migration/mac-mini-canary/Brewfile
$HOME/Library/Application Support/com.mitchellh.ghostty/config|$repo_dir/config/ghostty/config
$HOME/.config/herdr/config.toml|$repo_dir/config/herdr/config.toml
$HOME/.config/hunk/config.toml|$repo_dir/config/hunk/config.toml
$HOME/.config/mise/config.toml|$repo_dir/config/mise/config.toml
$HOME/.config/nvim|$repo_dir/config/nvim
$HOME/.config/starship.toml|$repo_dir/config/starship/starship.toml
$HOME/.hermes/skins/hamel-nord.yaml|$repo_dir/config/hermes/skins/hamel-nord.yaml
$HOME/.terminfo/78/xterm-ghostty|/Applications/Ghostty.app/Contents/Resources/terminfo/78/xterm-ghostty
EOF

[[ "$(<"$HOME/.config/btop/btop.log")" == "runtime log" ]] \
  && pass "Btop mutable state preserved" || fail "Btop mutable state changed"
[[ "$(<"$HOME/.config/fastfetch/legacy/sentinel")" == "legacy state" ]] \
  && pass "Fastfetch legacy state preserved" || fail "Fastfetch legacy state changed"
[[ "$(<"$HOME/.config/herdr/session")" == "runtime state" ]] \
  && pass "Herdr mutable state preserved" || fail "Herdr mutable state changed"
[[ "$(<"$HOME/.config/hunk/state.json")" == '{"state":"machine-owned"}' ]] \
  && pass "Hunk mutable state preserved" || fail "Hunk mutable state changed"
[[ "$(<"$HOME/.config/mise/state.toml")" == "machine state" ]] \
  && pass "mise mutable state preserved" || fail "mise mutable state changed"
[[ "$(<"$HOME/.hermes/session.json")" == '{"session":"machine-owned"}' ]] \
  && pass "Hermes mutable state preserved" || fail "Hermes mutable state changed"
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
for command_name in \
  bash-language-server bat bookokrat btop fastfetch fd ffmpeg fzf gh \
  git-filter-repo gog gopls herdr hunk jq lazygit lsd lua-language-server \
  magick marksman mise nvim pdftotext rg starship stylua tesseract \
  tmux tree-sitter uv vscode-html-language-server vtsls websocat xcodegen \
  zoxide; do
  command -v "$command_name" >/dev/null 2>&1 \
    && pass "$command_name available" || fail "$command_name missing"
done
if TERM=xterm-ghostty zsh -lic \
  'alias ll >/dev/null; [[ "$DOTFILES_MAC_PROFILE" == mac-mini ]]; [[ -n "$STARSHIP_CONFIG" ]]'; then
  pass "fresh Mac mini profile shell"
else
  fail "fresh Mac mini profile shell"
fi
if /Applications/Ghostty.app/Contents/MacOS/ghostty \
  +validate-config >/dev/null 2>&1; then
  pass "Ghostty config"
else
  fail "Ghostty config"
fi
if DOTFILES_NVIM_PROFILE=full nvim --headless \
  "+lua assert(vim.fn.maparg(' e','n',false,true).desc=='File explorer'); assert(require('snacks').config.dashboard.enabled==true); assert(vim.treesitter.language.add('markdown')); assert(vim.treesitter.language.add('markdown_inline'))" \
  '+qa!' >/dev/null 2>&1; then
  pass "full-profile Neovim and Markdown parsers"
else
  fail "full-profile Neovim or Markdown parsers"
fi

managed="$("$bin" --source "$source_dir" managed --path-style absolute)"
printf '%s\n' "$managed" | grep -Eq \
  '/\.ssh/|/Library/Preferences/|/Library/LaunchAgents/|/\.config/btop/btop\.log$|/\.config/fastfetch/legacy/|/\.config/mise/state\.toml$|/\.hermes/session\.json$' \
  && fail "excluded path is managed" \
  || pass "secrets, preferences, services, and mutable state excluded"

((failures == 0)) || exit 1
printf 'PASS  disposable Mac mini chezmoi delta canary\n'
