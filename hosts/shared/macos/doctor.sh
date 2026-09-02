#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$REPO_DIR}"
GIT_ALIASES_SCRIPT="$DOTFILES_DIR/config/git/configure-aliases.sh"
CHEZMOI_DOCTOR="${DOTFILES_CHEZMOI_DOCTOR:-$DOTFILES_DIR/chezmoi/doctor.sh}"
PROFILE=""
FAILURES=0
MISE_RUNTIME_FAILURES=0
APPLICATIONS_DIR="${DOTFILES_APPLICATIONS_DIR:-/Applications}"
PKGUTIL="${DOTFILES_PKGUTIL:-/usr/sbin/pkgutil}"
VAGRANT_VMWARE_PLUGIN_VERSION="3.0.5"
VAGRANT_VMWARE_UTILITY="${DOTFILES_VAGRANT_VMWARE_UTILITY:-/opt/vagrant-vmware-desktop/bin/vagrant-vmware-utility}"
VAGRANT_VMWARE_SERVICE_LABEL="com.vagrant.vagrant-vmware-utility"
SSH_CONFIG="$HOME/.ssh/config"
UBUNTU_LOGIN_KEY="$HOME/.ssh/id_ed25519_ubuntu_vm"

# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

usage() {
  printf 'Usage: doctor.sh --profile mac-pro|mac-studio|mac-mini\n'
}

pass() {
  printf 'PASS  %s\n' "$*"
}

fail() {
  printf 'FAIL  %s\n' "$*" >&2
  FAILURES=$((FAILURES + 1))
}

vagrant_vmware_plugin_current() {
  command -v vagrant >/dev/null 2>&1 \
    && vagrant plugin list 2>/dev/null \
      | /usr/bin/grep -Eq \
        "^vagrant-vmware-desktop \($VAGRANT_VMWARE_PLUGIN_VERSION([,)])"
}

