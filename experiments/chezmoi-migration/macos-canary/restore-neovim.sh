#!/bin/bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
repo_dir="$(CDPATH= cd -- "$script_dir/../../.." && pwd -P)"
lockfile="$repo_dir/config/nvim/lazy-lock.json"
backup="$(mktemp "${TMPDIR:-/tmp}/chezmoi-thin-lazy-lock.XXXXXX")"
cp -p "$lockfile" "$backup"

restore_lockfile() {
  if ! cmp -s "$lockfile" "$backup"; then
    cp -p "$backup" "$lockfile"
  fi
  rm -f "$backup"
}
trap restore_lockfile EXIT

DOTFILES_NVIM_PROFILE=thin DOTFILES_NVIM_RESTORE_ALL=1 \
  nvim --headless '+Lazy! restore' '+qa'
DOTFILES_NVIM_PROFILE=thin nvim --headless \
  "+lua local ok=require('nvim-treesitter').install({'markdown','markdown_inline'}):wait(); if not ok then vim.cmd('cquit 1') end" \
  '+qa'

restore_lockfile
trap - EXIT
printf 'Thin-profile Neovim restored without changing lazy-lock.json.\n'
