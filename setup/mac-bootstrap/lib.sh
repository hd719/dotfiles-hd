#!/usr/bin/env bash

say() {
  printf '%s\n' "$*"
}

APPROVED_BUN_VERSION="1.3.14"
APPROVED_GO_VERSION="1.26.3"
APPROVED_NODE_VERSION="24.18.0"
APPROVED_PNPM_VERSION="11.2.2"
APPROVED_PYTHON_VERSION="3.14.5"
LAZY_NVIM_REPOSITORY="https://github.com/folke/lazy.nvim.git"

# Keep this install list aligned with config/nvim/lua/plugins/editor.lua.
NEOVIM_PARSERS=(
  bash ecma go gomod gosum gowork graphql javascript json jsx lua markdown
  markdown_inline python query toml tsx typescript vim vimdoc yaml
)
NEOVIM_PARSER_BINARIES=(
  bash go gomod gosum gowork graphql javascript json lua markdown
  markdown_inline python query toml tsx typescript vim vimdoc yaml
)

die() {
  printf 'error: %s\n' "$*" >&2
  return 1
}

require_source() {
  local source_path="$1"
  [[ -e "$source_path" ]] || die "missing source: $source_path"
}

next_backup_path() {
  local destination="$1"
  local stamp="$2"
  local candidate="${destination}.backup-${stamp}"
  local suffix=1

  while [[ -e "$candidate" || -L "$candidate" ]]; do
    candidate="${destination}.backup-${stamp}.${suffix}"
    suffix=$((suffix + 1))
  done

  printf '%s\n' "$candidate"
}

backup_and_link() {
  local source_path="$1"
  local destination="$2"
  local stamp="$3"
  local dry_run="${4:-0}"
  local backup_path

  require_source "$source_path" || return 1

  if [[ -e "$destination" && ! -L "$destination" && "$source_path" -ef "$destination" ]]; then
    die "destination resolves to its tracked source; review ancestor symlinks: $destination"
    return 1
  fi

  if [[ -L "$destination" && "$(readlink "$destination")" == "$source_path" ]]; then
    say "already linked: $destination -> $source_path"
    return 0
  fi

  if [[ "$dry_run" == "1" ]]; then
    if [[ -e "$destination" || -L "$destination" ]]; then
      backup_path="$(next_backup_path "$destination" "$stamp")"
      say "would back up: $destination -> $backup_path"
    fi
    say "would link: $destination -> $source_path"
    return 0
  fi

  mkdir -p "$(dirname "$destination")"

  if [[ -e "$destination" || -L "$destination" ]]; then
    backup_path="$(next_backup_path "$destination" "$stamp")"
    mv "$destination" "$backup_path"
    say "backed up: $destination -> $backup_path"
  fi

  ln -s "$source_path" "$destination"
  [[ -L "$destination" && "$(readlink "$destination")" == "$source_path" ]] \
    || die "failed to verify link: $destination"
  say "linked: $destination -> $source_path"
}

reject_link_source_alias() {
  local source_path="$1"
  local destination="$2"

  if [[ -e "$destination" && ! -L "$destination" && "$source_path" -ef "$destination" ]]; then
    die "destination resolves to its tracked source; review ancestor symlinks: $destination"
    return 1
  fi
}

link_matches() {
  local source_path="$1"
  local destination="$2"

  [[ -e "$source_path" \
    && -e "$destination" \
    && -L "$destination" \
    && "$(readlink "$destination")" == "$source_path" ]]
}

legacy_link_source_for_destination() {
  local destination="$1"
  local spec
  local source_path
  local legacy_destination

  for spec in "${LEGACY_LINK_SPECS[@]}"; do
    source_path="${spec%%|*}"
    legacy_destination="${spec#*|}"
    if [[ "$legacy_destination" == "$destination" ]] \
      && link_matches "$source_path" "$destination"; then
      printf '%s\n' "$source_path"
      return 0
    fi
  done

  return 1
}

canonical_profile() {
  case "$1" in
    mac-pro|mac-mini)
      printf '%s\n' "$1"
      ;;
    mac-vm)
      printf '%s\n' "mac-pro"
      ;;
    *)
      die "unknown profile '$1' (expected mac-pro or mac-mini)"
      return 1
      ;;
  esac
}

