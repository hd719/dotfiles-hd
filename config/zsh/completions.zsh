# Shared Zsh completion and cache helpers.
# Machine profiles still own plugin timing, fpath entries, and cache policy.

zmodload zsh/datetime 2>/dev/null
zmodload zsh/stat 2>/dev/null

# Accept a pending history suggestion with Tab; otherwise keep normal completion.
_zsh_tab_accept_or_complete() {
  if [[ -n "$POSTDISPLAY" && "$CURSOR" -eq "${#BUFFER}" ]] &&
    (( $+widgets[autosuggest-accept] )); then
    zle autosuggest-accept
    zle -I
    zle redisplay
  else
    zle expand-or-complete
  fi
}

zle -N _zsh_tab_accept_or_complete
bindkey -M emacs '^I' _zsh_tab_accept_or_complete
bindkey -M viins '^I' _zsh_tab_accept_or_complete

_ZSH_CACHE_DIR="${_ZSH_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/zsh}"
[[ -d "$_ZSH_CACHE_DIR" ]] || mkdir -p "$_ZSH_CACHE_DIR"

_zsh_add_completion_dirs() {
  emulate -L zsh

  local completion_dir
  local -a completion_dirs

  for completion_dir in "$@"; do
    [[ -d "$completion_dir" ]] && completion_dirs+=("$completion_dir")
  done

  typeset -gaU fpath
  fpath=($completion_dirs $fpath)
}

_zsh_cache_needs_refresh() {
  emulate -L zsh

  local cache_file="$1"
  local max_age_seconds="${2:-86400}"
  local -a file_mtime

  [[ -s "$cache_file" ]] || return 0
  zstat -A file_mtime +mtime "$cache_file" 2>/dev/null || return 0
  (( EPOCHSECONDS - file_mtime[1] > max_age_seconds ))
}

_zsh_cache_and_source() {
  emulate -L zsh

  local command_name="$1"
  local cache_file="$2"
  local cache_dir="${cache_file:h}"
  local temporary_file="${cache_file}.tmp.$$"
  shift 2

  (( $# > 0 )) || return 2
  command -v "$command_name" >/dev/null 2>&1 || return 0

  if _zsh_cache_needs_refresh "$cache_file"; then
    [[ -d "$cache_dir" ]] || mkdir -p "$cache_dir"
    if "$@" > "$temporary_file" 2>/dev/null && [[ -s "$temporary_file" ]]; then
      mv "$temporary_file" "$cache_file"
    else
      rm -f "$temporary_file"
    fi
  fi

  [[ -s "$cache_file" ]] && source "$cache_file"
}

_zsh_compdump_is_fresh() {
  emulate -L zsh

  local dump_file="$1"
  local freshness_policy="${2:-daily}"
  local -a file_mtime

  [[ -f "$dump_file" ]] || return 1
  zstat -A file_mtime +mtime "$dump_file" 2>/dev/null || return 1

  if [[ "$freshness_policy" == daily ]]; then
    local today_start=$(( EPOCHSECONDS - (EPOCHSECONDS % 86400) ))
    (( file_mtime[1] >= today_start ))
  elif [[ "$freshness_policy" == <-> ]]; then
    (( EPOCHSECONDS - file_mtime[1] < freshness_policy ))
  else
    return 1
  fi
}

_zsh_init_completions() {
  emulate -L zsh

  local freshness_policy="${1:-daily}"
  local dump_file="${2:-$HOME/.zcompdump}"

  (( $+functions[compinit] )) || autoload -Uz compinit
  if _zsh_compdump_is_fresh "$dump_file" "$freshness_policy"; then
    compinit -C -d "$dump_file"
  else
    compinit -d "$dump_file"
  fi
}

_zsh_load_common_tool_completions() {
  emulate -L zsh

  _zsh_cache_and_source \
    uv \
    "$_ZSH_CACHE_DIR/uv-completion.zsh" \
    uv generate-shell-completion zsh
  _zsh_cache_and_source \
    op \
    "$_ZSH_CACHE_DIR/op-completion.zsh" \
    op completion zsh

  if (( $+functions[compdef] && $+functions[_op] )); then
    compdef _op op 2>/dev/null
  fi
}
