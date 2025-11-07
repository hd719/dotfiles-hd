ZSH_CONFIG_DIR=~/Developer/dotfiles-hd/setup/mac-vm/zsh-config

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

# [Syntax Highlighting]
# --------------------------------------------------------------------------------------------------------
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# [Autosuggestions]
# --------------------------------------------------------------------------------------------------------
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# [Completion System - Must load before using compdef]
# --------------------------------------------------------------------------------------------------------
autoload -Uz compinit
compinit

# [Job Config]
# --------------------------------------------------------------------------------------------------------
export PATH="/opt/homebrew/opt/curl/bin:$PATH"
fpath=(/Users/hameldesai/.docker/completions $fpath)
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
. "$HOME/.local/bin/env"
eval "$(uv generate-shell-completion zsh)"
eval "$(op completion zsh)"; compdef _op op

# [AWS Config]
alias aws-config="aws configure list"
# List available profiles
alias aws-profiles="aws configure list-profiles"
# # Select profile w/ env var
# $ AWS_PROFILE=dev aws s3 ls
# # Select profile w/ option
# $ aws --profile s3 ls

# [Repos]
alias cdplat='cd ~/Developer/Resilience/resilience-platform'
alias cdparg='cd ~/Developer/Resilience/resilience-pargasite'

# [Platform Development]
# Backend: Start all Docker containers (postgres, hasura, redis, data-connector, proxies)
alias res-plat-be="cd ~/Developer/Resilience/resilience-platform && bash docker/rsw-initup latest"

# Proxies (Dev Mode): Start both proxies with hot reloading for development
# Note: Using op run for both proxies in background is complex, run them separately instead with res-platproxy-web and res-platproxy-rsc
alias res-plat-proxy="cd ~/Developer/Resilience/resilience-platform/apps/resilience-security-workbench-proxy && GITHUB_TOKEN=op://Employee/GITHUB_TOKEN/credential op run -- yarn workbench-proxy & GITHUB_TOKEN=op://Employee/GITHUB_TOKEN/credential op run -- yarn client-portal-proxy &"

# Or separate (recommended)
alias res-plat-proxy-web="cd ~/Developer/Resilience/resilience-platform/apps/resilience-security-workbench-proxy && GITHUB_TOKEN=op://Employee/GITHUB_TOKEN/credential op run -- yarn workbench-proxy"
alias res-plat-proxy-rsc="cd ~/Developer/Resilience/resilience-platform/apps/resilience-security-workbench-proxy && GITHUB_TOKEN=op://Employee/GITHUB_TOKEN/credential op run -- yarn client-portal-proxy"

# Frontend: Start the web application(s) - need to check what's in your web app
# Injects GITHUB_TOKEN from 1Password before running yarn dev
alias res-plat-fe="cd ~/Developer/Resilience/resilience-platform/apps/resilience-security-workbench-web && GITHUB_TOKEN=op://Employee/GITHUB_TOKEN/credential op run -- yarn dev"

# Stop/Down: Stop all Docker containers
alias res-plat-down="cd ~/Developer/Resilience/resilience-platform && bash docker/rsw down"

# Logs: View Docker logs
alias res-plat-logs="cd ~/Developer/Resilience/resilience-platform && bash docker/rsw logs -f"

# Status: Check what's running
alias res-plat-status="cd ~/Developer/Resilience/resilience-platform && bash docker/rsw ps"

# [Tmux Platform Session Aliases]
alias tm-plat-fe="~/Developer/dotfiles-hd/setup/mac-resilience/tmux/platform/tm-fe.sh"
alias tm-plat-proxy="~/Developer/dotfiles-hd/setup/mac-resilience/tmux/platform/tm-ed.sh"
alias tm-plat-be="~/Developer/dotfiles-hd/setup/mac-resilience/tmux/platform/tm-be.sh"
alias tm-plat="~/Developer/dotfiles-hd/setup/mac-resilience/tmux/platform/tm-platform.sh"

# Build all workspace packages (run after install or pulling changes to internal packages)
alias res-plat-build="cd ~/Developer/Resilience/resilience-platform && GITHUB_TOKEN=op://Employee/GITHUB_TOKEN/credential op run -- yarn build"
# Install dependencies with proper authentication
alias res-plat-install="cd ~/Developer/Resilience/resilience-platform && GITHUB_TOKEN=op://Employee/GITHUB_TOKEN/credential op run -- yarn install"

