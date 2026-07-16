# =============================================================================
# ZSH Configuration (Mac mini - Hermes)
# =============================================================================

ZSH_CONFIG_DIR="$HOME/Developer/dotfiles-hd/setup/mac-vm/zsh-config"

_source_zsh_config() {
  local file="$1"
  [[ -r "$file" ]] && source "$file"
}

# -----------------------------------------------------------------------------
# Core Configuration
# -----------------------------------------------------------------------------
_source_zsh_config "$ZSH_CONFIG_DIR/prompt.zsh"
_source_zsh_config "$ZSH_CONFIG_DIR/tooling.zsh"
_source_zsh_config "$ZSH_CONFIG_DIR/functions.zsh"
_source_zsh_config "$ZSH_CONFIG_DIR/alias.zsh"
_source_zsh_config "$ZSH_CONFIG_DIR/k8s.zsh"

# -----------------------------------------------------------------------------
# Plugins
# -----------------------------------------------------------------------------
if (( $+functions[_load_homebrew_plugin] )); then
  _load_homebrew_plugin "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  _load_homebrew_plugin "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# -----------------------------------------------------------------------------
# Completions
# -----------------------------------------------------------------------------
[[ -d "$HOME/.docker/completions" ]] && fpath=("$HOME/.docker/completions" $fpath)

autoload -Uz compinit
if [[ -f "$HOME/.zcompdump" ]]; then
  typeset _zcomp_mtime _today_start
  zstat -A _zcomp_mtime +mtime "$HOME/.zcompdump" 2>/dev/null
  _today_start=$(( EPOCHSECONDS - (EPOCHSECONDS % 86400) ))
  if (( _zcomp_mtime >= _today_start )); then
    compinit -C
  else
    compinit
  fi
else
  compinit
fi

# -----------------------------------------------------------------------------
# Environment
# -----------------------------------------------------------------------------
[[ -d /opt/homebrew/opt/curl/bin ]] && export PATH="/opt/homebrew/opt/curl/bin:$PATH"
[[ -d /opt/homebrew/opt/postgresql@17/bin ]] && export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
# uv tools may use XDG_BIN_HOME. Keep the default local bin too because the Mac
# mini stores machine-local helpers such as cua-driver-rs there.
typeset -gaU path
path=("${XDG_BIN_HOME:-$HOME/.local/bin}" "$HOME/.local/bin" $path)
export PATH

if [[ -f "$HOME/.local/bin/env" ]]; then
  source "$HOME/.local/bin/env"
fi

if [[ -n "$SSH_CONNECTION" ]]; then
  export GIT_EDITOR="code --wait"
  export EDITOR="code --wait"
fi

export GOG_ACCOUNT="hameldesai3@gmail.com"
[[ -f "$HOME/.gog-env" ]] && source "$HOME/.gog-env"

# -----------------------------------------------------------------------------
# Tool Init Scripts
# -----------------------------------------------------------------------------
_cache_needs_refresh() {
  local cache_file="$1"
  [[ ! -f "$cache_file" ]] && return 0

  local file_mtime
  zstat -A file_mtime +mtime "$cache_file" 2>/dev/null || return 0
  (( EPOCHSECONDS - file_mtime > 86400 ))
}

if (( $+commands[uv] )); then
  _uv_cache="$_ZSH_CACHE_DIR/uv-completion.zsh"
  if _cache_needs_refresh "$_uv_cache"; then
    uv generate-shell-completion zsh > "$_uv_cache" 2>/dev/null
  fi
  [[ -f "$_uv_cache" ]] && source "$_uv_cache"
fi

if (( $+commands[op] )); then
  _op_cache="$_ZSH_CACHE_DIR/op-completion.zsh"
  if _cache_needs_refresh "$_op_cache"; then
    op completion zsh > "$_op_cache" 2>/dev/null
  fi
  [[ -f "$_op_cache" ]] && source "$_op_cache"
  compdef _op op 2>/dev/null
fi

if (( $+functions[_activate_mise] )); then
  _activate_mise
fi
