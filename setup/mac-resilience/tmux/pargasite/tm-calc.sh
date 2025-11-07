#!/bin/zsh

# Kill existing session if it exists
tmux has-session -t parg-calc 2>/dev/null && tmux kill-session -t parg-calc

# Start a new tmux session named "parg-calc"
tmux new-session -d -s parg-calc

# Create a window for the cyber-risk-calculator app
tmux rename-window -t parg-calc:1 "calculator"
tmux send-keys -t parg-calc:1 "res-parg-calc" C-m

# Attach to the tmux session
tmux attach -t parg-calc
