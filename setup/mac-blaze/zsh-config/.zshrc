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

# [Job Config]
# --------------------------------------------------------------------------------------------------------
eval "$(rbenv init - zsh)"
export PATH="/opt/homebrew/opt/llvm@14/bin:$PATH"
export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"
export PKG_CONFIG_PATH="/opt/homebrew/opt/postgresql@15/lib/pkgconfig"

# heroku autocomplete setup
HEROKU_AC_ZSH_SETUP_PATH=/Users/hameldesai/Library/Caches/heroku/autocomplete/zsh_setup && test -f $HEROKU_AC_ZSH_SETUP_PATH && source $HEROKU_AC_ZSH_SETUP_PATH;

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

## Databasees
alias blaze-restore="~/Developer/dotfiles-hd/setup/mac-blaze/zsh-config/scripts/db/blaze-restore.sh"
alias blaze-backup="~/Developer/dotfiles-hd/setup/mac-blaze/zsh-config/scripts/db/blaze-backup.sh"

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

# Pull all repos on master branch
# Pull all repos on master branch
gda() {
  startdir=$(pwd)

  # Function to update a single repo
  update_repo() {
    local repo_path="$1"
    local repo_name="$2"
    echo "****** Pulling $repo_name ******"
    cd "$repo_path" && git checkout master && git pull origin master
  }

  # Run all updates sequentially (no background processes)
  update_repo ~/Developer/Blaze/almanac-editor "Almanac Editor"
  update_repo ~/Developer/Blaze/blaze-on-rails "Blaze on Rails"
  update_repo ~/Developer/Blaze/monospace "Monospace"
  update_repo ~/Developer/Blaze/prose-core "Prosecore"

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

RED="\033[31m"
RESET="\033[0m"

echo -e "\n${RED}🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥${RESET}"
echo -e "${RED}🔥          Blaze AI          🔥${RESET}"
echo -e "${RED}🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥${RESET}\n"

# Add paths to environment variables
PATH=~/.console-ninja/.bin:$PATH
