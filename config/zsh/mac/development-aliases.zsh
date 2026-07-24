# Mac-only development aliases.

alias usedocker='docker context use desktop-linux'
alias dhd='cd ~/Developer/dotfiles-hd && code .'
alias open-zshrc='code ~/.zshrc'
alias code-restart="killall electron && killall node && killall code"
alias refresh-global='/opt/homebrew/bin/mise install && /opt/homebrew/bin/mise reshim && hash -r'
