# Shared Mac Zsh interface.
#
# Every Mac profile sources this file, then applies its own plugin timing,
# completion policy, PATH entries, credentials, and machine-specific behavior.
# Personal-only workflows load separately through personal.zsh.

ZSH_CONFIG_DIR="$HOME/Developer/dotfiles-hd/config/zsh/mac"

# Source order is intentional: later modules depend on helpers and environment
# established by earlier modules.
source "$ZSH_CONFIG_DIR/prompt.zsh"
source "$ZSH_CONFIG_DIR/tooling.zsh"
source "$ZSH_CONFIG_DIR/functions.zsh"
source "$ZSH_CONFIG_DIR/alias.zsh"
source "$ZSH_CONFIG_DIR/k8s.zsh"
source "$ZSH_CONFIG_DIR/../completions.zsh"
