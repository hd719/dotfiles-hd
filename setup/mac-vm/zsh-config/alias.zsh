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
alias docker-nuke='[ -n "$(docker ps -aq)" ] && docker rm -f $(docker ps -aq); [ -n "$(docker volume ls -q)" ] && docker volume rm -f $(docker volume ls -q); [ -n "$(docker images -q)" ] && docker rmi -f $(docker images -q); docker builder prune -a -f'
alias ld="lazydocker"

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
alias open-desktop='cd ~/Desktop/ && open .'
alias open-home='cd ~ && open .'
alias dhd='cd ~/Developer/dotfiles-hd && code .'
alias open-zshrc='code ~/.zshrc'
alias ff='fastfetch'
alias r='reload'

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

## LSD - Modern ls replacement with colors and icons
alias ls='lsd --tree --depth 1'
alias lss='lsd --tree --depth 2'
alias lsss='lsd --tree --depth 3'
alias ll='lsd -la --tree --depth 1'
alias l='lsd -l'
alias la='lsd -a'

## Bat
alias cat="bat --paging never --theme Dracula"

## Snitch - Network connection inspector (https://github.com/karol-broda/snitch)
alias sn='snitch'                    # Interactive TUI (all connections)
alias snl='snitch -l'                # TUI - listening sockets only
alias snt='snitch -t'                # TUI - TCP only
alias sne='snitch -e'                # TUI - established only
alias snls='snitch ls'               # One-shot styled table
alias snll='snitch ls -l'            # One-shot - listening only
alias snle='snitch ls -e'            # One-shot - established only
alias snlte='snitch ls -t -e'        # One-shot - TCP established
alias snlp='snitch ls -p'            # Plain output (parsable)
alias snj='snitch json'              # JSON output for scripting
alias snw='snitch watch'             # Stream JSON frames
alias snth='snitch themes'           # List available themes

## SSH
alias blaze="ssh hamels-macbook-pro-2"
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
alias tmks='tmux kill-session -t'           # Kill all tmux sessions
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
alias refresh-global='eval "$(devbox global shellenv --preserve-path-stack -r)" && hash -r'  # Refresh Devbox global environment

#Tailscale
alias tailscale="cd ~/go/bin; ./tailscale up --advertise-exit-node --ssh; ./tailscale status"

# Blaze
alias ble='export ZSH_PROFILE=blaze && source ~/.zshrc'

# Monorepo Devbox Scripts (scripts defined in devbox.json)
# --------------------------------------------------------------------------------------------------------

# HealthMetrics (runs from nextjs-monorepo directory where devbox.json defines these scripts)
alias hm-dev='(cd ~/Developer/nextjs-monorepo && devbox run hm:dev)'
alias hm-build='(cd ~/Developer/nextjs-monorepo && devbox run hm:build)'
alias hm-prisma-studio='(cd ~/Developer/nextjs-monorepo && devbox run hm:prisma:studio)'
alias hm-prisma-migrate='(cd ~/Developer/nextjs-monorepo && devbox run hm:prisma:migrate)'
alias hm-prisma-generate='(cd ~/Developer/nextjs-monorepo && devbox run hm:prisma:generate)'
alias hms-dev='cd ~/Developer/nextjs-monorepo/apps/healthmetrics && go run main.go'
alias hms-build='cd ~/Developer/nextjs-monorepo/apps/healthmetrics && go build -o healthmetrics main.go'
alias hms-test='cd ~/Developer/nextjs-monorepo/apps/healthmetrics && go test ./...'

# Run bun/bunx commands in healthmetrics with 1Password env vars loaded
# Usage: hm-bun run dev | hm-bunx prisma migrate diff ...
# Uses devbox run to ensure bun is in PATH
hm-bun() {
  (cd ~/Developer/nextjs-monorepo && devbox run -- bash -c "cd apps/healthmetrics && op run --env-file='./.env.development.local' -- bun $*")
}
hm-bunx() {
  (cd ~/Developer/nextjs-monorepo && devbox run -- bash -c "cd apps/healthmetrics && op run --env-file='./.env.development.local' -- bunx $*")
}

# Portfolio (runs from nextjs-monorepo directory where devbox.json defines these scripts)
alias pf-dev='(cd ~/Developer/nextjs-monorepo && devbox run pf:dev)'
alias pf-build='(cd ~/Developer/nextjs-monorepo && devbox run pf:build)'
alias pf-start='(cd ~/Developer/nextjs-monorepo && devbox run pf:start)'
alias pf-lint='(cd ~/Developer/nextjs-monorepo && devbox run pf:lint)'
