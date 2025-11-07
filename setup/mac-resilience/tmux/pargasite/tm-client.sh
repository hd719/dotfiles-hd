#!/bin/zsh

# Kill existing session if it exists
tmux has-session -t parg-client 2>/dev/null && tmux kill-session -t parg-client

# Start a new tmux session named "parg-client"
tmux new-session -d -s parg-client

# Create a window for the client-suite app
tmux rename-window -t parg-client:1 "client-suite"
tmux send-keys -t parg-client:1 "res-parg-client" C-m

# Attach to the tmux session
tmux attach -t parg-client
