# [Prompt]
# --------------------------------------------------------------------------------------------------------
export PATH="/opt/homebrew/bin:$PATH"
export TERM=xterm-256color

autoload -U +X bashcompinit && bashcompinit

# Check if Nix/Devbox is installed and use appropriate paths
if command -v nix &> /dev/null; then
    # With Devbox: Use Nix-managed binaries
    eval "$(/Users/hameldesai/.local/share/devbox/global/default/.devbox/nix/profile/default/bin/zoxide init --cmd cd zsh)"
    eval "$(/Users/hameldesai/.local/share/devbox/global/default/.devbox/nix/profile/default/bin/starship init zsh)"
else
    # Without Devbox: Use system binaries
    eval "$(zoxide init --cmd cd zsh)"
    eval "$(starship init zsh)"
fi


export STARSHIP_CONFIG=~/Developer/dotfiles-hd/config/starship/starship.toml

source ~/Developer/zsh-you-should-use/you-should-use.plugin.zsh
