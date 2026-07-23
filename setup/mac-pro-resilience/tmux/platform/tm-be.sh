#!/bin/zsh

# Kill existing session if it exists
tmux has-session -t rsw-backend 2>/dev/null && tmux kill-session -t rsw-backend

# Start a new tmux session named "rsw-backend"
tmux new-session -d -s rsw-backend

# Create a window for Docker backend services
tmux rename-window -t rsw-backend:1 "docker"
tmux send-keys -t rsw-backend:1 "cd ~/Developer/Resilience/resilience-platform && bash docker/rsw-initup latest" C-m

# Attach to the tmux session
tmux attach -t rsw-backend
