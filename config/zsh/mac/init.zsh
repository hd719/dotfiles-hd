# Shared Mac Zsh interface.
#
# Machine profiles source this file, then apply their own plugin timing,
# completion policy, PATH entries, credentials, and work-specific behavior.

ZSH_CONFIG_DIR="$HOME/Developer/dotfiles-hd/config/zsh/mac"

# Source order is intentional: later modules depend on helpers and environment
# established by earlier modules.
source "$ZSH_CONFIG_DIR/prompt.zsh"
source "$ZSH_CONFIG_DIR/tooling.zsh"
source "$ZSH_CONFIG_DIR/functions.zsh"
source "$ZSH_CONFIG_DIR/alias.zsh"
source "$ZSH_CONFIG_DIR/k8s.zsh"
source "$ZSH_CONFIG_DIR/../completions.zsh"
