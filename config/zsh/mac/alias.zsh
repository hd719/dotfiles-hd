# [Shared Mac Aliases]
# --------------------------------------------------------------------------------------------------------

typeset mac_aliases_file="${${(%):-%N}:A}"
source "${mac_aliases_file:h}/base-aliases.zsh"
unset mac_aliases_file

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
alias gclean='git branch --merged develop | grep -v develop | grep -v master | xargs git branch -D'
alias gdeletemerged='$PATH_TO_REPOS/dev-tools/git-delete-merged-branches.sh'
alias gdeletesquashed='$PATH_TO_REPOS/dev-tools/git-delete-squashed-branches.sh'
alias gitprune='gdeletemerged && gdeletesquashed'
alias ghd='gcm --no-verify'
alias glast='git checkout - && gpp'
alias glist='git branch --merged develop | grep -v develop | grep -v master'
alias gsoft='git reset --soft HEAD~1'

## Misc
alias v='nvim'
alias dhd='cd ~/Developer/dotfiles-hd && code .'
alias open-zshrc='code ~/.zshrc'
alias ff='fastfetch'

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
