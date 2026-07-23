# Personal Mac shell interface.
#
# Source the shared Mac interface first, then add workflows that must not leak
# into the Resilience work profile.

ZSH_CONFIG_DIR="${ZSH_CONFIG_DIR:-$HOME/Developer/dotfiles-hd/config/zsh/mac}"

source "$ZSH_CONFIG_DIR/personal-functions.zsh"
source "$ZSH_CONFIG_DIR/personal-aliases.zsh"
