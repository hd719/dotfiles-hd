#!/bin/bash
# AWS profile - checks env var first (instant), then falls back to config
# Environment variable changes are detected immediately in new panes

# First check if AWS_PROFILE env var is set (instant, no subprocess)
if [[ -n "$AWS_PROFILE" ]]; then
    echo "$AWS_PROFILE"
    exit 0
fi

# Fall back to cached aws configure value
CACHE_FILE="/tmp/tmux-aws-profile"
AWS_CONFIG_FILE="${AWS_CONFIG_FILE:-$HOME/.aws/config}"

config_mtime=$(stat -f %m "$AWS_CONFIG_FILE" 2>/dev/null || echo 0)
cache_mtime=$(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)

# Refresh if config is newer than cache
if [[ $config_mtime -gt $cache_mtime ]] || [[ ! -f "$CACHE_FILE" ]]; then
    aws configure get profile 2>/dev/null > "$CACHE_FILE" || echo "default" > "$CACHE_FILE"
fi

cat "$CACHE_FILE"
