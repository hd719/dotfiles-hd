# =============================================================================
# ZSH Configuration (Work - Resilience)
# =============================================================================

ZSH_CONFIG_DIR=~/Developer/dotfiles-hd/setup/mac-vm/zsh-config

# -----------------------------------------------------------------------------
# Core Configuration (order matters)
# -----------------------------------------------------------------------------
source $ZSH_CONFIG_DIR/prompt.zsh      # Prompt, starship, zoxide
source $ZSH_CONFIG_DIR/tooling.zsh     # Dev tools config
source $ZSH_CONFIG_DIR/functions.zsh   # Helper functions & caching
source $ZSH_CONFIG_DIR/alias.zsh       # Aliases
source $ZSH_CONFIG_DIR/k8s.zsh         # Kubernetes config

# -----------------------------------------------------------------------------
# Plugins (Homebrew) - Smart deferred loading (~32ms savings)
# -----------------------------------------------------------------------------
# Plugins load before first prompt via precmd hook (better UX than preexec)
# This keeps fast startup but plugins are active before you start typing
_deferred_plugins_loaded=0
_load_deferred_plugins() {
  (( _deferred_plugins_loaded )) && return
  _deferred_plugins_loaded=1
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _load_deferred_plugins

# -----------------------------------------------------------------------------
# Completions (cached compinit for speed)
# -----------------------------------------------------------------------------
# Uses zsh native EPOCHSECONDS and zstat (loaded in prompt.zsh) instead of external commands
fpath=(/Users/hameldesai/.docker/completions $fpath)
autoload -Uz compinit
if [[ -f ~/.zcompdump ]]; then
  local _zcomp_mtime _today_start
  zstat -A _zcomp_mtime +mtime ~/.zcompdump 2>/dev/null
  _today_start=$(( EPOCHSECONDS - (EPOCHSECONDS % 86400) ))
  if (( _zcomp_mtime >= _today_start )); then
    compinit -C  # Cached (fast)
  else
    compinit     # Full rebuild (once per day)
  fi
else
  compinit       # First run
fi

# -----------------------------------------------------------------------------
# Environment
# -----------------------------------------------------------------------------
export GIT_EDITOR="code --wait"
export EDITOR="code --wait"
export PATH="/opt/homebrew/opt/curl/bin:$PATH"
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
if [[ -f "$HOME/.local/bin/env" ]]; then
  . "$HOME/.local/bin/env"
fi

# -----------------------------------------------------------------------------
# Tool Init Scripts (cached for speed)
# -----------------------------------------------------------------------------
# Helper: Check if cache file needs refresh (older than 1 day)
# Uses zsh native EPOCHSECONDS and zstat instead of external commands
_cache_needs_refresh() {
  local cache_file="$1"
  [[ ! -f "$cache_file" ]] && return 0
  local file_mtime
  zstat -A file_mtime +mtime "$cache_file" 2>/dev/null || return 0
  (( EPOCHSECONDS - file_mtime > 86400 ))
}

# Cache uv completions
_uv_cache="$_ZSH_CACHE_DIR/uv-completion.zsh"
if _cache_needs_refresh "$_uv_cache"; then
  uv generate-shell-completion zsh > "$_uv_cache" 2>/dev/null
fi
[[ -f "$_uv_cache" ]] && source "$_uv_cache"

# Cache 1Password completions
_op_cache="$_ZSH_CACHE_DIR/op-completion.zsh"
if _cache_needs_refresh "$_op_cache"; then
  op completion zsh > "$_op_cache" 2>/dev/null
fi
[[ -f "$_op_cache" ]] && source "$_op_cache"
compdef _op op

# Cache fnm environment
_fnm_cache="$_ZSH_CACHE_DIR/fnm-env.zsh"
if _cache_needs_refresh "$_fnm_cache"; then
  fnm env --use-on-cd > "$_fnm_cache" 2>/dev/null
fi
[[ -f "$_fnm_cache" ]] && source "$_fnm_cache"
