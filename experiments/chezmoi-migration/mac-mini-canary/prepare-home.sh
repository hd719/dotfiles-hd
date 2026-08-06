#!/bin/bash
set -euo pipefail

[[ "$(uname -s)" == Darwin ]] || { printf 'macOS required\n' >&2; exit 1; }
state_dir="$HOME/.local/state/chezmoi-mac-mini-canary"
backup="$state_dir/pre-apply.tar"
[[ ! -e "$backup" ]] || { printf 'Backup already exists: %s\n' "$backup" >&2; exit 1; }

mkdir -p "$state_dir" \
  "$HOME/.config/btop" \
  "$HOME/.config/fastfetch/legacy" \
  "$HOME/.config/herdr" \
  "$HOME/.config/hunk" \
  "$HOME/.config/mise" \
  "$HOME/.hermes"
printf '# pre-chezmoi Mac mini canary marker\n' > "$HOME/.zshrc"
printf '[user]\n\tname = Mac Canary\n\temail = canary@invalid.example\n' > "$HOME/.gitconfig"
printf 'runtime log\n' > "$HOME/.config/btop/btop.log"
printf 'legacy state\n' > "$HOME/.config/fastfetch/legacy/sentinel"
printf 'runtime state\n' > "$HOME/.config/herdr/session"
printf '{"state":"machine-owned"}\n' > "$HOME/.config/hunk/state.json"
printf 'machine state\n' > "$HOME/.config/mise/state.toml"
printf '{"session":"machine-owned"}\n' > "$HOME/.hermes/session.json"
tar -C "$HOME" -cpf "$backup" \
  .zshrc .gitconfig .config/btop/btop.log .config/fastfetch/legacy \
  .config/herdr/session .config/hunk/state.json .config/mise/state.toml \
  .hermes/session.json
printf 'Prepared harmless pre-chezmoi state and backup: %s\n' "$backup"
