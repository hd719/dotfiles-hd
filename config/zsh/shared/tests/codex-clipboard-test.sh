#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd -P)"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-codex-clipboard.XXXXXX")"
trap 'rm -rf "$test_root"' EXIT

cat > "$test_root/codex" <<'CODEX'
#!/bin/sh
printf 'tty=%s\nconnection=%s\n' "${SSH_TTY-<unset>}" "${SSH_CONNECTION-<unset>}"
printf 'arg=%s\n' "$@"
exit "${CODEX_TEST_EXIT_STATUS:-0}"
CODEX
chmod +x "$test_root/codex"

PATH="$test_root:$PATH" /bin/zsh -df -s "$REPO_DIR" <<'ZSH'
set -eu
source "$1/config/zsh/shared/codex-aliases.zsh"
source "$1/config/zsh/shared/codex-functions.zsh"

unset SSH_TTY SSH_CONNECTION
export TERM_PROGRAM=rex

[[ "$(cod 'prompt with spaces')" == $'tty=rex\nconnection=<unset>\narg=prompt with spaces' ]]
[[ "$(codf --model 'custom model')" == $'tty=rex\nconnection=<unset>\narg=fork\narg=--model\narg=custom model' ]]
[[ "$(codfl)" == $'tty=rex\nconnection=<unset>\narg=fork\narg=--last' ]]
[[ "$(codr 'session with spaces')" == $'tty=rex\nconnection=<unset>\narg=resume\narg=session with spaces' ]]
[[ "$(codra)" == $'tty=rex\nconnection=<unset>\narg=resume\narg=--all' ]]
[[ "$(codrl)" == $'tty=rex\nconnection=<unset>\narg=resume\narg=--last' ]]

# The marker is confined to the Codex process, including after a failed launch.
_dotfiles_codex_interactive >/dev/null
[[ -z ${SSH_TTY+x} && -z ${SSH_CONNECTION+x} ]]
if CODEX_TEST_EXIT_STATUS=47 codrl >/dev/null; then
  exit 1
else
  [[ $? == 47 ]]
fi
[[ -z ${SSH_TTY+x} ]]

# Noninteractive shortcuts and plain codex stay unwrapped even inside Rex.
[[ "$(codu)" == $'tty=<unset>\nconnection=<unset>\narg=update' ]]
[[ "$(codd)" == $'tty=<unset>\nconnection=<unset>\narg=doctor' ]]
[[ "$(codx 'prompt with spaces')" == $'tty=<unset>\nconnection=<unset>\narg=exec\narg=prompt with spaces' ]]
[[ "$(codex --version)" == $'tty=<unset>\nconnection=<unset>\narg=--version' ]]

# Preserve inherited SSH values, including an explicitly empty SSH_TTY.
export SSH_TTY=/dev/ttys999
export SSH_CONNECTION='192.0.2.1 1234 192.0.2.2 22'
[[ "$(codrl)" == $'tty=/dev/ttys999\nconnection=192.0.2.1 1234 192.0.2.2 22\narg=resume\narg=--last' ]]
unset SSH_TTY
[[ "$(codr)" == $'tty=<unset>\nconnection=192.0.2.1 1234 192.0.2.2 22\narg=resume' ]]
unset SSH_CONNECTION
export SSH_TTY=''
[[ "$(codr)" == $'tty=\nconnection=<unset>\narg=resume' ]]

unset SSH_TTY
export TERM_PROGRAM=ghostty
[[ "$(codrl)" == $'tty=<unset>\nconnection=<unset>\narg=resume\narg=--last' ]]
unset TERM_PROGRAM
[[ "$(codrl)" == $'tty=<unset>\nconnection=<unset>\narg=resume\narg=--last' ]]
ZSH

printf 'Codex clipboard tests passed: Rex forwarding, aliases, arguments, SSH markers, failures, and other terminals.\n'