check_studio_ubuntu_ssh_alias() {
  local ssh_alias="$1"
  local expected_hostname="$2"
  local expected_port="$3"
  local effective

  effective="$(ssh -G -F "$SSH_CONFIG" "$ssh_alias" 2>/dev/null || true)"
  if printf '%s\n' "$effective" \
    | /usr/bin/grep -Fxq "hostname $expected_hostname" \
    && printf '%s\n' "$effective" | /usr/bin/grep -Fxq "port $expected_port" \
    && printf '%s\n' "$effective" | /usr/bin/grep -Fxq "user hamel" \
    && printf '%s\n' "$effective" | /usr/bin/grep -Fxq "addressfamily inet" \
    && printf '%s\n' "$effective" | /usr/bin/grep -Fxq "identitiesonly yes" \
    && printf '%s\n' "$effective" | /usr/bin/grep -Fxq "forwardagent no" \
    && printf '%s\n' "$effective" | /usr/bin/grep -Fxq "hostkeyalias ubuntu-dev" \
    && printf '%s\n' "$effective" | /usr/bin/grep -Fxq "stricthostkeychecking true" \
    && printf '%s\n' "$effective" \
      | /usr/bin/grep -Fq "$(basename "$UBUNTU_LOGIN_KEY")"; then
    pass "$ssh_alias Ubuntu route"
  else
    fail "$ssh_alias Ubuntu route is missing or unsafe"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      PROFILE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'error: unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

[[ -n "$PROFILE" ]] || { usage >&2; exit 2; }
PROFILE="$(canonical_profile "$PROFILE")" || exit 2
load_profile "$PROFILE" "$DOTFILES_DIR" "$HOME" || exit 2
load_mise_specs "$MISE_CONFIG" || exit 2
export MISE_AUTO_INSTALL=0

if "$CHEZMOI_DOCTOR" "$PROFILE"; then
  pass "$PROFILE Chezmoi configuration"
else
  fail "$PROFILE Chezmoi configuration"
fi

check_approved_pin() {
  local tool="$1"
  local actual="$2"
  local expected="$3"

  if [[ "$actual" == "$expected" ]]; then
    pass "$tool config pin is $expected"
  else
    fail "$tool config pin expected $expected, got $actual"
  fi
}

check_approved_pin node "$NODE_VERSION" "$APPROVED_NODE_VERSION"
check_approved_pin pnpm "$PNPM_VERSION" "$APPROVED_PNPM_VERSION"
check_approved_pin go "$GO_VERSION" "$APPROVED_GO_VERSION"
check_approved_pin python "$PYTHON_VERSION" "$APPROVED_PYTHON_VERSION"
check_approved_pin bun "$BUN_VERSION" "$APPROVED_BUN_VERSION"

for brewfile in "$COMMON_BREWFILE" "$PROFILE_BREWFILE"; do
  if HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --no-upgrade --file "$brewfile" >/dev/null; then
    pass "Brewfile satisfied: $brewfile"
  else
    fail "Brewfile missing dependencies: $brewfile"
  fi
done

if [[ "$PROFILE" == mac-studio ]]; then
  if "$PKGUTIL" --pkg-info com.apple.pkg.RosettaUpdateAuto >/dev/null 2>&1; then
    pass "Rosetta 2 installed"
  else
    fail "Rosetta 2 missing"
  fi

  if command -v vagrant >/dev/null 2>&1; then
    pass "Vagrant available"
  else
    fail "Vagrant missing"
  fi

  if [[ -x "$VAGRANT_VMWARE_UTILITY" ]]; then
    pass "Vagrant VMware utility available"
  else
    fail "Vagrant VMware utility missing"
  fi

  if launchctl print "system/$VAGRANT_VMWARE_SERVICE_LABEL" >/dev/null 2>&1; then
    pass "Vagrant VMware utility service active"
  else
    fail "Vagrant VMware utility service is not active"
  fi

  if vagrant_vmware_plugin_current; then
    pass "Vagrant VMware provider $VAGRANT_VMWARE_PLUGIN_VERSION"
  else
    fail "Vagrant VMware provider must be $VAGRANT_VMWARE_PLUGIN_VERSION"
  fi

  for app_name in "VMware Fusion.app" "Ollama.app"; do
    if [[ -d "$APPLICATIONS_DIR/$app_name" ]]; then
      pass "$app_name installed"
    else
      fail "$app_name missing"
    fi
  done

  if [[ "${DOTFILES_MAC_STUDIO_CUTOVER:-0}" == "1" ]]; then
    if [[ -r "$SSH_CONFIG" ]]; then
      pass "SSH config readable"
      check_studio_ubuntu_ssh_alias ubuntu-vm 127.0.0.1 2222
      check_studio_ubuntu_ssh_alias ubuntu-vm-ts ubuntu-dev 22
    else
      fail "SSH config missing or unreadable"
    fi
    if [[ -f "$UBUNTU_LOGIN_KEY" \
      && "$(stat -f '%Lp' "$UBUNTU_LOGIN_KEY" 2>/dev/null)" == "600" ]]; then
      pass "Ubuntu login key present with mode 600"
    else
      fail "Ubuntu login key missing or not mode 600"
    fi
  else
    printf 'SKIP  Studio Ubuntu SSH routes until DOTFILES_MAC_STUDIO_CUTOVER=1\n'
  fi
fi

if "$GIT_ALIASES_SCRIPT" --check >/dev/null 2>&1; then
  pass "portable Git aliases"
else
  fail "portable Git aliases are not configured"
fi

if zprofile_block_matches "$HOME/.zprofile" "$MISE_FRAGMENT"; then
  pass "mise shims block is exact in ~/.zprofile"
else
  fail "mise shims block is missing, malformed, or stale in ~/.zprofile"
fi

check_mise_version() {
  local tool="$1"
  local expected="$2"
  local command_name="$3"
  local version_argument="--version"
  local normalized
  local actual

  if ! MISE_NO_CONFIG=1 mise where "$tool@$expected" >/dev/null 2>&1; then
    fail "$tool $expected is not installed by mise"
    MISE_RUNTIME_FAILURES=$((MISE_RUNTIME_FAILURES + 1))
    return
  fi

  [[ "$command_name" == "go" ]] && version_argument="version"
  actual="$(MISE_NO_CONFIG=1 mise exec "$tool@$expected" -- "$command_name" "$version_argument" 2>/dev/null | head -n 1)"
  normalized="$(normalize_tool_version "$tool" "$actual")"
  if [[ "$normalized" == "$expected" ]]; then
    pass "$tool $expected"
  else
    fail "$tool expected $expected, got '${normalized:-missing}'"
    MISE_RUNTIME_FAILURES=$((MISE_RUNTIME_FAILURES + 1))
  fi
}

normalize_tool_version() {
  local tool="$1"
  local output="$2"

  output="${output//$'\r'/}"
  output="${output%%$'\n'*}"
  case "$tool" in
    node) output="${output#v}" ;;
    go)
      output="${output#go version go}"
      output="${output%% *}"
      ;;
    python)
      output="${output#Python }"
      output="${output%% *}"
      ;;
    pnpm|bun) output="${output%% *}" ;;
  esac
  printf '%s\n' "$output"
}

