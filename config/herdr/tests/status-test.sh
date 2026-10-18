#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
STATUS="$REPO_DIR/config/herdr/status.sh"
CASE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/herdr-status-test.XXXXXX")"
trap 'rm -rf "$CASE_DIR"' EXIT
mkdir -p "$CASE_DIR/bin" "$CASE_DIR/panes"
export STATUS_TEST_DIR="$CASE_DIR"
export HERDR_BIN_PATH="$CASE_DIR/bin/herdr"
export PATH="$CASE_DIR/bin:$PATH"

cat > "$CASE_DIR/bin/herdr" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "$1 $2" in
  'pane report-metadata')
    pane="$3"; shift 3
    [[ -f "$STATUS_TEST_DIR/panes/$pane" ]] || echo '{}' > "$STATUS_TEST_DIR/panes/$pane"
    while (($#)); do
      case "$1" in
        --token)
          jq --arg key "${2%%=*}" --arg value "${2#*=}" '.[$key]=$value' "$STATUS_TEST_DIR/panes/$pane" > "$STATUS_TEST_DIR/panes/$pane.tmp"
          mv "$STATUS_TEST_DIR/panes/$pane.tmp" "$STATUS_TEST_DIR/panes/$pane"
          shift 2 ;;
        --clear-token)
          jq --arg key "$2" 'del(.[$key])' "$STATUS_TEST_DIR/panes/$pane" > "$STATUS_TEST_DIR/panes/$pane.tmp"
          mv "$STATUS_TEST_DIR/panes/$pane.tmp" "$STATUS_TEST_DIR/panes/$pane"
          shift 2 ;;
        --source|--seq) shift 2 ;;
        *) exit 2 ;;
      esac
    done
    ;;
  'pane current') jq -c '{result:{pane:{tokens:.}}}' "$STATUS_TEST_DIR/panes/$4" ;;
  *) exit 2 ;;
esac
EOF
cat > "$CASE_DIR/bin/docker" <<'EOF'
#!/usr/bin/env bash
[[ "$*" == 'context show' ]] || exit 2
printf '%s\n' "${DOCKER_CONTEXT:-desktop-linux}"
EOF
cat > "$CASE_DIR/bin/kubectl" <<'EOF'
#!/usr/bin/env bash
[[ "${STATUS_TEST_NO_KUBE:-}" != 1 ]] || exit 1
[[ "$1 $2 $3" == 'config view --minify' ]] || exit 2
if [[ "${KUBECONFIG:-}" == 'dev:extra' ]]; then printf 'dev\tapps'; else printf 'prod\t'; fi
EOF
cat > "$CASE_DIR/bin/aws" <<'EOF'
#!/usr/bin/env bash
[[ "$1 $2 $3 $4" == 'configure get region --profile' ]] || exit 2
case "$5" in work) echo us-west-2 ;; personal) echo us-east-1 ;; *) echo eu-west-1 ;; esac
EOF
cat > "$CASE_DIR/bin/uname" <<'EOF'
#!/usr/bin/env bash
echo Darwin
EOF
cat > "$CASE_DIR/bin/sysctl" <<'EOF'
#!/usr/bin/env bash
echo 38654705664
EOF
cat > "$CASE_DIR/bin/top" <<'EOF'
#!/usr/bin/env bash
cat <<'SAMPLE'
CPU usage: 10.0% user, 10.0% sys, 80.0% idle
PhysMem: 9G used (1024M wired), 1G unused.
CPU usage: 15.0% user, 10.0% sys, 75.0% idle
PhysMem: 2048M used (1024M wired), 1G unused.
SAMPLE
EOF
chmod +x "$CASE_DIR/bin/"*

actual="$(/bin/bash "$STATUS" system)"
[[ "$actual" == 'CPU 25% · MEM 2.0/36G' ]] || exit 1

env HERDR_ENV=1 HERDR_PANE_ID=p1 AWS_PROFILE=work AWS_REGION= \
  AWS_DEFAULT_REGION= AWS_DEFAULT_PROFILE= DOCKER_CONTEXT=remote \
  DOCKER_HOST= DOCKER_CONFIG= KUBECONFIG=dev:extra \
  AWS_SECRET_ACCESS_KEY=fixture-secret AWS_CONFIG_FILE="$CASE_DIR/aws-config" \
  bash "$STATUS" report
! grep -Fq fixture-secret "$CASE_DIR/panes/p1" || exit 1
[[ "$(jq 'keys | length' "$CASE_DIR/panes/p1")" == 3 ]] || exit 1

env HERDR_ENV=1 HERDR_PANE_ID=p2 AWS_PROFILE=personal AWS_REGION=ap-south-1 \
  AWS_DEFAULT_REGION= AWS_DEFAULT_PROFILE= DOCKER_CONTEXT= DOCKER_HOST= \
  DOCKER_CONFIG= KUBECONFIG=prod AWS_CONFIG_FILE="$CASE_DIR/aws-config" \
  bash "$STATUS" report

