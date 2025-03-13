# [ZSH/System Config]
# --------------------------------------------------------------------------------------------------------
# if [ -z "$TMUX" ]; then
#     tmux attach -t default || tmux new -s default
# fi
export TERM=xterm-256color
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm use 21.6.2;
aws configure set profile default
eval "$(/opt/homebrew/bin/brew shellenv)"
autoload -Uz compinit && compinit
if type brew &>/dev/null
then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi
autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /opt/homebrew/bin/terraform terraform
source /Users/hameldesai/.docker/init-zsh.sh || true # Added by Docker Desktop

# [Kubernetes Config]
# --------------------------------------------------------------------------------------------------------
export KUBE_EDITOR='code --wait'
alias kubectl="kubecolor"
command -v kubecolor >/dev/null 2>&1 && alias kubectl="kubecolor"
# --------------------------------------------------------------------------------------------------------

# [Prompt]
# --------------------------------------------------------------------------------------------------------
eval "$(oh-my-posh init zsh --config ~/.config/ohmyposh/base.toml)"
eval "$(zoxide init --cmd cd zsh)"
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/Developer/zsh-you-should-use/you-should-use.plugin.zsh
# --------------------------------------------------------------------------------------------------------

# [Axio Conifig]
# --------------------------------------------------------------------------------------------------------
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export JAVA_HOME=/Users/hameldesai/.sdkman/candidates/java/current
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
export PATH=~/Developer/apache-maven-3.9.4/bin:$PATH
# mvn --version
# java --version

GITLAB_TOKEN=op://Development/Gitlab-Token/password
COGNITO_TOKEN=op://Development/Cognito-Token/password
ADO_TOKEN=op://Development/ADO-Token/password
B64_PAT=op://Development/ADO-Token/password
MY_PAT=op://Development/ADO-Token/password
ADO_GIT_PAT=op://Development/ADO-Git-PAT/password
GOOGLE_APPLICATION_CREDENTIALS="op://Development/Axio-GAC/password"

DOCKER_DEFAULT_PLATFORM=linux/amd64
PATH_TO_REPOS=~/Developer/Axio/
SETUP_USER_ID="${USER}"
PATH_TO_REPOS=/Users/hameldesai/Developer/Axio-ADO/Axio360-Project
EDITOR=${EDITOR:-'code'}
USE_GKE_GCLOUD_AUTH_PLUGIN=true
# --------------------------------------------------------------------------------------------------------

# [Aliases]
# --------------------------------------------------------------------------------------------------------
# Repos
alias adminme='cdadmin && gpp && npm start'
alias appme='cdcl ient && gpp && npm start'
alias appmeclean='cdclient && gpp && fucknode && npm run start'
alias cdstore='cd "$PATH_TO_REPOS/storage" && storage'
alias htmlreportme='cdhtmlreport && gpp && npm run start'

alias cdops='cd ~/Developer/Axio-ADO/Axio-Ops/Axio-Operations'
alias cdzops='cd "$PATH_TO_REPOS/Axio-Ops/z-ops-Axio%20Operations"'
alias cdadmin='cd "$PATH_TO_REPOS/admin-ui" '
alias cdbd='cd "$PATH_TO_REPOS/build-deploy"'
alias cdclient='cd "$PATH_TO_REPOS/client"'
alias cdcypress='cd "$PATH_TO_REPOS/cypress"'
alias cddash='cd "$PATH_TO_REPOS/dashboards"'
alias cddata='cd "$PATH_TO_REPOS/data-science"'
alias cddb='cd "$PATH_TO_REPOS/db_listener"'
alias cddt='cd "$PATH_TO_REPOS/dev-tools"'
alias cdgraphql='cd "$PATH_TO_REPOS/graphql-storage"'
alias cdhtmlreport='cd "$PATH_TO_REPOS/html-report-server"'
alias cdreport='cd "$PATH_TO_REPOS/reporting"'
alias cdservices='cd "$PATH_TO_REPOS/services"'
alias cdstorage='cd "$PATH_TO_REPOS/storage"'
alias cdonerepo='cd "$PATH_TO_REPOS/OneRepo"'

