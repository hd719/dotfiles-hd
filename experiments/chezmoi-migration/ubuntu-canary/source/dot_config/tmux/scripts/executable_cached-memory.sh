#!/bin/bash
# Cached memory pressure - refreshes every 10 seconds
CACHE_FILE="/tmp/tmux-memory-pressure"
CACHE_TTL=5

if [[ -f "$CACHE_FILE" ]]; then
    age=$(($(date +%s) - $(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)))
    if [[ $age -lt $CACHE_TTL ]]; then
        cat "$CACHE_FILE"
        exit 0
    fi
fi

# Update cache
memory_pressure 2>/dev/null | awk '/percentage/{print $5}' > "$CACHE_FILE"
cat "$CACHE_FILE"
