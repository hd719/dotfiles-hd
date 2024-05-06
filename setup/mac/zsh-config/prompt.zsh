# [Prompt]
# --------------------------------------------------------------------------------------------------------
export PATH="/opt/homebrew/bin:$PATH"

autoload -U +X bashcompinit && bashcompinit

eval "$(starship init zsh)"
export STARSHIP_CONFIG=~/Developer/dotfiles-hd/config/starship/starship.toml

eval "$(zoxide init --cmd cd zsh)"

source ~/Developer/zsh-you-should-use/you-should-use.plugin.zsh
