#!/usr/bin/env bash
# Stop on command errors, unset variables, and failures hidden in pipelines.
set -euo pipefail

# Exercise the Ubuntu adapter against disposable fake machines. Nothing in this
# test invokes the real package manager, sudo, network, or user configuration.
SOURCE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
INSTALLER="$SOURCE_ROOT/setup/ubuntu/install-neovim-dependencies.sh"
REAL_BASH="$(command -v bash)"
REAL_NODE="$(command -v node)"

# Keep the first red-green run obvious while the production script is being
# developed. Invoke it through Bash, so the source file need not be executable.
if [[ ! -f "$INSTALLER" ]]; then
  echo "missing production script: $INSTALLER" >&2
  exit 1
fi

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/ubuntu-nvim-deps.XXXXXX")"
failures=0
trap 'rm -rf "$TMP_ROOT"' EXIT

write_stub() {
  local path="$1"
  shift

  {
    printf '#!%s\n' "$REAL_BASH"
    printf '%s\n' "$@"
  } >"$path"
  chmod +x "$path"
}

link_real_commands() {
  local dir="$1"
  local name path

  # These are harmless harness utilities, not dependency capabilities. Archive,
  # package-manager, downloader, and removal commands are controlled stubs below.
  for name in \
    awk basename bash cat chmod cmp cp cut date dirname env grep head ln mkdir mktemp mv \
    readlink sed sort tail touch tr true wc
  do
    path="$(command -v "$name" 2>/dev/null || true)"
    [[ -n "$path" ]] && ln -s "$path" "$dir/$name"
  done
}

expect() {
  local label="$1"
  shift

  if ! "$@"; then
    echo "FAIL: $label" >&2
    failures=$((failures + 1))
  fi
}

expect_status() {
  local label="$1"
  local wanted="$2"

  if ((RUN_STATUS != wanted)); then
    echo "FAIL: $label (wanted $wanted, got $RUN_STATUS)" >&2
    printf '%s\n' "$RUN_OUTPUT" >&2
    failures=$((failures + 1))
  fi
}

expect_success() {
  local label="$1"

  if ((RUN_STATUS != 0)); then
    echo "FAIL: $label" >&2
    printf '%s\n' "$RUN_OUTPUT" >&2
    failures=$((failures + 1))
  fi
}

expect_output() {
  local label="$1"
  local pattern="$2"

  if ! printf '%s\n' "$RUN_OUTPUT" | grep -Eiq -- "$pattern"; then
    echo "FAIL: $label (missing pattern: $pattern)" >&2
    printf '%s\n' "$RUN_OUTPUT" >&2
    failures=$((failures + 1))
  fi
}

expect_completion_order() {
  local output="$1"
  local export_line link_line bootstrap_line

  export_line="$(printf '%s\n' "$output" | grep -nEm1 'export PATH=.*\.local/bin' | cut -d: -f1 || true)"
  link_line="$(printf '%s\n' "$output" | grep -nEm1 'setup/nvim/link-config\.sh' | cut -d: -f1 || true)"
  bootstrap_line="$(printf '%s\n' "$output" | grep -nEm1 'setup/nvim/bootstrap\.sh[[:space:]]+core' | cut -d: -f1 || true)"

  if [[ -z "$export_line" || -z "$link_line" || -z "$bootstrap_line" ]]; then
    echo "FAIL: completion output lists PATH, link, and core bootstrap commands" >&2
    printf '%s\n' "$output" >&2
    failures=$((failures + 1))
  elif ! ((export_line < link_line && link_line < bootstrap_line)); then
    echo "FAIL: completion commands are not in PATH -> link -> bootstrap order" >&2
    printf '%s\n' "$output" >&2
    failures=$((failures + 1))
  fi
}

expect_log() {
  local label="$1"
  local pattern="$2"
  local file="${3:-$MUTATION_LOG}"

  if ! grep -Eq -- "$pattern" "$file"; then
    echo "FAIL: $label (missing pattern: $pattern)" >&2
    printf '%s\n' "--- $file ---" >&2
    cat "$file" >&2
    failures=$((failures + 1))
  fi
}

expect_no_log() {
  local label="$1"
  local pattern="$2"
  local file="${3:-$MUTATION_LOG}"

  if grep -Eq -- "$pattern" "$file"; then
    echo "FAIL: $label (unexpected pattern: $pattern)" >&2
    printf '%s\n' "--- $file ---" >&2
    cat "$file" >&2
    failures=$((failures + 1))
  fi
}

install_generic_tool() {
  local name="$1"

  cp "$GENERIC_STUB" "$LOCAL_BIN/$name"
  chmod +x "$LOCAL_BIN/$name"
}

