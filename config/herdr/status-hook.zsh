# Keep status selectors tied to each pane instead of Herdr's startup environment.
typeset -g _dotfiles_herdr_status_script="${${(%):-%N}:A:h}/status.sh"
zmodload zsh/datetime
zmodload zsh/stat
typeset -g _dotfiles_herdr_status_signature=""
typeset -gi _dotfiles_herdr_status_reported_at=0

_dotfiles_herdr_report_environment() {
  emulate -L zsh
  [[ "${HERDR_ENV:-}" == 1 && -n "${HERDR_PANE_ID:-}" ]] || return 0
  local kube_files="${KUBECONFIG:-$HOME/.kube/config}"
  local -a files=("${AWS_CONFIG_FILE:-$HOME/.aws/config}" "$HOME/.aws/credentials"
    "${DOCKER_CONFIG:-$HOME/.docker}/config.json" "${(@s.:.)kube_files}")
  local -a fingerprint=("$HERDR_PANE_ID" "${HERDR_SOCKET_PATH:-}" "$PATH"
    "${AWS_PROFILE:-}" "${AWS_DEFAULT_PROFILE:-}" "${AWS_REGION:-}" "${AWS_DEFAULT_REGION:-}"
    "${DOCKER_CONTEXT:-}" "${DOCKER_HOST:-}" "${HERDR_BIN_PATH:-}")
  local file signature
  local -A info
  for file in "${files[@]}"; do
    fingerprint+=("$file")
    if zstat -H info "$file" 2>/dev/null; then
      fingerprint+=("${info[mtime]}" "${info[ctime]}" "${info[size]}" "${info[inode]}")
    else
      fingerprint+=(missing)
    fi
  done
  signature="${(qqq)fingerprint}"
  # Recheck occasionally so a failed report or newly installed CLI can recover.
  if [[ "$signature" == "$_dotfiles_herdr_status_signature" ]] &&
    (( EPOCHSECONDS - _dotfiles_herdr_status_reported_at < 30 )); then
    return 0
  fi
  _dotfiles_herdr_status_signature="$signature"
  _dotfiles_herdr_status_reported_at=$EPOCHSECONDS
  local herdr_bin="${HERDR_BIN_PATH:-${commands[herdr]:-$HOME/.local/bin/herdr}}"
  (HERDR_BIN_PATH="$herdr_bin" DOTFILES_HERDR_STATUS_SEQ="${EPOCHREALTIME/./}" bash "$_dotfiles_herdr_status_script" report >/dev/null 2>&1 &!)
}

autoload -Uz add-zsh-hook
add-zsh-hook -d precmd _dotfiles_herdr_report_environment
add-zsh-hook precmd _dotfiles_herdr_report_environment
