#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
CHEZMOI_DIR="$(cd "$TEST_DIR/.." && pwd -P)"
REPO_DIR="$(cd "$CHEZMOI_DIR/.." && pwd -P)"
CHEZMOI_BIN="${CHEZMOI_BIN:-}"
[[ -x "$CHEZMOI_BIN" ]] || {
  printf 'Set CHEZMOI_BIN to a chezmoi 2.72.0 binary.\n' >&2
  exit 2
}

case "$($CHEZMOI_BIN --version)" in
  *'version v2.72.0'*) ;;
  *) printf 'chezmoi 2.72.0 is required.\n' >&2; exit 1 ;;
esac

case_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-chezmoi-test.XXXXXX")"
trap 'rm -rf "$case_dir"' EXIT

prepare_mac_mini_home() {
  local home_dir="$1"
  mkdir -p \
    "$home_dir/.config/btop" \
    "$home_dir/.config/fastfetch" \
    "$home_dir/.config/herdr" \
    "$home_dir/.config/hunk" \
    "$home_dir/.config/mise" \
    "$home_dir/.hermes/skins" \
    "$home_dir/Library/Application Support/com.mitchellh.ghostty"
  chmod 700 "$home_dir/.config" "$home_dir/.hermes"
}

path_mode() {
  if [[ "$(uname -s)" == Darwin ]]; then
    stat -f '%Lp' "$1"
  else
    stat -c '%a' "$1"
  fi
}

prepare_profile_parents() {
  local profile="$1"
  local home_dir="$2"
  local relative _source

  while IFS='|' read -r relative _source; do
    mkdir -p "$(dirname "$home_dir/$relative")"
  done < "$CHEZMOI_DIR/profiles/$profile.paths"
}

