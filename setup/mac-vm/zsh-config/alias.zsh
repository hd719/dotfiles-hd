# [Aliases]
# --------------------------------------------------------------------------------------------------------

## Mac defaults
alias reset-finder="defaults write com.apple.finder CreateDesktop -bool true; killall Finder; open /System/Library/CoreServices/Finder.app"
alias reset-dock="defaults write com.apple.dock autohide -bool false; killall Dock"

## Npm
alias npb='npm run build'
alias npp='npm run prettier'
alias nps='npm run start'
alias npserve='npm run serve'
alias npserved='npm run serve:dev'
alias npt='npm run test'

## Node
alias fucknode='rm -rf node_modules'

## Docker
alias dockercleanup='docker system prune --force'
alias dockerkill='docker kill $(docker ps -a -q)'
alias usedocker='docker context use desktop-linux'
alias docker-nuke='docker rm -f $(docker ps -aq) && docker volume rm -f $(docker volume ls -q) && docker rmi -f $(docker images -q) && docker builder prune -a -f'

## Kubernetes
alias kc=kubectl
alias kca='kc apply -f'
alias kcdel='kc delete'
alias kcdes='kc describe'
alias kcg='kc get'
alias kcgnet='kcg networkPolicy'
alias kcgpod='kcg pods'

## Git
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

## Misc
alias home='cd ~'
alias c=clear
alias ll='ls -a -l'
alias open-desktop='cd ~/Desktop/ && open .'
alias open-home='cd ~ && open .'
alias dhd='cd ~/Developer/dotfiles-hd && code .'
alias open-zshrc='code ~/.zshrc'

## Brew
alias open-brew='cd /opt/homebrew'

## Terraform
alias tf=terraform

## Golang
alias go=go
alias gomod=go mod
alias gomodt=go mod tidy
alias gomodv=go mod vendor
alias got='go run $(ls cmd/web/*.go | grep -v "_test.go")'
alias coverage='go test -coverprofile=coverage.out ./... && go tool cover -html=coverage.out'

## VSCode
alias code-restart="killall electron && killall node && killall code"

## LSD
alias ls='lsd'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'

## Bat
alias cat="bat --paging never --theme Dracula"

## SSH
alias blaze="ssh hamels-macbook-pro-2-1"
alias hosts="awk '/^Host / {print \$2}' ~/.ssh/config"

## Nix
alias switch="sudo darwin-rebuild switch --flake ~/Developer/dotfiles-hd/setup/mac-vm/darwin/nix#hameldesai" # sudo temporarily (will change in future)
alias nix-update="nix flake update"
# Alias: List all system generations
alias nix-gen-list='sudo nix-env --list-generations --profile /nix/var/nix/profiles/system'

# Alias: List all system generations (as before)
alias nix-gen-list='sudo nix-env --list-generations --profile /nix/var/nix/profiles/system'

# Alias: Delete old generations older than 7 days
alias nix-gen-clean='sudo nix-collect-garbage --delete-older-than 7d'

# Tmux
alias tm='tmux'                             # Start tmux
alias tma='tmux attach-session'             # Attach to a tmux session
alias tmat='tmux attach-session -t'         # Attach to a tmux session with name
alias tmks='tmux kill-session -a'           # Kill all tmux sessions
alias tml='tmux list-sessions'              # List tmux sessions
alias tmn='tmux new-session'                # Start a new tmux session
alias tmns='tmux new -s'                    # Start a new tmux session with name
alias tms='tmux new-session -s'             # Start a new tmux session
alias tmk='tmux kill-server'                # Kill all tmux sessions

# Devbox
alias dbshell='devbox shell'       # Enter the Devbox environment
alias dbup='devbox up'             # Start the Devbox environment
alias dbdown='devbox down'         # Stop the Devbox environment
alias dbrm='devbox rm'             # Remove the Devbox environment
alias dbls='devbox ls'             # List all available Devbox environments
alias dbinit='devbox init'         # Initialize a new Devbox environment
alias dbbuild='devbox build'       # Build/compile the Devbox environment
alias dbrun='devbox run'           # Run a command inside the Devbox environment
alias dbps='devbox ps'             # Show running processes in Devbox
alias dblogs='devbox logs'         # Display logs for the Devbox environment
alias dbconfig='devbox config'     # Open the configuration for Devbox
alias dbhelp='devbox help'         # Show help information for Devbox

#Tailscale
alias tailscale="cd ~/go/bin; ./tailscale up --advertise-exit-node --ssh; ./tailscale status"

# Blaze
alias ble='export ZSH_PROFILE=blaze && source ~/.zshrc'