# ADO
alias ado='cd ~/Developer/Axio-ADO'
alias ado-360='cd ~/Developer/Axio-ADO/Axio360-Project'
alias ado-ops='cd ~/Developer/Axio-ADO/Axio-Ops'

# VSCode
alias code-admin-ui='admin-ui && code .'
alias code-client='client && code .'
alias code-cypress='cypress && code .'
alias code-dev-tools='dev-tools && code .'
alias code-docs='docs && code .'
alias code-reporting='reporting && code .'
alias code-storage='storage && code .'

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
alias usedocker="docker context use desktop-linux" # change from orb to docker

# Kubernetes
alias kc=kubectl
alias kca='kc apply -f'
alias kcdel='kc delete'
alias kcdes='kc describe'
alias kcg='kc get'
alias kcgnet='kcg networkPolicy'
alias kcgpod='kcg pods'
alias demo-ctx='gcloud config set project axio-dev-platform; kubectx demo; gcloud auth application-default set-quota-project axio-dev-platform'
alias dev-ctx='gcloud config set project axio-dev-platform; kubectx dev; gcloud auth application-default set-quota-project axio-dev-platform'
alias ll-ctx='gcloud config set project axio-lloyds-lab; kubectx lloyds-lab; gcloud auth application-default set-quota-project axio-lloyds-lab'
alias ops-ctx='gcloud config set project axio-operations;  kubectx ops; gcloud auth application-default set-quota-project axio-operations;'
alias qa-ctx='gcloud config set project axio-qa-platform; kubectx qa; gcloud auth application-default set-quota-project axio-qa-platform'
alias eu-ctx='gcloud config set project axio-eu-platform; kubectx eu; gcloud auth application-default set-quota-project axio-eu-platform'

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
alias gettokenme='TOKEN=$($PATH_TO_REPOS/storage/tests/get_token.sh $COGNITO_USERNAME $COGNITO_PASSWORD) && echo $TOKEN && echo $TOKEN | pbcopy'
alias ts="cd ~/go/bin; ./tailscale"
alias tsd="cd ~/go/bin; sudo ./tailscaled"
alias tss="cd ~/go/bin; ./tailscale serve"

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

# Bat https://github.com/sharkdp/bat
alias cat="bat --paging never --theme ansi"

# Tmux
alias tm='tmux'                             # Start tmux
alias tma='tmux attach-session'             # Attach to a tmux session
alias tmat='tmux attach-session -t'         # Attach to a tmux session with name
alias tmks='tmux kill-session -a'           # Kill all tmux sessions
alias tml='tmux list-sessions'              # List tmux sessions
alias tmn='tmux new-session'                # Start a new tmux session
alias tmns='tmux new -s'                    # Start a new tmux session with name
alias tms='tmux new-session -s'             # Start a new tmux session

# AWS
alias awsdev='export AWS_PROFILE=dev'
alias awsprod='export AWS_PROFILE=default'
# --------------------------------------------------------------------------------------------------------

# [Functions]
# --------------------------------------------------------------------------------------------------------
gpa() {
  startdir=$(pwd);
  echo '******Pulling Client******';
  cdclient && gpp;
  echo '******Pulling Storage******';
  cdstorage && gpp;
  echo '******Pulling Reporting******';
  cdreport && gpp;
  echo '******Pulling HTML-Reporting******';
  cdhtmlreport && gpp;
  echo '******Pulling GraphQL Storage******';
  cdgraphql && gpp;
  echo '******Pulling Data-Science******';
  cddata && gpp;
  echo '******Pulling Cypress******';
  cdcypress && gpp;
  echo '******Pulling Build Deploy******';
  cdbd && gpp;
  echo '******Pulling Admin UI******';
  cdadmin && gpp;
  echo '******Pulling Db-listener ******';
  cddb && gpp;
  echo '******Pulling Dashboards ******';
  cddash && gpp;
  echo '******Pulling OneRepo ******';
  cdonerepo && gpp;
  cd "$startdir";
}

