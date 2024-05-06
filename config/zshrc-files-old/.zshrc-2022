# HomeBrew
# --------------------------------------------------------------------------------------------------------
if type brew &>/dev/null
then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"

  autoload -Uz compinit
  compinit
fi

eval "$(/opt/homebrew/bin/brew shellenv)"

export HOMEBREW_NO_AUTO_UPDATE=false
# --------------------------------------------------------------------------------------------------------

# [Insert Company Here]
# --------------------------------------------------------------------------------------------------------
# -> Good luck!
# --------------------------------------------------------------------------------------------------------

# Pure Prompt Theme
# --------------------------------------------------------------------------------------------------------
# autoload -U promptinit; promptinit
# # optionally define some options:
# # turn on git stash status
# zstyle :prompt:pure:git:stash show yes
# prompt pure
# PURE_PROMPT_SYMBOL='❯'
# prompt_newline='%666v'
# PROMPT=" $PROMPT"
# PURE_GIT_DOWN_ARROW='↓'
# PURE_GIT_UP_ARROW='↑'
# PROMPT=' %(?.%F{magenta}△.%F{red}▲)%f '
# RPROMPT='$(git config user.email 2>/dev/null)'
# --------------------------------------------------------------------------------------------------------

# Plugins, Functions, Keybindings
# --------------------------------------------------------------------------------------------------------
# source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
# [ -f /usr/local/etc/profile.d/autojump.sh ] && . /usr/local/etc/profile.d/autojump.sh # -> Autojump

plugins=(
  git
  # autojump
  # urltools
  # bgnotify
	z
)

# source $ZSH/oh-my-zsh.sh -> TODO REMOVE THIS
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

# Git
alias g="git"
# --------------------------------------------------------------------------------------------------------