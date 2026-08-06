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

for script in "$CHEZMOI_DIR"/*.sh; do
  bash -n "$script"
done
[[ "$(wc -l < "$CHEZMOI_DIR/bootstrap.sh" | tr -d ' ')" -le 25 ]]

for profile in ubuntu mac-thin mac-mini work-mac; do
  home_dir="$case_dir/$profile/home"
  state_dir="$case_dir/$profile/state"
  mkdir -p "$home_dir" "$state_dir"
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
    mac-mini) printf '%s\n' 10-configure-git.sh ;;
    work-mac) printf '%s\n' 10-configure-git.sh 40-install-work-tools.sh ;;
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

  "$CHEZMOI_BIN" "${common[@]}" apply \
    --exclude=scripts --force --no-tty
  [[ -z "$("$CHEZMOI_BIN" "${common[@]}" status)" ]]
  "$CHEZMOI_BIN" "${common[@]}" verify --exclude=scripts
  DOTFILES_CHEZMOI_TEST=1 \
    CHEZMOI_BIN="$CHEZMOI_BIN" \
    CHEZMOI_DESTINATION="$home_dir" \
    CHEZMOI_STATE_DIR="$state_dir" \
    bash "$CHEZMOI_DIR/doctor.sh" "$profile" >/dev/null
done

rollback_home="$case_dir/rollback/home"
rollback_state="$case_dir/rollback/state"
rollback_backups="$case_dir/rollback/backups"
mkdir -p "$rollback_home/.config/herdr" "$rollback_home/.config/hunk"
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
"$CHEZMOI_BIN" "${rollback_common[@]}" apply \
  --exclude=scripts --force --no-tty
DOTFILES_CHEZMOI_TEST=1 \
  CHEZMOI_BIN="$CHEZMOI_BIN" \
  CHEZMOI_DESTINATION="$rollback_home" \
  CHEZMOI_STATE_DIR="$rollback_state" \
  CHEZMOI_BACKUP_ROOT="$rollback_backups" \
  bash "$CHEZMOI_DIR/rollback.sh" mac-mini "$backup_dir" >/dev/null

grep -Fxq 'original herdr' "$rollback_home/.config/herdr/config.toml"
[[ "$(readlink "$rollback_home/.config/hunk/config.toml")" == \
  "$rollback_home/original-hunk.toml" ]]
[[ ! -e "$rollback_home/.zshrc" && ! -L "$rollback_home/.zshrc" ]]

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
grep -Fq 'the previous writer is active again' \
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

printf 'chezmoi_production_tests=ok\n'
