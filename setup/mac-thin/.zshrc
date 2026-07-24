# Thin Mac control plane. Project tooling and runtimes belong in Linux VMs.

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

setopt append_history
setopt hist_ignore_all_dups
setopt share_history

autoload -Uz compinit
compinit -C
