# =============================================================================
# ZSH Configuration - Optimized for Speed (~35-45ms target)
# =============================================================================

# Shared Mac shell behavior lives behind one interface. This file keeps the
# MacBook-specific plugin timing, completion policy, and PATH setup local.
source "$HOME/Developer/dotfiles-hd/config/zsh/mac/init.zsh"

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
