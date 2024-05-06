# Node Version Manager
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Tylt
eval "$(rbenv init -)"
source ~/hd/.secrets
source ~/hd/.alias

#Plugins
source ~/Development/dotfiles/zsh/plugins/oh-my-zsh/lib/history.zsh
source ~/Development/dotfiles/zsh/plugins/oh-my-zsh/lib/key-bindings.zsh
source ~/Development/dotfiles/zsh/plugins/oh-my-zsh/lib/completion.zsh
source ~/Development/dotfiles/zsh/plugins/vi-mode.plugin.zsh
source ~/Development/dotfiles/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/Development/dotfiles/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/Development/dotfiles/zsh/keybindings.sh

plugins=(
  zsh-autosuggestions
  zsh-syntax-highlighting
)

#Functions
	# Custom cd
	c() {
		cd $1;
		ls;
	}
	alias cd="c"

# Fix for arrow-key searching
# start typing + [Up-Arrow] - fuzzy find history forward
if [[ "${terminfo[kcuu1]}" != "" ]]; then
	autoload -U up-line-or-beginning-search
	zle -N up-line-or-beginning-search
	bindkey "${terminfo[kcuu1]}" up-line-or-beginning-search
fi
# start typing + [Down-Arrow] - fuzzy find history backward
if [[ "${terminfo[kcud1]}" != "" ]]; then
	autoload -U down-line-or-beginning-search
	zle -N down-line-or-beginning-search
	bindkey "${terminfo[kcud1]}" down-line-or-beginning-search
fi

HISTFILE=~/.zsh_history
	setopt inc_append_history # To save every command before it is executed
	setopt share_history # setopt inc_append_history

# Set Spaceship ZSH as a prompt
autoload promptinit; promptinit

SPACESHIP_PROMPT_ORDER=(
  user          # Username section
  dir           # Current directory section
  host          # Hostname section
  git           # Git section (git_branch + git_status)
  hg            # Mercurial section (hg_branch  + hg_status)
  package       # Package version
  node          # Node.js section
  ruby          # Ruby section
  # elm           # Elm section
  # elixir        # Elixir section
  # xcode         # Xcode section
  # swift         # Swift section
  # golang        # Go section
  # php           # PHP section
  # rust          # Rust section
  # haskell       # Haskell Stack section
  # julia         # Julia section
  # docker        # Docker section
  aws           # Amazon Web Services section
  venv          # virtualenv section
  # conda         # conda virtualenv section
  # pyenv         # Pyenv section
  # dotnet        # .NET section
  # ember         # Ember.js section
  kubecontext   # Kubectl context section
  line_sep
  time          # Time stampts section
  exec_time     # Execution time
  # line_sep      # Line break
  #  battery    # Battery level and status
  vi_mode       # Vi-mode indicator
  jobs          # Background jobs indicator
  exit_code     # Exit code section
  char          # Prompt character
)
prompt spaceship

# What is the I before prompt character ?
# https://denysdovhan.com/spaceship-prompt/docs/Troubleshooting.html
SPACESHIP_VI_MODE_SHOW=false

# Prompt
SPACESHIP_PROMPT_ADD_NEWLINE=true

# Shows time
SPACESHIP_TIME_SHOW=true
SPACESHIP_TIME_12HR=true
SPACESHIP_TIME_PREFIX=""

# Char settings
SPACESHIP_CHAR_SUFFIX=" "
SPACESHIP_CHAR_COLOR_SUCCESS="magenta"
SPACESHIP_CHAR_SYMBOL="❯"

# Git branch color
SPACESHIP_GIT_BRANCH_COLOR="cyan"

# Directory color
SPACESHIP_DIR_COLOR="blue"