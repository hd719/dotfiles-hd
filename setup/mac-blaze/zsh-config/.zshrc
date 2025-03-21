ZSH_CONFIG_DIR=~/Developer/dotfiles-hd/setup/mac/zsh-config

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

# [Job Config]
# --------------------------------------------------------------------------------------------------------

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

export PATH="/opt/homebrew/opt/llvm@14/bin:$PATH"

# Pull all repos on master branch
gda() {
  startdir=$(pwd);

	echo '******Pulling Almanac Editor  ******';
	cdalmanac && git checkout master && gpp;

	echo '******Pulling Blaze on Rails ******';
	cdblazeonrails && git checkout master && gpp;

	echo '******Pulling Monospace ******';
	cdmonospace && git checkout master && gpp;

	echo '******Pulling Prosecore ******';
	cdprosecore && git checkout master && gpp;

  cd "$startdir";
}

goodMorning() {
  echo "🙏 Om Shree Ganeshaya Namaha 🙏"
  brew update && brew upgrade
	gda
  echo "🙏 Om Shree Ganeshaya Namaha 🙏"
}

RED="\033[31m"
RESET="\033[0m"

echo -e "\n${RED}🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥${RESET}"
echo -e "${RED}🔥          Blaze AI          🔥${RESET}"
echo -e "${RED}🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥${RESET}\n"

fastfetch

# Add paths to environment variables
PATH=~/.console-ninja/.bin:$PATH
