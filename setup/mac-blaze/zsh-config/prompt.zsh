# [Prompt]
# --------------------------------------------------------------------------------------------------------
export PATH="/opt/homebrew/bin:$PATH"

autoload -U +X bashcompinit && bashcompinit
autoload -U compinit; compinit

eval "$(zoxide init --cmd cd zsh)"
eval "$(starship init zsh)"
export STARSHIP_CONFIG=~/Developer/dotfiles-hd/config/starship/starship.toml

source ~/Developer/zsh-you-should-use/you-should-use.plugin.zsh
