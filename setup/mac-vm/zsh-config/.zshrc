# =============================================================================
# ZSH Configuration
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
# Plugins (Nix/Devbox - using cached paths for speed)
# -----------------------------------------------------------------------------
_load_nix_plugin "zsh-autosuggestions"
_load_nix_plugin "zsh-syntax-highlighting"

# -----------------------------------------------------------------------------
# Devbox Global Environment (cached for speed)
# -----------------------------------------------------------------------------
_devbox_cache="$_ZSH_CACHE_DIR/devbox-shellenv.zsh"
if [[ ! -f "$_devbox_cache" || $(( $(date +%s) - $(stat -f %m "$_devbox_cache" 2>/dev/null || echo 0) )) -gt 86400 ]]; then
  devbox global shellenv > "$_devbox_cache" 2>/dev/null
fi
source "$_devbox_cache"

# -----------------------------------------------------------------------------
# Completions (cached compinit for speed)
# -----------------------------------------------------------------------------
fpath=(/Users/hameldesai/.docker/completions $fpath)
autoload -Uz compinit
if [[ -f ~/.zcompdump && $(date +'%j') == $(stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null) ]]; then
  compinit -C  # Cached (fast)
else
  compinit     # Full rebuild (once per day)
fi