[[ "$(HERDR_ACTIVE_PANE_ID=p1 AWS_PROFILE=wrong-daemon-profile bash "$STATUS" aws)" == 'AWS work/us-west-2' ]] || exit 1
[[ "$(HERDR_ACTIVE_PANE_ID=p1 bash "$STATUS" k8s)" == 'K8s dev/apps' ]] || exit 1
[[ "$(HERDR_ACTIVE_PANE_ID=p1 bash "$STATUS" docker)" == 'Docker remote' ]] || exit 1
[[ "$(HERDR_ACTIVE_PANE_ID=p2 AWS_PROFILE=wrong-daemon-profile bash "$STATUS" aws)" == 'AWS personal/ap-south-1' ]] || exit 1
[[ "$(HERDR_ACTIVE_PANE_ID=p2 bash "$STATUS" k8s)" == 'K8s prod/default' ]] || exit 1
[[ "$(HERDR_ACTIVE_PANE_ID=p2 DOCKER_CONTEXT=wrong-daemon-context bash "$STATUS" docker)" == 'Docker desktop-linux' ]] || exit 1
[[ "$(HERDR_ACTIVE_PANE_ID=not-reported AWS_PROFILE=wrong-daemon-profile bash "$STATUS" aws 2>/dev/null)" == 'AWS …' ]] || exit 1
STATUS_TEST_NO_KUBE=1 HERDR_ENV=1 HERDR_PANE_ID=p1 AWS_PROFILE=work bash "$STATUS" report
[[ "$(HERDR_ACTIVE_PANE_ID=p1 bash "$STATUS" k8s)" == 'K8s not set' ]] || exit 1

# Unconfigured selectors stay visible instead of silently disappearing.
mkdir -p "$CASE_DIR/empty-home"
env HOME="$CASE_DIR/empty-home" HERDR_ENV=1 HERDR_PANE_ID=unconfigured \
  AWS_PROFILE= AWS_DEFAULT_PROFILE= AWS_REGION= AWS_DEFAULT_REGION= \
  AWS_CONFIG_FILE="$CASE_DIR/aws-config" STATUS_TEST_NO_KUBE=1 \
  bash "$STATUS" report
[[ "$(HERDR_ACTIVE_PANE_ID=unconfigured bash "$STATUS" aws)" == 'AWS not set' ]] || exit 1
[[ "$(HERDR_ACTIVE_PANE_ID=unconfigured bash "$STATUS" k8s)" == 'K8s not set' ]] || exit 1

# Register once when re-sourced, then report the shell's latest selectors.
HERDR_ENV=1 HERDR_PANE_ID=p3 AWS_PROFILE=hook-profile /bin/zsh -dfc '
  source "$1/config/herdr/status-hook.zsh"
  source "$1/config/herdr/status-hook.zsh"
  (( ${#precmd_functions[(I)_dotfiles_herdr_report_environment]} == 1 )) || exit 1
  _dotfiles_herdr_report_environment
' status-hook "$REPO_DIR"
for attempt in {1..30}; do
  jq -e '.dotfiles_aws | contains("hook-profile")' "$CASE_DIR/panes/p3" >/dev/null 2>&1 && break
  sleep 0.1
done
[[ "$(jq -r .dotfiles_aws "$CASE_DIR/panes/p3")" == 'AWS hook-profile/eu-west-1' ]] || exit 1
env -u HERDR_ENV HERDR_PANE_ID=p4 bash "$STATUS" report
[[ ! -e "$CASE_DIR/panes/p4" ]] || exit 1

# Repeated prompts avoid new reporters, while selectors and local files refresh.
mkdir -p "$CASE_DIR/cache-home/.aws" "$CASE_DIR/cache-home/.docker"
touch "$CASE_DIR/cache-home/.aws/config" "$CASE_DIR/cache-home/.docker/config.json" "$CASE_DIR/kube-one" "$CASE_DIR/kube-two"
HOME="$CASE_DIR/cache-home" HERDR_ENV=1 HERDR_PANE_ID=p-cache \
  KUBECONFIG="$CASE_DIR/kube-one:$CASE_DIR/kube-two" AWS_PROFILE=cache-one \
  AWS_CONFIG_FILE= DOCKER_CONFIG= /bin/zsh -dfc '
  source "$1/config/herdr/status-hook.zsh"
  bash() { print -r -- "$AWS_PROFILE" >> "$STATUS_TEST_DIR/cache-reports"; }
  wait_reports() {
    local attempt
    for attempt in {1..30}; do
      if [[ -f "$STATUS_TEST_DIR/cache-reports" ]] &&
        (( $(wc -l < "$STATUS_TEST_DIR/cache-reports") == $1 )); then return 0; fi
      sleep 0.05
    done
    return 1
  }
  _dotfiles_herdr_report_environment
  wait_reports 1 || exit 1
  for attempt in {1..10}; do _dotfiles_herdr_report_environment; done
  sleep 0.1
  (( $(wc -l < "$STATUS_TEST_DIR/cache-reports") == 1 )) || exit 1

  export AWS_PROFILE=cache-two
  _dotfiles_herdr_report_environment
  wait_reports 2 || exit 1
  [[ "$(tail -1 "$STATUS_TEST_DIR/cache-reports")" == cache-two ]] || exit 1
  expected=2
  for file in "$HOME/.aws/config" "$STATUS_TEST_DIR/kube-two" "$HOME/.docker/config.json"; do
    print changed > "$file"
    _dotfiles_herdr_report_environment
    (( ++expected ))
    wait_reports "$expected" || exit 1
  done
  (( _dotfiles_herdr_status_reported_at -= 31 ))
  _dotfiles_herdr_report_environment
  wait_reports 6 || exit 1
' status-cache "$REPO_DIR"

printf 'Herdr status tests passed: metrics, pane isolation, selectors, defaults, hook registration/cache, file changes, retry, and credential exclusion.\n'
