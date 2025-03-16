#!/bin/zsh

tmux new-session -d -s blaze-editor

tmux rename-window -t blaze:4 "dev"
tmux send-keys -t blaze:4 "cd ~/Developer/Blaze/monospace && nvm use 18.17.1; pnpm run dev" C-m

tmux new-window -t blaze:5 -n "worker"
tmux send-keys -t blaze:5 "cd ~/Developer/Blaze/monospace && nvm use 18.17.1; pnpm run dev" C-m

# Attach to the tmux session
tmux attach -t blaze-editor