# Pull all repos on master branch
gda() {
  startdir=$(pwd);
  echo '******Pulling Client ******';
  cdclient && git checkout master && gpp;
  echo '******Pulling Storage ******';
  cdstorage && git checkout master && gpp;
  echo '******Pulling Reporting ******';
  cdreport && git checkout master && gpp;
  echo '******Pulling HTML-Reporting ******';
  cdhtmlreport && git checkout develop && gpp;
  echo '******Pulling GraphQL Storage ******';
  cdgraphql && git checkout master && gpp;
  echo '******Pulling Data-Science ******';
  cddata && git checkout master && gpp;
  echo '******Pulling Cypress ******';
  cdcypress && git checkout develop && gpp;
  echo '******Pulling Build Deploy ******';
  cdbd && git checkout master && gpp;
  echo '******Pulling Admin UI ******';
  cdadmin && git checkout master && gpp;
  echo '******Pulling Db-listener ******';
  cddb && git checkout master && gpp;
  echo '******Pulling Dashboards ******';
  cddash && git checkout develop && gpp;
  echo '******Pulling OneRepo ******';
  cdonerepo && git checkout main && gpp;
  cd "$startdir";
}

delete_branch_from_all_services() {
  startdir=$(pwd);
  echo "Enter the branch name to delete:"
  read branch_name

  echo "$branch_name"

  echo '****** Client ******';
  cdclient && git checkout master && git bdd "$branch_name";
  echo '****** Storage ******';
  cdstorage && git checkout master && git bdd "$branch_name";
  echo '****** Reporting ******';
  cdreport && git checkout master && git bdd "$branch_name";
  echo '****** HTML-Reporting ******';
  cdhtmlreport && git checkout develop && git bdd "$branch_name";
  echo '****** GraphQL Storage ******';
  cdgraphql && git checkout master && git bdd "$branch_name";
  echo '****** Data-Science ******';
  cddata && git checkout master && git bdd "$branch_name";
  echo '****** Cypress ******';
  cdcypress && git checkout develop && git bdd "$branch_name";
  echo '****** Build Deploy ******';
  cdbd && git checkout master && git bdd "$branch_name";
  echo '****** Admin UI ******';
  cdadmin && git checkout master && git bdd "$branch_name";
  echo '****** Db-listener ******';
  cddb && git checkout master && git bdd "$branch_name";
  echo '****** Dashboards ******';
  cddash && git checkout develop && git bdd "$branch_name";
  echo '****** OneRepo ******';
  cdonerepo && git checkout main && git bdd "$branch_name";

  cd "$startdir";
}

create_branch_from_all_services() {
  startdir=$(pwd);
  echo "Enter the branch name to create:"
  read branch_name

  echo "$branch_name"

  echo '****** Client ******';
  cdclient && git checkout master && git co -b "$branch_name";
  echo '****** Storage ******';
  cdstorage && git checkout master && git co -b "$branch_name";
  echo '****** Reporting ******';
  cdreport && git checkout master && git co -b "$branch_name";
  echo '****** HTML-Reporting ******';
  cdhtmlreport && git checkout develop && git co -b "$branch_name";
  echo '****** GraphQL Storage ******';
  cdgraphql && git checkout master && git co -b "$branch_name";
  echo '****** Data-Science ******';
  cddata && git checkout master && git co -b "$branch_name";
  echo '****** Admin UI ******';
  cdadmin && git checkout master && git co -b "$branch_name";
  echo '****** Db-listener ******';
  cddb && git checkout master && git co -b "$branch_name";
  echo '****** Dashboards ******';
  cddash && git checkout develop && git co -b "$branch_name";
  echo '****** OneRepo ******';
  cdonerepo && git checkout main && git co -b "$branch_name";

  cd "$startdir";
}

