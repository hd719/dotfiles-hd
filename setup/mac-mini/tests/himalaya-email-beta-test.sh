#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$(cd "$TEST_DIR/.." && pwd)/configure-himalaya-email-beta.sh"
TMP_ROOT="$(mktemp -d)"
TESTS=0
trap 'rm -rf "$TMP_ROOT"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  TESTS=$((TESTS + 1))
  grep -Fq -- "$2" "$1" || fail "expected '$2' in $1"
}

assert_not_contains() {
  TESTS=$((TESTS + 1))
  ! grep -Fq -- "$2" "$1" || fail "did not expect '$2' in $1"
}

assert_eq() {
  TESTS=$((TESTS + 1))
  [[ "$1" == "$2" ]] || fail "$3 (expected '$1', got '$2')"
}

file_mode() {
  if stat -f '%Lp' "$1" >/dev/null 2>&1; then
    stat -f '%Lp' "$1"
  else
    stat -c '%a' "$1"
  fi
}

fake_bin="$TMP_ROOT/bin"
home_dir="$TMP_ROOT/home"
config="$home_dir/.config/himalaya/config.toml"
single_config="$home_dir/.config/himalaya/single.toml"
many_config="$home_dir/.config/himalaya/many.toml"
duplicate_config="$home_dir/.config/himalaya/duplicate.toml"
keychain="$home_dir/Library/Keychains/login.keychain-db"
command_log="$TMP_ROOT/commands.log"
mkdir -p "$fake_bin" "$home_dir" "$(dirname "$keychain")"
touch "$keychain"

cat > "$fake_bin/himalaya" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == '--version' ]]; then
  printf 'himalaya v2.0.0 +imap\n'
  exit 0
fi
printf 'himalaya %s\n' "$*" >> "${COMMAND_LOG:?}"
if [[ " $* " == *' account check '* ]]; then
  if [[ "${HIMALAYA_FAKE_AUTH_OK:-1}" == '1' ]]; then
    printf '{"account":"test","backends":[{"backend":"imap","ok":true,"error":null}]}\n'
  else
    printf '{"account":"test","backends":[{"backend":"imap","ok":false,"error":"test auth failure"}]}\n'
  fi
fi
EOF
chmod +x "$fake_bin/himalaya"

cat > "$fake_bin/security" <<'EOF'
#!/usr/bin/env bash
account=''
service=''
while [[ $# -gt 0 ]]; do
  case "$1" in
    -a) account="$2"; shift 2 ;;
    -s) service="$2"; shift 2 ;;
    *) shift ;;
  esac
done
IFS= read -r secret
[[ -n "$secret" ]] || exit 41
printf 'security account=%s service=%s\n' "$account" "$service" >> "${COMMAND_LOG:?}"
EOF
chmod +x "$fake_bin/security"

run_configure_two() {
  printf '%s\n' \
    2 \
    personal personal@example.com \
    work work@example.com \
    first-test-password second-test-password \
    | HOME="$home_dir" \
      COMMAND_LOG="$command_log" \
      HIMALAYA_BIN="$fake_bin/himalaya" \
      SECURITY_BIN="$fake_bin/security" \
      HIMALAYA_KEYCHAIN_PATH="$keychain" \
      HIMALAYA_CONFIG_PATH="$config" \
      HIMALAYA_BETA_ALLOW_NONINTERACTIVE=1 \
      "$SCRIPT" --configure >/dev/null
}

run_configure_one() {
  printf '%s\n' \
    1 \
    personal personal@example.com \
    first-test-password \
    | HOME="$home_dir" \
      COMMAND_LOG="$command_log" \
      HIMALAYA_BIN="$fake_bin/himalaya" \
      SECURITY_BIN="$fake_bin/security" \
      HIMALAYA_KEYCHAIN_PATH="$keychain" \
      HIMALAYA_CONFIG_PATH="$single_config" \
      HIMALAYA_BETA_ALLOW_NONINTERACTIVE=1 \
      "$SCRIPT" --configure >/dev/null
}

run_configure_many() {
  printf '%s\n' \
    3 \
    personal personal@example.com \
    work work@example.com \
    archive archive@example.com \
    first-test-password second-test-password third-test-password \
    | HOME="$home_dir" \
      COMMAND_LOG="$command_log" \
      HIMALAYA_BIN="$fake_bin/himalaya" \
      SECURITY_BIN="$fake_bin/security" \
      HIMALAYA_KEYCHAIN_PATH="$keychain" \
      HIMALAYA_CONFIG_PATH="$many_config" \
      HIMALAYA_BETA_ALLOW_NONINTERACTIVE=1 \
      "$SCRIPT" --configure >/dev/null
}

