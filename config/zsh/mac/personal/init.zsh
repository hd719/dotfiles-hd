# Personal Mac development interface.
#
# Source mac/init.zsh first. Thin Macs source only aliases.zsh from this folder.

typeset zsh_personal_dir="${${(%):-%N}:A:h}"
typeset zsh_personal_shared_dir="${zsh_personal_dir:h:h}/shared"
source "$zsh_personal_dir/development-functions.zsh"
source "$zsh_personal_shared_dir/codex-aliases.zsh"
source "$zsh_personal_dir/codex-functions.zsh"
source "$zsh_personal_dir/aliases.zsh"
source "$zsh_personal_dir/development-aliases.zsh"
unset zsh_personal_dir zsh_personal_shared_dir
