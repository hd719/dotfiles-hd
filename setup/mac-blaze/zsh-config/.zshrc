ZSH_CONFIG_DIR=~/Developer/dotfiles-hd/setup/mac-blaze/zsh-config

# [ZSH/System Config]
# --------------------------------------------------------------------------------------------------------
source $ZSH_CONFIG_DIR/prompt.zsh

# [Tooling]
# --------------------------------------------------------------------------------------------------------
source $ZSH_CONFIG_DIR/tooling.zsh

# [Aliases]
# --------------------------------------------------------------------------------------------------------
source $ZSH_CONFIG_DIR/alias.zsh

# [Functions]
# --------------------------------------------------------------------------------------------------------
source $ZSH_CONFIG_DIR/functions.zsh

# [Kubernetes Config]
# --------------------------------------------------------------------------------------------------------
source $ZSH_CONFIG_DIR/k8s.zsh

# [Job Config]
# --------------------------------------------------------------------------------------------------------
source $ZSH_CONFIG_DIR/job.zsh

source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

export TERM=xterm-256color
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

export PATH="/opt/homebrew/opt/llvm@14/bin:$PATH"

# pnpm
export PNPM_HOME="/Users/hameldesai/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end


RED="\033[31m"
RESET="\033[0m"

echo -e "\n${RED}🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥${RESET}"
echo -e "${RED}🔥          Blaze AI          🔥${RESET}"
echo -e "${RED}🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥${RESET}\n"

fastfetch

# Add paths to environment variables
PATH=~/.console-ninja/.bin:$PATH