run_configure_two
config_mode="$(file_mode "$config")"
assert_eq '600' "$config_mode" 'config is private'
assert_eq '2' "$(grep -c '^\[accounts\.' "$config")" 'config has exactly two accounts'
assert_contains "$config" '[accounts.personal]'
assert_contains "$config" '[accounts.work]'
assert_contains "$config" 'imap.sasl.plain.username = "personal@example.com"'
assert_contains "$config" 'hd.himalaya.personal'
assert_contains "$config" 'hd.himalaya.work'
assert_contains "$config" "imap.sasl.plain.password.command = [\"/usr/bin/security\", \"find-generic-password\", \"-w\", \"-s\", \"hd.himalaya.personal\", \"-a\", \"personal@example.com\", \"$keychain\"]"
assert_not_contains "$config" 'first-test-password'
assert_not_contains "$config" 'second-test-password'
assert_not_contains "$config" 'smtp.'
assert_contains "$command_log" 'security account=personal@example.com service=hd.himalaya.personal'
assert_contains "$command_log" 'security account=work@example.com service=hd.himalaya.work'

if [[ -n "${REAL_HIMALAYA_BIN:-}" ]]; then
  "$REAL_HIMALAYA_BIN" -c "$config" account list >/dev/null
  TESTS=$((TESTS + 1))
fi

run_configure_one
assert_eq '1' "$(grep -c '^\[accounts\.' "$single_config")" 'single config has one account'
assert_contains "$single_config" '[accounts.personal]'
assert_not_contains "$single_config" '[accounts.work]'
assert_not_contains "$single_config" 'second-test-password'
if [[ -n "${REAL_HIMALAYA_BIN:-}" ]]; then
  "$REAL_HIMALAYA_BIN" -c "$single_config" account list >/dev/null
  TESTS=$((TESTS + 1))
fi

run_configure_many
assert_eq '3' "$(grep -c '^\[accounts\.' "$many_config")" 'many config has three accounts'
assert_contains "$many_config" '[accounts.archive]'
assert_contains "$many_config" 'hd.himalaya.archive'
assert_not_contains "$many_config" 'third-test-password'
assert_contains "$command_log" 'security account=archive@example.com service=hd.himalaya.archive'
if [[ -n "${REAL_HIMALAYA_BIN:-}" ]]; then
  "$REAL_HIMALAYA_BIN" -c "$many_config" account list >/dev/null
  TESTS=$((TESTS + 1))
fi

HOME="$home_dir" \
  COMMAND_LOG="$command_log" \
  HIMALAYA_BIN="$fake_bin/himalaya" \
  HIMALAYA_CONFIG_PATH="$many_config" \
  "$SCRIPT" --check >/dev/null

HOME="$home_dir" \
  COMMAND_LOG="$command_log" \
  HIMALAYA_BIN="$fake_bin/himalaya" \
  HIMALAYA_CONFIG_PATH="$config" \
  "$SCRIPT" --check >/dev/null
assert_contains "$command_log" '--backend imap account check --json'

auth_failure_log="$TMP_ROOT/auth-failure.log"
if HOME="$home_dir" \
  COMMAND_LOG="$command_log" \
  HIMALAYA_BIN="$fake_bin/himalaya" \
  HIMALAYA_CONFIG_PATH="$config" \
  HIMALAYA_FAKE_AUTH_OK=0 \
  "$SCRIPT" --check >"$auth_failure_log" 2>&1; then
  fail 'expected failed backend auth to fail --check'
fi
TESTS=$((TESTS + 1))
assert_contains "$auth_failure_log" 'IMAP authentication failed'

duplicate_log="$TMP_ROOT/duplicate.log"
if printf '%s\n' \
  2 \
  personal personal@example.com \
  personal archive@example.com \
  | HOME="$home_dir" \
    COMMAND_LOG="$command_log" \
    HIMALAYA_BIN="$fake_bin/himalaya" \
    SECURITY_BIN="$fake_bin/security" \
    HIMALAYA_KEYCHAIN_PATH="$keychain" \
    HIMALAYA_CONFIG_PATH="$duplicate_config" \
    HIMALAYA_BETA_ALLOW_NONINTERACTIVE=1 \
    "$SCRIPT" --configure >"$duplicate_log" 2>&1; then
  fail 'expected a duplicate account name to fail configuration'
fi
TESTS=$((TESTS + 1))
assert_contains "$duplicate_log" "account name 'personal' is already configured"

run_configure_two
assert_eq '1' "$(find "$(dirname "$config")" -maxdepth 1 -name 'config.toml.backup-*' | wc -l | tr -d ' ')" \
  'reconfigure creates one backup'

printf 'Himalaya email beta tests passed: %d assertions.\n' "$TESTS"