for script in "$CHEZMOI_DIR"/*.sh; do
  bash -n "$script"
done
[[ "$(wc -l < "$CHEZMOI_DIR/bootstrap.sh" | tr -d ' ')" -le 25 ]]

bootstrap_home="$case_dir/bootstrap/home"
bootstrap_bin="$case_dir/bootstrap/chezmoi"
mkdir -p "$bootstrap_home"
prepare_mac_mini_home "$bootstrap_home"
cat > "$bootstrap_bin" <<'EOF'
#!/bin/sh
if [ "${1:-}" = --version ]; then
  printf 'chezmoi version %s, test build\n' "${FAKE_CHEZMOI_VERSION:-v2.72.0}"
fi
EOF
chmod +x "$bootstrap_bin"
HOME="$bootstrap_home" \
  DOTFILES_CHEZMOI_TEST=1 \
  CHEZMOI_BIN="$bootstrap_bin" \
  FAKE_CHEZMOI_VERSION=v2.72.0 \
  bash "$CHEZMOI_DIR/bootstrap.sh" mac-mini --preview \
  > "$case_dir/bootstrap-correct.log"
set +e
bootstrap_wrong_output="$({
  HOME="$bootstrap_home" \
    DOTFILES_CHEZMOI_TEST=1 \
    CHEZMOI_BIN="$bootstrap_bin" \
    FAKE_CHEZMOI_VERSION=v2.71.0 \
    bash "$CHEZMOI_DIR/bootstrap.sh" mac-mini --preview
} 2>&1)"
bootstrap_wrong_status=$?
set -e
((bootstrap_wrong_status != 0))
[[ "$bootstrap_wrong_output" == *"chezmoi v2.72.0 is required"* ]]

checkout_home="$case_dir/reviewed-checkout/home"
checkout_repo="$checkout_home/Developer/dotfiles-hd"
mkdir -p "$checkout_repo"
git -C "$checkout_repo" init -q -b master
git -C "$checkout_repo" config user.name test
git -C "$checkout_repo" config user.email test@example.com
printf 'reviewed\n' > "$checkout_repo/README.md"
git -C "$checkout_repo" add README.md
git -C "$checkout_repo" commit -q -m reviewed
git -C "$checkout_repo" remote add origin \
  git@github.com:hd719/dotfiles-hd.git
git -C "$checkout_repo" update-ref refs/remotes/origin/master HEAD

require_reviewed_checkout() {
  HOME="$checkout_home" DOTFILES_CHEZMOI_TEST=0 \
    DOTFILES_CHEZMOI_REVIEWED_REF="${1:-master}" \
    DOTFILES_TEST_PROFILE="${2:-ubuntu}" \
    bash -c '
      source "$1/lib.sh"
      REPO_DIR="$2"
      DEST_DIR="$HOME"
      BACKUP_ROOT="$HOME/.local/state/dotfiles-hd/chezmoi-backups"
      PROFILE="$DOTFILES_TEST_PROFILE"
      require_canonical_checkout
    ' _ "$CHEZMOI_DIR" "$checkout_repo"
}

require_reviewed_checkout
git -C "$checkout_repo" remote set-url origin \
  git@github.com:someone-else/dotfiles-hd.git
set +e
checkout_output="$(require_reviewed_checkout 2>&1)"
checkout_status=$?
set -e
((checkout_status != 0))
[[ "$checkout_output" == *"apply requires canonical origin"* ]]
git -C "$checkout_repo" remote set-url origin \
  git@github.com:hd719/dotfiles-hd.git
git -C "$checkout_repo" commit -q --allow-empty -m unreviewed
set +e
checkout_output="$(require_reviewed_checkout 2>&1)"
checkout_status=$?
set -e
((checkout_status != 0))
[[ "$checkout_output" == *"master does not match origin/master"* ]]

git -C "$checkout_repo" checkout -q -b canary refs/remotes/origin/master
git -C "$checkout_repo" commit -q --allow-empty -m reviewed-canary
git -C "$checkout_repo" update-ref refs/remotes/origin/canary HEAD
set +e
checkout_output="$(require_reviewed_checkout 2>&1)"
checkout_status=$?
set -e
((checkout_status != 0))
[[ "$checkout_output" == *"apply requires reviewed master"* ]]
require_reviewed_checkout canary
set +e
checkout_output="$(require_reviewed_checkout canary mac-thin 2>&1)"
checkout_status=$?
set -e
((checkout_status != 0))
[[ "$checkout_output" == *"custom reviewed branches are limited to the Ubuntu canary"* ]]
git -C "$checkout_repo" commit -q --allow-empty -m unreviewed-canary
set +e
checkout_output="$(require_reviewed_checkout canary 2>&1)"
checkout_status=$?
set -e
((checkout_status != 0))
[[ "$checkout_output" == *"canary does not match origin/canary"* ]]
set +e
checkout_output="$(require_reviewed_checkout -bad 2>&1)"
checkout_status=$?
set -e
((checkout_status != 0))
[[ "$checkout_output" == *"invalid reviewed branch: -bad"* ]]

layout_home="$case_dir/layout/home"
layout_target="$case_dir/layout/config-target"
mkdir -p "$layout_home" "$layout_target"
ln -s "$layout_target" "$layout_home/.config"
set +e
layout_output="$({
  HOME="$layout_home" \
    DOTFILES_CHEZMOI_TEST=1 \
    DOTFILES_CHEZMOI_CONFIG_ONLY_PREVIEW=1 \
    CHEZMOI_BIN="$CHEZMOI_BIN" \
    CHEZMOI_DESTINATION="$layout_home" \
    bash "$CHEZMOI_DIR/preview.sh" mac-thin
} 2>&1)"
layout_status=$?
set -e
((layout_status != 0))
[[ "$layout_output" == *"unapproved mac-thin symlink parent"* ]]

for profile in ubuntu mac-thin mac-pro mac-studio mac-mini mac-work; do
  home_dir="$case_dir/$profile/home"
  state_dir="$case_dir/$profile/state"
  mkdir -p "$home_dir" "$state_dir"
  case "$profile" in
    ubuntu) mkdir -p "$home_dir/.config/btop" "$home_dir/.config/fastfetch" ;;
    mac-pro|mac-studio|mac-mini) prepare_mac_mini_home "$home_dir" ;;
  esac
  prepare_profile_parents "$profile" "$home_dir"
  if [[ "$profile" == mac-thin ]]; then
    chmod 700 "$home_dir/.config" "$home_dir/.config/fastfetch"
  fi
  common=(
    --source "$CHEZMOI_DIR/source"
    --config "$CHEZMOI_DIR/profiles/$profile.toml"
    --destination "$home_dir"
    --persistent-state "$state_dir/$profile.boltdb"
  )

  cut -d '|' -f 1 "$CHEZMOI_DIR/profiles/$profile.paths" | sort \
    > "$case_dir/$profile.expected"
  "$CHEZMOI_BIN" "${common[@]}" managed \
    --include=symlinks --path-style=relative | sort \
    > "$case_dir/$profile.managed"
  diff -u "$case_dir/$profile.expected" "$case_dir/$profile.managed"

  case "$profile" in
    ubuntu) printf '%s\n' 10-configure-git.sh 20-install-ubuntu-tools.sh ;;
    mac-thin) printf '%s\n' 10-configure-git.sh 30-install-thin-tools.sh ;;
    mac-pro) printf '%s\n' 10-configure-git.sh ;;
    mac-studio) printf '%s\n' 10-configure-git.sh ;;
    mac-mini) printf '%s\n' 10-configure-git.sh ;;
    mac-work) printf '%s\n' 10-configure-git.sh 40-install-work-tools.sh ;;
  esac > "$case_dir/$profile.expected-scripts"
  "$CHEZMOI_BIN" "${common[@]}" managed \
    --include=scripts --path-style=relative \
    > "$case_dir/$profile.managed-scripts"
  diff -u "$case_dir/$profile.expected-scripts" \
    "$case_dir/$profile.managed-scripts"

  rendered_git_script="$case_dir/$profile.configure-git.sh"
  "$CHEZMOI_BIN" "${common[@]}" execute-template \
    < "$CHEZMOI_DIR/source/run_once_after_10-configure-git.sh.tmpl" \
    > "$rendered_git_script"
  sh -n "$rendered_git_script"
  if [[ "$profile" == ubuntu ]]; then
    grep -Fq 'git config --global core.editor nvim' "$rendered_git_script"
    grep -Fq 'git config --global core.excludesfile' "$rendered_git_script"
  else
    ! grep -Fq 'git config --global core.editor' "$rendered_git_script"
  fi

  if [[ -f "$CHEZMOI_DIR/profiles/$profile.ancestors" ]]; then
    "$CHEZMOI_BIN" "${common[@]}" apply \
      --exclude=scripts,dirs --force --no-tty
    [[ -z "$("$CHEZMOI_BIN" "${common[@]}" status --exclude=scripts,dirs)" ]]
    "$CHEZMOI_BIN" "${common[@]}" verify --exclude=scripts,dirs
    [[ "$(path_mode "$home_dir/.config")" == 700 ]]
    if [[ "$profile" == mac-thin ]]; then
      [[ "$(path_mode "$home_dir/.config/fastfetch")" == 700 ]]
    fi
    if [[ "$profile" == mac-mini ]]; then
      [[ "$(path_mode "$home_dir/.hermes")" == 700 ]]
    fi
  else
    "$CHEZMOI_BIN" "${common[@]}" apply \
      --exclude=scripts --force --no-tty
    [[ -z "$("$CHEZMOI_BIN" "${common[@]}" status --exclude=scripts)" ]]
    "$CHEZMOI_BIN" "${common[@]}" verify --exclude=scripts
  fi
  DOTFILES_CHEZMOI_TEST=1 \
    CHEZMOI_BIN="$CHEZMOI_BIN" \
    CHEZMOI_DESTINATION="$home_dir" \
    CHEZMOI_STATE_DIR="$state_dir" \
    bash "$CHEZMOI_DIR/doctor.sh" "$profile" >/dev/null
done

studio_guard_home="$case_dir/mac-studio-guard/home"
studio_guard_state="$case_dir/mac-studio-guard/state"
mkdir -p "$studio_guard_home" "$studio_guard_state"
set +e
studio_guard_output="$({
  DOTFILES_CHEZMOI_TEST=1 \
    DOTFILES_CHEZMOI_APPROVED=1 \
    CHEZMOI_BIN="$CHEZMOI_BIN" \
    CHEZMOI_DESTINATION="$studio_guard_home" \
    CHEZMOI_STATE_DIR="$studio_guard_state" \
    bash "$CHEZMOI_DIR/apply.sh" mac-studio
} 2>&1)"
studio_guard_status=$?
set -e
((studio_guard_status != 0))
[[ "$studio_guard_output" == \
  *"mac-studio apply requires DOTFILES_MAC_STUDIO_ARRIVED=1"* ]]

rollback_home="$case_dir/rollback/home"
rollback_state="$case_dir/rollback/state"
rollback_backups="$case_dir/rollback/backups"
mkdir -p "$rollback_home/.config/herdr" "$rollback_home/.config/hunk"
prepare_mac_mini_home "$rollback_home"
rmdir "$rollback_home/.config/btop" "$rollback_home/.config/fastfetch" \
  "$rollback_home/.config/mise"
ln -s "$REPO_DIR/config/btop" "$rollback_home/.config/btop"
ln -s "$REPO_DIR/config/fastfetch" "$rollback_home/.config/fastfetch"
ln -s "$REPO_DIR/config/mise" "$rollback_home/.config/mise"
printf 'original herdr\n' > "$rollback_home/.config/herdr/config.toml"
printf 'original hunk\n' > "$rollback_home/original-hunk.toml"
ln -s "$rollback_home/original-hunk.toml" \
  "$rollback_home/.config/hunk/config.toml"

backup_dir="$(
  DOTFILES_CHEZMOI_TEST=1 \
    CHEZMOI_BIN="$CHEZMOI_BIN" \
    CHEZMOI_DESTINATION="$rollback_home" \
    CHEZMOI_STATE_DIR="$rollback_state" \
    CHEZMOI_BACKUP_ROOT="$rollback_backups" \
    bash "$CHEZMOI_DIR/backup.sh" mac-mini
)"
rollback_common=(
  --source "$CHEZMOI_DIR/source"
  --config "$CHEZMOI_DIR/profiles/mac-mini.toml"
  --destination "$rollback_home"
  --persistent-state "$rollback_state/mac-mini.boltdb"
)
unlink "$rollback_home/.config/btop"
unlink "$rollback_home/.config/fastfetch"
unlink "$rollback_home/.config/mise"
mkdir -m 700 "$rollback_home/.config/btop" "$rollback_home/.config/fastfetch" \
  "$rollback_home/.config/mise"
"$CHEZMOI_BIN" "${rollback_common[@]}" apply \
  --exclude=scripts,dirs --force --no-tty

wrong_host_backup="$rollback_backups/wrong-host-mac-mini"
cp -a "$backup_dir" "$wrong_host_backup"
awk -F $'\t' 'BEGIN { OFS = "\t" } $1 == "host" { $2 = "other-host" } { print }' \
  "$wrong_host_backup/metadata.tsv" \
  > "$wrong_host_backup/metadata.tmp"
mv "$wrong_host_backup/metadata.tmp" "$wrong_host_backup/metadata.tsv"
set +e
wrong_host_output="$({
  DOTFILES_CHEZMOI_TEST=1 \
    CHEZMOI_BIN="$CHEZMOI_BIN" \
    CHEZMOI_DESTINATION="$rollback_home" \
    CHEZMOI_STATE_DIR="$rollback_state" \
    CHEZMOI_BACKUP_ROOT="$rollback_backups" \
    bash "$CHEZMOI_DIR/rollback.sh" mac-mini "$wrong_host_backup" --preview
} 2>&1)"
wrong_host_status=$?
set -e
((wrong_host_status != 0))
[[ "$wrong_host_output" == *"backup host mismatch"* ]]

tampered_backup="$rollback_backups/tampered-mac-mini"
cp -a "$backup_dir" "$tampered_backup"
mkdir -p "$rollback_home/.ssh"
printf 'do not move\n' > "$rollback_home/.ssh/id_ed25519"
printf '.ssh/id_ed25519|absent|||\n' \
  >> "$tampered_backup/manifest.tsv"
set +e
tampered_output="$({
  DOTFILES_CHEZMOI_TEST=1 \
    CHEZMOI_BIN="$CHEZMOI_BIN" \
    CHEZMOI_DESTINATION="$rollback_home" \
    CHEZMOI_STATE_DIR="$rollback_state" \
    CHEZMOI_BACKUP_ROOT="$rollback_backups" \
    bash "$CHEZMOI_DIR/rollback.sh" mac-mini "$tampered_backup" --preview
} 2>&1)"
tampered_status=$?
set -e
((tampered_status != 0))
[[ "$tampered_output" == *"manifest does not match the mac-mini allowlist"* ]]
grep -Fxq 'do not move' "$rollback_home/.ssh/id_ed25519"

DOTFILES_CHEZMOI_TEST=1 \
  CHEZMOI_BIN="$CHEZMOI_BIN" \
  CHEZMOI_DESTINATION="$rollback_home" \
  CHEZMOI_STATE_DIR="$rollback_state" \
  CHEZMOI_BACKUP_ROOT="$rollback_backups" \
  bash "$CHEZMOI_DIR/rollback.sh" mac-mini "$backup_dir" --preview \
  > "$case_dir/rollback-preview.log"
grep -Fq 'rollback preview passed' "$case_dir/rollback-preview.log"
[[ "$(readlink "$rollback_home/.config/herdr/config.toml")" == \
  "$REPO_DIR/config/herdr/config.toml" ]]

DOTFILES_CHEZMOI_TEST=1 \
  CHEZMOI_BIN="$CHEZMOI_BIN" \
  CHEZMOI_DESTINATION="$rollback_home" \
  CHEZMOI_STATE_DIR="$rollback_state" \
  CHEZMOI_BACKUP_ROOT="$rollback_backups" \
  bash "$CHEZMOI_DIR/rollback.sh" mac-mini "$backup_dir" >/dev/null

grep -Fxq 'original herdr' "$rollback_home/.config/herdr/config.toml"
[[ "$(readlink "$rollback_home/.config/hunk/config.toml")" == \
  "$rollback_home/original-hunk.toml" ]]
[[ "$(readlink "$rollback_home/.config/btop")" == \
  "$REPO_DIR/config/btop" ]]
[[ "$(readlink "$rollback_home/.config/fastfetch")" == \
  "$REPO_DIR/config/fastfetch" ]]
[[ "$(readlink "$rollback_home/.config/mise")" == \
  "$REPO_DIR/config/mise" ]]
[[ ! -e "$rollback_home/.zshrc" && ! -L "$rollback_home/.zshrc" ]]

initial_home="$case_dir/initial-rollback/home"
initial_state="$case_dir/initial-rollback/state"
initial_backups="$case_dir/initial-rollback/backups"
mkdir -p "$initial_home/.config" "$initial_state"
ln -s "$REPO_DIR/config/btop" "$initial_home/.config/btop"
ln -s "$REPO_DIR/config/fastfetch" "$initial_home/.config/fastfetch"
initial_backup="$(
  DOTFILES_CHEZMOI_TEST=1 \
    CHEZMOI_BIN="$CHEZMOI_BIN" \
    CHEZMOI_DESTINATION="$initial_home" \
    CHEZMOI_STATE_DIR="$initial_state" \
    CHEZMOI_BACKUP_ROOT="$initial_backups" \
    bash "$CHEZMOI_DIR/backup.sh" ubuntu
)"
initial_common=(
  --source "$CHEZMOI_DIR/source"
  --config "$CHEZMOI_DIR/profiles/ubuntu.toml"
  --destination "$initial_home"
  --persistent-state "$initial_state/ubuntu.boltdb"
)
unlink "$initial_home/.config/btop"
unlink "$initial_home/.config/fastfetch"
mkdir -m 700 "$initial_home/.config/btop" "$initial_home/.config/fastfetch"
prepare_profile_parents ubuntu "$initial_home"
"$CHEZMOI_BIN" "${initial_common[@]}" apply \
  --exclude=scripts,dirs --force --no-tty
[[ -d "$initial_home/.config/btop" && ! -L "$initial_home/.config/btop" ]]
[[ -d "$initial_home/.config/fastfetch" && ! -L "$initial_home/.config/fastfetch" ]]
HOME="$initial_home" \
  DOTFILES_CHEZMOI_TEST=1 \
  CHEZMOI_BIN="$CHEZMOI_BIN" \
  CHEZMOI_DESTINATION="$initial_home" \
  CHEZMOI_STATE_DIR="$initial_state" \
  CHEZMOI_BACKUP_ROOT="$initial_backups" \
  bash "$CHEZMOI_DIR/rollback.sh" ubuntu "$initial_backup" \
  > "$case_dir/initial-rollback.log"
[[ "$(readlink "$initial_home/.config/btop")" == "$REPO_DIR/config/btop" ]]
[[ "$(readlink "$initial_home/.config/fastfetch")" == \
  "$REPO_DIR/config/fastfetch" ]]

activation_home="$case_dir/activation/home"
activation_state="$case_dir/activation/state"
activation_backups="$case_dir/activation/backups"
mkdir -p "$activation_home" "$activation_state"
activation_backup="$({
  DOTFILES_CHEZMOI_TEST=1 \
    CHEZMOI_BIN="$CHEZMOI_BIN" \
    CHEZMOI_DESTINATION="$activation_home" \
    CHEZMOI_STATE_DIR="$activation_state" \
    CHEZMOI_BACKUP_ROOT="$activation_backups" \
    bash "$CHEZMOI_DIR/backup.sh" ubuntu
})"
grep -Fqx $'active\tabsent' "$activation_backup/metadata.tsv"
HOME="$activation_home" \
  DOTFILES_CHEZMOI_TEST=1 \
  CHEZMOI_BIN="$CHEZMOI_BIN" \
  CHEZMOI_DESTINATION="$activation_home" \
  CHEZMOI_STATE_DIR="$activation_state" \
  CHEZMOI_BACKUP_ROOT="$activation_backups" \
  bash -c 'source "$1/lib.sh"; load_profile ubuntu; activate_profile' \
  _ "$CHEZMOI_DIR"
[[ -f "$activation_state/ubuntu-active" ]]
DOTFILES_CHEZMOI_TEST=1 \
  CHEZMOI_BIN="$CHEZMOI_BIN" \
  CHEZMOI_DESTINATION="$activation_home" \
  CHEZMOI_STATE_DIR="$activation_state" \
  CHEZMOI_BACKUP_ROOT="$activation_backups" \
  bash "$CHEZMOI_DIR/rollback.sh" ubuntu "$activation_backup" \
  > "$case_dir/activation-rollback.log"
[[ ! -e "$activation_state/ubuntu-active" ]]
grep -Fq 'the timestamped backup state is active' \
  "$case_dir/activation-rollback.log"

printf 'profile=ubuntu\ncommit=original\n' \
  > "$activation_state/ubuntu-active"
active_backup="$({
  DOTFILES_CHEZMOI_TEST=1 \
    CHEZMOI_BIN="$CHEZMOI_BIN" \
    CHEZMOI_DESTINATION="$activation_home" \
    CHEZMOI_STATE_DIR="$activation_state" \
    CHEZMOI_BACKUP_ROOT="$activation_backups" \
    bash "$CHEZMOI_DIR/backup.sh" ubuntu
})"
grep -Fqx $'active\tpresent' "$active_backup/metadata.tsv"
printf 'profile=ubuntu\ncommit=changed\n' \
  > "$activation_state/ubuntu-active"
DOTFILES_CHEZMOI_TEST=1 \
  CHEZMOI_BIN="$CHEZMOI_BIN" \
  CHEZMOI_DESTINATION="$activation_home" \
  CHEZMOI_STATE_DIR="$activation_state" \
  CHEZMOI_BACKUP_ROOT="$activation_backups" \
  bash "$CHEZMOI_DIR/rollback.sh" ubuntu "$active_backup" >/dev/null
cmp -s "$active_backup/activation-marker" \
  "$activation_state/ubuntu-active"

apply_home="$case_dir/apply/home"
mkdir -p "$apply_home"
prepare_mac_mini_home "$apply_home"
rmdir "$apply_home/.config/btop" "$apply_home/.config/fastfetch" \
  "$apply_home/.config/mise"
ln -s "$REPO_DIR/config/btop" "$apply_home/.config/btop"
ln -s "$REPO_DIR/config/fastfetch" "$apply_home/.config/fastfetch"
ln -s "$REPO_DIR/config/mise" "$apply_home/.config/mise"
HOME="$apply_home" \
  DOTFILES_CHEZMOI_TEST=1 \
  DOTFILES_CHEZMOI_APPROVED=1 \
  DOTFILES_MAC_MINI_CONFIG_ONLY=1 \
  CHEZMOI_BIN="$CHEZMOI_BIN" \
  CHEZMOI_DESTINATION="$apply_home" \
  CHEZMOI_STATE_DIR="$case_dir/apply/state" \
  CHEZMOI_BACKUP_ROOT="$case_dir/apply/backups" \
  bash "$CHEZMOI_DIR/apply.sh" mac-mini \
  > "$case_dir/apply.log"
grep -Fq 'PASS  mac-mini production chezmoi profile' \
  "$case_dir/apply.log"
grep -Fq 'rollback preview passed' "$case_dir/apply.log"
[[ "$(path_mode "$apply_home/.config")" == 700 ]]
[[ "$(path_mode "$apply_home/.hermes")" == 700 ]]
[[ -d "$apply_home/.config/btop" && ! -L "$apply_home/.config/btop" ]]
[[ -d "$apply_home/.config/fastfetch" && ! -L "$apply_home/.config/fastfetch" ]]
[[ -d "$apply_home/.config/mise" && ! -L "$apply_home/.config/mise" ]]
[[ "$(path_mode "$apply_home/.config/btop")" == 700 ]]
[[ "$(path_mode "$apply_home/.config/fastfetch")" == 700 ]]
[[ "$(path_mode "$apply_home/.config/mise")" == 700 ]]
[[ "$(readlink "$apply_home/.config/btop/btop.conf")" == \
  "$REPO_DIR/config/btop/btop.conf" ]]
[[ "$(readlink "$apply_home/.config/fastfetch/config.jsonc")" == \
  "$REPO_DIR/config/fastfetch/config.jsonc" ]]
[[ "$(readlink "$apply_home/.config/mise/config.toml")" == \
  "$REPO_DIR/config/mise/config.toml" ]]

printf 'chezmoi_production_tests=ok\n'
