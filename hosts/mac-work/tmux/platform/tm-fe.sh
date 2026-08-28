#!/bin/zsh

# Kill existing session if it exists
tmux has-session -t rsw-frontend 2>/dev/null && tmux kill-session -t rsw-frontend

tmux new-session -d -s rsw-frontend

tmux rename-window -t rsw-frontend:1 "frontend"
tmux send-keys -t rsw-frontend:1 "cd ~/Developer/Resilience/resilience-platform/apps/resilience-security-workbench-web && yarn dev" C-m

# Attach to the tmux session
tmux attach -t rsw-frontend
