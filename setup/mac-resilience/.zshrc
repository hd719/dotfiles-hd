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
# alias itbe="~/Developer/dotfiles-hd/setup/mac-blaze/zsh-config/scripts/iterm/it-be.sh"
# alias ited="~/Developer/dotfiles-hd/setup/mac-blaze/zsh-config/scripts/iterm/ie-ed.sh"
# alias itfe="~/Developer/dotfiles-hd/setup/mac-blaze/zsh-config/scripts/iterm/it-fe.sh"
# alias itall="~/Developer/dotfiles-hd/setup/mac-blaze/zsh-config/scripts/iterm/it-all.sh"

# alias tmfe="~/Developer/dotfiles-hd/setup/mac-blaze/zsh-config/scripts/tmux/tm-fe.sh"
# alias tmed="~/Developer/dotfiles-hd/setup/mac-blaze/zsh-config/scripts/tmux/tm-ed.sh"
# alias tmbe="~/Developer/dotfiles-hd/setup/mac-blaze/zsh-config/scripts/tmux/tm-be.sh"
# alias tmbl="~/Developer/dotfiles-hd/setup/mac-blaze/zsh-config/scripts/tmux/tm-all.sh"

# alias console-dev="heroku run rails c -a blaze-ai-rails"
# alias console-prod="heroku run rails c -a blaze-ai-rails"

# ## Databasees
# alias blaze-restore="~/Developer/dotfiles-hd/setup/mac-blaze/zsh-config/scripts/db/blaze-restore.sh"
# alias blaze-backup="~/Developer/dotfiles-hd/setup/mac-blaze/zsh-config/scripts/db/blaze-backup.sh"

# ## Repos
# alias cdfe='nvm use 16.5.0; cd ~/Developer/Blaze/almanac-editor/apps/blaze'
# alias cdbe='nvm use stable; rbenv use local 3.1.3; cd ~/Developer/Blaze/blaze-on-rails'
# alias cdmo='nvm use 18.17.1; cd ~/Developer/Blaze/monospace'
# alias cdpc='nvm use 18.17.1; cd ~/Developer/Blaze/prose-core'
# alias cdeng='nvm use stable; cd ~/Developer/Blaze/eng-cli'

# ## Rails
# alias be="bundle exec"
# alias r="bundle exec rails"
# alias rs="bundle exec rails s"
# alias rc="bundle exec rails c"
# alias rr="bundle exec rails routes"
# alias rdbm="bundle exec rails db:migrate"
# alias rdbs="bundle exec rails db:schema:load"
# alias rdbmr="bundle exec rails db:rollback"
# alias rdbr="bundle exec rake db:reset"

# ## Rails Environment
# alias rdbmdev="bundle exec rails db:migrate RAILS_ENV=development"
# alias rdbmprod="bundle exec rails db:migrate RAILS_ENV=production"
# alias rdbmrdev="bundle exec rails db:rollback RAILS_ENV=development"
# alias rdbmrprod="bundle exec rails db:rollback RAILS_ENV=production"

# # Pull all repos on master branch
# # Pull all repos on master branch
# gda() {
#   echo "🙏 Om Shree Ganeshaya Namaha 🙏"
#   startdir=$(pwd)

#   # Function to update a single repo
#   update_repo() {
#     local repo_path="$1"
#     local repo_name="$2"
#     echo "****** Pulling $repo_name ******"
#     cd "$repo_path" && git checkout master && git pull origin master
#   }

#   # Run all updates sequentially (no background processes)
#   update_repo ~/Developer/Blaze/almanac-editor "Almanac Editor"
#   update_repo ~/Developer/Blaze/blaze-on-rails "Blaze on Rails"
#   update_repo ~/Developer/Blaze/monospace "Monospace"
#   update_repo ~/Developer/Blaze/prose-core "Prosecore"
#   update_repo ~/Developer/Blaze/eng-cli "Eng CLI"

#   cd "$startdir"
#   echo "🙏 Om Shree Ganeshaya Namaha 🙏"
# }

# goodMorning() {
#   echo "🙏 Om Shree Ganeshaya Namaha 🙏"

#   # Skip Homebrew updates if hostname contains 'virtual' (case insensitive)
#   if [[ ! "$(hostname)" =~ [Vv]irtual ]]; then
#     # Optional flag for Homebrew updates
#     if [[ "$1" != "--no-brew" ]]; then
#       echo "Updating Homebrew..."
#       brew update
#       if brew outdated | grep -q .; then
#         brew upgrade --greedy
#         brew cleanup
#         brew autoremove
#       else
#         echo "No Homebrew packages to upgrade"
#       fi
#     fi
#   else
#     echo "Skipping Homebrew update (virtual environment detected)"
#   fi

#   echo "Updating Git repositories..."
#   gda
#   echo "🙏 Om Shree Ganeshaya Namaha 🙏"
# }
