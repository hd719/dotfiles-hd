#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
CASE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/work-links-test.XXXXXX")"
trap 'rm -rf "$CASE_DIR"' EXIT
export HOME="$CASE_DIR/home" DOTFILES_DIR="$REPO_DIR"
mkdir -p "$HOME/.config/yazi/plugins"
printf 'original theme\n' > "$HOME/.config/yazi/theme.toml"
printf 'mutable plugin\n' > "$HOME/.config/yazi/plugins/local.lua"

bash "$REPO_DIR/hosts/mac-work/link-terminal-editor-config.sh" >/dev/null
while IFS='|' read -r destination source; do
  [[ -L "$HOME/$destination" && -e "$HOME/$destination" ]]
  [[ "$(readlink "$HOME/$destination")" == "$REPO_DIR/$source" ]]
done <<'EOF'
.config/bookokrat|config/bookokrat
Library/Application Support/com.mitchellh.ghostty/config|config/ghostty/config
.config/herdr/config.toml|config/herdr/config.toml
.config/hunk/config.toml|config/hunk/config.toml
.config/nvim|config/nvim
.config/yazi/theme.toml|config/yazi/theme.toml
.config/yazi/yazi.toml|config/yazi/yazi.toml
EOF
grep -Fxq 'mutable plugin' "$HOME/.config/yazi/plugins/local.lua"
backup="$(find "$HOME/.config/yazi" -name 'theme.toml.backup-*' -print)"
[[ -n "$backup" ]]
grep -Fxq 'original theme' "$backup"
bash "$REPO_DIR/hosts/mac-work/link-terminal-editor-config.sh" >/dev/null
[[ "$(find "$HOME" -name '*.backup-*' -print | wc -l | tr -d ' ')" == 1 ]]

# Reject a linked parent before changing any managed destination.
export HOME="$CASE_DIR/linked-parent-home"
mkdir -p "$HOME/.config" "$CASE_DIR/external"
printf 'keep original\n' > "$CASE_DIR/external/theme.toml"
ln -s "$CASE_DIR/external" "$HOME/.config/yazi"
if bash "$REPO_DIR/hosts/mac-work/link-terminal-editor-config.sh" > "$CASE_DIR/error.log" 2>&1; then
  printf 'Linked Yazi parent should be rejected.\n' >&2
  exit 1
fi
grep -Fq 'Yazi config parent must be a real directory' "$CASE_DIR/error.log"
grep -Fxq 'keep original' "$CASE_DIR/external/theme.toml"
[[ ! -e "$HOME/.config/bookokrat" ]]
printf 'Work Mac terminal/editor link tests passed.\n'
