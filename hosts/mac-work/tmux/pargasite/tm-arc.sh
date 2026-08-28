#!/bin/zsh

# Kill existing session if it exists
tmux has-session -t parg-arc 2>/dev/null && tmux kill-session -t parg-arc

# Start a new tmux session named "parg-arc"
tmux new-session -d -s parg-arc

# Create a window for the arc app
tmux rename-window -t parg-arc:1 "arc"
tmux send-keys -t parg-arc:1 "res-parg-arc" C-m

# Attach to the tmux session
tmux attach -t parg-arc
