# [Kubernetes Config]
# --------------------------------------------------------------------------------------------------------
export KUBE_EDITOR='code --wait'
# Use zsh native command check (faster than command -v)
(( $+commands[kubecolor] )) && alias kubectl="kubecolor"
