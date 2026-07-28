# Ubuntu shell configuration

typeset -U path PATH
path=("$HOME/.local/bin" $path)

export EDITOR="nvim"
export VISUAL="nvim"
export GIT_EDITOR="nvim"
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
unset GIT_PAGER

# Keep history suggestions readable over the shared Ghostty Nord background.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#9399b2'

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY HIST_IGNORE_DUPS SHARE_HISTORY

autoload -Uz compinit
compinit

source_if_exists() {
  [[ -r "$1" ]] && source "$1"
}

typeset ubuntu_zshrc="${${(%):-%N}:A}"
typeset ubuntu_repo="${ubuntu_zshrc:h:h:h}"
source_if_exists "$ubuntu_repo/config/zsh/shared/functions.zsh"
source_if_exists "$ubuntu_repo/config/zsh/shared/aliases.zsh"
source_if_exists "$ubuntu_repo/config/zsh/shared/codex-aliases.zsh"

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

source_if_exists "$ubuntu_repo/config/zsh/shared/development-aliases.zsh"
unset ubuntu_repo ubuntu_zshrc

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init --cmd cd zsh)"
fi

alias gs='git status --short --branch'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias d='docker'
alias dc='docker compose'
alias lg='lazygit'

source_if_exists /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source_if_exists /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
