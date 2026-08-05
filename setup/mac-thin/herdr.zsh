# Thin Mac adds current-directory routing to the shared Herdr reset wrapper.

typeset -g DOTFILES_HERDR_ROUTE_CWD=1
typeset -g thin_herdr_module="${${(%):-%N}:A}"
source "${thin_herdr_module:h:h:h}/config/zsh/shared/herdr.zsh"
unset DOTFILES_HERDR_ROUTE_CWD thin_herdr_module
