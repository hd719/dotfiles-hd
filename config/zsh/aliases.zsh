# Shared cross-platform aliases.

## LSD - Modern ls replacement with colors and icons
alias ls='lsd --tree --depth 1'
alias lss='lsd --tree --depth 2'
alias lsss='lsd --tree --depth 3'
alias ll='lsd -la --tree --depth 1'
alias l='lsd -l'
alias la='lsd -a'

## Hunk - Review-first Git diff viewer
alias hwatch='hunk diff --watch'
alias hdiff='hunk diff'
alias hstaged='hunk diff --staged'
alias hshow='hunk show'
