# Thin Mac adds current-directory routing while leaving Herdr lifecycle native.

typeset -g DOTFILES_HERDR_ROUTE_CWD=1
typeset -g DOTFILES_HERDR_RESET_ENABLED=0
typeset -g thin_herdr_module="${${(%):-%N}:A}"
source "${thin_herdr_module:h:h:h}/config/zsh/shared/herdr.zsh"
unset DOTFILES_HERDR_RESET_ENABLED DOTFILES_HERDR_ROUTE_CWD thin_herdr_module
