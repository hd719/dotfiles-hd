# Node Version Manager
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Tylt
eval “$(rbenv init -)”
source ~/hd/.secrets
source ~/hd/.alias

#Plugins
source ~/Development/dotfiles/zsh/plugins/oh-my-zsh/lib/key-bindings.zsh
source ~/Development/dotfiles/zsh/plugins/oh-my-zsh/lib/completion.zsh
source ~/Development/dotfiles/zsh/plugins/vi-mode.plugin.zsh
source ~/Development/dotfiles/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/Development/dotfiles/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/Development/dotfiles/zsh/keybindings.sh

# Set Spaceship ZSH as a prompt
autoload promptinit; promptinit
prompt spaceship

# What is the I before prompt character ?
# https://denysdovhan.com/spaceship-prompt/docs/Troubleshooting.html
SPACESHIP_VI_MODE_SHOW=false

# Set Spaceship Pure as a prompt
# autoload -U promptinit; promptinit
# PURE_CMD_MAX_EXEC_TIME=10
# prompt pure