check_mise_version node "$APPROVED_NODE_VERSION" node
check_mise_version pnpm "$APPROVED_PNPM_VERSION" pnpm
check_mise_version go "$APPROVED_GO_VERSION" go
check_mise_version python "$APPROVED_PYTHON_VERSION" python
check_mise_version bun "$APPROVED_BUN_VERSION" bun

if [[ "$MISE_RUNTIME_FAILURES" -eq 0 ]]; then
  for command_name in npm npx; do
    if MISE_NO_CONFIG=1 mise exec "node@$NODE_VERSION" -- "$command_name" --version >/dev/null 2>&1; then
      pass "$command_name remains available through mise Node"
    else
      fail "$command_name is missing from mise Node"
    fi
  done

  required_commands='mise node npm npx pnpm go python bun nvim rg fd fzf lazygit hunk tree-sitter lua-language-server marksman stylua vtsls vscode-eslint-language-server bash-language-server gopls ruff mdformat'
  shell_baseline_path="$(sanitize_shell_path "$PATH")"
  shell_version_probe='printf "__DOTFILES_NODE__=%s\n" "$(node --version 2>/dev/null)"
printf "__DOTFILES_PNPM__=%s\n" "$(pnpm --version 2>/dev/null)"
printf "__DOTFILES_GO__=%s\n" "$(go version 2>/dev/null)"
printf "__DOTFILES_PYTHON__=%s\n" "$(python --version 2>/dev/null)"
printf "__DOTFILES_BUN__=%s\n" "$(bun --version 2>/dev/null)"'
  for shell_mode in '-lic' '-lc'; do
    if HOME="$HOME" PATH="$shell_baseline_path" /bin/zsh "$shell_mode" "for tool in $required_commands; do command -v \"\$tool\" >/dev/null || exit 1; done" >/dev/null 2>&1; then
      pass "zsh $shell_mode resolves the required toolchain"
    else
      fail "zsh $shell_mode cannot resolve the full required toolchain"
    fi

    shell_versions="$(HOME="$HOME" PATH="$shell_baseline_path" /bin/zsh "$shell_mode" "$shell_version_probe" 2>/dev/null || true)"
    for version_spec in \
      "node|$NODE_VERSION|NODE" \
      "pnpm|$PNPM_VERSION|PNPM" \
      "go|$GO_VERSION|GO" \
      "python|$PYTHON_VERSION|PYTHON" \
      "bun|$BUN_VERSION|BUN"; do
      tool="${version_spec%%|*}"
      version_spec="${version_spec#*|}"
      expected="${version_spec%%|*}"
      tag="${version_spec#*|}"
      raw_version="$(printf '%s\n' "$shell_versions" | sed -n "s/^__DOTFILES_${tag}__=//p" | tail -n 1)"
      actual_version="$(normalize_tool_version "$tool" "$raw_version")"
      if [[ "$actual_version" == "$expected" ]]; then
        pass "zsh $shell_mode active $tool is $expected"
      else
        fail "zsh $shell_mode active $tool expected $expected, got '${actual_version:-missing}'"
      fi
    done
  done
else
  fail "active shell checks skipped because pinned mise runtimes are missing"
fi

if [[ "$PROFILE" == mac-mini ]]; then
  if /bin/zsh -lic '
    test "$(whence -w herdr)" = "herdr: function"
    test "$(whence -w _dotfiles_herdr_reset)" = "_dotfiles_herdr_reset: function"
    test "$(alias hdk)" = "hdk='\''herdr server reset'\''"
  ' >/dev/null 2>&1; then
    pass "Mac mini shared Herdr reset"
  else
    fail "Mac mini shared Herdr reset is unavailable"
  fi
fi

ruff_output="$("${XDG_BIN_HOME:-$HOME/.local/bin}/ruff" --version 2>/dev/null || true)"
if [[ "$ruff_output" == "ruff 0.15.21" ]]; then
  pass "Ruff 0.15.21"
else
  fail "Ruff expected 0.15.21, got '${ruff_output:-missing}'"
fi

