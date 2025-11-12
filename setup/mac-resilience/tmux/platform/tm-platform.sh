#!/bin/zsh

# Kill existing session if it exists
tmux has-session -t platform 2>/dev/null && tmux kill-session -t platform

# Wait a moment for processes to clean up
sleep 1

# Kill any lingering processes on common ports used by this project
# This prevents EADDRINUSE errors when restarting
lsof -ti :9001 | xargs kill -9 2>/dev/null || true
lsof -ti :9002 | xargs kill -9 2>/dev/null || true
lsof -ti :3000 | xargs kill -9 2>/dev/null || true
lsof -ti :3001 | xargs kill -9 2>/dev/null || true
lsof -ti :8080 | xargs kill -9 2>/dev/null || true

# Wait another moment after cleanup
sleep 1

# Start a new tmux session named "resilience"
tmux new-session -d -s platform

# Create a window for the backend with docker compose
tmux rename-window -t platform:1 "backend"
tmux send-keys -t platform:1 "res-plat-be" C-m

# Create a window for the frontend with yarn dev
tmux new-window -t platform:2 -n "frontend"
tmux send-keys -t platform:2 "res-plat-fe" C-m

# Attach to the tmux session
tmux attach -t platform
