#!/bin/zsh

tmux new-session -d -s blaze-fe

tmux rename-window -t blaze:1 "blaze-fe"
tmux send-keys -t blaze:1 "cd ~/Developer/Blaze/almanac-editor/apps/blaze && nvm use 18.17.1; pnpm i; pnpm exec vite" C-m

# Attach to the tmux session
tmux attach -t blaze-fe
