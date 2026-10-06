# Portable functions shared by every shell profile.

reload() {
  emulate -L zsh

  zmodload zsh/datetime 2>/dev/null
  local start_time="$EPOCHREALTIME"
  source "$HOME/.zshrc"
  local end_time="$EPOCHREALTIME"
  local duration=$(( (end_time - start_time) * 1000 ))

  printf "Zsh configuration reloaded in %.0fms\n" "$duration"
}

# Review a PR's full diff against its actual base branch (main, dev, etc.),
# not a hardcoded one. Asks GitHub for the open PR's real base first, since
# that is the only source that is never a guess; falls back to the repo's
# default branch when there is no open PR or `gh` is unavailable/unauthed.
hpr() {
  emulate -L zsh

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "hpr: not a git repository" >&2
    return 1
  fi

  local base
  if (( $+commands[gh] )); then
    base="$(gh pr view --json baseRefName -q .baseRefName 2>/dev/null)"
  fi

  if [[ -z "$base" ]]; then
    base="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)"
    base="${base#refs/remotes/origin/}"
  fi

  if [[ -z "$base" ]]; then
    echo "hpr: could not detect a base branch (no open PR, no origin/HEAD)" >&2
    return 1
  fi

  git fetch origin "$base" --quiet
  EDITOR=nvim hunk diff "origin/$base...HEAD" "$@"
}
