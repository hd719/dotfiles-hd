# [GIT]
# --------------------------------------------------------------------------------------------------------
export GIT_EDITOR="cursor --wait"
export EDITOR="cursor --wait"

# [PNPM]
# --------------------------------------------------------------------------------------------------------
# pnpm
export PNPM_HOME="/Users/hameldesai/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# [NVM]
# --------------------------------------------------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
