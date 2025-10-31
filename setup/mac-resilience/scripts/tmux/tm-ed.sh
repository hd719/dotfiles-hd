#!/bin/zsh

tmux new-session -d -s blaze-editor

tmux rename-window -t blaze:1 "dev"
tmux send-keys -t blaze:1 "cd ~/Developer/Blaze/monospace && nvm use 18.17.1; pnpm run dev" C-m

tmux new-window -t blaze:2 -n "worker"
tmux send-keys -t blaze:2 "cd ~/Developer/Blaze/monospace && nvm use 18.17.1; pnpm start-worker" C-m

# Attach to the tmux session
tmux attach -t blaze-editor
