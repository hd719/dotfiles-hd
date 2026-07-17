# =============================================================================
# ZSH Configuration - Optimized for Speed (~35-45ms target)
# =============================================================================

ZSH_CONFIG_DIR="$HOME/Developer/dotfiles-hd/setup/mac-vm/zsh-config"

# -----------------------------------------------------------------------------
# Core Configuration (order matters)
# -----------------------------------------------------------------------------
source $ZSH_CONFIG_DIR/prompt.zsh      # Prompt, starship, zoxide (loads zsh/datetime, zsh/stat)
source $ZSH_CONFIG_DIR/tooling.zsh     # Dev tools config
source $ZSH_CONFIG_DIR/functions.zsh   # Helper functions & caching
source $ZSH_CONFIG_DIR/alias.zsh       # Aliases
source $ZSH_CONFIG_DIR/k8s.zsh         # Kubernetes config
source "$ZSH_CONFIG_DIR/../../../config/zsh/completions.zsh"

# -----------------------------------------------------------------------------
# Plugins - Load immediately for better UX
# Adds ~5-10ms to startup but plugins work right away
# -----------------------------------------------------------------------------
_load_homebrew_plugin "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
_load_homebrew_plugin "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# Keep color-capable CLIs from inheriting restrictive environment flags.
unset NO_COLOR
unset CI
export FORCE_COLOR=1

# -----------------------------------------------------------------------------
# Completions (cached compinit for speed)
# Uses zsh native stat instead of external stat command
# -----------------------------------------------------------------------------
_zsh_add_completion_dirs \
  "$HOME/.docker/completions" \
  /opt/homebrew/share/zsh/site-functions \
  /usr/local/share/zsh/site-functions
_zsh_init_completions 43200
typeset -gaU path
path=("${XDG_BIN_HOME:-$HOME/.local/bin}" $path)
export PATH

_activate_mise
