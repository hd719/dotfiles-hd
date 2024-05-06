# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# [ZSH/System Config]
# --------------------------------------------------------------------------------------------------------
autoload -U +X bashcompinit && bashcompinit
PATH=~/.console-ninja/.bin:$PATH
# pnpm
export PNPM_HOME="/home/hameldesai/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# [NVM Config]
# --------------------------------------------------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
# nvm use system; nvm use 18.16.0;
# --------------------------------------------------------------------------------------------------------

# [Prompt]
# --------------------------------------------------------------------------------------------------------
eval "$(oh-my-posh --init --shell zsh --config ~/.poshthemes/kushal.omp.json)"

# eval "$(starship init zsh)"
# export STARSHIP_CONFIG=~/starship.toml
# source ~/Developer/powerlevel10k/powerlevel10k.zsh-theme
source ~/Developer/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source /home/hameldesai/Developer/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/Developer/zsh-history-substring-search/zsh-history-substring-search.zsh
source ~/Developer/zsh-z/zsh-z.plugin.zsh
source ~/Developer/zsh-you-should-use/you-should-use.plugin.zsh
# --------------------------------------------------------------------------------------------------------

# [Job Config]
# --------------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------------

# [Aliases]
# --------------------------------------------------------------------------------------------------------

export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin

# [Kubernetes Config]
export KUBE_EDITOR='code --wait'
alias kubectl="kubecolor"
command -v kubecolor >/dev/null 2>&1 && alias kubectl="kubecolor"

# Npm
alias npb='npm run build'
alias npp='npm run prettier'
alias nps='npm run start'
alias npserve='npm run serve'
alias npserved='npm run serve:dev'
alias npt='npm run test'

# Node
alias fucknode='rm -rf node_modules'

# Docker
alias dockercleanup='docker system prune --force'
alias dockerkill='docker kill $(docker ps -a -q)'

# Kubernetes
alias kc=kubectl
alias kca='kc apply -f'
alias kcdel='kc delete'
alias kcdes='kc describe'
alias kcg='kc get'
alias kcgnet='kcg networkPolicy'
alias kcgpod='kcg pods'

# Git
alias g=git
alias gadd='git add .'
alias gba='git branch -a'
alias gclean='git branch --merged develop | grep -v develop | grep -v master | xargs git branch -D'
alias gcm='git commit -a -m'
alias gdeletemerged='$PATH_TO_REPOS/dev-tools/git-delete-merged-branches.sh'
alias gdeletesquashed='$PATH_TO_REPOS/dev-tools/git-delete-squashed-branches.sh'
alias gdiff='git diff'
alias gitprune='gdeletemerged && gdeletesquashed'
alias ghd='gcm --no-verify'
alias glast='git checkout - && gpp'
alias glist='git branch --merged develop | grep -v develop | grep -v master'
alias gnew='git checkout -b'
alias gpp='gpull && gprune'
alias gprune='git fetch --prune'
alias gpublish='git push -u origin $(git rev-parse --abbrev-ref HEAD)'
alias gpull='git pull'
alias gpush='git push'
alias gs='git status'
alias gsoft='git reset --soft HEAD~1'
alias gss='git status'
alias gsshort='gss | grep -e "Your branch" -e "modified"'

# Mongo
alias logs-mongo='cat /opt/homebrew/var/log/mongodb/mongo.log'

# Misc
alias home='cd ~'
alias c=clear
alias ll='ls -a -l'
alias open-desktop='cd ~/Desktop/ && open .'
alias open-home='cd ~ && open .'
alias dhd='cd ~/Developer/dotfiles-hd && code .'
alias open-zshrc='code ~/.zshrc'

# Brew
alias open-brew='cd /opt/homebrew'

# Terraform
alias tf=terraform

# Golang
alias go=go
alias gomod=go mod
alias gomodt=go mod tidy
alias gomodv=go mod vendor
alias got='go run $(ls cmd/web/*.go | grep -v '_test.go')'
alias coverage='go test -coverprofile=coverage.out ./... && go tool cover -html=coverage.out'

# VSCode
alias code-restart="killall electron && killall node && killall code"

# LSD https://github.com/lsd-rs/lsd
alias ls='lsd'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'
# --------------------------------------------------------------------------------------------------------

# [Functions]
# --------------------------------------------------------------------------------------------------------
killport() {
    if [[ $# -ne 1 ]]; then
        print "Add a port number to kill the process on that port. Example: killport 3000"
        return 1
    fi

    local port="$1"
    local pid=$(lsof -ti tcp:"$port")

    if [[ -z $pid ]]; then
        print "No process found on port $port"
        return 1
    else
        print "Killing process on port $port"
        echo "$pid" | xargs kill -9
    fi
}

# Updates brew packages, pulls down latest code for all repos, and reloads this profile to pick up changes
goodMorning() {
  brew update && brew upgrade
}
# --------------------------------------------------------------------------------------------------------
PATH=~/.console-ninja/.bin:$PATH

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
