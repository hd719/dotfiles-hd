# =============================================================================
# ZSH Configuration - Optimized for Speed (~35-45ms target)
# =============================================================================

ZSH_CONFIG_DIR=~/Developer/dotfiles-hd/setup/mac-vm/zsh-config

# -----------------------------------------------------------------------------
# Core Configuration (order matters)
# -----------------------------------------------------------------------------
source $ZSH_CONFIG_DIR/prompt.zsh      # Prompt, starship, zoxide (loads zsh/datetime, zsh/stat)
source $ZSH_CONFIG_DIR/tooling.zsh     # Dev tools config
source $ZSH_CONFIG_DIR/functions.zsh   # Helper functions & caching
source $ZSH_CONFIG_DIR/alias.zsh       # Aliases
source $ZSH_CONFIG_DIR/k8s.zsh         # Kubernetes config

# -----------------------------------------------------------------------------
# Devbox Global Environment (cached for speed, using zsh native stat)
# -----------------------------------------------------------------------------
_load_devbox_shellenv_cached

# -----------------------------------------------------------------------------
# Plugins - Load immediately for better UX
# Adds ~5-10ms to startup but plugins work right away
# -----------------------------------------------------------------------------
_load_nix_plugin "zsh-autosuggestions"
_load_nix_plugin "zsh-syntax-highlighting"

# Fix: Devbox sets NO_COLOR, FORCE_COLOR=0, and CI=1 which disables colors
# Override these to enable colors for lsd, bat, snitch, and other CLI tools
unset NO_COLOR
unset CI
export FORCE_COLOR=1

# -----------------------------------------------------------------------------
# Completions (cached compinit for speed)
# Uses zsh native stat instead of external stat command
# -----------------------------------------------------------------------------
fpath=(/Users/hameldesai/.docker/completions $fpath)
autoload -Uz compinit
# Check if zcompdump exists and is from today (using zsh native stat)
if [[ -f ~/.zcompdump ]]; then
  local _zcomp_mtime _today_start
  zstat -A _zcomp_mtime +mtime ~/.zcompdump 2>/dev/null
  # Calculate start of today (midnight)
  _today_start=$(( EPOCHSECONDS - (EPOCHSECONDS % 86400) ))
  if (( _zcomp_mtime >= _today_start )); then
    compinit -C  # Cached (fast)
  else
    compinit     # Full rebuild (once per day)
  fi
else
  compinit       # First run
fi
