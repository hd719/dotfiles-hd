#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
DOTFILES_DIR="${DOTFILES_DIR:-$REPO_DIR}"
CHEZMOI_DOCTOR="${DOTFILES_CHEZMOI_DOCTOR:-$DOTFILES_DIR/chezmoi/doctor.sh}"
APPLICATIONS_DIR="${DOTFILES_APPLICATIONS_DIR:-/Applications}"
# Reuse read-only Neovim checks with the same Markdown-only parser set as thin.
source "$DOTFILES_DIR/hosts/shared/macos/lib.sh"
NEOVIM_PARSERS=(markdown markdown_inline)
NEOVIM_PARSER_BINARIES=(markdown markdown_inline)
FAILURES=0
pass() { printf 'PASS  %s\n' "$*"; }
fail() { printf 'FAIL  %s\n' "$*" >&2; FAILURES=$((FAILURES + 1)); }

[[ "$(uname -s)" == Darwin ]] && pass macOS || fail 'macOS required'
if HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --no-upgrade \
  --file "$DOTFILES_DIR/hosts/mac-air/Brewfile"; then
  pass 'thin-Mac client and note packages'
else
  fail 'thin-Mac client and note packages missing'
fi
if "$CHEZMOI_DOCTOR" mac-air; then
  pass 'Air client configuration'
else
  fail 'Air client configuration'
fi
for tool in bookokrat fastfetch herdr hunk lsd marksman nvim rg tree-sitter; do
  command -v "$tool" >/dev/null 2>&1 && pass "$tool available" || fail "$tool missing"
done
if nvim --headless -u NONE -i NONE --noplugin \
  "+lua if vim.fn.has('nvim-0.12') ~= 1 then vim.cmd('cquit 1') end" \
  '+qa!' >/dev/null 2>&1; then
  pass 'Neovim 0.12+'
else
  fail 'Neovim 0.12+ required'
fi
if verify_neovim_parsers_restored; then
  pass 'Markdown parsers restored'
else
  fail 'Markdown parsers missing or unloadable'
fi
if verify_neovim_config_sandboxed "$DOTFILES_DIR/config/nvim" thin; then
  pass 'Thin Neovim starts in isolated data'
else
  fail 'Thin Neovim isolated startup'
fi
for app in ChatGPT Ghostty Obsidian Tailscale; do
  [[ -d "$APPLICATIONS_DIR/$app.app" ]] \
    && pass "$app installed" || fail "$app missing"
done
printf 'MANUAL  Verify Studio SSH, Screen Sharing and remote execution over Tailscale.\n'
((FAILURES == 0))
