# [Prompt]
# --------------------------------------------------------------------------------------------------------
export PATH="/opt/homebrew/bin:$PATH"

autoload -U +X bashcompinit && bashcompinit

if type brew &>/dev/null; then
    FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

    autoload -Uz compinit
    compinit
fi

eval "$(starship init zsh)"
export STARSHIP_CONFIG=~/Developer/dotfiles-hd/config/starship/starship.toml
# eval "$(oh-my-posh init zsh --config ~/.config/ohmyposh/base.toml)"

eval "$(zoxide init --cmd cd zsh)"

source ~/Developer/zsh-you-should-use/you-should-use.plugin.zsh
