#!/bin/zsh

# Kill existing session if it exists
tmux has-session -t platform 2>/dev/null && tmux kill-session -t platform

# Start a new tmux session named "resilience"
tmux new-session -d -s platform

# Create a window for the backend with docker compose
tmux rename-window -t platform:1 "backend"
tmux send-keys -t platform:1 "res-plat-be" C-m

# Create a window for the frontend with yarn dev
tmux new-window -t platform:2 -n "frontend"
tmux send-keys -t platform:2 "res-plat-fe" C-m
# Create a window for the proxy-web
tmux new-window -t platform:3 -n "proxy-web"
tmux send-keys -t platform:3 "res-plat-proxy-web" C-m
# Create a window for resilience proxy client
tmux new-window -t platform:4 -n "proxy-client"
tmux send-keys -t platform:4 "res-plat-proxy-rsc" C-m
# Attach to the tmux session
tmux attach -t platform