check_repo_for_merged_prs_by_tags() {
  local alias="$1"
  local repo_name="$2"
  local branch_name="$3"

  echo "****** $repo_name ******"
  eval "$alias" && git checkout $branch_name && gpp

  # Get the most recent and second most recent tags starting with "v"
  local recent_tag=$(git describe --tags --abbrev=0 --match="v*" HEAD)
  local second_recent_tag=$(git describe --tags --abbrev=0 --match="v*" HEAD^)

  # Show merge commits between the two tags
  echo "Merge commits between $recent_tag and $second_recent_tag:"
  git log --merges --oneline "$second_recent_tag..$recent_tag"

  # Echo the recent tag and the second most recent tag
  echo "Recent tag: $recent_tag"
  echo "Second most recent tag: $second_recent_tag"
}

check_repo_for_merged_prs_by_dates() {
 local alias="$1"
 local repo_name="$2"
 local branch_name="$3"
 local today_date="$4"
 local from_date="$5"

 echo " "
 echo " "
 echo "****** $repo_name ******"
 eval "$alias" && git checkout $branch_name && gpp

 # Show merge commits between the two Fridays
 echo "Merge commits between $from_date and $today_date:"
 git log --merges --oneline --since="$from_date" --until="$today_date"

 # Echo the dates for the current Friday and the last Friday
 echo "From: $from_date" "|" "To: $today_date"
}

display_prs_by_tags() {
  check_repo_for_merged_prs_by_tags "cdclient" "client" "master"
  check_repo_for_merged_prs_by_tags "cdstorage" "storage" "master"
  check_repo_for_merged_prs_by_tags "cdreport" "report" "master"
  check_repo_for_merged_prs_by_tags "cdhtmlreport" "htmlreport" "develop"
  check_repo_for_merged_prs_by_tags "cdgraphql" "graphql" "master"
  check_repo_for_merged_prs_by_tags "cddata" "data" "master"
  check_repo_for_merged_prs_by_tags "cdcypress" "cypress" "develop"
  check_repo_for_merged_prs_by_tags "cdbd" "bd" "master"
  check_repo_for_merged_prs_by_tags "cdadmin" "admin" "master"
  check_repo_for_merged_prs_by_tags "cddb" "db" "master"
  check_repo_for_merged_prs_by_tags "cddash" "dash" "develop"
  check_repo_for_merged_prs_by_tags "cdonerepo" "OneRepo" "main"
}

display_prs_by_date() {
  echo "To (DD-MM-YYYY):"
  read today_date
  echo "From (DD-MM-YYYY):"
  read from_date

  check_repo_for_merged_prs_by_dates "cdclient" "client" "master" "$today_date" "$from_date"
  check_repo_for_merged_prs_by_dates "cdstorage" "storage" "master" "$today_date" "$from_date"
  check_repo_for_merged_prs_by_dates "cdreport" "report" "master" "$today_date" "$from_date"
  check_repo_for_merged_prs_by_dates "cdhtmlreport" "htmlreport" "develop" "$today_date" "$from_date"
  check_repo_for_merged_prs_by_dates "cdgraphql" "graphql" "master" "$today_date" "$from_date"
  check_repo_for_merged_prs_by_dates "cddata" "data" "master" "$today_date" "$from_date"
  check_repo_for_merged_prs_by_dates "cdcypress" "cypress" "develop" "$today_date" "$from_date"
  check_repo_for_merged_prs_by_dates "cdbd" "bd" "master" "$today_date" "$from_date"
  check_repo_for_merged_prs_by_dates "cdadmin" "admin" "master" "$today_date" "$from_date"
  check_repo_for_merged_prs_by_dates "cddb" "db" "master" "$today_date" "$from_date"
  check_repo_for_merged_prs_by_dates "cddash" "dash" "develop" "$today_date" "$from_date"
  check_repo_for_merged_prs_by_dates "cdonerepo" "OneRepo" "main" "$today_date" "$from_date"
}

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

