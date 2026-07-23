# [Shared Mac Kubernetes Config]
# --------------------------------------------------------------------------------------------------------
export KUBE_EDITOR="$EDITOR"
# Use zsh native command check (faster than command -v)
(( $+commands[kubecolor] )) && alias kubectl="kubecolor"
