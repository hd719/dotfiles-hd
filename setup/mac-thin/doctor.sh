#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$REPO_DIR}"
GIT_ALIASES_SCRIPT="$DOTFILES_DIR/config/git/configure-aliases.sh"
APPLICATIONS_DIR="${DOTFILES_APPLICATIONS_DIR:-/Applications}"
BREWFILE="$DOTFILES_DIR/setup/mac-thin/Brewfile"
SSH_CONFIG="$HOME/.ssh/config"
VAGRANT_SSH_CONFIG="$DOTFILES_DIR/setup/mac-thin/ssh/ubuntu-vagrant.conf"
UBUNTU_LOGIN_KEY="$HOME/.ssh/id_ed25519_ubuntu_vm"
UBUNTU_LOGIN_KEY_NAME="$(basename "$UBUNTU_LOGIN_KEY")"
FAILURES=0
VAGRANT_VMWARE_PLUGIN_VERSION="3.0.5"
VAGRANT_VMWARE_UTILITY="${DOTFILES_VAGRANT_VMWARE_UTILITY:-/opt/vagrant-vmware-desktop/bin/vagrant-vmware-utility}"
VAGRANT_VMWARE_SERVICE_LABEL="com.vagrant.vagrant-vmware-utility"
HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"

# shellcheck source=../mac-bootstrap/lib.sh
source "$DOTFILES_DIR/setup/mac-bootstrap/lib.sh"

NEOVIM_PARSERS=(markdown markdown_inline)
NEOVIM_PARSER_BINARIES=(markdown markdown_inline)

pass() {
  printf 'PASS  %s\n' "$*"
}

fail() {
  printf 'FAIL  %s\n' "$*" >&2
  FAILURES=$((FAILURES + 1))
}

if [[ "$(uname -s)" == "Darwin" && "$(uname -m)" == "arm64" ]]; then
  pass "Apple Silicon macOS"
else
  fail "Apple Silicon macOS required"
fi

if command -v brew >/dev/null 2>&1; then
  pass "Homebrew available"
else
  fail "Homebrew missing"
fi

if HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --no-upgrade --file "$BREWFILE" >/dev/null; then
  pass "Brewfile satisfied"
else
  fail "Brewfile missing applications"
fi

if command -v vagrant >/dev/null 2>&1; then
  pass "Vagrant available"
else
  fail "Vagrant missing"
fi

if command -v herdr >/dev/null 2>&1; then
  pass "Herdr remote client available"
else
  fail "Herdr remote client missing"
fi

for command_name in bookokrat hunk lsd marksman nvim rg starship tree-sitter zoxide; do
  if command -v "$command_name" >/dev/null 2>&1; then
    pass "$command_name available"
  else
    fail "$command_name missing"
  fi
done

for plugin_path in \
  "$HOMEBREW_PREFIX/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh" \
  "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"; do
  if [[ -r "$plugin_path" ]]; then
    pass "$(basename "$plugin_path") readable"
  else
    fail "Zsh plugin missing: $plugin_path"
  fi
done

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

if command -v vagrant >/dev/null 2>&1 \
  && vagrant plugin list 2>/dev/null \
    | /usr/bin/grep -Eq \
      "^vagrant-vmware-desktop \\($VAGRANT_VMWARE_PLUGIN_VERSION([,)])"; then
  pass "Vagrant VMware provider $VAGRANT_VMWARE_PLUGIN_VERSION"
else
  fail "Vagrant VMware provider must be $VAGRANT_VMWARE_PLUGIN_VERSION"
fi

LINK_SPECS=(
  "$DOTFILES_DIR/config/bookokrat|$HOME/.config/bookokrat"
  "$DOTFILES_DIR/setup/mac-thin/.zshrc|$HOME/.zshrc"
  "$DOTFILES_DIR/config/ghostty/config|$HOME/Library/Application Support/com.mitchellh.ghostty/config"
  "$DOTFILES_DIR/config/herdr/config.toml|$HOME/.config/herdr/config.toml"
  "$DOTFILES_DIR/config/hunk/config.toml|$HOME/.config/hunk/config.toml"
  "$DOTFILES_DIR/config/nvim|$HOME/.config/nvim"
  "$DOTFILES_DIR/config/starship/starship.toml|$HOME/.config/starship.toml"
)
for spec in "${LINK_SPECS[@]}"; do
  source_path="${spec%%|*}"
  destination="${spec#*|}"
  if link_matches "$source_path" "$destination"; then
    pass "$destination -> $source_path"
  else
    fail "link mismatch: $destination"
  fi
done

if "$GIT_ALIASES_SCRIPT" --check >/dev/null 2>&1; then
  pass "portable Git aliases"
else
  fail "portable Git aliases are not configured"
fi

