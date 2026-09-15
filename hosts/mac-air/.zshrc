# Lightweight remote-access shell. No local project runtimes or VM helpers.
export DOTFILES_MAC_PROFILE=mac-air
export EDITOR=vi
export VISUAL=vi
export GIT_EDITOR=vi
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt append_history hist_ignore_all_dups share_history

typeset -gaU path
path=("${HOMEBREW_PREFIX:-/opt/homebrew}/bin" "$HOME/.local/bin" $path)
export PATH

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
