# ZSH Prompt Optimization Guide

Optimizations to reduce zsh shell startup time from ~500ms → ~82ms → **~20ms**.

## Results

| Metric | Original | Phase 1 | Phase 2 (Current) |
|--------|----------|---------|-------------------|
| Shell reload time | ~500-600ms | ~82ms | **~18-20ms** |
| Fresh shell startup | ~500ms | ~93ms | **~32-35ms** |
| Improvement | - | ~86% faster | **~96% faster** |

---

## Phase 2 Optimizations (Jan 2026)

### 1. Cached `brew shellenv`

**Problem:** `eval "$(/opt/homebrew/bin/brew shellenv)"` spawns subprocess every startup (~30ms).

**Solution:** Cache output to file, source cached file. Falls back to eval if cache missing.

```zsh
# .zprofile
_BREW_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/brew-shellenv.zsh"
if [[ -f "$_BREW_CACHE" ]]; then
  source "$_BREW_CACHE"
else
  eval "$(/opt/homebrew/bin/brew shellenv)"  # Fallback
fi
```

Cache created by `goodMorning`.

**Savings:** ~30ms

---

### 2. Deferred Plugin Loading

**Problem:** `zsh-syntax-highlighting` (~19ms) and `zsh-autosuggestions` (~13ms) load at startup even though you don't need them until you start typing.

**Before (slow):**
```
Shell starts → Load plugins (32ms) → Show prompt
                    ↑
            You're waiting here
```

**Solution:** Defer loading until first command execution using `preexec` hook.

```zsh
# .zshrc
_deferred_plugins_loaded=0
_load_deferred_plugins() {
  (( _deferred_plugins_loaded )) && return
  _deferred_plugins_loaded=1
  _load_nix_plugin "zsh-autosuggestions"
  _load_nix_plugin "zsh-syntax-highlighting"
}
autoload -Uz add-zsh-hook
add-zsh-hook preexec _load_deferred_plugins
```

**How it works:**

| Line | Purpose |
|------|---------|
| `_deferred_plugins_loaded=0` | Flag to track if plugins loaded (starts false) |
| `(( _deferred_plugins_loaded )) && return` | If flag is 1 (truthy), exit early |
| `_deferred_plugins_loaded=1` | Mark as loaded so we don't reload |
| `add-zsh-hook preexec ...` | `preexec` runs **right before any command executes** |

**After (fast):**
```
Shell starts → Show prompt (instant!) → You type "ls" → preexec hook fires
                                                              ↓
                                                      Load plugins (32ms)
                                                              ↓
                                                      Run "ls"
```

The 32ms delay still happens, but it's hidden between pressing Enter and seeing output — feels instant because you're already interacting. Subsequent commands have no delay (flag prevents reloading).

**Savings:** ~32ms perceived startup time

---

### 3. Deferred `you-should-use` Plugin

**Problem:** Plugin loads at startup (~10ms).

**Solution:** Defer until first prompt using `precmd` hook.

```zsh
# prompt.zsh
_load_ysu() {
  unset -f _load_ysu
  source ~/Developer/zsh-you-should-use/you-should-use.plugin.zsh
}
precmd_functions+=(_load_ysu)
```

**Savings:** ~10ms

---

### 4. Native Zsh `zstat` and `EPOCHSECONDS`

**Problem:** External `stat` and `date` commands spawn subprocesses.

```zsh
# Before (slow - spawns subprocesses)
if [[ $(( $(date +%s) - $(stat -f %m "$file") )) -gt 86400 ]]; then
```

**Solution:** Use zsh native modules.

```zsh
# prompt.zsh (load modules once)
zmodload zsh/datetime 2>/dev/null  # Provides $EPOCHSECONDS, $EPOCHREALTIME
zmodload zsh/stat 2>/dev/null      # Provides zstat builtin

# Usage (fast - no subprocesses)
local file_mtime
zstat -A file_mtime +mtime "$file"
if (( EPOCHSECONDS - file_mtime > 86400 )); then
```

**Savings:** ~5-10ms

---

### 5. Zsh Builtin `read` Instead of `$(cat ...)`

**Problem:** `$(cat "$file")` spawns a subprocess.

```zsh
# Before (slow)
local cached_path="$(cat "$cache_file")"
```

**Solution:** Use zsh builtin `read`.

```zsh
# After (fast - no subprocess)
local cached_path
read -r cached_path < "$cache_file"
```

**Savings:** ~2-5ms per read

---

## Phase 1 Optimizations (Original)

### 1. Cached `compinit`

**Problem:** `compinit` scans all completion files every startup (~100-300ms).

**Solution:** Rebuild cache once per day using `-C` flag.

```zsh
# .zshrc (using zsh native zstat)
fpath=(/Users/hameldesai/.docker/completions $fpath)
autoload -Uz compinit
if [[ -f ~/.zcompdump ]]; then
  local _zcomp_mtime _today_start
  zstat -A _zcomp_mtime +mtime ~/.zcompdump
  _today_start=$(( EPOCHSECONDS - (EPOCHSECONDS % 86400) ))
  if (( _zcomp_mtime >= _today_start )); then
    compinit -C  # Cached (fast)
  else
    compinit     # Full rebuild (once per day)
  fi
else
  compinit       # First run
fi
```

**Savings:** ~100-200ms

---

### 2. Cached Nix Plugin Paths

