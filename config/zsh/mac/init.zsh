# Full Mac development interface.
#
# Every Mac profile sources this file, then applies its own plugin timing,
# completion policy, PATH entries, credentials, and machine-specific behavior.
# Personal-only workflows load separately through personal/init.zsh.

typeset zsh_mac_dir="${${(%):-%N}:A:h}"
typeset zsh_shared_dir="${zsh_mac_dir:h}/shared"

# Source order is intentional: later modules depend on helpers and environment
# established by earlier modules.
source "$zsh_mac_dir/prompt.zsh"
source "$zsh_mac_dir/tooling.zsh"
source "$zsh_shared_dir/functions.zsh"
source "$zsh_mac_dir/development-functions.zsh"
source "$zsh_shared_dir/aliases.zsh"
source "$zsh_shared_dir/development-aliases.zsh"
source "$zsh_mac_dir/aliases.zsh"
source "$zsh_mac_dir/development-aliases.zsh"
source "$zsh_mac_dir/k8s.zsh"
source "$zsh_shared_dir/completions.zsh"
unset zsh_mac_dir zsh_shared_dir
