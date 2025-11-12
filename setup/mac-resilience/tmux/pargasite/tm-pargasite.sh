#!/bin/zsh

# Kill existing pargasite session if it exists
tmux has-session -t pargasite 2>/dev/null && tmux kill-session -t pargasite

# Start a new tmux session named "pargasite"
tmux new-session -d -s pargasite

# Window 1: Platform Backend (required dependency)
# Check if Docker containers are actually running (not just tmux session)
BACKEND_RUNNING=$(docker ps --filter "name=rsw-" --format "{{.Names}}" 2>/dev/null | wc -l | tr -d ' ')
BACKEND_STARTED=0
if [ "$BACKEND_RUNNING" -gt 0 ]; then
    tmux rename-window -t pargasite:1 "plat-backend"
    tmux send-keys -t pargasite:1 "echo 'Platform backend containers already running ($BACKEND_RUNNING containers)'" C-m
    tmux send-keys -t pargasite:1 "docker ps --filter \"name=rsw-\" --format \"table {{.Names}}\t{{.Status}}\"" C-m
    tmux send-keys -t pargasite:1 "echo ''" C-m
    tmux send-keys -t pargasite:1 "echo 'Backend is ready. Skipping res-plat-be.'" C-m
else
    tmux rename-window -t pargasite:1 "plat-backend"
    tmux send-keys -t pargasite:1 "res-plat-be" C-m
    BACKEND_STARTED=1
fi

# Window 2: Platform Proxy (required dependency)
# Check if proxy process is running on port 9001 (workbench) or 9002 (client portal)
PROXY_RUNNING=$(lsof -ti:9001,9002 2>/dev/null | wc -l | tr -d ' ')
PROXY_STARTED=0
if [ "$PROXY_RUNNING" -gt 0 ]; then
    tmux new-window -t pargasite:2 -n "plat-proxy"
    tmux send-keys -t pargasite:2 "echo 'Platform proxy already running on ports 9001/9002'" C-m
    tmux send-keys -t pargasite:2 "lsof -i:9001,9002 | grep LISTEN" C-m
    tmux send-keys -t pargasite:2 "echo ''" C-m
    tmux send-keys -t pargasite:2 "echo 'Proxy is ready. Skipping res-plat-proxy-rsc.'" C-m
else
    tmux new-window -t pargasite:2 -n "plat-proxy"
    tmux send-keys -t pargasite:2 "res-plat-proxy-rsc" C-m
    PROXY_STARTED=1
fi

# Determine startup delay: only wait if we started backend or proxy
if [ "$BACKEND_STARTED" -eq 1 ] || [ "$PROXY_STARTED" -eq 1 ]; then
    STARTUP_DELAY="sleep 15"  # Wait for backend/proxy to initialize
    DELAY_MSG="Waiting 15s for backend/proxy to start..."
else
    STARTUP_DELAY="echo 'Backend and proxy already running, starting immediately...'"
    DELAY_MSG=""
fi

# Window 3: Client Suite (port 3003)
tmux new-window -t pargasite:3 -n "client-suite"
tmux send-keys -t pargasite:3 "$STARTUP_DELAY && res-parg-client" C-m

# Window 4: Arc (port 4004)
tmux new-window -t pargasite:4 -n "arc"
tmux send-keys -t pargasite:4 "$STARTUP_DELAY && res-parg-arc" C-m

# Attach to the tmux session
tmux attach -t pargasite
