#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="${HIMALAYA_CONFIG_PATH:-$HOME/.config/himalaya/config.toml}"
HIMALAYA_BIN="${HIMALAYA_BIN:-$(command -v himalaya || true)}"
SECURITY_BIN="${SECURITY_BIN:-/usr/bin/security}"
KEYCHAIN_PATH="${HIMALAYA_KEYCHAIN_PATH:-$HOME/Library/Keychains/login.keychain-db}"

usage() {
  printf 'Usage: %s --configure|--check\n' "$(basename "$0")"
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

file_mode() {
  if stat -f '%Lp' "$1" >/dev/null 2>&1; then
    stat -f '%Lp' "$1"
  else
    stat -c '%a' "$1"
  fi
}

next_backup_path() {
  local path="$1"
  local stamp="$2"
  local candidate="${path}.backup-${stamp}"
  local suffix=1

  while [[ -e "$candidate" || -L "$candidate" ]]; do
    candidate="${path}.backup-${stamp}.${suffix}"
    suffix=$((suffix + 1))
  done
  printf '%s\n' "$candidate"
}

validate_account_name() {
  printf '%s\n' "$1" | grep -Eq '^[a-z0-9][a-z0-9_-]*$' \
    || die "account name '$1' must use lowercase letters, numbers, dashes, or underscores"
}

validate_email() {
  printf '%s\n' "$1" | grep -Eq '^[^[:space:]@"]+@[^[:space:]@"]+\.[^[:space:]@"]+$' \
    || die "invalid email address: $1"
}

toml_quote() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '"%s"' "$value"
}

write_account() {
  local destination="$1"
  local account="$2"
  local email="$3"
  local is_default="$4"
  local keychain_path="$5"
  local service="hd.himalaya.${account}"

  {
    printf '[accounts.%s]\n' "$account"
    printf 'default = %s\n' "$is_default"
    printf 'imap.server = "imaps://imap.gmail.com:993"\n'
    printf 'imap.sasl.plain.username = %s\n' "$(toml_quote "$email")"
    printf 'imap.sasl.plain.password.command = ['
    printf '"/usr/bin/security", "find-generic-password", "-w", "-s", %s, "-a", %s, %s' \
      "$(toml_quote "$service")" "$(toml_quote "$email")" \
      "$(toml_quote "$keychain_path")"
    printf ']\n'
    printf 'mailbox.alias.inbox = "INBOX"\n'
    printf 'mailbox.alias.sent = "[Gmail]/Sent Mail"\n'
    printf 'mailbox.alias.drafts = "[Gmail]/Drafts"\n'
    printf 'mailbox.alias.trash = "[Gmail]/Trash"\n'
    printf 'mailbox.alias.archive = "[Gmail]/All Mail"\n\n'
  } >> "$destination"
}

