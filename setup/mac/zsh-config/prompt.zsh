# [Prompt]
# --------------------------------------------------------------------------------------------------------
export PATH="/opt/homebrew/bin:$PATH"
export TERM=xterm-256color

autoload -U +X bashcompinit && bashcompinit

eval "$(zoxide init --cmd cd zsh)"
eval "$(starship init zsh)"
export STARSHIP_CONFIG=~/Developer/dotfiles-hd/config/starship/starship.toml

source ~/Developer/zsh-you-should-use/you-should-use.plugin.zsh
