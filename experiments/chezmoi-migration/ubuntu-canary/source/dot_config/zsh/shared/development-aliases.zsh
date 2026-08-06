# Portable aliases for full development profiles.

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
alias docker-nuke='[ -n "$(docker ps -aq)" ] && docker rm -f $(docker ps -aq); [ -n "$(docker volume ls -q)" ] && docker volume rm -f $(docker volume ls -q); [ -n "$(docker images -q)" ] && docker rmi -f $(docker images -q); docker builder prune -a -f'
if (( $+commands[lazydocker] )); then
  alias ld='lazydocker'
fi

## Kubernetes
alias kc='kubectl'
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

## System
alias ff='fastfetch'
if (( $+commands[bat] )); then
  alias cat='bat --paging never --theme Nord'
fi

## Terraform
alias tf='terraform'

## Golang
alias gomod='go mod'
alias gomodt='go mod tidy'
alias gomodv='go mod vendor'
alias got='go run $(ls cmd/web/*.go | grep -v "_test.go")'
alias coverage='go test -coverprofile=coverage.out ./... && go tool cover -html=coverage.out'

## Snitch
alias sn='snitch'
alias snl='snitch -l'
alias snt='snitch -t'
alias sne='snitch -e'
alias snls='snitch ls'
alias snll='snitch ls -l'
alias snle='snitch ls -e'
alias snlte='snitch ls -t -e'
alias snlp='snitch ls -p'
alias snj='snitch json'
alias snw='snitch watch'
alias snth='snitch themes'

## Tmux
alias tm='tmux'
alias tma='tmux attach-session'
alias tmat='tmux attach-session -t'
alias tmks='tmux kill-session -t'
alias tml='tmux list-sessions'
alias tmn='tmux new-session'
alias tmns='tmux new -s'
alias tms='tmux new-session -s'
alias tmk='tmux kill-server'
