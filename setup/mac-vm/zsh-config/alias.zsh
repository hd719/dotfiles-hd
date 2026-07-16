# [Aliases]
# --------------------------------------------------------------------------------------------------------

## Mac defaults
alias reset-finder="defaults write com.apple.finder CreateDesktop -bool true; killall Finder; open /System/Library/CoreServices/Finder.app"
alias reset-dock="defaults write com.apple.dock autohide -bool false; killall Dock"

## Pnpm
alias npb='pnpm run build'
alias npp='pnpm run prettier'
alias nps='pnpm run start'
alias npserve='pnpm run serve'
alias npserved='pnpm run serve:dev'
alias npt='pnpm run test'

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
alias gsshort='gs | grep -e "Your branch" -e "modified"'

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
alias gomod=go mod
alias gomodt=go mod tidy
alias gomodv=go mod vendor
alias got='go run $(ls cmd/web/*.go | grep -v "_test.go")'
alias coverage='go test -coverprofile=coverage.out ./... && go tool cover -html=coverage.out'

## VSCode
alias code-restart="killall electron && killall node && killall code"

## LSD - Modern ls replacement with colors and icons
source "$ZSH_CONFIG_DIR/../../../config/zsh/lsd-aliases.zsh"

## Bat
alias cat="bat --paging never --theme Nord"

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

alias refresh-global='/opt/homebrew/bin/mise install && /opt/homebrew/bin/mise reshim && hash -r'

# OpenClaw
alias opdash='lsof -ti:18789 | xargs kill -9 2>/dev/null; ssh -L 18789:127.0.0.1:18789 hd@100.120.198.12 -f -N && open "http://127.0.0.1:18789/#token=$(op read "op://Development/OpenClaw-Gateway-Token/password")"'


# Monorepo Shell Scripts
# --------------------------------------------------------------------------------------------------------

# HealthMetrics
alias hm-dev='(cd ~/Developer/nextjs-monorepo/apps/healthmetrics && op run --env-file="./.env.development.local" -- bun run dev)'
alias hm-build='(cd ~/Developer/nextjs-monorepo/apps/healthmetrics && op run --env-file="./.env.development.local" -- bun run build)'
alias hm-prisma-studio='(cd ~/Developer/nextjs-monorepo/apps/healthmetrics && op run --env-file="./.env.development.local" -- bunx prisma studio)'
alias hm-prisma-migrate='(cd ~/Developer/nextjs-monorepo/apps/healthmetrics && op run --env-file="./.env.development.local" -- bunx prisma migrate dev)'
alias hm-prisma-generate='(cd ~/Developer/nextjs-monorepo/apps/healthmetrics && op run --env-file="./.env.development.local" -- bunx prisma generate)'
alias hms-dev='cd ~/Developer/nextjs-monorepo/apps/healthmetrics && go run main.go'
alias hms-build='cd ~/Developer/nextjs-monorepo/apps/healthmetrics && go build -o healthmetrics main.go'
alias hms-test='cd ~/Developer/nextjs-monorepo/apps/healthmetrics && go test ./...'

# Run bun/bunx commands in healthmetrics with 1Password env vars loaded
# Usage: hm-bun run dev | hm-bunx prisma migrate diff ...
hm-bun() {
  (cd ~/Developer/nextjs-monorepo/apps/healthmetrics && op run --env-file="./.env.development.local" -- bun "$@")
}
hm-bunx() {
  (cd ~/Developer/nextjs-monorepo/apps/healthmetrics && op run --env-file="./.env.development.local" -- bunx "$@")
}

# Portfolio
alias pf-dev='(cd ~/Developer/nextjs-monorepo/apps/portfolio && bun run dev)'
alias pf-build='(cd ~/Developer/nextjs-monorepo/apps/portfolio && bun run build)'
alias pf-start='(cd ~/Developer/nextjs-monorepo/apps/portfolio && bun run start)'
alias pf-lint='(cd ~/Developer/nextjs-monorepo/apps/portfolio && bun run lint)'
