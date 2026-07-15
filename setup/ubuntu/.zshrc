# Ubuntu shell configuration

typeset -U path PATH
path=("$HOME/.local/bin" $path)

export EDITOR="nvim"
export VISUAL="nvim"
export GIT_EDITOR="nvim"
export STARSHIP_CONFIG="$HOME/.config/starship.toml"

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY HIST_IGNORE_DUPS SHARE_HISTORY

autoload -Uz compinit
compinit

source_if_exists() {
  [[ -r "$1" ]] && source "$1"
}

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init --cmd cd zsh)"
fi

alias g='git'
alias gs='git status --short --branch'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias d='docker'
alias dc='docker compose'
alias lg='lazygit'

source_if_exists /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source_if_exists /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