mdformat_output="$("${XDG_BIN_HOME:-$HOME/.local/bin}/mdformat" --version 2>/dev/null || true)"
mdformat_components="$(printf '%s\n' "$mdformat_output" \
  | tr '(),' '\n' \
  | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
for expected_component in \
  'mdformat 1.0.0' \
  'mdformat_gfm_alerts 2.0.0' \
  'mdformat-gfm 1.0.0' \
  'mdformat_footnote 0.1.3' \
  'mdformat_wikilink 0.3.0' \
  'mdformat_frontmatter 2.1.2'; do
  if grep -Fqx "$expected_component" <<< "$mdformat_components"; then
    pass "$expected_component"
  else
    fail "mdformat component missing or wrong: $expected_component"
  fi
done

graphql_lsp="$HOME/.local/graphql-lsp/bin/graphql-lsp"
graphql_marker="$HOME/.local/graphql-lsp/.pnpm-managed-version"
graphql_marker_value="graphql-language-service-cli@3.5.0 via pnpm@$PNPM_VERSION"
if [[ "$MISE_RUNTIME_FAILURES" -eq 0 ]]; then
  graphql_output="$(MISE_NO_CONFIG=1 mise exec "node@$NODE_VERSION" -- "$graphql_lsp" --version 2>/dev/null || true)"
  if [[ "$graphql_output" == "3.5.0" ]] \
    && [[ -f "$graphql_marker" ]] \
    && [[ "$(cat "$graphql_marker")" == "$graphql_marker_value" ]]; then
    pass "GraphQL LSP 3.5.0 installed with pnpm at fixed prefix"
  else
    fail "GraphQL LSP expected pnpm-managed 3.5.0, got '${graphql_output:-missing}'"
  fi
else
  fail "GraphQL LSP check skipped because pinned mise Node is missing"
fi

nvim_version_output="$(nvim --version 2>/dev/null | head -n 1)"
nvim_version="${nvim_version_output#NVIM v}"
nvim_major="${nvim_version%%.*}"
nvim_remainder="${nvim_version#*.}"
nvim_minor="${nvim_remainder%%.*}"
if [[ "$nvim_major" =~ ^[0-9]+$ && "$nvim_minor" =~ ^[0-9]+$ ]] \
  && (( nvim_major > 0 || (nvim_major == 0 && nvim_minor >= 12) )); then
  pass "Neovim is $nvim_version (required 0.12+)"
else
  fail "Neovim 0.12+ required, got '${nvim_version_output:-missing}'"
fi

nvim_runtime_ready=0
if ! verify_neovim_plugins_restored "$DOTFILES_DIR/config/nvim/lazy-lock.json"; then
  fail "Neovim plugins are not fully restored"
elif ! verify_neovim_parsers_restored; then
  fail "Tree-sitter parsers are not fully restored"
elif verify_neovim_config_sandboxed "$DOTFILES_DIR/config/nvim"; then
  pass "Neovim config starts in an isolated, network-blocked data directory"
  nvim_runtime_ready=1
else
  fail "Neovim isolated headless startup"
fi

if [[ "$nvim_runtime_ready" -eq 1 ]]; then
  if DOTFILES_NVIM_PROFILE=full nvim --headless "$DOTFILES_DIR/config/nvim/README.md" \
    "+lua assert(not vim.lsp.is_enabled('marksman'),'Marksman was enabled globally'); local mapping=vim.fn.maparg(' mm','n',false,true); assert(mapping.desc=='Toggle Marksman for file','Space m m is not mapped to Marksman'); local bufnr=vim.api.nvim_get_current_buf(); vim.cmd.MarksmanToggleCurrent(); assert(vim.wait(5000,function() return #vim.lsp.get_clients({bufnr=bufnr,name='marksman'})>0 end),'Marksman did not attach on request'); vim.cmd.MarksmanToggleCurrent(); assert(vim.wait(5000,function() return #vim.lsp.get_clients({bufnr=bufnr,name='marksman'})==0 end),'Marksman did not detach on request')" \
    '+qa!' >/dev/null 2>&1; then
    pass "Full-profile Marksman toggles per Markdown buffer"
  else
    fail "Full-profile Marksman does not toggle per Markdown buffer"
  fi
fi

if [[ "$FAILURES" -eq 0 ]]; then
  printf 'Doctor passed for %s.\n' "$PROFILE"
  exit 0
fi

printf 'Doctor found %d failure(s).\n' "$FAILURES" >&2
exit 1
