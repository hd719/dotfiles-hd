if [[ -n "$ZSH_PROFILE" ]]; then
    source ~/Developer/dotfiles-hd/setup/mac-$ZSH_PROFILE/zsh-config/.zshrc
else
    source ~/Developer/dotfiles-hd/setup/mac-vm/zsh-config/.zshrc
fi
