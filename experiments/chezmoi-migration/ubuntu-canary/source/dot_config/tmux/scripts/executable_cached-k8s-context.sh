#!/bin/bash
# Smart cached kubectl context - refreshes when kubeconfig changes
CACHE_FILE="/tmp/tmux-k8s-context"
KUBECONFIG_FILE="${KUBECONFIG:-$HOME/.kube/config}"

# Get kubeconfig modification time (0 if doesn't exist)
config_mtime=$(stat -f %m "$KUBECONFIG_FILE" 2>/dev/null || echo 0)
cache_mtime=$(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)

# Refresh if config is newer than cache, or cache doesn't exist
if [[ $config_mtime -gt $cache_mtime ]] || [[ ! -f "$CACHE_FILE" ]]; then
    kubectl config current-context 2>/dev/null > "$CACHE_FILE" || echo "Not set" > "$CACHE_FILE"
fi

cat "$CACHE_FILE"
