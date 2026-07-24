# Safe host aliases shared by every Mac profile.

## Mac defaults
alias reset-finder="defaults write com.apple.finder CreateDesktop -bool true; killall Finder; open /System/Library/CoreServices/Finder.app"
alias reset-dock="defaults write com.apple.dock autohide -bool false; killall Dock"

## Navigation
alias open-desktop='cd ~/Desktop && open .'
alias open-home='cd ~ && open .'
alias open-brew='cd /opt/homebrew'

## Git
alias gs='git status'
alias gsshort='gs | grep -e "Your branch" -e "modified"'
