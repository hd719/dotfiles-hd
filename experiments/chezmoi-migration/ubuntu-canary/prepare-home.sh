#!/usr/bin/env bash
set -euo pipefail

[[ "$HOME" == "/home/hamel" ]] || {
  printf 'Refusing unexpected home: %s\n' "$HOME" >&2
  exit 1
}

state_dir="$HOME/.local/state/chezmoi-canary"
backup="$state_dir/pre-apply.tar"
mkdir -p "$state_dir"

if [[ ! -f "$backup" ]]; then
  printf '# pre-chezmoi canary marker\n' >"$HOME/.zshrc"
  git config --global user.name "Chezmoi Canary"
  git config --global user.email "canary@invalid.example"
  tar -C "$HOME" -cpf "$backup" .zshrc .gitconfig
fi

printf 'Prepared canary home; backup: %s\n' "$backup"
