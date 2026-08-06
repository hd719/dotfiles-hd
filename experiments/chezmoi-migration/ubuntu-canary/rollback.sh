#!/usr/bin/env bash
set -euo pipefail

[[ "$HOME" == "/home/hamel" ]] || {
  printf 'Refusing unexpected home: %s\n' "$HOME" >&2
  exit 1
}

source_dir="${CHEZMOI_SOURCE_DIR:-/tmp/chezmoi-source}"
backup="$HOME/.local/state/chezmoi-canary/pre-apply.tar"
[[ -f "$backup" ]] || {
  printf 'Missing rollback archive: %s\n' "$backup" >&2
  exit 1
}

mapfile -t managed_targets < <(
  "$HOME/.local/bin/chezmoi" --source "$source_dir" \
    managed --include files,symlinks --path-style absolute
)
((${#managed_targets[@]} > 0))

for target in "${managed_targets[@]}"; do
  [[ "$target" == "$HOME/"* ]] || {
    printf 'Refusing managed target outside home: %s\n' "$target" >&2
    exit 1
  }
done

# Do not use `chezmoi destroy`: it also deletes the source-state files.
rm -f -- "${managed_targets[@]}"

mapfile -t managed_dirs < <(
  "$HOME/.local/bin/chezmoi" --source "$source_dir" \
    managed --include dirs --path-style absolute | LC_ALL=C sort -r
)
for target in "${managed_dirs[@]}"; do
  [[ "$target" == "$HOME/"* ]] || continue
  rmdir -- "$target" 2>/dev/null || true
done

# Let the next apply rebuild target and script state from the preserved source.
"$HOME/.local/bin/chezmoi" --source "$source_dir" --force \
  state reset

tar -C "$HOME" -xpf "$backup"

grep -Fxq '# pre-chezmoi canary marker' "$HOME/.zshrc"
[[ "$(git config --global user.name)" == "Chezmoi Canary" ]]
[[ "$(git config --global user.email)" == "canary@invalid.example" ]]
! git config --global --get-all include.path 2>/dev/null \
  | grep -Fxq "$HOME/.config/git/aliases.gitconfig"

printf 'Rollback restored the pre-chezmoi canary state.\n'