zprofile_block_matches() {
  local profile_path="$1"
  local fragment_path="$2"
  local begin_marker="# BEGIN dotfiles-hd mac-bootstrap mise shims"
  local end_marker="# END dotfiles-hd mac-bootstrap mise shims"
  local legacy_begin_marker="# BEGIN dotfiles-hd personal-mac mise shims"
  local legacy_end_marker="# END dotfiles-hd personal-mac mise shims"
  local begin_line
  local end_line
  local quoted_fragment
  local expected
  local actual

  [[ -f "$profile_path" && ! -L "$profile_path" && -r "$profile_path" ]] \
    || return 1
  [[ -f "$fragment_path" && -r "$fragment_path" ]] || return 1
  [[ "$(grep -Fxc "$begin_marker" "$profile_path" || true)" == "1" ]] \
    || return 1
  [[ "$(grep -Fxc "$end_marker" "$profile_path" || true)" == "1" ]] \
    || return 1
  [[ "$(grep -Fxc "$legacy_begin_marker" "$profile_path" || true)" == "0" ]] \
    || return 1
  [[ "$(grep -Fxc "$legacy_end_marker" "$profile_path" || true)" == "0" ]] \
    || return 1

  begin_line="$(grep -Fn "$begin_marker" "$profile_path")"
  begin_line="${begin_line%%:*}"
  end_line="$(grep -Fn "$end_marker" "$profile_path")"
  end_line="${end_line%%:*}"
  [[ "$begin_line" -lt "$end_line" ]] || return 1

  printf -v quoted_fragment '%q' "$fragment_path"
  printf -v expected '%s\nif [[ -r %s ]]; then\n  source %s\nfi\n%s' \
    "$begin_marker" "$quoted_fragment" "$quoted_fragment" "$end_marker"
  actual="$(awk -v begin="$begin_marker" -v end="$end_marker" \
    '$0 == begin { capture = 1 } capture { print } $0 == end && capture { exit }' \
    "$profile_path")"

  [[ "$actual" == "$expected" ]]
}

