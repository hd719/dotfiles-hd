#!/bin/zsh

# Kill existing session if it exists
tmux has-session -t rsw-proxy 2>/dev/null && tmux kill-session -t rsw-proxy

tmux new-session -d -s rsw-proxy

tmux rename-window -t rsw-proxy:1 "proxy-web"
tmux send-keys -t rsw-proxy:1 "cd ~/Developer/Resilience/resilience-platform/apps/resilience-security-workbench-proxy && yarn workbench-proxy" C-m

tmux new-window -t rsw-proxy:2 -n "proxy-client"
tmux send-keys -t rsw-proxy:2 "cd ~/Developer/Resilience/resilience-platform/apps/resilience-security-workbench-proxy && yarn client-portal-proxy" C-m

# Attach to the tmux session
tmux attach -t rsw-proxy
