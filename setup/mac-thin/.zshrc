# Thin Mac control plane. Project tooling and runtimes belong in Linux VMs.

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

setopt append_history
setopt hist_ignore_all_dups
setopt share_history

export DOTFILES_NVIM_PROFILE=thin
export EDITOR=nvim
export VISUAL=nvim
export GIT_EDITOR=nvim
unset GIT_PAGER

typeset mac_thin_brew_prefix="${HOMEBREW_PREFIX:-/opt/homebrew}"

if [[ -o interactive ]]; then
  if [[ -r "$mac_thin_brew_prefix/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh" ]]; then
    source "$mac_thin_brew_prefix/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh"
  fi

  if (( $+commands[zoxide] )); then
    eval "$(zoxide init --cmd cd zsh)"
  fi
fi

typeset mac_thin_zshrc="${${(%):-%N}:A}"
typeset mac_thin_dir="${mac_thin_zshrc:h}"
typeset mac_thin_repo="${mac_thin_dir:h:h}"
source "$mac_thin_repo/config/zsh/shared/functions.zsh"
source "$mac_thin_repo/config/zsh/shared/aliases.zsh"
source "$mac_thin_repo/config/zsh/shared/codex-aliases.zsh"
source "$mac_thin_repo/config/zsh/mac/aliases.zsh"
source "$mac_thin_repo/config/zsh/mac/personal/aliases.zsh"
source "$mac_thin_dir/vm.zsh"

if [[ -o interactive ]]; then
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#9399b2'
  if [[ -r "$mac_thin_brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$mac_thin_brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  fi

  if (( $+commands[starship] )); then
    eval "$(starship init zsh)"
  fi
fi

unset mac_thin_brew_prefix
unset mac_thin_dir mac_thin_repo mac_thin_zshrc