sanitize_shell_path() {
  local path_value="$1"
  local local_bin="${XDG_BIN_HOME:-$HOME/.local/bin}"
  local mise_data="${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}"
  local entry
  local sanitized=""
  local -a entries=()

  IFS=':' read -r -a entries <<< "$path_value"
  for entry in "${entries[@]}"; do
    [[ -n "$entry" ]] || continue
    case "$entry" in
      "$local_bin"|"$mise_data/shims"|"$mise_data/installs/"*|*/mise/shims|*/mise/installs/*)
        continue
        ;;
    esac
    sanitized="${sanitized:+$sanitized:}$entry"
  done

  printf '%s\n' "$sanitized"
}

write_zprofile_block() {
  local profile_path="$1"
  local fragment_path="$2"
  local stamp="$3"
  local dry_run="${4:-0}"
  local begin_marker="# BEGIN dotfiles-hd mac-bootstrap mise shims"
  local end_marker="# END dotfiles-hd mac-bootstrap mise shims"
  local legacy_begin_marker="# BEGIN dotfiles-hd personal-mac mise shims"
  local legacy_end_marker="# END dotfiles-hd personal-mac mise shims"
  local begin_count=0
  local end_count=0
  local legacy_begin_count=0
  local legacy_end_count=0
  local managed_begin_marker="$begin_marker"
  local managed_end_marker="$end_marker"
  local managed_count=0
  local begin_line=0
  local end_line=0
  local quoted_fragment
  local temporary
  local backup_path
  local line
  local replacing=0

  require_source "$fragment_path" || return 1
  printf -v quoted_fragment '%q' "$fragment_path"

  if [[ -L "$profile_path" ]]; then
    die "cannot safely marker-edit symlinked profile: $profile_path"
    return 1
  elif [[ -f "$profile_path" && ! -r "$profile_path" ]]; then
    die "cannot read existing profile: $profile_path"
    return 1
  elif [[ -f "$profile_path" ]]; then
    begin_count="$(grep -Fxc "$begin_marker" "$profile_path" || true)"
    end_count="$(grep -Fxc "$end_marker" "$profile_path" || true)"
    legacy_begin_count="$(grep -Fxc "$legacy_begin_marker" "$profile_path" || true)"
    legacy_end_count="$(grep -Fxc "$legacy_end_marker" "$profile_path" || true)"
  elif [[ -e "$profile_path" || -L "$profile_path" ]]; then
    die "cannot manage non-file profile: $profile_path"
    return 1
  fi

  if [[ "$begin_count" -gt 1 || "$end_count" -gt 1 || "$begin_count" -ne "$end_count" ]]; then
    die "malformed managed block in $profile_path"
    return 1
  fi

  if [[ "$legacy_begin_count" -gt 1 || "$legacy_end_count" -gt 1 \
    || "$legacy_begin_count" -ne "$legacy_end_count" ]]; then
    die "malformed legacy managed block in $profile_path"
    return 1
  fi

  managed_count=$((begin_count + legacy_begin_count))
  if [[ "$managed_count" -gt 1 ]]; then
    die "multiple managed blocks in $profile_path"
    return 1
  fi

  if [[ "$legacy_begin_count" -eq 1 ]]; then
    managed_begin_marker="$legacy_begin_marker"
    managed_end_marker="$legacy_end_marker"
  fi

  if [[ "$managed_count" -eq 1 ]]; then
    begin_line="$(grep -Fn "$managed_begin_marker" "$profile_path")"
    begin_line="${begin_line%%:*}"
    end_line="$(grep -Fn "$managed_end_marker" "$profile_path")"
    end_line="${end_line%%:*}"
    if [[ "$begin_line" -ge "$end_line" ]]; then
      die "managed block markers are out of order in $profile_path"
      return 1
    fi
  fi

  if [[ "$dry_run" == "1" ]]; then
    say "would manage mise shims block: $profile_path"
    return 0
  fi

  mkdir -p "$(dirname "$profile_path")"
  temporary="$(mktemp "$(dirname "$profile_path")/.zprofile.dotfiles.XXXXXX")"

  if [[ "$managed_count" -eq 1 ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      if [[ "$line" == "$managed_begin_marker" ]]; then
        {
          printf '%s\n' "$begin_marker"
          printf 'if [[ -r %s ]]; then\n' "$quoted_fragment"
          printf '  source %s\n' "$quoted_fragment"
          printf '%s\n' 'fi'
          printf '%s\n' "$end_marker"
        } >> "$temporary"
        replacing=1
      elif [[ "$replacing" == "1" && "$line" == "$managed_end_marker" ]]; then
        replacing=0
      elif [[ "$replacing" == "0" ]]; then
        printf '%s\n' "$line" >> "$temporary"
      fi
    done < "$profile_path"
  else
    if [[ -f "$profile_path" ]]; then
      cat "$profile_path" > "$temporary"
      if [[ -s "$profile_path" && "$(tail -c 1 "$profile_path" | wc -l | tr -d ' ')" == "0" ]]; then
        printf '\n' >> "$temporary"
      fi
      [[ ! -s "$profile_path" ]] || printf '\n' >> "$temporary"
    fi
    {
      printf '%s\n' "$begin_marker"
      printf 'if [[ -r %s ]]; then\n' "$quoted_fragment"
      printf '  source %s\n' "$quoted_fragment"
      printf '%s\n' 'fi'
      printf '%s\n' "$end_marker"
    } >> "$temporary"
  fi

  if [[ -f "$profile_path" ]] && cmp -s "$profile_path" "$temporary"; then
    rm -f "$temporary"
    say "mise shims block already current: $profile_path"
    return 0
  fi

  if [[ -f "$profile_path" ]]; then
    backup_path="$(next_backup_path "$profile_path" "$stamp")"
    cp -p "$profile_path" "$backup_path"
    chmod "$(stat -f '%Lp' "$profile_path")" "$temporary"
    say "backed up: $profile_path -> $backup_path"
  fi

  mv "$temporary" "$profile_path"
  say "managed mise shims block: $profile_path"
}

load_profile() {
  local profile
  local dotfiles_dir="$2"
  local home_dir="$3"

  profile="$(canonical_profile "$1")" || return 1
  COMMON_BREWFILE="$dotfiles_dir/setup/mac-bootstrap/Brewfile"
  PROFILE_BREWFILE="$dotfiles_dir/setup/$profile/Brewfile"
  MISE_CONFIG="${DOTFILES_MISE_CONFIG:-$dotfiles_dir/config/mise/config.toml}"
  MISE_FRAGMENT="$dotfiles_dir/setup/mac-bootstrap/mise-shims.zsh"

  LINK_SPECS=(
    "$dotfiles_dir/config/btop|$home_dir/.config/btop"
    "$dotfiles_dir/config/fastfetch|$home_dir/.config/fastfetch"
    "$dotfiles_dir/config/bookokrat|$home_dir/.config/bookokrat"
    "$dotfiles_dir/config/ghostty/config|$home_dir/Library/Application Support/com.mitchellh.ghostty/config"
    "$dotfiles_dir/config/herdr/config.toml|$home_dir/.config/herdr/config.toml"
    "$dotfiles_dir/config/hunk/config.toml|$home_dir/.config/hunk/config.toml"
    "$dotfiles_dir/config/mise|$home_dir/.config/mise"
    "$dotfiles_dir/config/nvim|$home_dir/.config/nvim"
    "$dotfiles_dir/config/zed/keymap.json|$home_dir/.config/zed/keymap.json"
    "$dotfiles_dir/config/zed/settings.json|$home_dir/.config/zed/settings.json"
    "$dotfiles_dir/config/zed/themes|$home_dir/.config/zed/themes"
  )
  LEGACY_LINK_SPECS=()

  case "$profile" in
    mac-pro)
      LINK_SPECS+=(
        "$dotfiles_dir/setup/mac-pro/.zshrc|$home_dir/.zshrc"
        "$dotfiles_dir/config/karabiner|$home_dir/.config/karabiner"
      )
      LEGACY_LINK_SPECS+=(
        "$dotfiles_dir/setup/mac-vm/zsh-config/.zshrc|$home_dir/.zshrc"
      )
      ;;
    mac-mini)
      LINK_SPECS+=(
        "$dotfiles_dir/setup/mac-mini/.zshrc|$home_dir/.zshrc"
      )
      ;;
  esac
}

read_mise_pin() {
  local config_file="$1"
  local tool="$2"
  local version

  version="$(awk -F ' *= *' -v tool="$tool" '
    $1 == tool {
      gsub(/^"|"$/, "", $2)
      print $2
      exit
    }
  ' "$config_file")"
  [[ -n "$version" ]] || die "missing mise pin for $tool in $config_file"
  printf '%s\n' "$version"
}

load_mise_specs() {
  local config_file="$1"

  BUN_VERSION="$(read_mise_pin "$config_file" bun)" || return 1
  GO_VERSION="$(read_mise_pin "$config_file" go)" || return 1
  NODE_VERSION="$(read_mise_pin "$config_file" node)" || return 1
  PNPM_VERSION="$(read_mise_pin "$config_file" pnpm)" || return 1
  PYTHON_VERSION="$(read_mise_pin "$config_file" python)" || return 1
  MISE_SPECS=(
    "bun@$BUN_VERSION"
    "go@$GO_VERSION"
    "node@$NODE_VERSION"
    "pnpm@$PNPM_VERSION"
    "python@$PYTHON_VERSION"
  )
}

validate_neovim_parser_manifest() {
  local editor_file="$1"
  local configured=()
  local parser

  require_source "$editor_file" || return 1
  while IFS= read -r parser; do
    configured+=("$parser")
  done < <(awk '
    /^local parsers = \{/ { capture = 1; next }
    capture && /^}/ { exit }
    capture && match($0, /"[^"]+"/) {
      print substr($0, RSTART + 1, RLENGTH - 2)
    }
  ' "$editor_file")

  [[ "${configured[*]}" == "${NEOVIM_PARSERS[*]}" ]] \
    || die "Neovim parser manifest differs from $editor_file"
}

validate_neovim_lockfile() {
  local lockfile="$1"

  require_source "$lockfile" || return 1
  /usr/bin/ruby -rjson -e '
    lock = JSON.parse(File.read(ARGV.fetch(0)))
    raise "lock must be a nonempty object" unless lock.is_a?(Hash) && !lock.empty?
    lock.each do |name, entry|
      raise "invalid plugin name" unless name.is_a?(String) && !name.empty?
      commit = entry.is_a?(Hash) ? entry["commit"] : nil
      raise "invalid commit for #{name}" unless commit.is_a?(String) && commit.match?(/\A[0-9a-f]{40}\z/)
    end
  ' "$lockfile" >/dev/null 2>&1 || die "invalid Neovim lockfile: $lockfile"
}

read_lazy_manager_commit() {
  local lockfile="$1"

  /usr/bin/ruby -rjson -e \
    'puts JSON.parse(File.read(ARGV.fetch(0))).fetch("lazy.nvim").fetch("commit")' \
    "$lockfile"
}

pin_lazy_manager() {
  local lazy_dir="$1"
  local expected_commit="$2"

  [[ -d "$lazy_dir/.git" ]] || die "lazy.nvim checkout is missing: $lazy_dir"
  if ! git -C "$lazy_dir" cat-file -e "$expected_commit^{commit}" 2>/dev/null; then
    git -C "$lazy_dir" fetch --quiet origin "$expected_commit" \
      || die "cannot fetch locked lazy.nvim commit $expected_commit"
  fi
  git -C "$lazy_dir" checkout --quiet --detach "$expected_commit" \
    || die "cannot activate locked lazy.nvim commit $expected_commit"
}

provision_lazy_manager() {
  local lazy_dir="$1"

  if [[ -d "$lazy_dir/.git" ]]; then
    return 0
  fi
  [[ ! -e "$lazy_dir" && ! -L "$lazy_dir" ]] \
    || die "lazy.nvim path exists but is not a Git checkout: $lazy_dir"
  mkdir -p "$(dirname "$lazy_dir")" \
    || die "cannot create lazy.nvim parent directory: $(dirname "$lazy_dir")"
  if ! git clone --quiet --filter=blob:none --no-checkout \
    "$LAZY_NVIM_REPOSITORY" "$lazy_dir"; then
    rm -rf -- "$lazy_dir"
    die "cannot clone lazy.nvim into $lazy_dir"
  fi
}

validate_approved_mise_pins() {
  [[ "$BUN_VERSION" == "$APPROVED_BUN_VERSION" ]] \
    || die "unapproved bun pin: $BUN_VERSION (expected $APPROVED_BUN_VERSION)"
  [[ "$GO_VERSION" == "$APPROVED_GO_VERSION" ]] \
    || die "unapproved go pin: $GO_VERSION (expected $APPROVED_GO_VERSION)"
  [[ "$NODE_VERSION" == "$APPROVED_NODE_VERSION" ]] \
    || die "unapproved node pin: $NODE_VERSION (expected $APPROVED_NODE_VERSION)"
  [[ "$PNPM_VERSION" == "$APPROVED_PNPM_VERSION" ]] \
    || die "unapproved pnpm pin: $PNPM_VERSION (expected $APPROVED_PNPM_VERSION)"
  [[ "$PYTHON_VERSION" == "$APPROVED_PYTHON_VERSION" ]] \
    || die "unapproved python pin: $PYTHON_VERSION (expected $APPROVED_PYTHON_VERSION)"
}

restore_neovim_plugins() {
  local lockfile="$1"
  local lockfile_backup
  local nvim_status=0
  local parser
  local parser_list=""
  local lazy_commit
  local lazy_dir="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/lazy.nvim"

  validate_neovim_lockfile "$lockfile" || return 1
  lazy_commit="$(read_lazy_manager_commit "$lockfile")" || return 1
  lockfile_backup="$(mktemp "${TMPDIR:-/tmp}/dotfiles-lazy-lock.XXXXXX")"
  cp -p "$lockfile" "$lockfile_backup"

  for parser in "${NEOVIM_PARSERS[@]}"; do
    printf -v parser_list "%s'%s'," "$parser_list" "$parser"
  done

  if provision_lazy_manager "$lazy_dir"; then
    if pin_lazy_manager "$lazy_dir" "$lazy_commit"; then
      if DOTFILES_NVIM_RESTORE_ALL=1 \
        nvim --headless '+Lazy! restore' '+qa'; then
        if nvim --headless \
          "+lua local ok=require('nvim-treesitter').install({$parser_list}):wait(); if not ok then vim.cmd('cquit 1') end" \
          '+qa'; then
          :
        else
          nvim_status=$?
        fi
      else
        nvim_status=$?
      fi
    else
      nvim_status=$?
    fi
  else
    nvim_status=$?
  fi

  if ! cmp -s "$lockfile" "$lockfile_backup"; then
    cp -p "$lockfile_backup" "$lockfile"
    say "restored unchanged Neovim lockfile: $lockfile"
  fi
  rm -f "$lockfile_backup"

  [[ "$nvim_status" -eq 0 ]] || die "Neovim plugin restore failed"
}

verify_neovim_plugin_checkout() {
  local plugin_dir="$1"
  local expected_commit="$2"
  local head
  local untracked
  local unexpected_untracked=0

  [[ -d "$plugin_dir/.git" ]] || return 1
  head="$(git -C "$plugin_dir" rev-parse HEAD 2>/dev/null)" || return 1
  [[ "$head" == "$expected_commit" ]] || return 1
  git -C "$plugin_dir" diff --quiet --ignore-submodules=none -- || return 1
  git -C "$plugin_dir" diff --cached --quiet --ignore-submodules=none -- \
    || return 1

  while IFS= read -r -d '' untracked; do
    if [[ "$untracked" != "doc/tags" ]]; then
      unexpected_untracked=1
      break
    fi
  done < <(git -C "$plugin_dir" ls-files --others --exclude-standard -z)
  [[ "$unexpected_untracked" -eq 0 ]]
}

verify_neovim_plugins_restored() {
  local lockfile="$1"
  local plugin_root="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy"
  local name
  local expected_commit
  local bad=()

  validate_neovim_lockfile "$lockfile" || return 1
  while IFS=$'\t' read -r name expected_commit; do
    if ! verify_neovim_plugin_checkout \
      "$plugin_root/$name" "$expected_commit"; then
      bad+=("$name")
    fi
  done < <(/usr/bin/ruby -rjson -e '
    JSON.parse(File.read(ARGV.fetch(0))).each do |name, entry|
      puts "#{name}\t#{entry.fetch("commit")}"
    end
  ' "$lockfile")

  if [[ "${#bad[@]}" -gt 0 ]]; then
    printf 'invalid locked Neovim plugins: %s\n' "${bad[*]}" >&2
    return 1
  fi
}

verify_neovim_parsers_restored() {
  local parser
  local install_list=""
  local parser_list=""

  for parser in "${NEOVIM_PARSERS[@]}"; do
    printf -v install_list "%s'%s'," "$install_list" "$parser"
  done
  for parser in "${NEOVIM_PARSER_BINARIES[@]}"; do
    printf -v parser_list "%s'%s'," "$parser_list" "$parser"
  done

  DOTFILES_NVIM_PARSERS="$parser_list" \
    nvim --headless -u NONE -i NONE --noplugin \
    "+lua local install={$install_list}; local binaries={$parser_list}; local data=vim.fn.stdpath('data')..'/site/'; local bad={}; for _,parser in ipairs(install) do if vim.fn.filereadable(data..'parser-info/'..parser..'.lua')==0 then table.insert(bad,parser..' (missing parser-info)') end; if vim.fn.isdirectory(data..'queries/'..parser)==0 then table.insert(bad,parser..' (missing queries)') end end; for _,parser in ipairs(binaries) do if vim.fn.filereadable(data..'parser/'..parser..'.so')==0 then table.insert(bad,parser..' (missing binary)') else local ok=pcall(vim.treesitter.language.add,parser); if not ok then table.insert(bad,parser..' (unloadable)') end end end; if #bad>0 then io.stderr:write('invalid Tree-sitter state: '..table.concat(bad,', ')..'\\n'); vim.cmd('cquit 1') end" \
    '+qa!' >/dev/null 2>&1
}

verify_neovim_config_sandboxed() {
  local config_dir="$1"
  local live_data="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
  local sandbox
  local exit_status=0
  local blocked_command

  sandbox="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-nvim-doctor.XXXXXX")" || return 1
  require_source "$config_dir/init.lua" || { rm -rf "$sandbox"; return 1; }
  mkdir -p \
    "$sandbox/bin" \
    "$sandbox/cache" \
    "$sandbox/data/nvim/lazy" \
    "$sandbox/config" \
    "$sandbox/state"
  cp -R "$config_dir" "$sandbox/config/nvim" || exit_status=$?
  if [[ "$exit_status" -eq 0 ]]; then
    cp -R "$live_data/lazy/." "$sandbox/data/nvim/lazy/" || exit_status=$?
  fi
  if [[ "$exit_status" -eq 0 ]]; then
    cp -R "$live_data/site" "$sandbox/data/nvim/site" || exit_status=$?
  fi

  if [[ "$exit_status" -eq 0 ]]; then
    for blocked_command in curl git wget; do
      printf '#!/bin/sh\nexit 99\n' > "$sandbox/bin/$blocked_command"
      chmod +x "$sandbox/bin/$blocked_command"
    done

    PATH="$sandbox/bin:$PATH" \
      XDG_CACHE_HOME="$sandbox/cache" \
      XDG_CONFIG_HOME="$sandbox/config" \
      XDG_DATA_HOME="$sandbox/data" \
      XDG_STATE_HOME="$sandbox/state" \
      nvim --headless \
        "+lua if vim.v.errmsg ~= '' then io.stderr:write(vim.v.errmsg..'\\n'); vim.cmd('cquit 1') end" \
        '+qa!' >/dev/null 2>&1 || exit_status=$?
  fi

  rm -rf "$sandbox"
  [[ "$exit_status" -eq 0 ]]
}
