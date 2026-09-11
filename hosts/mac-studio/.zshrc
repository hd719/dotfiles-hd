# Mac Studio primary control plane and compute host.

export DOTFILES_MAC_PROFILE="mac-studio"

source "$HOME/Developer/dotfiles-hd/config/zsh/mac/init.zsh"
source "$HOME/Developer/dotfiles-hd/config/zsh/mac/personal/init.zsh"

_load_homebrew_plugin "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
_load_homebrew_plugin "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

unset NO_COLOR
unset CI
export FORCE_COLOR=1

_zsh_add_completion_dirs \
  "$HOME/.docker/completions" \
  /opt/homebrew/share/zsh/site-functions \
  /usr/local/share/zsh/site-functions
_zsh_init_completions 43200
typeset -gaU path
path=("${XDG_BIN_HOME:-$HOME/.local/bin}" $path)
export PATH

_activate_mise

source "$HOME/Developer/dotfiles-hd/hosts/mac-studio/vm.zsh"
