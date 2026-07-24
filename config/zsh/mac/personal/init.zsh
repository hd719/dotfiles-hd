# Personal Mac development interface.
#
# Source mac/init.zsh first. Thin Macs source only aliases.zsh from this folder.

typeset zsh_personal_dir="${${(%):-%N}:A:h}"
source "$zsh_personal_dir/development-functions.zsh"
source "$zsh_personal_dir/aliases.zsh"
source "$zsh_personal_dir/development-aliases.zsh"
unset zsh_personal_dir
