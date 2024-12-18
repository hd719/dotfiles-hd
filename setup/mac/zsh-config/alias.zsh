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
alias cat="bat --paging never --theme ansi"

## SSH
alias axio="ssh -L 27018:localhost:27018 ssh -L 27017:localhost:27017 -L 3000:localhost:3000 -L 3001:localhost:3001 -L 3002:localhost:3002 -L 4000:localhost:4000 -L 5432:localhost:5432 -L 8080:localhost:8080 axiombp-7g77nn4-hamel"

## Nix
alias switch="darwin-rebuild switch --flake ~/Developer/dotfiles-hd/setup/mac/darwin/nix#hameldesai"
alias nix-update="nix flake update"

# Tmux
alias tm='tmux'                             # Start tmux
alias tma='tmux attach-session'             # Attach to a tmux session
alias tmat='tmux attach-session -t'         # Attach to a tmux session with name
alias tmks='tmux kill-session -a'           # Kill all tmux sessions
alias tml='tmux list-sessions'              # List tmux sessions
alias tmn='tmux new-session'                # Start a new tmux session
alias tmns='tmux new -s'                    # Start a new tmux session with name
alias tms='tmux new-session -s'             # Start a new tmux session

# Obsidian CLI
alias obshelp='obsidian-cli --help'                    # Print help
alias obsset='obsidian-cli set-default'                # Set default vault
alias obsdefault='obsidian-cli print-default'          # Print default vault
alias obsopen='obsidian-cli open'                      # Open note in default vault
alias obsopenvault='obsidian-cli open--vault'          # Open note in specified vault
alias obssearch='obsidian-cli search'                  # Search in default vault
alias obssearchvault='obsidian-cli search--vault'      # Search in specified vault
alias obscreate='obsidian-cli create'                  # Create empty note in default vault and open it
alias obscreatevault='obsidian-cli create--vault'      # Create empty note in specified vault and open it
alias obscreatec='obsidian-cli create--content'        # Create note with content in default vault
alias obscreateow='obsidian-cli create--content--overwrite' # Create note with content and overwrite existing note
alias obscreateap='obsidian-cli create--content--append'    # Create note with content and append to existing note
alias obscreateo='obsidian-cli create--content--open'       # Create note with content and open it
alias obsmove='obsidian-cli move'                      # Rename note in default vault
alias obsmovevault='obsidian-cli move--vault'          # Rename note in specified vault
alias obsmoveo='obsidian-cli move--open'               # Rename note in default vault and open it
alias obsdel='obsidian-cli delete'                     # Delete note in default vault
alias obsdelvault='obsidian-cli delete--vault'         # Delete note in specified vault
# Aliases for Devbox CLI commands using 'db' instead of 'devbox'

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