if command -v nvim >/dev/null 2>&1 \
  && nvim --headless -u NONE -i NONE --noplugin \
    "+lua assert(vim.fn.has('nvim-0.12') == 1, 'Neovim 0.12+ required')" \
    '+qa' >/dev/null 2>&1; then
  pass "Neovim 0.12+"
else
  fail "Neovim 0.12+ required"
fi

if command -v nvim >/dev/null 2>&1 && verify_neovim_parsers_restored; then
  pass "Thin-profile Markdown parsers"
else
  fail "Thin-profile Markdown parsers are incomplete"
fi

if command -v nvim >/dev/null 2>&1 \
  && verify_neovim_config_sandboxed "$DOTFILES_DIR/config/nvim" thin; then
  pass "Thin-profile Neovim config starts in an isolated data directory"
else
  fail "Thin-profile Neovim isolated startup"
fi

if command -v nvim >/dev/null 2>&1 \
  && DOTFILES_NVIM_PROFILE=thin nvim --headless \
    "+lua local mapping=vim.fn.maparg(' e','n',false,true); local restart=vim.fn.maparg(' cr','n',false,true); local Snacks=require('snacks'); local source=Snacks.config.picker.sources.buffers; local buffers=source.win; local scratch=vim.api.nvim_create_buf(true,false); local dashboard=Snacks.config.dashboard; local header=dashboard.preset.header; local logo=vim.fs.dirname(vim.fn.resolve(vim.fn.stdpath('config')))..'/fastfetch/logo-anon.txt'; assert(mapping.desc=='File explorer','Space e is not mapped to Snacks Explorer'); assert(restart.desc=='Restart Neovim with session','Space c r is not mapped to session restart'); assert(Snacks.config.explorer.replace_netrw==false,'Snacks Explorer would replace Oil'); assert(Snacks.config.picker.sources.explorer.hidden==true,'Snacks Explorer should show dotfiles'); assert(buffers.input.keys['<leader>d'][1]=='bufdelete','Space d is not mapped in the buffer-picker input'); assert(buffers.list.keys['<leader>d']=='bufdelete','Space d is not mapped in the buffer-picker list'); assert(source.transform({buf=scratch,name=''})==false,'Empty replacement buffers should stay hidden'); assert(dashboard.enabled==true,'Thin dashboard disabled'); assert(vim.fn.filereadable(logo)==1 and header~='NVIM' and #header>100,'Anon dashboard header unavailable'); for _,key in ipairs(dashboard.preset.keys) do assert(key.key~='g','Thin dashboard advertises unavailable LazyGit') end; Snacks.dashboard.open(); vim.api.nvim_buf_delete(scratch,{force=true})" \
    '+qa!' >/dev/null 2>&1; then
  pass "Thin-profile Snacks dashboard, explorer, and buffer picker"
else
  fail "Thin-profile Snacks dashboard, explorer, or buffer picker is unavailable"
fi

if command -v nvim >/dev/null 2>&1 \
  && DOTFILES_NVIM_PROFILE=thin nvim --headless \
    "+lua local Snacks=require('snacks'); assert(not vim.tbl_contains(Snacks.config.image.formats,'pdf'),'Snacks would rasterize PDFs'); assert(vim.fn.exists('#BookokratPdfLauncher#BufReadCmd')==1,'Bookokrat PDF launcher missing'); local mapping=vim.fn.maparg(' oe','n',false,true); assert(mapping.desc=='Open file externally','Space o e is not mapped to the PDF launcher')" \
    '+qa!' >/dev/null 2>&1; then
  pass "Thin-profile Bookokrat PDF launcher"
else
  fail "Thin-profile PDFs are not routed to Bookokrat"
fi

if command -v nvim >/dev/null 2>&1 \
  && DOTFILES_NVIM_PROFILE=thin nvim --headless \
    "+lua local repeated=vim.fn.maparg('  ','n',false,true); local terminal=vim.fn.maparg(' t','n',false,true); local floating=vim.fn.maparg(' T','n',false,true); assert(repeated.desc=='Ignore repeated leader','Repeated Space is not consumed'); assert(terminal.desc=='New terminal','Space t is not mapped on thin'); assert(floating.desc=='New floating terminal','Space T is not mapped on thin'); assert(require('which-key.config').delay==0,'WhichKey is not immediate'); vim.api.nvim_buf_set_lines(0,0,-1,false,{'leader test'}); vim.api.nvim_win_set_cursor(0,{1,0}); vim.api.nvim_feedkeys('  ','xt',false); vim.wait(1000); assert(vim.api.nvim_win_get_cursor(0)[2]==0,'Repeated Space moved the cursor')" \
    '+qa!' >/dev/null 2>&1; then
  pass "Thin-profile immediate leader and terminal mappings"
else
  fail "Thin-profile leader or terminal mappings are unavailable"
