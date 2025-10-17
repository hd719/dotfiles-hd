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
export PATH="$PATH:/home/hamel/.local/bin"
export PATH="$HOME/Developer/tools/anycable:$PATH"

# [Prompt / Shell Plugins]
# --------------------------------------------------------------------------------------------------------
eval "$(starship init zsh)"
eval "$(zoxide init --cmd cd zsh)"

# Initialize rbenv if it exists
if [ -d "$HOME/.rbenv" ]; then
  export PATH="$HOME/.rbenv/bin:$PATH"
  eval "$(rbenv init - zsh)"
fi

# Only initialize brew if it exists
if [ -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Load zsh plugins if they exist
if [ -f "$HOME/Developer/zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$HOME/Developer/zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

if [ -f "$HOME/Developer/zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "$HOME/Developer/zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

if [ -f "$HOME/Developer/zsh-plugins/zsh-you-should-use/you-should-use.plugin.zsh" ]; then
  source "$HOME/Developer/zsh-plugins/zsh-you-should-use/you-should-use.plugin.zsh"
fi

# [Node.js]
# --------------------------------------------------------------------------------------------------------
# fnm
FNM_PATH="/home/hamel/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "`fnm env`"
fi

# [pnpm]
# --------------------------------------------------------------------------------------------------------
export PNPM_HOME="/home/hamel/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# [Aliases]
# --------------------------------------------------------------------------------------------------------

export GIT_EDITOR="code --wait"
export EDITOR="code --wait"
