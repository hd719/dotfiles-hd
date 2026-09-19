# Lightweight remote-access shell. No local project runtimes or VM helpers.
export DOTFILES_MAC_PROFILE=mac-air
export DOTFILES_NVIM_PROFILE=thin
export EDITOR=nvim
export VISUAL=nvim
export GIT_EDITOR=nvim
unset GIT_PAGER
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt append_history hist_ignore_all_dups share_history

typeset -gaU path
path=("${HOMEBREW_PREFIX:-/opt/homebrew}/bin" "$HOME/.local/bin" $path)
export PATH

typeset air_zshrc="${${(%):-%N}:A}"
typeset air_repo="${air_zshrc:h:h:h}"
source "$air_repo/config/zsh/shared/functions.zsh"
source "$air_repo/config/zsh/shared/aliases.zsh"
source "$air_repo/config/zsh/shared/codex-aliases.zsh"
source "$air_repo/config/zsh/shared/codex-functions.zsh"
source "$air_repo/config/zsh/mac/aliases.zsh"
alias vault='cd ~/Developer/hd'
unset air_repo air_zshrc

if [[ -o interactive ]]; then
  (( $+commands[zoxide] )) && eval "$(zoxide init --cmd cd zsh)"
  (( $+commands[starship] )) && eval "$(starship init zsh)"
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#9399b2'
  for air_plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    air_plugin_path="${HOMEBREW_PREFIX:-/opt/homebrew}/share/$air_plugin/$air_plugin.zsh"
    [[ ! -r "$air_plugin_path" ]] || source "$air_plugin_path"
  done
  unset air_plugin air_plugin_path
fi