fi

if command -v nvim >/dev/null 2>&1 \
  && DOTFILES_NVIM_PROFILE=thin nvim --headless "$SCRIPT_DIR/README.md" \
    "+lua assert(not vim.lsp.is_enabled('marksman'),'Marksman was enabled globally'); assert(#vim.lsp.get_clients({bufnr=0,name='marksman'})==0,'Marksman attached before request'); local mapping=vim.fn.maparg(' mm','n',false,true); assert(mapping.desc=='Toggle Marksman for file','Space m m is not mapped to Marksman'); local first=vim.api.nvim_get_current_buf(); vim.cmd.MarksmanToggleCurrent(); assert(vim.wait(5000,function() return #vim.lsp.get_clients({bufnr=first,name='marksman'})>0 end),'Marksman did not attach on request'); vim.cmd.enew(); vim.bo.filetype='markdown'; assert(#vim.lsp.get_clients({bufnr=0,name='marksman'})==0,'Marksman attached to an unrequested buffer'); vim.api.nvim_set_current_buf(first); vim.cmd.MarksmanToggleCurrent(); assert(vim.wait(5000,function() return #vim.lsp.get_clients({bufnr=first,name='marksman'})==0 end),'Marksman did not detach on request')" \
    '+qa!' >/dev/null 2>&1; then
  pass "Marksman toggles per Markdown buffer"
else
  fail "Marksman does not toggle per Markdown buffer"
fi

for app_name in \
  "1Password.app" \
  "Brave Browser.app" \
  "ChatGPT.app" \
  "Ghostty.app" \
  "Hermes.app" \
  "Obsidian.app" \
  "Tailscale.app" \
  "VMware Fusion.app" \
  "zoom.us.app"; do
  if [[ -d "$APPLICATIONS_DIR/$app_name" ]]; then
    pass "$app_name installed"
  else
    fail "$app_name missing"
  fi
done

if [[ -r "$SSH_CONFIG" ]]; then
  pass "SSH config readable"
else
  fail "SSH config missing or unreadable"
fi

check_ubuntu_ssh_alias() {
  local ssh_alias="$1"
  local effective

  effective="$(ssh -G -F "$SSH_CONFIG" "$ssh_alias" 2>/dev/null || true)"

  if printf '%s\n' "$effective" \
    | /usr/bin/awk '$1 == "addressfamily" && $2 == "inet" { found = 1 } END { exit !found }'; then
    pass "$ssh_alias prefers IPv4"
  else
    fail "$ssh_alias must set AddressFamily inet"
  fi

  if printf '%s\n' "$effective" \
    | /usr/bin/awk '$1 == "forwardagent" && $2 == "no" { found = 1 } END { exit !found }' \
    && printf '%s\n' "$effective" \
      | /usr/bin/awk '$1 == "identitiesonly" && $2 == "yes" { found = 1 } END { exit !found }' \
    && printf '%s\n' "$effective" | /usr/bin/grep -Fq "$UBUNTU_LOGIN_KEY_NAME"; then
    pass "$ssh_alias uses only the Ubuntu login key"
  else
    fail "$ssh_alias must use only the Ubuntu login key"
  fi
}

check_ubuntu_ssh_alias ubuntu-vm
check_ubuntu_ssh_alias ubuntu-vm-ts

if [[ -f "$UBUNTU_LOGIN_KEY" && "$(stat -f '%Lp' "$UBUNTU_LOGIN_KEY" 2>/dev/null)" == "600" ]]; then
  pass "$UBUNTU_LOGIN_KEY_NAME present with mode 600"
else
  fail "$UBUNTU_LOGIN_KEY_NAME missing or not mode 600"
fi

check_vagrant_ssh_alias() {
  local ssh_alias="$1"
  local expected_hostname="$2"
  local expected_port="$3"
  local expected_host_key_alias="$4"
  local effective

  effective="$(ssh -G -F "$VAGRANT_SSH_CONFIG" "$ssh_alias" 2>/dev/null || true)"
  if printf '%s\n' "$effective" | /usr/bin/grep -Fq "$UBUNTU_LOGIN_KEY_NAME" \
    && printf '%s\n' "$effective" | /usr/bin/grep -Fxq "hostname $expected_hostname" \
    && printf '%s\n' "$effective" | /usr/bin/grep -Fxq "port $expected_port" \
    && printf '%s\n' "$effective" | /usr/bin/grep -Fxq "hostkeyalias $expected_host_key_alias" \
    && printf '%s\n' "$effective" | /usr/bin/grep -Fxq "forwardagent no" \
    && printf '%s\n' "$effective" | /usr/bin/grep -Fxq "identitiesonly yes" \
    && printf '%s\n' "$effective" | /usr/bin/grep -Fxq "stricthostkeychecking true"; then
    pass "$ssh_alias Vagrant policy"
  else
    fail "$ssh_alias Vagrant SSH policy is incomplete"
  fi
}