check_config() {
  local version
  local mode
  local account
  local check_result
  local compact_result
  local -a accounts=()

  [[ -n "$HIMALAYA_BIN" && -x "$HIMALAYA_BIN" ]] || die 'Himalaya is not installed'
  version="$($HIMALAYA_BIN --version | head -n 1)"
  [[ "$version" == 'himalaya v2.'* ]] || die "Himalaya 2.x required, got: $version"
  [[ -f "$CONFIG_PATH" && ! -L "$CONFIG_PATH" ]] || die "missing regular config file: $CONFIG_PATH"

  mode="$(file_mode "$CONFIG_PATH")"
  [[ "$mode" == '600' ]] || die "config mode must be 600, got $mode"

  while IFS= read -r account; do
    accounts+=("$account")
  done < <(sed -nE 's/^\[accounts\.([a-z0-9_-]+)\]$/\1/p' "$CONFIG_PATH")
  (( ${#accounts[@]} >= 1 )) \
    || die "expected at least one account, found ${#accounts[@]}"

  "$HIMALAYA_BIN" -c "$CONFIG_PATH" account list >/dev/null
  for account in "${accounts[@]}"; do
    if ! check_result="$("$HIMALAYA_BIN" -c "$CONFIG_PATH" -a "$account" \
      --backend imap account check --json 2>/dev/null)"; then
      die "$account IMAP authentication check failed"
    fi
    compact_result="$(printf '%s' "$check_result" | tr -d '[:space:]')"
    if [[ "$compact_result" != *'"backend":"imap"'* \
      || "$compact_result" != *'"ok":true'* \
      || "$compact_result" == *'"ok":false'* ]]; then
      die "$account IMAP authentication failed"
    fi
    printf 'PASS  %s IMAP authentication\n' "$account"
  done
  printf 'Himalaya email beta check passed.\n'
}

configure() {
  local index
  local temporary
  local backup_path
  local stamp
  local service
  local account_count
  local is_default
  local account
  local email
  local existing_index
  local -a accounts=()
  local -a emails=()

  if [[ "${HIMALAYA_BETA_ALLOW_NONINTERACTIVE:-0}" != '1' && ! -t 0 ]]; then
    die '--configure requires an interactive terminal'
  fi
  [[ -n "$HIMALAYA_BIN" && -x "$HIMALAYA_BIN" ]] || die 'Himalaya is not installed'
  [[ -x "$SECURITY_BIN" ]] || die "security tool missing: $SECURITY_BIN"
  if [[ -e "$CONFIG_PATH" || -L "$CONFIG_PATH" ]]; then
    [[ -f "$CONFIG_PATH" && ! -L "$CONFIG_PATH" ]] \
      || die "refusing to replace non-regular config: $CONFIG_PATH"
  fi

  read -r -p 'Number of accounts to configure [1+]: ' account_count
  [[ "$account_count" =~ ^[1-9][0-9]*$ ]] \
    || die 'account count must be a positive integer'
  for ((index = 1; index <= account_count; index++)); do
    read -r -p "Account $index short name: " account
    read -r -p "Account $index Gmail or Workspace address: " email
    validate_account_name "$account"
    validate_email "$email"
    for ((existing_index = 0; existing_index < index - 1; existing_index++)); do
      [[ "$account" != "${accounts[$existing_index]}" ]] \
        || die "account name '$account' is already configured"
      [[ "$email" != "${emails[$existing_index]}" ]] \
        || die "email address '$email' is already configured"
    done
    accounts+=("$account")
    emails+=("$email")
  done

  umask 077
  mkdir -p "$(dirname "$CONFIG_PATH")"
  temporary="$(mktemp "$(dirname "$CONFIG_PATH")/.himalaya-beta.XXXXXX")"
  trap 'rm -f "${temporary:-}"' EXIT
  {
    printf '# Generated by dotfiles-hd. Machine-owned; never commit.\n'
    printf '# IMAP-only one-or-N-account beta. SMTP is intentionally absent.\n\n'
  } > "$temporary"
  for index in "${!accounts[@]}"; do
    is_default=false
    if [[ "$index" -eq 0 ]]; then
      is_default=true
    fi
    write_account "$temporary" "${accounts[$index]}" "${emails[$index]}" \
      "$is_default" "$KEYCHAIN_PATH"
  done
  "$HIMALAYA_BIN" -c "$temporary" account list >/dev/null

  for index in "${!accounts[@]}"; do
    service="hd.himalaya.${accounts[$index]}"
    printf 'Enter the Google app password for %s in the Keychain prompt.\n' "${emails[$index]}"
    "$SECURITY_BIN" add-generic-password -U \
      -a "${emails[$index]}" -s "$service" -w
  done

  if [[ -e "$CONFIG_PATH" || -L "$CONFIG_PATH" ]]; then
    stamp="$(date +%Y%m%d-%H%M%S)"
    backup_path="$(next_backup_path "$CONFIG_PATH" "$stamp")"
    cp -p "$CONFIG_PATH" "$backup_path"
    printf 'Backed up existing config: %s\n' "$backup_path"
  fi
  install -m 600 "$temporary" "$CONFIG_PATH"
  rm -f "$temporary"
  trap - EXIT
  check_config
}

case "${1:-}" in
  --configure)
    [[ "$#" -eq 1 ]] || { usage >&2; exit 2; }
    configure
    ;;
  --check)
    [[ "$#" -eq 1 ]] || { usage >&2; exit 2; }
    check_config
    ;;
  -h|--help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
