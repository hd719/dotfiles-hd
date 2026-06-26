#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Developer/dotfiles-hd}"
ZED_SRC_DIR="$DOTFILES_DIR/config/zed"
ZED_DEST_DIR="$HOME/.config/zed"
CODEX_SKILLS_DIR="${CODEX_SKILLS_DIR:-$HOME/.codex/skills}"
AGENTS_SKILLS_DIR="${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}"

backup_path() {
  local path="$1"
  local backup="$path.bak.$(date +%Y%m%d%H%M%S)"

  echo "Backing up $path -> $backup"
  mv "$path" "$backup"
}

link_path() {
  local src="$1"
  local dest="$2"

  if [[ ! -e "$src" ]]; then
    echo "Skipping missing source: $src"
    return 0
  fi

  mkdir -p "$(dirname "$dest")"

  if [[ -L "$dest" ]]; then
    local current
    current="$(readlink "$dest")"
    if [[ "$current" == "$src" ]]; then
      echo "Already linked: $dest -> $src"
      return 0
    fi

    echo "Replacing symlink: $dest"
    rm "$dest"
  elif [[ -e "$dest" ]]; then
    backup_path "$dest"
  fi

  ln -s "$src" "$dest"
  echo "Linked: $dest -> $src"
}

link_skill() {
  local src="$1"
  local name
  local dest

  name="$(basename "$src")"
  dest="$AGENTS_SKILLS_DIR/$name"

  if [[ ! -f "$src/SKILL.md" ]]; then
    return 0
  fi

  if [[ -L "$dest" ]]; then
    local current
    current="$(readlink "$dest")"
    if [[ "$current" == "$src" ]]; then
      echo "Already linked skill: $name"
      return 0
    fi

    rm "$dest"
  elif [[ -e "$dest" ]]; then
    echo "Skipping skill conflict, not a symlink: $dest"
    return 0
  fi

  ln -s "$src" "$dest"
  echo "Linked skill: $name"
}

link_zed_config() {
  if [[ ! -d "$ZED_SRC_DIR" ]]; then
    echo "Missing Zed dotfiles config directory: $ZED_SRC_DIR" >&2
    exit 1
  fi

  mkdir -p "$ZED_DEST_DIR"

  link_path "$ZED_SRC_DIR/settings.json" "$ZED_DEST_DIR/settings.json"
  link_path "$ZED_SRC_DIR/keymap.json" "$ZED_DEST_DIR/keymap.json"
  link_path "$ZED_SRC_DIR/themes" "$ZED_DEST_DIR/themes"

  echo "Leaving $ZED_DEST_DIR/prompts local; it is Zed runtime state, not portable config."
}

link_agent_skills() {
  if [[ ! -d "$CODEX_SKILLS_DIR" ]]; then
    echo "Skipping agent skills; Codex skills directory not found: $CODEX_SKILLS_DIR"
    return 0
  fi

  if [[ -L "$AGENTS_SKILLS_DIR" ]]; then
    rm "$AGENTS_SKILLS_DIR"
  elif [[ -e "$AGENTS_SKILLS_DIR" && ! -d "$AGENTS_SKILLS_DIR" ]]; then
    backup_path "$AGENTS_SKILLS_DIR"
  fi

  mkdir -p "$AGENTS_SKILLS_DIR"

  while IFS= read -r skill_dir; do
    link_skill "$skill_dir"
  done < <(find "$CODEX_SKILLS_DIR" -mindepth 1 -maxdepth 1 \( -type d -o -type l \) | sort)

  if [[ -d "$CODEX_SKILLS_DIR/.system" ]]; then
    while IFS= read -r skill_dir; do
      link_skill "$skill_dir"
    done < <(find "$CODEX_SKILLS_DIR/.system" -mindepth 1 -maxdepth 1 \( -type d -o -type l \) | sort)
  fi
}

main() {
  link_zed_config
  link_agent_skills
  echo "Zed dotfiles bootstrap complete."
}

main "$@"