# [Pargasite Development]
# Note: Pargasite depends on Platform's backend (postgres, hasura, proxy) - run res-plat-be first!

# Bootstrap: Install all packages including Playwright (first time setup)
alias res-parg-bootstrap="cd ~/Developer/Resilience/resilience-pargasite && GITHUB_TOKEN=op://Employee/GITHUB_TOKEN/credential op run -- yarn bootstrap"

# Doppler Setup: Configure environment variables (first time setup)
alias res-parg-doppler="cd ~/Developer/Resilience/resilience-pargasite && yarn run doppler-setup-dev"

# Git Hooks: Setup linting, formatting, and tests (first time setup)
alias res-parg-hooks="cd ~/Developer/Resilience/resilience-pargasite && yarn init-git-hooks"

# Build: Build all packages (run after install or pulling package changes)
alias res-parg-build="cd ~/Developer/Resilience/resilience-pargasite && GITHUB_TOKEN=op://Employee/GITHUB_TOKEN/credential op run -- yarn build"

# Install: Install dependencies
alias res-parg-install="cd ~/Developer/Resilience/resilience-pargasite && GITHUB_TOKEN=op://Employee/GITHUB_TOKEN/credential op run -- yarn install"

# Dev: Run all apps in parallel (client-suite on :3003, arc on :4004, etc.)
alias res-parg-dev="cd ~/Developer/Resilience/resilience-pargasite && GITHUB_TOKEN=op://Employee/GITHUB_TOKEN/credential op run -- yarn dev"

# Client Suite: Run only the client-suite app (port 3003)
alias res-parg-client="cd ~/Developer/Resilience/resilience-pargasite/apps/client-suite && GITHUB_TOKEN=op://Employee/GITHUB_TOKEN/credential op run -- yarn dev"

# Arc: Run only the arc app (port 4004)
alias res-parg-arc="cd ~/Developer/Resilience/resilience-pargasite/apps/arc && GITHUB_TOKEN=op://Employee/GITHUB_TOKEN/credential op run -- yarn dev"

# Cyber Risk Calculator: Run only the cyber-risk-calculator app
alias res-parg-calc="cd ~/Developer/Resilience/resilience-pargasite/apps/cyber-risk-calculator && GITHUB_TOKEN=op://Employee/GITHUB_TOKEN/credential op run -- yarn dev"

# GraphQL: Refresh GraphQL schema and codegen
alias res-parg-gql="cd ~/Developer/Resilience/resilience-pargasite && GITHUB_TOKEN=op://Employee/GITHUB_TOKEN/credential op run -- yarn refresh-gql"

# [Tmux Pargasite Session Aliases]
alias tm-parg-client="~/Developer/dotfiles-hd/setup/mac-resilience/tmux/pargasite/tm-client.sh"
alias tm-parg-arc="~/Developer/dotfiles-hd/setup/mac-resilience/tmux/pargasite/tm-arc.sh"
alias tm-parg-calc="~/Developer/dotfiles-hd/setup/mac-resilience/tmux/pargasite/tm-calc.sh"
alias tm-parg="~/Developer/dotfiles-hd/setup/mac-resilience/tmux/pargasite/tm-pargasite.sh"

# [Pull all repos on dev branch]
gda() {
  startdir=$(pwd)

  # Function to update a single repo
  update_repo() {
    local repo_path="$1"
    local repo_name="$2"
    echo "****** Pulling $repo_name ******"
    cd "$repo_path" && git checkout dev && git pull origin dev
  }

  # Run all updates sequentially (no background processes)
  update_repo ~/Developer/Resilience/resilience-platform "Resilience Platform"
  update_repo ~/Developer/Resilience/resilience-pargasite "Resilience Pargasite"

  cd "$startdir"
}

goodMorning() {
  echo "🙏 Om Shree Ganeshaya Namaha 🙏"

  # Skip Homebrew updates if hostname contains 'virtual' (case insensitive)
  if [[ ! "$(hostname)" =~ [Vv]irtual ]]; then
    # Optional flag for Homebrew updates
    if [[ "$1" != "--no-brew" ]]; then
      echo "Updating Homebrew..."
      brew update
      if brew outdated | grep -q .; then
        brew upgrade --greedy
        brew cleanup
        brew autoremove
      else
        echo "No Homebrew packages to upgrade"
      fi
    fi
  else
    echo "Skipping Homebrew update (virtual environment detected)"
  fi

  echo "Updating Git repositories..."
  gda
  echo "🙏 Om Shree Ganeshaya Namaha 🙏"
}