**Problem:** Glob patterns like `/nix/store/*-zsh-autosuggestions-*/...` enumerate thousands of directories.

**Solution:** Resolve paths once, cache to files, read from cache on startup.

```zsh
# functions.zsh (using zsh builtin read)
_get_cached_nix_plugin() {
  local cache_file="$_ZSH_CACHE_DIR/nix-$1-path"
  if [[ -f "$cache_file" ]]; then
    local cached_path
    read -r cached_path < "$cache_file"
    [[ -r "$cached_path" ]] && echo "$cached_path" && return 0
  fi
  return 1
}

_load_nix_plugin() {
  local cached_path="$(_get_cached_nix_plugin "$1")"
  if [[ -n "$cached_path" ]]; then
    source "$cached_path"  # Fast path
  else
    # Fallback: glob (slow, first run only)
    local found=(/nix/store/*-$1-*/share/$1/$1.zsh(N[1]))
    [[ -n "$found" ]] && source "$found" && echo "$found" > "$_ZSH_CACHE_DIR/nix-$1-path"
  fi
}
```

**Savings:** ~50-150ms

---

### 3. Cached Init Scripts (Starship, Zoxide, Devbox)

**Problem:** `eval "$(starship init zsh)"` spawns subprocess every startup.

**Solution:** Cache command output to files, source cached files.

```zsh
# prompt.zsh (using zsh native zstat)
_cache_init() {
  local name="$1" cmd="$2"
  local cache_file="$_ZSH_CACHE_DIR/${name}-init.zsh"

  if [[ ! -f "$cache_file" ]]; then
    eval "$cmd" > "$cache_file"
  else
    local file_mtime
    zstat -A file_mtime +mtime "$cache_file"
    (( EPOCHSECONDS - file_mtime > 86400 )) && eval "$cmd" > "$cache_file"
  fi
  source "$cache_file"
}

_cache_init "starship" "starship init zsh"
_cache_init "zoxide" "zoxide init --cmd cd zsh"
```

**Savings:** ~130-230ms

---

### 4. Native Zsh Command Checking

**Problem:** `command -v nix` spawns a subprocess every time.

**Solution:** Use zsh's native `$commands` hash table lookup.

```zsh
# Before (slow - spawns subprocess)
if command -v nix &> /dev/null; then

# After (fast - hash table lookup)
if (( $+commands[nix] )); then
```

**Savings:** ~10-20ms

---

## Cache Management

### Cache Location

```
~/.cache/zsh/
├── brew-shellenv.zsh          # Homebrew environment
├── starship-init.zsh          # Starship prompt init
├── zoxide-init.zsh            # Zoxide cd replacement
├── devbox-shellenv.zsh        # Devbox global environment
├── nix-zsh-autosuggestions-path
└── nix-zsh-syntax-highlighting-path

~/.zcompdump  # Completion cache
```

### Commands

```bash
reload                    # Reload config, shows time in ms
refresh_zsh_cache         # Rebuild ALL caches (brew, init scripts, nix plugins)
refresh_nix_plugin_cache  # Refresh Nix plugin paths only
```

### When to Refresh

- After `devbox global update`
- After `brew upgrade`
- After updating starship, zoxide
- If shell behaves unexpectedly
- `goodMorning` auto-refreshes after updates

---

## Measuring Startup Time

```bash
# Quick (using reload function)
reload

# Benchmark new shell (5 runs)
for i in 1 2 3 4 5; do time (zsh -i -c exit); done

# Profile individual components
zsh -c '
zmodload zsh/datetime
start=$EPOCHREALTIME
source ~/.zprofile
printf "zprofile: %.1fms\n" "$(( (EPOCHREALTIME - start) * 1000 ))"
# ... add more sources
'

# Detailed profiling (add to .zshrc temporarily)
# Top of file:
zmodload zsh/zprof
# Bottom of file:
zprof
```

---

## Performance Breakdown (Current)

| Component | Time |
|-----------|------|
| `brew shellenv` (cached) | ~0.1ms |
| `prompt.zsh` (starship+zoxide cached) | ~12ms |
| `tooling+functions+alias+k8s` | ~1.5ms |
| `devbox shellenv` (cached) | ~0.3ms |
| `compinit -C` (cached) | ~10ms |
| **Total startup** | **~25-35ms** |

Deferred (loads after first command):
- `zsh-autosuggestions`: ~13ms
- `zsh-syntax-highlighting`: ~19ms
- `you-should-use`: ~10ms

---

## File Summary

| File | Purpose |
|------|---------|
| `.zprofile` | Brew shellenv (cached) |
| `.zshrc` | Main config, deferred plugins, devbox cache, compinit |
| `prompt.zsh` | Starship, zoxide, zsh modules, cached init scripts |
| `functions.zsh` | Cache functions, `reload()`, `refresh_zsh_cache()`, `goodMorning()` |
| `alias.zsh` | Aliases |
| `tooling.zsh` | Dev tool configs |
| `k8s.zsh` | Kubernetes config |

---

## Key Principles

1. **Cache expensive operations** - Subprocess spawning is slow (~5-30ms each)
2. **Use zsh native builtins** - `zstat`, `EPOCHSECONDS`, `read`, `$+commands[]`
3. **Defer non-essential plugins** - Load after prompt appears, not during startup
4. **Rebuild caches via `goodMorning`** - Not during shell startup
5. **Fall back gracefully** - If cache missing, use slow path (works before `goodMorning` runs)
