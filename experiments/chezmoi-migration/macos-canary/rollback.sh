#!/bin/bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
source_dir="$script_dir/source"
bin="$HOME/.local/bin/chezmoi"
backup="$HOME/.local/state/chezmoi-macos-canary/pre-apply.tar"
[[ -f "$backup" ]] || { printf 'Missing rollback archive: %s\n' "$backup" >&2; exit 1; }

while IFS= read -r target; do
  [[ "$target" == "$HOME/"* ]] || { printf 'Refusing target: %s\n' "$target" >&2; exit 1; }
  rm -f -- "$target"
done < <("$bin" --source "$source_dir" managed \
  --include files,symlinks --path-style absolute)

while IFS= read -r target; do
  [[ "$target" == "$HOME/"* ]] && rmdir -- "$target" 2>/dev/null || true
done < <("$bin" --source "$source_dir" managed \
  --include dirs --path-style absolute | LC_ALL=C sort -r)

"$bin" --source "$source_dir" --force state reset
tar -C "$HOME" -xpf "$backup"
grep -Fxq '# pre-chezmoi macOS canary marker' "$HOME/.zshrc"
grep -Fxq 'runtime state' "$HOME/.config/herdr/session"
grep -Fxq '{"state":"machine-owned"}' "$HOME/.config/hunk/state.json"
! grep -Fq "$HOME/.config/git/aliases.gitconfig" "$HOME/.gitconfig"
printf 'Rollback restored the pre-chezmoi macOS canary state.\n'
