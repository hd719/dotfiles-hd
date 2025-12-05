# [Prompt]
# --------------------------------------------------------------------------------------------------------
export PATH="/opt/homebrew/bin:$PATH"
export TERM=xterm-256color

autoload -U +X bashcompinit && bashcompinit

# Without Devbox:
# eval "$(zoxide init --cmd cd zsh)"
# eval "$(starship init zsh)"

# With Devbox: 
eval "$(/Users/hameldesai/.local/share/devbox/global/default/.devbox/nix/profile/default/bin/zoxide init --cmd cd zsh)"
eval "$(/Users/hameldesai/.local/share/devbox/global/default/.devbox/nix/profile/default/bin/starship init zsh)"
export STARSHIP_CONFIG=~/Developer/dotfiles-hd/config/starship/starship.toml

source ~/Developer/zsh-you-should-use/you-should-use.plugin.zsh
