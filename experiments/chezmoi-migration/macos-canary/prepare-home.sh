#!/bin/bash
set -euo pipefail

[[ "$(uname -s)" == Darwin ]] || { printf 'macOS required\n' >&2; exit 1; }
state_dir="$HOME/.local/state/chezmoi-macos-canary"
backup="$state_dir/pre-apply.tar"
[[ ! -e "$backup" ]] || { printf 'Backup already exists: %s\n' "$backup" >&2; exit 1; }

mkdir -p "$state_dir" "$HOME/.config/herdr" "$HOME/.config/hunk"
printf '# pre-chezmoi macOS canary marker\n' > "$HOME/.zshrc"
printf '[user]\n\tname = Mac Canary\n\temail = canary@invalid.example\n' > "$HOME/.gitconfig"
printf 'runtime state\n' > "$HOME/.config/herdr/session"
printf '{"state":"machine-owned"}\n' > "$HOME/.config/hunk/state.json"
tar -C "$HOME" -cpf "$backup" \
  .zshrc .gitconfig .config/herdr/session .config/hunk/state.json
printf 'Prepared harmless pre-chezmoi state and backup: %s\n' "$backup"
