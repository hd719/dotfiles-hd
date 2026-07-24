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
alias gdiff='git diff'
alias gnew='git checkout -b'
alias gpp='gpull && gprune'
alias gprune='git fetch --prune'
alias gpublish='git push -u origin $(git rev-parse --abbrev-ref HEAD)'
alias gpull='git pull'
alias gpush='git push'

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