if [[ -r "$VAGRANT_SSH_CONFIG" ]]; then
  check_vagrant_ssh_alias ubuntu-vm 127.0.0.1 2222 ubuntu-dev
  check_vagrant_ssh_alias ubuntu-vm-ts ubuntu-dev 22 ubuntu-dev
else
  fail "Vagrant SSH config missing"
fi

if /bin/zsh -dfc "
  source '$DOTFILES_DIR/setup/mac-thin/.zshrc'
  [[ \"\$DOTFILES_NVIM_PROFILE\" == thin ]]
  [[ \"\$EDITOR\" == nvim ]]
  [[ \"\$VISUAL\" == nvim ]]
  [[ \"\$GIT_EDITOR\" == nvim ]]
  [[ -z \"\${GIT_PAGER+x}\" ]]
  [[ \"\$(alias g)\" == 'g=git' ]]
  [[ \"\$(alias gs)\" == \"gs='git status'\" ]]
  [[ \"\$(alias hdiff)\" == \"hdiff='hunk diff'\" ]]
  [[ \"\$(alias hstaged)\" == \"hstaged='hunk diff --staged'\" ]]
  [[ \"\$(alias hshow)\" == \"hshow='hunk show'\" ]]
  [[ \"\$(alias hwatch)\" == \"hwatch='hunk diff --watch'\" ]]
  [[ \"\$(alias ls)\" == \"ls='lsd --tree --depth 1'\" ]]
  [[ \"\$(alias ll)\" == \"ll='lsd -la --tree --depth 1'\" ]]
  [[ \"\$(alias v)\" == 'v=nvim' ]]
  ! alias gdiff >/dev/null 2>&1
  [[ \"\$(alias cod)\" == 'cod=codex' ]]
  [[ \"\$(alias codu)\" == \"codu='codex update'\" ]]
  [[ \"\$(alias dots)\" == \"dots='cd ~/Developer/dotfiles-hd'\" ]]
  [[ \"\$(alias vault)\" == \"vault='cd ~/Developer/hd'\" ]]
  [[ \"\$(alias u)\" == \"u='ssh ubuntu-vm'\" ]]
  [[ \"\$(alias ut)\" == \"ut='ssh ubuntu-vm-ts'\" ]]
  [[ \"\$(alias hu)\" == \"hu='herdr --remote ubuntu-vm'\" ]]
  [[ \"\$(alias hut)\" == \"hut='herdr --remote ubuntu-vm-ts'\" ]]
  ! alias uc >/dev/null 2>&1
  ! alias uct >/dev/null 2>&1
  ! alias ubuntu >/dev/null 2>&1
  ! alias ubuntu-ts >/dev/null 2>&1
  ! alias uvm-open >/dev/null 2>&1
  [[ \"\$(whence -w reload)\" == 'reload: function' ]]
  [[ \"\$(whence -w uvm-status)\" == 'uvm-status: function' ]]
  [[ \"\$(whence -w uvm-ip)\" == 'uvm-ip: function' ]]
  [[ \"\$(whence -w uvm-up)\" == 'uvm-up: function' ]]
  [[ \"\$(whence -w uvm-up-headless)\" != 'uvm-up-headless: function' ]]
  [[ \"\$(whence -w uvm-stop)\" == 'uvm-stop: function' ]]
  [[ \"\$(whence -w uvm-suspend)\" == 'uvm-suspend: function' ]]
  [[ \"\$(whence -w uvm-resume)\" == 'uvm-resume: function' ]]
  [[ \"\$(whence -w uvm-destroy)\" == 'uvm-destroy: function' ]]
  ! alias hm-dev >/dev/null 2>&1
  ! alias docker-nuke >/dev/null 2>&1
"; then
  pass "Thin-Mac personal shell allowlist available"
else
  fail "Thin-Mac personal shell allowlist invalid"
fi

if HOMEBREW_PREFIX="$HOMEBREW_PREFIX" /bin/zsh -dfic "
  source '$DOTFILES_DIR/setup/mac-thin/.zshrc'
  (( \${#functions[(I)*autocomplete*]} > 0 ))
  (( \${#functions[(I)*autosuggest*]} > 0 ))
  whence -w _zsh_highlight >/dev/null
" >/dev/null 2>&1; then
  pass "Thin-Mac interactive Zsh plugins"
else
  fail "Thin-Mac interactive Zsh plugins"
fi

if [[ "$FAILURES" -eq 0 ]]; then
  printf 'Doctor passed for mac-thin.\n'
  exit 0
fi

printf 'Doctor found %d failure(s).\n' "$FAILURES" >&2
exit 1
