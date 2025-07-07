# [ZSH Config Directory]
ZSH_CONFIG_DIR=~/Developer/dotfiles-hd/setup/mac-vm/zsh-config

# [ZSH/System Aliases]
# --------------------------------------------------------------------------------------------------------
source $ZSH_CONFIG_DIR/alias.zsh

# [ZSH/System Functions]
# --------------------------------------------------------------------------------------------------------
source $ZSH_CONFIG_DIR/functions.zsh

# [Kubernetes Config]
# --------------------------------------------------------------------------------------------------------
source $ZSH_CONFIG_DIR/k8s.zsh

# [Environment Variables]
# --------------------------------------------------------------------------------------------------------
export GIT_EDITOR="cursor --wait"
export EDITOR="cursor --wait"
export TERM=xterm-256color

export STARSHIP_CONFIG=~/Developer/dotfiles-hd/config/starship/starship.toml
export PATH="$PATH:/home/hameldesai/.local/bin"
export PATH="$HOME/Developer/tools/anycable:$PATH"

# [Prompt / Shell Plugins]
# --------------------------------------------------------------------------------------------------------
eval "$(starship init zsh)"
eval "$(zoxide init --cmd cd zsh)"
eval "$(rbenv init - zsh)"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

source /home/hameldesai/Developer/zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /home/hameldesai/Developer/zsh-plugins/zsh-you-should-use/you-should-use.plugin.zsh

# [Node.js - NVM]
# --------------------------------------------------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# [pnpm]
# --------------------------------------------------------------------------------------------------------
export PNPM_HOME="/home/hameldesai/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# [Aliases]
# --------------------------------------------------------------------------------------------------------
alias mount-shared="vmhgfs-fuse .host:/ /mnt/hgfs -o allow_other"

# Alias to start Cursor editor (AppImage)
alias cursor-app="~/Applications/Cursor-1.2.1-aarch64.AppImage"

# Reset Font (175% scaling)
alias font="gsettings set org.gnome.mutter experimental-features \"['scale-monitor-framebuffer']\" && gsettings set org.gnome.desktop.interface text-scaling-factor 1.75"
PATH=~/.console-ninja/.bin:$PATH