hex_to_decimal_ip() {
  local hex_ip="$1"

  # Check if a hexadecimal IP is provided
  if [ -z "$hex_ip" ]; then
    echo "Usage: hex_to_decimal_ip <HEX_IP>"
    return 1
  fi

  # Remove '0x' prefix if present
  hex_ip="${hex_ip#0x}"

  # Split the hexadecimal IP into four 2-character segments
  local seg1="${hex_ip:0:2}"
  local seg2="${hex_ip:2:2}"
  local seg3="${hex_ip:4:2}"
  local seg4="${hex_ip:6:2}"

  # Convert each segment from hexadecimal to decimal
  local decimal_seg1=$((16#$seg1))
  local decimal_seg2=$((16#$seg2))
  local decimal_seg3=$((16#$seg3))
  local decimal_seg4=$((16#$seg4))

  # Create the decimal IP address by joining the segments with dots
  local decimal_ip="$decimal_seg1.$decimal_seg2.$decimal_seg3.$decimal_seg4"

  echo "$decimal_ip"
}

network_info() {
  local interface="$1"

  # Check if the interface name is provided
  if [ -z "$interface" ]; then
    echo "Usage: parse_network_info <INTERFACE_NAME>"
    return 1
  fi

  # Use ifconfig to retrieve network information
  local ifconfig_output
  ifconfig_output=$(ifconfig "$interface" 2>/dev/null)

  # Check if the interface exists and is active
  if [ -z "$ifconfig_output" ]; then
    echo "Interface '$interface' not found or not active."
    return 1
  fi

  # Parse and display IPv4 address, netmask, and default gateway
  local ipv4_address
  ipv4_address=$(echo "$ifconfig_output" | grep -oE 'inet (addr:)?[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | awk '{print $2}')

  local netmask
  netmask=$(echo "$ifconfig_output" | grep -o 'netmask 0x[0-9a-f]*' | awk '{print $2}' | cut -c3- | awk '{gsub(/^0[xX]/,""); print}')

  local default_gateway
  default_gateway=$(route -n get default | grep 'gateway:' | awk '{print $2}')

  # Display the parsed network information
  echo "Interface...............: $interface"
  echo "IPv4 Address............: $ipv4_address"
  echo "Subnet Mask.............: $(hex_to_decimal_ip $netmask)"
  echo "Default Gateway.........: $default_gateway"
}

terraform() {
    # Get the current AWS profile from the environment variable
    AWS_PROFILE=${AWS_PROFILE:-default}

    # Prompt the user to either proceed with the current profile or switch to a new one
    echo "Current AWS Profile is '$AWS_PROFILE'."
    echo -n "Do you want to proceed with this profile? (y/n): "
    read choice

    if [[ "$choice" == "y" ]]; then
        echo "Proceeding with AWS Profile '$AWS_PROFILE'..."
    else
        echo "Please select a new AWS profile to switch to:"
        select new_profile in "dev" "staging" "cancel"; do
            case $new_profile in
                dev)
                    export AWS_PROFILE="dev"
                    echo "AWS Profile is now set to 'dev'."
                    break
                    ;;
                staging)
                    export AWS_PROFILE="staging"
                    echo "AWS Profile is now set to 'staging'."
                    break
                    ;;
                cancel)
                    echo "Profile change canceled. Exiting..."
                    return 1
                    ;;
                *)
                    echo "Invalid option. Please try again."
                    ;;
            esac
        done
    fi

    # Call the original terraform command with all arguments passed to this function
    command terraform "$@"
}

# Updates brew packages, pulls down latest code for all repos, and reloads this profile to pick up changes
goodMorning() {
  echo "Om Shree Ganeshaya Namaha 🙏"
  brew update && brew upgrade
  gpa
  gda
  gcloud components update
  echo "Om Shree Ganeshaya Namaha 🙏"
}
# --------------------------------------------------------------------------------------------------------

# pokeget dialga --hide-name | fastfetch --logo-type ascii

PATH=~/.console-ninja/.bin:$PATH
