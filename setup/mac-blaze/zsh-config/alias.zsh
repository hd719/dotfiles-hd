# [Aliases]
# --------------------------------------------------------------------------------------------------------

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

## Nix
alias switch="darwin-rebuild switch --flake ~/Developer/dotfiles-hd/setup/mac/darwin/nix#hameldesai"
alias nix-update="nix flake update"

#Tailscale
alias tailscale="cd ~/go/bin; ./tailscale up --advertise-exit-node --ssh"

# Tmux
alias tm='tmux'                             # Start tmux
alias tma='tmux attach-session'             # Attach to a tmux session
alias tmat='tmux attach-session -t'         # Attach to a tmux session with name
alias tmks='tmux kill-session -a'           # Kill all tmux sessions
alias tml='tmux list-sessions'              # List tmux sessions
alias tmn='tmux new-session'                # Start a new tmux session
alias tmns='tmux new -s'                    # Start a new tmux session with name
alias tms='tmux new-session -s'             # Start a new tmux session
alias tmk='tmux kill-server'

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

# Blaze
alias hydrate-s3-dev="bin/rails restore_db_and_index:from_s3"
alias hydrate-s3-prod="bin/rails restore_db_and_index:from_live_production"
# — this will download pre-sanitized data from S3 and restore it locally. It will then clear the Algolia indices, and reindex them. Make sure redis is running before this or the index step will fail! Alternatively, you can run bin/rails restore_db_and_index:from_live_production to get a fresh copy of prod, sanitize it, and restore it locally. This method will take multiple hours, so only use if the s3 dump is broken (Please notify engineering channel if this is the case so we can fix it).
alias run-migration="bin/rails db:migrate RAILS_ENV=development"
alias it-be="~/Developer/dotfiles-hd/setup/mac-blaze/zsh-config/scripts/iterm/it-be.sh"
alias it-ed="~/Developer/dotfiles-hd/setup/mac-blaze/zsh-config/scripts/iterm/ie-ed.sh"
alias it-fe="~/Developer/dotfiles-hd/setup/mac-blaze/zsh-config/scripts/iterm/it-fe.sh"
alias tm-fe="~/Developer/dotfiles-hd/setup/mac-blaze/zsh-config/scripts/tmux/tm-fe.sh"
alias tm-ed="~/Developer/dotfiles-hd/setup/mac-blaze/zsh-config/scripts/tmux/tm-ed.sh"
alias tm-be="~/Developer/dotfiles-hd/setup/mac-blaze/zsh-config/scripts/tmux/tm-be.sh"
alias tm-all="~/Developer/dotfiles-hd/setup/mac-blaze/zsh-config/scripts/tmux/tm-all.sh"
alias console-dev="heroku run rails c -a blaze-ai-rails"
alias console-prod="heroku run rails c -a blaze-ai-rails"

## Repos
alias cdalmanac='cd ~/Developer/Blaze/almanac-editor'
alias cdblazeonrails='cd ~/Developer/Blaze/blaze-on-rails'
alias cdmonospace='cd ~/Developer/Blaze/monospace'
alias cdprosecore='cd ~/Developer/Blaze/prose-core'

## Rails
alias be="bundle exec"
alias r="bundle exec rails"
alias rs="bundle exec rails s"
alias rc="bundle exec rails c"
alias rr="bundle exec rails routes"
alias rdbm="bundle exec rails db:migrate"
alias rdbs="bundle exec rails db:schema:load"
alias rdbmr="bundle exec rails db:rollback"
alias rdbr="bundle exec rake db:reset"

## Rails Environment
alias rdbmdev="bundle exec rails db:migrate RAILS_ENV=development"
alias rdbmprod="bundle exec rails db:migrate RAILS_ENV=production"
alias rdbmrdev="bundle exec rails db:rollback RAILS_ENV=development"
alias rdbmrprod="bundle exec rails db:rollback RAILS_ENV=production"
