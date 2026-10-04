# MacBook Air thin client. Project tooling and runtimes stay on the development Mac.

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

typeset mac_air_brew_prefix="${HOMEBREW_PREFIX:-/opt/homebrew}"

if [[ -o interactive ]]; then
  if (( $+commands[zoxide] )); then
    eval "$(zoxide init --cmd cd zsh)"
  fi
fi

typeset mac_air_zshrc="${${(%):-%N}:A}"
typeset mac_air_dir="${mac_air_zshrc:h}"
typeset mac_air_repo="${mac_air_dir:h:h}"
source "$mac_air_repo/config/zsh/shared/functions.zsh"
source "$mac_air_repo/config/zsh/shared/aliases.zsh"
source "$mac_air_repo/config/zsh/shared/codex-aliases.zsh"
source "$mac_air_repo/config/zsh/shared/codex-functions.zsh"
source "$mac_air_repo/config/zsh/mac/aliases.zsh"
source "$mac_air_repo/config/zsh/mac/personal/aliases.zsh"
source "$mac_air_dir/herdr.zsh"

if [[ -o interactive ]]; then
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#9399b2'
  if [[ -r "$mac_air_brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$mac_air_brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  fi

  if (( $+commands[starship] )); then
    eval "$(starship init zsh)"
  fi
fi

unset mac_air_brew_prefix
unset mac_air_dir mac_air_repo mac_air_zshrc

# Load last so it can wrap every ZLE widget created above.
if [[ -o interactive \
  && -r "${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
