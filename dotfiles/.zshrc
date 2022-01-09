# HomeBrew
# --------------------------------------------------------------------------------------------------------
# eval "$(rbenv init - zsh)" -> Ruby
if type brew &>/dev/null
then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"

  autoload -Uz compinit
  compinit
fi

export HOMEBREW_NO_AUTO_UPDATE=false
# --------------------------------------------------------------------------------------------------------

# [Insert Company Here]
# --------------------------------------------------------------------------------------------------------
# -> Good luck!
# --------------------------------------------------------------------------------------------------------

# Pure Prompt Theme
# --------------------------------------------------------------------------------------------------------
autoload -U promptinit; promptinit
# optionally define some options:
# turn on git stash status
zstyle :prompt:pure:git:stash show yes
prompt pure
PURE_PROMPT_SYMBOL='❯'
prompt_newline='%666v'
PROMPT=" $PROMPT"
PURE_GIT_DOWN_ARROW='↓'
PURE_GIT_UP_ARROW='↑'
# PROMPT=' %(?.%F{magenta}△.%F{red}▲)%f '
# RPROMPT='$(git config user.email 2>/dev/null)'
# --------------------------------------------------------------------------------------------------------

# Jovial Theme
# --------------------------------------------------------------------------------------------------------
export ZSH="/Users/hameld/.oh-my-zsh"
# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="jovial"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS=true

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# --------------------------------------------------------------------------------------------------------

# Plugins, Functions, Keybindings
# --------------------------------------------------------------------------------------------------------
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

plugins=(
  git
  autojump
  urltools
  bgnotify
  # jovial
	z
)

# source $ZSH/oh-my-zsh.sh
source ~/.oh-my-zsh/oh-my-zsh.sh

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

# up
	function up_widget() {
		BUFFER="cd .."
		zle accept-line
	}
	zle -N up_widget
	bindkey "^k" up_widget

# git
	function git_prepare() {
		if [ -n "$BUFFER" ]; then
				BUFFER="git add -A; git commit -m \"$BUFFER\" && git push"
		fi

		if [ -z "$BUFFER" ]; then
				BUFFER="git add -A; git commit -v && git push"
		fi
		zle accept-line
	}
	zle -N git_prepare
	bindkey "^g" git_prepare

# home
	function goto_home() {
		BUFFER="cd ~/"$BUFFER
		zle end-of-line
		zle accept-line
	}
	zle -N goto_home
	bindkey "^h" goto_home

# Edit and rerun
	function edit_and_run() {
		BUFFER="fc"
		zle accept-line
	}
	zle -N edit_and_run
	bindkey "^v" edit_and_run

# LS
	function ctrl_l() {
		BUFFER="ls"
		zle accept-line
	}
	zle -N ctrl_l
	bindkey "^l" ctrl_l

# Enter
	function enter_line() {
		zle accept-line
	}
	zle -N enter_line
	bindkey "^o" enter_line

# Sudo
	function add_sudo() {
		BUFFER="sudo "$BUFFER
		zle end-of-line
	}
	zle -N add_sudo
	bindkey "^s" add_sudo
# --------------------------------------------------------------------------------------------------------

# Aliases
# --------------------------------------------------------------------------------------------------------
# Node
alias nps="npm run start"
alias npd="npm run dev"
alias npb="npm run build"
alias npt="npm run test"
alias npl="npm run lint"
alias npp="npm run prettier"
alias npserved="npm run serve:dev"
alias npserve="npm run serve"
alias ys="yarn start"
alias ysd="yarn dev"
alias yb="yarn build"
alias yt="yarn test"
alias yl="yarn lint"
alias yp="yarn prettier"
alias ysd="yarn serve:dev"
alias yserve="yarn serve"

# Rails
alias rs="bundle exec rails s"
alias sidekiq="bundle exec sidekiq"
alias reds="redis-server"

# Universal
alias home="cd ~"
alias open-home="cd ~ && open ."
alias desktop="cd ~/Desktop/"
alias open-desktop="cd ~/Desktop/ && open ."
alias c="clear"

# iOS
alias pods="cd ios && pod install; cd .."
alias clean="git clean -fd && git checkout ."
# --------------------------------------------------------------------------------------------------------
