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
# nvm
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
# nvm end

# [Docker]
# --------------------------------------------------------------------------------------------------------
# Lazy load docker completions
docker() {
    unset -f docker
    fpath=(/Users/hameldesai/.docker/completions $fpath)
    autoload -Uz compinit
    compinit
    docker "$@"
}