make_fake_machine() {
  local name="$1"
  local architecture="$2"

  MACHINE_ROOT="$TMP_ROOT/$name"
  FAKE_HOME="$MACHINE_ROOT/home"
  LOCAL_BIN="$FAKE_HOME/.local/bin"
  SYSTEM_BIN="$MACHINE_ROOT/system-bin"
  STATE_DIR="$MACHINE_ROOT/state"
  TRACE_LOG="$STATE_DIR/trace.log"
  MUTATION_LOG="$STATE_DIR/mutations.log"
  OS_RELEASE="$MACHINE_ROOT/os-release"
  GENERIC_STUB="$STATE_DIR/generic-tool"
  PNPM_STUB="$STATE_DIR/pnpm"
  GO_STUB="$STATE_DIR/go"
  OLD_GOPLS_STUB="$STATE_DIR/old-gopls"
  OLD_NVIM_STUB="$STATE_DIR/old-nvim"
  OLD_TREE_SITTER_STUB="$STATE_DIR/old-tree-sitter"
  TEST_PATH="$LOCAL_BIN:$SYSTEM_BIN"

  mkdir -p "$LOCAL_BIN" "$SYSTEM_BIN" "$STATE_DIR"
  : >"$TRACE_LOG"
  : >"$MUTATION_LOG"
  printf 'ID=ubuntu\nVERSION_ID="26.04"\n' >"$OS_RELEASE"
  link_real_commands "$SYSTEM_BIN"

  write_stub "$GENERIC_STUB" \
    'name="${0##*/}"' \
    'case "$name" in' \
    '  nvim) echo "NVIM v0.12.2" ;;' \
    '  tree-sitter) echo "tree-sitter 0.26.1" ;;' \
    '  lua-language-server) echo "3.17.1" ;;' \
    '  stylua) echo "stylua 2.4.0" ;;' \
    '  uv)' \
    '    if [[ "${1:-} ${2:-} ${3:-}" == "tool dir --bin" ]]; then' \
    '      printf "%s\n" "$TEST_LOCAL_BIN"' \
    '    else' \
    '      echo "uv 0.10.9"' \
    '    fi' \
    '    ;;' \
    '  node)' \
    '    [[ "${1:-}" == "-e" ]] && exec "$TEST_REAL_NODE" "$@"' \
    '    echo "v22.22.0"' \
    '    ;;' \
    '  go) echo "go version go1.26.0 linux/$TEST_ARCH" ;;' \
    '  gopls) echo "golang.org/x/tools/gopls v0.23.0" ;;' \
    '  *) exit 0 ;;' \
    'esac'

  write_stub "$OLD_GOPLS_STUB" 'echo "golang.org/x/tools/gopls v0.16.1"'
  write_stub "$OLD_NVIM_STUB" 'echo "NVIM v0.11.6"'
  write_stub "$OLD_TREE_SITTER_STUB" 'echo "tree-sitter 0.25.9"'

  # pnpm records global installs and materializes the command names supplied by
  # each pinned package. Each fake shim resolves a payload relative to `$0`, just
  # like pnpm's real shims, so the test catches the broken symlink topology.
  write_stub "$PNPM_STUB" \
    'if [[ "${1:-}" == "--version" || "${1:-}" == "-v" ]]; then' \
    '  echo "11.2.2"' \
    '  exit 0' \
    'fi' \
    'if [[ " ${*:-} " == *" list "* ]]; then' \
    '  global_dir=""' \
    '  args=("$@")' \
    '  for ((i = 0; i < ${#args[@]}; i++)); do' \
    '    [[ "${args[$i]}" == "--global-dir" ]] && { i=$((i + 1)); global_dir="${args[$i]}"; }' \
    '  done' \
    '  [[ -n "$global_dir" ]] || exit 90' \
    '  package_root="${global_dir%/global}/packages"' \
    '  printf '\''[{"dependencies":{"bash-language-server":{"version":"5.6.0","path":"%s/bash"},"@vtsls/language-server":{"version":"0.3.0","path":"%s/vtsls"},"vscode-langservers-extracted":{"version":"4.10.0","path":"%s/vscode"},"graphql-language-service-cli":{"version":"3.5.0","path":"%s/graphql"}}}]\n'\'' "$package_root" "$package_root" "$package_root" "$package_root"' \
    '  exit 0' \
    'fi' \
    'if [[ " $* " != *" add "* ]]; then exit 0; fi' \
    'printf "pnpm-add %s\n" "$*" >>"$TEST_MUTATION_LOG"' \
    'bin_dir=""' \
    'global_dir=""' \
    'args=("$@")' \
    'for ((i = 0; i < ${#args[@]}; i++)); do' \
    '  case "${args[$i]}" in' \
    '    --global-bin-dir) i=$((i + 1)); bin_dir="${args[$i]}" ;;' \
    '    --global-bin-dir=*) bin_dir="${args[$i]#--global-bin-dir=}" ;;' \
    '    --global-dir) i=$((i + 1)); global_dir="${args[$i]}" ;;' \
    '    --global-dir=*) global_dir="${args[$i]#--global-dir=}" ;;' \
    '  esac' \
    'done' \
    '[[ -n "$bin_dir" && -n "$global_dir" ]] || exit 90' \
    'payload_dir="$bin_dir/../payload"' \
    'package_root="${global_dir%/global}/packages"' \
    'mkdir -p "$bin_dir" "$payload_dir" "$package_root/bash" "$package_root/vtsls" "$package_root/vscode" "$package_root/graphql"' \
    'for spec in "$@"; do' \
    '  case "$spec" in' \
    '    bash-language-server@*) commands=(bash-language-server) ;;' \
    '    @vtsls/language-server@*) commands=(vtsls) ;;' \
    '    vscode-langservers-extracted@*) commands=(vscode-eslint-language-server vscode-json-language-server vscode-css-language-server vscode-html-language-server) ;;' \
    '    graphql-language-service-cli@*) commands=(graphql-lsp) ;;' \
    '    *) continue ;;' \
    '  esac' \
    '  for command_name in "${commands[@]}"; do' \
    '    cp "$TEST_GENERIC_STUB" "$payload_dir/$command_name"' \
    '    printf '\''#!%s\nexec "$(cd "$(dirname "$0")/../payload" && pwd -P)/%s" "$@"\n'\'' "$TEST_REAL_BASH" "$command_name" >"$bin_dir/$command_name"' \
    '    chmod +x "$bin_dir/$command_name"' \
    '  done' \
    'done'

  # Go stays host-managed. When full needs gopls, require a pinned go-install
  # target and place the result only in the caller-selected GOBIN.
  write_stub "$GO_STUB" \
    'if [[ "${1:-}" == "version" ]]; then' \
    '  echo "go version go1.26.0 linux/$TEST_ARCH"' \
    '  exit 0' \
    'fi' \
    'if [[ "${1:-}" == "install" ]]; then' \
    '  printf "go-install %s\n" "$*" >>"$TEST_MUTATION_LOG"' \
    '  destination="${GOBIN:-$HOME/go/bin}"' \
    '  mkdir -p "$destination"' \
    '  cp "$TEST_GENERIC_STUB" "$destination/gopls"' \
    '  chmod +x "$destination/gopls"' \
    'fi'

  # APT owns distro packages. It creates only the commands associated with the
  # requested package, including Ubuntu's fdfind name rather than pretending the
  # package supplies an fd command.
  write_stub "$SYSTEM_BIN/apt-command" \
    'action=""' \
    'for arg in "$@"; do' \
    '  case "$arg" in update|install) action="$arg"; break ;; esac' \
    'done' \
    'printf "apt %s\n" "$*" >>"$TEST_TRACE_LOG"' \
    '[[ "$action" == "install" ]] || exit 0' \
    'printf "apt-install %s\n" "$*" >>"$TEST_MUTATION_LOG"' \
    'for package in "$@"; do' \
    '  package="${package%%:*}"' \
    '  case "$package" in' \
    '    git) commands=(git) ;;' \
    '    ripgrep) commands=(rg) ;;' \
    '    fd-find) commands=(fdfind) ;;' \
    '    fzf) commands=(fzf) ;;' \
    '    lazygit) commands=(lazygit) ;;' \
    '    build-essential|gcc) commands=(cc) ;;' \
    '    neovim) cp "$TEST_OLD_NVIM_STUB" "$TEST_LOCAL_BIN/nvim"; chmod +x "$TEST_LOCAL_BIN/nvim"; continue ;;' \
    '    tree-sitter-cli) cp "$TEST_OLD_TREE_SITTER_STUB" "$TEST_LOCAL_BIN/tree-sitter"; chmod +x "$TEST_LOCAL_BIN/tree-sitter"; continue ;;' \
    '    nodejs) commands=(node) ;;' \
    '    golang-go|golang) cp "$TEST_GO_STUB" "$TEST_LOCAL_BIN/go"; chmod +x "$TEST_LOCAL_BIN/go"; commands=(gofmt) ;;' \
    '    imagemagick) commands=(magick) ;;' \
    '    ghostscript) commands=(gs) ;;' \
    '    xdg-utils) commands=(xdg-open) ;;' \
    '    *) continue ;;' \
    '  esac' \
    '  for command_name in "${commands[@]}"; do' \
    '    ln -sf "$TEST_GENERIC_STUB" "$TEST_LOCAL_BIN/$command_name"' \
    '  done' \
    'done'
  ln -s "$SYSTEM_BIN/apt-command" "$SYSTEM_BIN/apt-get"
  ln -s "$SYSTEM_BIN/apt-command" "$SYSTEM_BIN/apt"

  write_stub "$SYSTEM_BIN/apt-cache" \
    'case "$*" in' \
    '  *neovim*) echo "  Candidate: 0.11.6-1" ;;' \
    '  *tree-sitter-cli*) echo "  Candidate: 0.25.9-1" ;;' \
    '  *) echo "  Candidate: 1.0.0" ;;' \
    'esac'

  write_stub "$SYSTEM_BIN/sudo" \
    'printf "sudo %s\n" "$*" >>"$TEST_TRACE_LOG"' \
    'while (($#)) && [[ "$1" == -* ]]; do shift; done' \
    'while (($#)) && [[ "$1" == *=* ]]; do export "$1"; shift; done' \
    'exec "$@"'

  write_stub "$SYSTEM_BIN/dpkg" \
    'if [[ "${1:-}" == "--print-architecture" ]]; then echo "$TEST_ARCH"; fi'
  write_stub "$SYSTEM_BIN/uname" \
    'if [[ "${1:-}" == "-m" ]]; then' \
    '  [[ "$TEST_ARCH" == "arm64" ]] && echo aarch64 || echo x86_64' \
    'else' \
    '  echo Linux' \
    'fi'
  write_stub "$SYSTEM_BIN/arch" \
    '[[ "$TEST_ARCH" == "arm64" ]] && echo aarch64 || echo x86_64'

  # Fake downloads contain URL markers rather than the real release bytes. This
  # verifier keeps checksum behavior deterministic while still requiring the
  # production script to supply a real-looking 64-hex pin and an existing file.
  # It accepts GNU `sha256sum -c` and the equivalent `shasum -a 256 -c` shape.
  write_stub "$SYSTEM_BIN/sha256sum" \
    'check=0; status_only=0; input="-"; skip_next=0; files=()' \
    'for arg in "$@"; do' \
    '  if ((skip_next)); then skip_next=0; continue; fi' \
    '  case "$arg" in' \
    '    -a) skip_next=1 ;;' \
    '    -c|--check) check=1 ;;' \
    '    --status) status_only=1 ;;' \
    '    -) input="-" ;;' \
    '    -*) ;;' \
    '    *) if ((check)); then input="$arg"; else files+=("$arg"); fi ;;' \
    '  esac' \
    'done' \
    'check_line() {' \
    '  local line="$1" checksum file unused' \
    '  read -r checksum file unused <<<"$line"' \
    '  file="${file#\*}"' \
    '  [[ "$checksum" =~ ^[0-9a-fA-F]{64}$ ]] || return 1' \
    '  [[ -f "$file" ]] || return 1' \
    '  printf "sha256sum-check %s %s\n" "$checksum" "$file" >>"$TEST_TRACE_LOG"' \
    '  ((status_only)) || printf "%s: OK\n" "$file"' \
    '}' \
    'if ((check)); then' \
    '  if [[ "$input" == "-" ]]; then' \
    '    while IFS= read -r line; do [[ -z "$line" ]] || check_line "$line"; done' \
    '  else' \
    '    while IFS= read -r line; do [[ -z "$line" ]] || check_line "$line"; done <"$input"' \
    '  fi' \
    '  exit 0' \
    'fi' \
    'zero="0000000000000000000000000000000000000000000000000000000000000000"' \
    'if ((${#files[@]} == 0)); then cat >/dev/null; printf "%s  -\n" "$zero"; exit 0; fi' \
    'for file in "${files[@]}"; do [[ -f "$file" ]] || exit 1; printf "%s  %s\n" "$zero" "$file"; done'
  ln -s "$SYSTEM_BIN/sha256sum" "$SYSTEM_BIN/shasum"

  # Downloads contain their URL as a marker. Controlled archive commands turn
  # that marker into realistic executable layouts without touching the network.
  write_stub "$SYSTEM_BIN/curl" \
    'output=""; url=""' \
    'while (($#)); do' \
    '  case "$1" in' \
    '    -o|--output) output="$2"; shift 2 ;;' \
    '    --output=*) output="${1#--output=}"; shift ;;' \
    '    -o*) output="${1#-o}"; shift ;;' \
    '    http://*|https://*) url="$1"; shift ;;' \
    '    *) shift ;;' \
    '  esac' \
    'done' \
    'printf "download %s\n" "$url" >>"$TEST_MUTATION_LOG"' \
    'if [[ -n "$output" ]]; then' \
    '  mkdir -p "${output%/*}"' \
    '  printf "%s\n" "$url" >"$output"' \
    'else' \
    '  printf "%s\n" "$url"' \
    'fi'

  write_stub "$SYSTEM_BIN/tar" \
    'destination="."; archive=""' \
    'args=("$@")' \
    'for ((i = 0; i < ${#args[@]}; i++)); do' \
    '  case "${args[$i]}" in' \
    '    -C) i=$((i + 1)); destination="${args[$i]}" ;;' \
    '    -f) i=$((i + 1)); archive="${args[$i]}" ;;' \
    '    -*f*) i=$((i + 1)); archive="${args[$i]}" ;;' \
    '    *.tar|*.tar.gz|*.tgz) archive="${args[$i]}" ;;' \
    '  esac' \
    'done' \
    'mkdir -p "$destination/bin" "$destination/nvim-linux-arm64/bin" "$destination/nvim-linux-x86_64/bin" "$destination/nvim-linux64/bin" "$destination/lua-language-server/bin" "$destination/uv-aarch64-unknown-linux-gnu" "$destination/uv-x86_64-unknown-linux-gnu"' \
    'for path in bin/nvim nvim-linux-arm64/bin/nvim nvim-linux-x86_64/bin/nvim nvim-linux64/bin/nvim bin/lua-language-server lua-language-server/bin/lua-language-server stylua uv uvx uv-aarch64-unknown-linux-gnu/uv uv-aarch64-unknown-linux-gnu/uvx uv-x86_64-unknown-linux-gnu/uv uv-x86_64-unknown-linux-gnu/uvx; do' \
    '  cp "$TEST_GENERIC_STUB" "$destination/$path"' \
    '  chmod +x "$destination/$path"' \
    'done'

  write_stub "$SYSTEM_BIN/unzip" \
    'destination="."' \
    'args=("$@")' \
    'for ((i = 0; i < ${#args[@]}; i++)); do' \
    '  [[ "${args[$i]}" == "-d" ]] && { i=$((i + 1)); destination="${args[$i]}"; }' \
    'done' \
    'mkdir -p "$destination/bin"' \
    'cp "$TEST_GENERIC_STUB" "$destination/stylua"' \
    'cp "$TEST_GENERIC_STUB" "$destination/bin/stylua"' \
    'chmod +x "$destination/stylua" "$destination/bin/stylua"'

  write_stub "$SYSTEM_BIN/gzip-command" \
    'input="${*: -1}"' \
    'if [[ " $* " == *" -c "* || "$*" == *"dc"* ]]; then' \
    '  cat "$TEST_GENERIC_STUB"' \
    'else' \
    '  output="${input%.gz}"' \
    '  cp "$TEST_GENERIC_STUB" "$output"' \
    '  chmod +x "$output"' \
    'fi'
  ln -s "$SYSTEM_BIN/gzip-command" "$SYSTEM_BIN/gzip"
  ln -s "$SYSTEM_BIN/gzip-command" "$SYSTEM_BIN/gunzip"
  ln -s "$SYSTEM_BIN/gzip-command" "$SYSTEM_BIN/zcat"

  # Support GNU-style `install -Dm755` while the regression test itself runs on
  # macOS. The last two non-option arguments are the source and destination.
  write_stub "$SYSTEM_BIN/install" \
    'values=(); skip=0' \
    'for arg in "$@"; do' \
    '  if ((skip)); then skip=0; continue; fi' \
    '  case "$arg" in -m|-o|-g) skip=1 ;; -*) ;; *) values+=("$arg") ;; esac' \
    'done' \
    'count=${#values[@]}' \
    '((count >= 2)) || exit 2' \
    'source_path="${values[$((count - 2))]}"' \
    'destination="${values[$((count - 1))]}"' \
    'mkdir -p "${destination%/*}"' \
    'if [[ -f "$source_path" ]]; then cp "$source_path" "$destination"; else cp "$TEST_GENERIC_STUB" "$destination"; fi' \
    'chmod +x "$destination"'

  write_stub "$SYSTEM_BIN/rm" \
    'printf "rm %s\n" "$*" >>"$TEST_TRACE_LOG"' \
    'exec "$TEST_REAL_RM" "$@"'

  for forbidden in brew snap; do
    write_stub "$SYSTEM_BIN/$forbidden" \
      'printf "FORBIDDEN %s %s\n" "${0##*/}" "$*" >>"$TEST_TRACE_LOG"' \
      'exit 97'
  done

  export TEST_ARCH="$architecture"
  export TEST_LOCAL_BIN="$LOCAL_BIN"
  export TEST_GENERIC_STUB="$GENERIC_STUB"
  export TEST_PNPM_STUB="$PNPM_STUB"
  export TEST_GO_STUB="$GO_STUB"
  export TEST_OLD_GOPLS_STUB="$OLD_GOPLS_STUB"
  export TEST_OLD_NVIM_STUB="$OLD_NVIM_STUB"
  export TEST_OLD_TREE_SITTER_STUB="$OLD_TREE_SITTER_STUB"
  export TEST_TRACE_LOG="$TRACE_LOG"
  export TEST_MUTATION_LOG="$MUTATION_LOG"
  export TEST_REAL_BASH="$REAL_BASH"
  export TEST_REAL_NODE="$REAL_NODE"
  export TEST_REAL_RM="$(command -v rm)"
}

run_installer() {
  local profile="$1"

  set +e
  RUN_OUTPUT="$(
    env \
      HOME="$FAKE_HOME" \
      PATH="$TEST_PATH" \
      DOTFILES_OS_RELEASE_FILE="$OS_RELEASE" \
      "$REAL_BASH" "$INSTALLER" "$profile" 2>&1
  )"
  RUN_STATUS=$?
  set -e
}

run_from_documented_caller_path() {
  set +e
  CALLER_OUTPUT="$(
    export HOME="$FAKE_HOME"
    export PATH="$HOME/.local/bin:$SYSTEM_BIN"
    export DOTFILES_OS_RELEASE_FILE="$OS_RELEASE"

    # Prove the command was absent before the child process populated the
    # already-exported user-local directory.
    if command -v nvim >/dev/null 2>&1; then
      exit 80
    fi

    "$REAL_BASH" "$INSTALLER" core
    command -v nvim
    nvim --version
  )"
  CALLER_STATUS=$?
  set -e
}

seed_core_ready() {
  local command_name

  for command_name in nvim tree-sitter git rg fd fzf lazygit cc; do
    install_generic_tool "$command_name"
  done
}

seed_host_runtimes() {
  install_generic_tool node
  cp "$PNPM_STUB" "$LOCAL_BIN/pnpm"
  cp "$GO_STUB" "$LOCAL_BIN/go"
  install_generic_tool gofmt
  chmod +x "$LOCAL_BIN/pnpm" "$LOCAL_BIN/go"
}

seed_supported_node_and_pnpm() {
  install_generic_tool node
  cp "$PNPM_STUB" "$LOCAL_BIN/pnpm"
  chmod +x "$LOCAL_BIN/pnpm"
}

seed_full_ready() {
  local command_name

  seed_core_ready
  seed_host_runtimes
  for command_name in \
    gopls lua-language-server stylua uv bash-language-server vtsls \
    vscode-eslint-language-server vscode-json-language-server \
    vscode-css-language-server vscode-html-language-server graphql-lsp
  do
    install_generic_tool "$command_name"
  done
}

assert_common_safety() {
  expect_no_log "Homebrew and Snap are never invoked" '^FORBIDDEN ' "$TRACE_LOG"
  expect_no_log \
    "Node's bundled npm and npx files are never removed" \
    'rm .*(/npm([[:space:]]|$)|/npx([[:space:]]|$)|node_modules/npm)' \
    "$TRACE_LOG"
  expect_no_log "upstream downloads never use a floating latest URL" '(releases/)?latest' "$MUTATION_LOG"
}

assert_core_architecture() {
  local architecture="$1"

  expect_success "$architecture core bootstrap succeeds"
  expect_log "$architecture core uses APT" '^apt-install '
  expect_log "$architecture core installs Ubuntu ripgrep" 'apt-install .*ripgrep'
  expect_log "$architecture core installs Ubuntu fd-find" 'apt-install .*fd-find'
  expect_log "$architecture core installs fzf" 'apt-install .*fzf'
  expect_log "$architecture core downloads pinned Neovim" 'download .*nvim'
  expect_log "$architecture core downloads pinned Tree-sitter" 'download .*tree-sitter'
  expect "Ubuntu fd compatibility command is available" test -x "$LOCAL_BIN/fd"
  expect "Neovim 0.12 is installed" \
    bash -c 'PATH="$1" nvim --version | grep -q "NVIM v0\.12"' _ "$TEST_PATH"
  expect "Tree-sitter 0.26.1 is installed" \
    bash -c 'PATH="$1" tree-sitter --version | grep -q "tree-sitter 0\.26\.1"' _ "$TEST_PATH"
  expect_no_log "core excludes full assets" 'download .*(lua-language-server|stylua|/uv[-_])'
  expect_no_log "core excludes pnpm language servers" '^pnpm-add '
  expect_no_log "core excludes desktop packages" 'apt-install .*(imagemagick|ghostscript|xdg-utils)'
  assert_common_safety
}

# CLI and platform guards must stop before making system changes.
make_fake_machine "invalid-profile" arm64
run_installer impossible
expect_status "invalid profiles return usage status 2" 2
expect "invalid profile performs no mutations" test ! -s "$MUTATION_LOG"

make_fake_machine "non-ubuntu" arm64
printf 'ID=debian\nVERSION_ID="13"\n' >"$OS_RELEASE"
run_installer core
expect "non-Ubuntu hosts fail" test "$RUN_STATUS" -ne 0
expect "non-Ubuntu host performs no mutations" test ! -s "$MUTATION_LOG"

# A normal user cannot safely reach APT without sudo. Fail with guidance before
# any package, download, or user-local state is changed.
make_fake_machine "non-root-without-sudo" arm64
rm -f "$SYSTEM_BIN/sudo"
run_installer core
expect "non-root setup without sudo fails" test "$RUN_STATUS" -ne 0
expect_output "missing sudo failure gives actionable guidance" 'sudo.*required|install.*sudo|run.*root'
expect "missing sudo fails before mutations" test ! -s "$MUTATION_LOG"
assert_common_safety

# A fresh ARM VM must use Ubuntu packages where they are sufficient and choose
# ARM variants for the two version-pinned core tools.
make_fake_machine "core-arm64" arm64
run_installer core
assert_core_architecture arm64
expect_log "ARM Neovim asset is selected" 'download .*nvim.*(arm64|aarch64)'
expect_log "ARM Tree-sitter asset is selected" 'download .*tree-sitter.*(arm64|aarch64)'
expect_no_log "ARM run never downloads an x86 asset" 'download .*(amd64|x86_64|linux-x64)'
expect_completion_order "$RUN_OUTPUT"

# The same fresh-core contract must map Debian's amd64 name to each upstream
# project's x86 spelling without ever falling back to an ARM artifact.
make_fake_machine "core-amd64" amd64
run_installer core
assert_core_architecture amd64
expect_log "amd64 Neovim asset is selected" 'download .*nvim.*x86_64'
expect_log "amd64 Tree-sitter asset is selected" 'download .*tree-sitter.*(x64|x86_64|amd64)'
expect_no_log "amd64 run never downloads an ARM asset" 'download .*(arm64|aarch64)'

# This is the documented invocation shape: the caller exports ~/.local/bin,
# launches the adapter as a child, then immediately launches the installed tool.
make_fake_machine "caller-path-visibility" arm64
run_from_documented_caller_path
expect "documented caller PATH survives child exit" test "$CALLER_STATUS" -eq 0
expect "installed Neovim is visible to the caller" \
  bash -c 'printf "%s\n" "$1" | grep -q "$2/.local/bin/nvim"' _ "$CALLER_OUTPUT" "$FAKE_HOME"
expect "the caller can execute installed Neovim" \
  bash -c 'printf "%s\n" "$1" | grep -q "NVIM v0\.12"' _ "$CALLER_OUTPUT"
assert_common_safety

# Invalid content at a version-pinned destination is never deleted. Preserve
# every sentinel in a timestamped sibling before moving the verified tool in.
make_fake_machine "conflicting-managed-targets" arm64
seed_host_runtimes
mkdir -p \
  "$FAKE_HOME/.local/opt/nvim/0.12.4" \
  "$FAKE_HOME/.local/opt/tree-sitter/0.26.11" \
  "$FAKE_HOME/.local/opt/lua-language-server/3.18.2" \
  "$FAKE_HOME/.local/opt/stylua/2.5.2" \
  "$FAKE_HOME/.local/opt/uv/0.11.28"
printf '%s\n' 'nvim-sentinel' >"$FAKE_HOME/.local/opt/nvim/0.12.4/sentinel"
printf '%s\n' 'tree-sitter-sentinel' \
  >"$FAKE_HOME/.local/opt/tree-sitter/0.26.11/tree-sitter"
printf '%s\n' 'luals-sentinel' \
  >"$FAKE_HOME/.local/opt/lua-language-server/3.18.2/sentinel"
printf '%s\n' 'stylua-sentinel' >"$FAKE_HOME/.local/opt/stylua/2.5.2/stylua"
printf '%s\n' 'uv-sentinel' >"$FAKE_HOME/.local/opt/uv/0.11.28/sentinel"
run_installer full
expect_success "conflicting managed targets are replaced safely"
for target_and_sentinel in \
  "$FAKE_HOME/.local/opt/nvim/0.12.4|sentinel|nvim-sentinel" \
  "$FAKE_HOME/.local/opt/tree-sitter/0.26.11/tree-sitter||tree-sitter-sentinel" \
  "$FAKE_HOME/.local/opt/lua-language-server/3.18.2|sentinel|luals-sentinel" \
  "$FAKE_HOME/.local/opt/stylua/2.5.2/stylua||stylua-sentinel" \
  "$FAKE_HOME/.local/opt/uv/0.11.28|sentinel|uv-sentinel"
do
  IFS='|' read -r target child sentinel <<<"$target_and_sentinel"
  expect "backup preserves $sentinel" \
    bash -c '
      shopt -s nullglob
      backups=("$1".backup-*)
      ((${#backups[@]} == 1)) || exit 1
      if [[ -n "$2" ]]; then
        grep -Fxq "$3" "${backups[0]}/$2"
      else
        grep -Fxq "$3" "${backups[0]}"
      fi
    ' _ "$target" "$child" "$sentinel"
done
assert_common_safety

# A known-unsupported host runtime must stop before APT, downloads, pnpm, or Go
# can alter the machine. The error must identify the runtime that needs action.
make_fake_machine "full-node-16" arm64
seed_core_ready
write_stub "$LOCAL_BIN/node" 'echo "v16.20.2"'
cp "$PNPM_STUB" "$LOCAL_BIN/pnpm"
cp "$GO_STUB" "$LOCAL_BIN/go"
install_generic_tool gofmt
chmod +x "$LOCAL_BIN/pnpm" "$LOCAL_BIN/go"
run_installer full
expect "full rejects Node 16" test "$RUN_STATUS" -ne 0
expect_output "Node 16 failure explains the supported minimum" 'Node.*18.*(required|newer)'
expect_output "Node 16 failure reports the active version" 'v16\.20\.2'
expect "Node 16 fails before installation mutations" test ! -s "$MUTATION_LOG"
assert_common_safety

# A supported Node without pnpm is still incomplete. Stop before APT or any
# download and point personal machines at the shared mise bootstrap.
make_fake_machine "full-without-pnpm" arm64
seed_core_ready
install_generic_tool node
cp "$GO_STUB" "$LOCAL_BIN/go"
install_generic_tool gofmt
chmod +x "$LOCAL_BIN/go"
run_installer full
expect "full rejects a missing pnpm" test "$RUN_STATUS" -ne 0
expect_output "missing pnpm failure names the required package manager" 'pnpm.*required|required.*pnpm'
expect_output "missing pnpm points personal Ubuntu at mise setup" 'install-mise\.sh'
expect "missing pnpm fails before installation mutations" test ! -s "$MUTATION_LOG"
assert_common_safety

# A command named pnpm is not enough. Reject both an unsupported major version
# and a broken shim before APT, downloads, or language-server installs run.
make_fake_machine "full-with-pnpm-10" arm64
seed_core_ready
install_generic_tool node
cp "$GO_STUB" "$LOCAL_BIN/go"
install_generic_tool gofmt
write_stub "$LOCAL_BIN/pnpm" 'echo "10.9.0"'
chmod +x "$LOCAL_BIN/go"
run_installer full
expect "full rejects pnpm 10" test "$RUN_STATUS" -ne 0
expect_output "old pnpm failure names the supported minimum" 'pnpm.*11|11.*pnpm'
expect "old pnpm fails before installation mutations" test ! -s "$MUTATION_LOG"
assert_common_safety

make_fake_machine "full-with-broken-pnpm" arm64
seed_core_ready
install_generic_tool node
cp "$GO_STUB" "$LOCAL_BIN/go"
install_generic_tool gofmt
write_stub "$LOCAL_BIN/pnpm" 'exit 42'
chmod +x "$LOCAL_BIN/go"
run_installer full
expect "full rejects a broken pnpm shim" test "$RUN_STATUS" -ne 0
expect_output "broken pnpm failure names the supported minimum" 'pnpm.*11|11.*pnpm'
expect "broken pnpm fails before installation mutations" test ! -s "$MUTATION_LOG"
assert_common_safety

# A machine that already owns either half of Go's toolchain must repair that
# host runtime intentionally. APT must not replace it just to fill the other half.
make_fake_machine "full-go-without-gofmt" arm64
seed_core_ready
seed_supported_node_and_pnpm
cp "$GO_STUB" "$LOCAL_BIN/go"
chmod +x "$LOCAL_BIN/go"
run_installer full
expect "full rejects go without gofmt" test "$RUN_STATUS" -ne 0
expect_output "partial Go failure explains host ownership" 'host-managed.*Go|Go.*host-managed'
expect_output "partial Go failure names missing gofmt" 'gofmt'
expect "go without gofmt fails before mutations" test ! -s "$MUTATION_LOG"
assert_common_safety

make_fake_machine "full-gofmt-without-go" arm64
seed_core_ready
seed_supported_node_and_pnpm
install_generic_tool gofmt
run_installer full
expect "full rejects gofmt without go" test "$RUN_STATUS" -ne 0
expect_output "reverse partial Go failure explains host ownership" 'host-managed.*Go|Go.*host-managed'
expect_output "reverse partial Go failure names missing go" 'missing.*go|go.*missing|not[[:space:]]+go'
expect "gofmt without go fails before mutations" test ! -s "$MUTATION_LOG"
assert_common_safety

# If one caller-owned language server already works, fill and link only the
# missing commands. Never shadow or rewrite the host's existing executable.
make_fake_machine "full-partial-node-servers" arm64
seed_core_ready
seed_host_runtimes
for command_name in lua-language-server stylua uv gopls; do
  install_generic_tool "$command_name"
done
HOST_LSP_BIN="$MACHINE_ROOT/host-bin"
mkdir -p "$HOST_LSP_BIN"
cp "$GENERIC_STUB" "$HOST_LSP_BIN/bash-language-server"
chmod +x "$HOST_LSP_BIN/bash-language-server"
cp "$HOST_LSP_BIN/bash-language-server" "$STATE_DIR/bash-language-server.before"
TEST_PATH="$LOCAL_BIN:$HOST_LSP_BIN:$SYSTEM_BIN"

run_installer full
expect_success "full fills only missing Node language servers"
expect "host language server remains byte-identical" \
  cmp -s "$STATE_DIR/bash-language-server.before" "$HOST_LSP_BIN/bash-language-server"
expect "host language server is not shadowed by a local link" \
  test ! -e "$LOCAL_BIN/bash-language-server"
expect "host language server keeps its exact resolved path" \
  bash -c 'PATH="$1"; export PATH; test "$(command -v bash-language-server)" = "$2/bash-language-server"' \
    _ "$TEST_PATH" "$HOST_LSP_BIN"
for command_name in \
  vtsls vscode-eslint-language-server vscode-json-language-server \
  vscode-css-language-server vscode-html-language-server graphql-lsp
do
  expect "missing $command_name receives a local wrapper" \
    bash -c 'test -f "$1" && test ! -L "$1"' _ "$LOCAL_BIN/$command_name"
  expect "the $command_name wrapper executes its private pnpm shim" \
    bash -c 'PATH="$1"; export PATH; "$2" >/dev/null 2>&1' _ "$TEST_PATH" "$command_name"
done
assert_common_safety

# Full adds pinned user-local tools without changing a working Node/pnpm/Go host
# runtime. The second run must make no additional installation mutations.
make_fake_machine "full-arm64" arm64
seed_core_ready
seed_host_runtimes
cp "$LOCAL_BIN/node" "$STATE_DIR/node.before"
cp "$LOCAL_BIN/pnpm" "$STATE_DIR/pnpm.before"
run_installer full
expect_success "full profile succeeds"
expect_log "full downloads pinned LuaLS" 'download .*lua-language-server.*(arm64|aarch64)'
expect_log "full downloads pinned StyLua" 'download .*stylua.*(arm64|aarch64)'
expect_log "full downloads pinned uv" 'download .*(uv.*aarch64|aarch64.*uv)'
expect_log "bash-language-server is version-pinned" 'pnpm-add .*bash-language-server@[0-9]'
expect_log "vtsls is version-pinned" 'pnpm-add .*@vtsls/language-server@[0-9]'
expect_log "VSCode language servers are version-pinned" 'pnpm-add .*vscode-langservers-extracted@[0-9]'
expect_log "GraphQL language server is version-pinned" 'pnpm-add .*graphql-language-service-cli@[0-9]'
expect_no_log "full excludes desktop packages" 'apt-install .*(imagemagick|ghostscript|xdg-utils)'
expect "host Node is byte-identical" cmp -s "$STATE_DIR/node.before" "$LOCAL_BIN/node"
expect "host pnpm is byte-identical" cmp -s "$STATE_DIR/pnpm.before" "$LOCAL_BIN/pnpm"
expect "host pnpm remains a regular command" test ! -L "$LOCAL_BIN/pnpm"
expect "host Node version is unchanged" \
  bash -c 'PATH="$1"; export PATH; test "$(node --version)" = "v22.22.0"' _ "$TEST_PATH"
expect "host pnpm version is unchanged" \
  bash -c 'PATH="$1"; export PATH; test "$(pnpm --version)" = "11.2.2"' _ "$TEST_PATH"
for command_name in \
  lua-language-server stylua uv gopls bash-language-server vtsls \
  vscode-eslint-language-server vscode-json-language-server \
  vscode-css-language-server vscode-html-language-server graphql-lsp
do
  expect "full supplies $command_name" test -x "$LOCAL_BIN/$command_name"
done
for command_name in \
  bash-language-server vtsls vscode-eslint-language-server \
  vscode-json-language-server vscode-css-language-server \
  vscode-html-language-server graphql-lsp
do
  expect "full executes the $command_name pnpm wrapper" \
    bash -c 'PATH="$1"; export PATH; "$2" >/dev/null 2>&1' _ "$TEST_PATH" "$command_name"
  expect "full marks the $command_name wrapper as managed" \
    grep -Fqx \
      "# dotfiles-managed pnpm wrapper: $FAKE_HOME/.local/nvim-pnpm-tools/bin/$command_name" \
      "$LOCAL_BIN/$command_name"
done
expect "newly installed gopls reports the pinned version" \
  bash -c 'PATH="$1"; export PATH; gopls version | grep -q "v0\.23\.0"' _ "$TEST_PATH"
assert_common_safety

cp "$MUTATION_LOG" "$STATE_DIR/full-first-run.log"
run_installer full
expect_success "second full run succeeds"
expect "second full run performs no installation mutations" \
  cmp -s "$STATE_DIR/full-first-run.log" "$MUTATION_LOG"
expect "second full run preserves pnpm" cmp -s "$STATE_DIR/pnpm.before" "$LOCAL_BIN/pnpm"
assert_common_safety

# A leftover shim and wrapper must not hide a deleted pnpm package payload.
# Reinstall the exact managed set once, then become a no-op again.
rm -rf "$FAKE_HOME/.local/nvim-pnpm-tools/packages/vtsls"
before_payload_repair_lines="$(wc -l <"$MUTATION_LOG")"
run_installer full
expect_success "a missing pnpm package payload is repaired"
tail -n "+$((before_payload_repair_lines + 1))" "$MUTATION_LOG" \
  >"$STATE_DIR/pnpm-payload-repair.log"
expect_log "payload repair reinstalls the exact pnpm package set" \
  '^pnpm-add ' "$STATE_DIR/pnpm-payload-repair.log"
expect_no_log "payload repair changes no unrelated dependency" \
  '^(apt-install|download|go-install) ' "$STATE_DIR/pnpm-payload-repair.log"
expect "the repaired vtsls wrapper executes" \
  bash -c 'PATH="$1"; export PATH; vtsls >/dev/null 2>&1' _ "$TEST_PATH"
assert_common_safety

cp "$MUTATION_LOG" "$STATE_DIR/pnpm-payload-repair-first-run.log"
run_installer full
expect_success "matching repaired pnpm payload is a no-op"
expect "second payload-repair run performs no mutations" \
  cmp -s "$STATE_DIR/pnpm-payload-repair-first-run.log" "$MUTATION_LOG"
assert_common_safety

# Managed wrappers are state, not mere command names. Repair both a lost
# executable bit and a modified body, while preserving each damaged file.
chmod -x "$LOCAL_BIN/vtsls"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  "# dotfiles-managed pnpm wrapper: $FAKE_HOME/.local/nvim-pnpm-tools/bin/graphql-lsp" \
  'exit 91' \
  >"$LOCAL_BIN/graphql-lsp"
chmod +x "$LOCAL_BIN/graphql-lsp"
before_wrapper_repair_lines="$(wc -l <"$MUTATION_LOG")"
run_installer full
expect_success "damaged pnpm wrappers are repaired"
tail -n "+$((before_wrapper_repair_lines + 1))" "$MUTATION_LOG" \
  >"$STATE_DIR/pnpm-wrapper-repair.log"
expect_log "wrapper repair reconverges the exact pnpm package set" \
  '^pnpm-add ' "$STATE_DIR/pnpm-wrapper-repair.log"
for command_name in vtsls graphql-lsp; do
  expect "repaired $command_name wrapper is executable" test -x "$LOCAL_BIN/$command_name"
  expect "repaired $command_name wrapper executes" \
    bash -c 'PATH="$1"; export PATH; "$2" >/dev/null 2>&1' _ "$TEST_PATH" "$command_name"
  expect "damaged $command_name wrapper was preserved" \
    bash -c '
      shopt -s nullglob
      backups=("$1".backup-*)
      ((${#backups[@]} == 1))
    ' _ "$LOCAL_BIN/$command_name"
done
assert_common_safety

cp "$MUTATION_LOG" "$STATE_DIR/pnpm-wrapper-repair-first-run.log"
run_installer full
expect_success "matching repaired wrappers are a no-op"
expect "second wrapper-repair run performs no mutations" \
  cmp -s "$STATE_DIR/pnpm-wrapper-repair-first-run.log" "$MUTATION_LOG"
assert_common_safety

# A pin change must reconverge commands already linked from the private pnpm
# prefix exactly once. Command presence alone cannot hide a stale managed set.
printf '%s\n' 'stale-package-pins' >"$FAKE_HOME/.local/nvim-pnpm-tools/.dotfiles-package-pins"
before_pin_refresh_lines="$(wc -l <"$MUTATION_LOG")"
run_installer full
expect_success "stale private pnpm pins are refreshed"
tail -n "+$((before_pin_refresh_lines + 1))" "$MUTATION_LOG" >"$STATE_DIR/pnpm-pin-refresh.log"
expect_log "pin refresh reinstalls the exact pnpm package set" '^pnpm-add ' "$STATE_DIR/pnpm-pin-refresh.log"
expect_no_log "pin refresh changes no unrelated dependency" \
  '^(apt-install|download|go-install) ' "$STATE_DIR/pnpm-pin-refresh.log"
for package_spec in \
  'bash-language-server@5.6.0' \
  '@vtsls/language-server@0.3.0' \
  'vscode-langservers-extracted@4.10.0' \
  'graphql-language-service-cli@3.5.0'
do
  expect "refreshed manifest records $package_spec" \
    grep -Fxq "$package_spec" "$FAKE_HOME/.local/nvim-pnpm-tools/.dotfiles-package-pins"
done
assert_common_safety

cp "$MUTATION_LOG" "$STATE_DIR/pnpm-pin-refresh-first-run.log"
run_installer full
expect_success "matching private pnpm pins are a no-op"
expect "second pin-convergence run performs no mutations" \
  cmp -s "$STATE_DIR/pnpm-pin-refresh-first-run.log" "$MUTATION_LOG"
assert_common_safety

# Raising a ready full machine to desktop installs only preview/opener gaps.
before_desktop_lines="$(wc -l <"$MUTATION_LOG")"
run_installer desktop
expect_success "desktop profile succeeds"
tail -n "+$((before_desktop_lines + 1))" "$MUTATION_LOG" >"$STATE_DIR/desktop-delta.log"
expect_log "desktop adds ImageMagick" 'apt-install .*imagemagick' "$STATE_DIR/desktop-delta.log"
expect_log "desktop adds Ghostscript" 'apt-install .*ghostscript' "$STATE_DIR/desktop-delta.log"
expect_log "desktop adds xdg-utils" 'apt-install .*xdg-utils' "$STATE_DIR/desktop-delta.log"
expect_no_log "desktop never installs Ghostty or Herdr" '(ghostty|herdr)' "$STATE_DIR/desktop-delta.log"
for command_name in magick gs xdg-open; do
  expect "desktop supplies $command_name" test -x "$LOCAL_BIN/$command_name"
done
assert_common_safety

cp "$MUTATION_LOG" "$STATE_DIR/desktop-first-run.log"
run_installer desktop
expect_success "second desktop run succeeds"
expect "second desktop run performs no installation mutations" \
  cmp -s "$STATE_DIR/desktop-first-run.log" "$MUTATION_LOG"
assert_common_safety

# Command presence alone is insufficient for gopls: replace a known stale
# version with the configured pin, then prove the version-aware check is stable.
make_fake_machine "full-stale-gopls" arm64
seed_full_ready
cp "$OLD_GOPLS_STUB" "$LOCAL_BIN/gopls"
chmod +x "$LOCAL_BIN/gopls"
run_installer full
expect_success "full replaces stale gopls"
expect_log "stale gopls is replaced with the pinned target" \
  '^go-install install golang\.org/x/tools/gopls@v0\.23\.0$'
expect "replaced gopls reports v0.23.0" \
  bash -c 'PATH="$1"; export PATH; gopls version | grep -q "v0\.23\.0"' _ "$TEST_PATH"
expect_no_log "gopls replacement does not reinstall unrelated tools" \
  '^(apt-install|download|pnpm-add) '
assert_common_safety

cp "$MUTATION_LOG" "$STATE_DIR/stale-gopls-first-run.log"
run_installer full
expect_success "second pinned-gopls full run succeeds"
expect "pinned gopls is idempotent" \
  cmp -s "$STATE_DIR/stale-gopls-first-run.log" "$MUTATION_LOG"
expect "second run keeps gopls at v0.23.0" \
  bash -c 'PATH="$1"; export PATH; gopls version | grep -q "v0\.23\.0"' _ "$TEST_PATH"
assert_common_safety

if ((failures > 0)); then
  echo "$failures Ubuntu dependency-adapter regression test(s) failed." >&2
  exit 1
fi

echo "Ubuntu dependency-adapter regression tests: ok"
