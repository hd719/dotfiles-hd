# Portable aliases shared by every shell profile.

## Shell and navigation
alias c='clear'
alias home='cd ~'
alias dots='cd ~/Developer/dotfiles-hd'
alias r='reload'

## Git
alias g='git'
alias gadd='git add .'
alias gba='git branch -a'
alias gcm='git commit -a -m'
alias gnew='git checkout -b'
alias gpp='gpull && gprune'
alias gprune='git fetch --prune'
alias gpublish='git push -u origin $(git rev-parse --abbrev-ref HEAD)'
alias gpull='git pull'
alias gpush='git push'

## Hunk
# EDITOR=nvim is scoped to these aliases only: pressing `e` inside Hunk opens
# the file in Neovim, without changing $EDITOR for git commit messages or
# other tools (some profiles pin that to `code --wait`).
alias hwatch='EDITOR=nvim hunk diff --watch'
alias hdiff='EDITOR=nvim hunk diff'
alias hstaged='EDITOR=nvim hunk diff --staged'
alias hshow='EDITOR=nvim hunk show'

## Editor
alias v='nvim'

## Optional portable tools
if (( $+commands[lsd] )); then
  alias ls='lsd --tree --depth 1'
  alias lss='lsd --tree --depth 2'
  alias lsss='lsd --tree --depth 3'
  alias ll='lsd -la --tree --depth 1'
  alias l='lsd -l'
  alias la='lsd -a'
fi

## SSH
alias hosts="awk '/^Host / {print \$2}' ~/.ssh/config"
