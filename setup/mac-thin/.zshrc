# Thin Mac control plane. Project tooling and runtimes belong in Linux VMs.

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

setopt append_history
setopt hist_ignore_all_dups
setopt share_history

# Preserve the preferred Git pager while keeping fresh restores usable before
# Homebrew finishes installing the control-plane formula.
if (( $+commands[diff-so-fancy] )); then
  export GIT_PAGER='diff-so-fancy | less --tabs=4 -RFX'
else
  export GIT_PAGER='less --tabs=4 -RFX'
fi

autoload -Uz compinit
compinit -C

typeset mac_thin_zshrc="${${(%):-%N}:A}"
typeset mac_thin_dir="${mac_thin_zshrc:h}"
typeset mac_thin_repo="${mac_thin_dir:h:h}"
source "$mac_thin_repo/config/zsh/shared/functions.zsh"
source "$mac_thin_repo/config/zsh/shared/aliases.zsh"
source "$mac_thin_repo/config/zsh/mac/aliases.zsh"
source "$mac_thin_repo/config/zsh/mac/personal/aliases.zsh"
source "$mac_thin_dir/vm.zsh"
unset mac_thin_dir mac_thin_repo mac_thin_zshrc
