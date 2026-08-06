#!/bin/bash
# Smart cached docker context - refreshes when docker config changes
CACHE_FILE="/tmp/tmux-docker-context"
DOCKER_CONFIG_FILE="${DOCKER_CONFIG:-$HOME/.docker/config.json}"

# Get docker config modification time (0 if doesn't exist)
config_mtime=$(stat -f %m "$DOCKER_CONFIG_FILE" 2>/dev/null || echo 0)
cache_mtime=$(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)

# Refresh if config is newer than cache, or cache doesn't exist
if [[ $config_mtime -gt $cache_mtime ]] || [[ ! -f "$CACHE_FILE" ]]; then
    docker context show 2>/dev/null | tr -d '\n' > "$CACHE_FILE" || echo "default" > "$CACHE_FILE"
fi

cat "$CACHE_FILE"
