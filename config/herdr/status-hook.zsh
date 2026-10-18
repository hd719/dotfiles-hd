# Keep status selectors tied to each pane instead of Herdr's startup environment.
typeset -g _dotfiles_herdr_status_script="${${(%):-%N}:A:h}/status.sh"
zmodload zsh/datetime

_dotfiles_herdr_report_environment() {
  [[ "${HERDR_ENV:-}" == 1 && -n "${HERDR_PANE_ID:-}" ]] || return 0
  local herdr_bin="${HERDR_BIN_PATH:-${commands[herdr]:-$HOME/.local/bin/herdr}}"
  (HERDR_BIN_PATH="$herdr_bin" DOTFILES_HERDR_STATUS_SEQ="${EPOCHREALTIME/./}" bash "$_dotfiles_herdr_status_script" report >/dev/null 2>&1 &!)
}

autoload -Uz add-zsh-hook
add-zsh-hook -d precmd _dotfiles_herdr_report_environment
add-zsh-hook precmd _dotfiles_herdr_report_environment
