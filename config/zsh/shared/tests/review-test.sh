#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd -P)"

/bin/zsh -df -s "$REPO_DIR" <<'ZSH'
set -eu
source "$1/config/zsh/shared/functions.zsh"
source "$1/config/zsh/shared/aliases.zsh"

review_test_pr_base=dev
review_test_default_base=main
review_test_git_status=0
review_test_fetch_status=0
commands[gh]=/usr/bin/true

gh() {
  [[ -n "$review_test_pr_base" ]] || return 1
  print -r -- "$review_test_pr_base"
}

git() {
  case "$1" in
    rev-parse) return "$review_test_git_status" ;;
    fetch) return "$review_test_fetch_status" ;;
    symbolic-ref)
      [[ -n "$review_test_default_base" ]] || return 1
      print -r -- "refs/remotes/origin/$review_test_default_base"
      ;;
    *) return 99 ;;
  esac
}

herdr-reviewr() {
  print -r -- "$EDITOR|$*"
}

[[ "$(review --wrap off)" == 'nvim|--wrap off' ]]
[[ "$(reviewpr --wrap off)" == 'nvim|--base origin/dev --wrap off' ]]
[[ "$(hpr --wrap off)" == 'nvim|--base origin/dev --wrap off' ]]

review_test_pr_base=''
[[ "$(reviewpr)" == 'nvim|--base origin/main' ]]

review_test_fetch_status=42
if output="$(reviewpr 2>/dev/null)"; then
  exit 1
else
  [[ $? == 42 && -z "$output" ]]
fi

review_test_fetch_status=0
review_test_default_base=''
if output="$(reviewpr 2>/dev/null)"; then
  exit 1
else
  [[ $? == 1 && -z "$output" ]]
fi

review_test_git_status=1
if output="$(reviewpr 2>/dev/null)"; then
  exit 1
else
  [[ $? == 1 && -z "$output" ]]
fi
ZSH

printf 'Review command tests passed: launch, PR base, hpr compatibility, fallback, and failures.\n'
