#!/usr/bin/env bash
# Herdr runs these commands on the server that owns the selected pane.
set -o pipefail
export LC_ALL=C

system_status() {
  local total sample first second cpu memory
  case "$(uname -s)" in
    Darwin)
      total="$(sysctl -n hw.memsize 2>/dev/null)" || return 1
      sample="$(top -l 2 -s 1 -n 0 2>/dev/null)" || return 1
      printf '%s\n' "$sample" | awk -v total="$total" '
        /^CPU usage:/ { idle=$(NF-1); sub(/%$/, "", idle); cpu=100-idle; have_cpu=1 }
        /^PhysMem:/ { used=$2; have_memory=1 }
        END {
          if (!have_cpu || !have_memory || total <= 0) exit 1
          unit=substr(used, length(used)); memory=used+0
          if (unit == "M") memory/=1024
          else if (unit == "K") memory/=1048576
          else if (unit != "G") exit 1
          printf "CPU %.0f%% · MEM %.1f/%.0fG\n", cpu, memory, total/1073741824
        }'
      ;;
    Linux)
      first="$(awk '/^cpu / { idle=$5+$6; for(i=2;i<=9;i++) total+=$i; print total, idle; exit }' /proc/stat)" || return 1
      sleep 0.2
      second="$(awk '/^cpu / { idle=$5+$6; for(i=2;i<=9;i++) total+=$i; print total, idle; exit }' /proc/stat)" || return 1
      cpu="$(awk -v before="$first" -v after="$second" 'BEGIN {
        split(before,a); split(after,b); total=b[1]-a[1]
        if (total <= 0) exit 1
        value=100*(1-(b[2]-a[2])/total)
        if (value < 0) value=0; if (value > 100) value=100
        printf "%.0f", value
      }')" || return 1
      memory="$(awk '
        /^MemTotal:/ { total=$2 }
        /^MemAvailable:/ { available=$2; found=1 }
        END {
          if (!found || total <= 0) exit 1
          printf "%.1f/%.0fG", (total-available)/1048576, total/1048576
        }' /proc/meminfo)" || return 1
      printf 'CPU %s%% · MEM %s\n' "$cpu" "$memory"
      ;;
  esac
}

context_status() {
  local pane pending=""
  case "$1" in k8s) pending="K8s …" ;; aws) pending="AWS …" ;; esac
  if [[ -n "${HERDR_ACTIVE_PANE_ID:-}" ]] &&
    pane="$("${HERDR_BIN_PATH:-herdr}" pane current --pane "$HERDR_ACTIVE_PANE_ID" 2>/dev/null)"; then
    printf '%s\n' "$pane" | jq -r --arg key "dotfiles_$1" --arg pending "$pending" '.result.pane.tokens[$key] // $pending'
  else
    printf '%s\n' "$pending"
  fi
}

report_context() {
  [[ "${HERDR_ENV:-}" == 1 && -n "${HERDR_PANE_ID:-}" ]] || return 0
  local profile region docker_context kube_context namespace value name
  local docker_label="" kube_label="K8s not set" aws_label="AWS not set"

  if command -v docker >/dev/null 2>&1; then
    if [[ -n "${DOCKER_HOST:-}" && -z "${DOCKER_CONTEXT:-}" ]]; then
      docker_context=custom
    else
      docker_context="$(docker context show 2>/dev/null)" || docker_context=""
    fi
    [[ -z "$docker_context" ]] || docker_label="Docker $docker_context"
  fi

  if command -v kubectl >/dev/null 2>&1; then
    value="$(kubectl config view --minify -o 'jsonpath={.current-context}{"\t"}{.contexts[0].context.namespace}' 2>/dev/null)" || value=""
    IFS=$'\t' read -r kube_context namespace <<< "$value"
    [[ -z "$kube_context" ]] || kube_label="K8s $kube_context/${namespace:-default}"
  fi

  profile="${AWS_PROFILE:-${AWS_DEFAULT_PROFILE:-}}"
  region="${AWS_REGION:-${AWS_DEFAULT_REGION:-}}"
  if [[ -n "$profile$region" || -f "${AWS_CONFIG_FILE:-$HOME/.aws/config}" || -f "$HOME/.aws/credentials" ]]; then
    profile="${profile:-default}"
    if [[ -z "$region" ]] && command -v aws >/dev/null 2>&1; then
      region="$(aws configure get region --profile "$profile" 2>/dev/null)" || region=""
    fi
    aws_label="AWS $profile${region:+/$region}"
  fi

  local -a args=(pane report-metadata "$HERDR_PANE_ID" --source dotfiles-status)
  [[ -z "${DOTFILES_HERDR_STATUS_SEQ:-}" ]] || args+=(--seq "$DOTFILES_HERDR_STATUS_SEQ")
  for name in docker k8s aws; do
    case "$name" in docker) value="$docker_label" ;; k8s) value="$kube_label" ;; aws) value="$aws_label" ;; esac
    if [[ -n "$value" ]]; then args+=(--token "dotfiles_$name=$value"); else args+=(--clear-token "dotfiles_$name"); fi
  done
  "${HERDR_BIN_PATH:-herdr}" "${args[@]}" >/dev/null
}

case "${1:-}" in
  system) system_status ;;
  docker|k8s|aws) context_status "$1" ;;
  report) report_context ;;
  *) printf 'Usage: status.sh {system|docker|k8s|aws|report}\n' >&2; exit 2 ;;
esac
