# ZSH Prompt Optimization Guide

Optimizations to reduce zsh shell startup time from ~500ms → ~82ms → **~40ms** (consistent, prioritizing UX).

## Results

| Metric | Original | Phase 1 | Phase 2 (Current) |
|--------|----------|---------|-------------------|
| Shell reload time | ~500-600ms | ~82ms | **~40ms** |
| Fresh shell startup | ~500ms | ~93ms | **~40ms** |
| Improvement | - | ~86% faster | **~92% faster** |
| Reload consistency | Varies | Varies | **Always ~40ms** |

**Note:** Prioritizes UX (immediate plugin functionality, consistent performance) over extreme speed optimization.

---

## Phase 2 Optimizations (Jan 2026)

### 1. Cached `brew shellenv` & Eager Cache Rebuild

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

**Cache Refresh:** `goodMorning()` calls `refresh_zsh_cache()` which rebuilds all caches immediately (eager rebuild):
- `brew shellenv` → `brew-shellenv.zsh`
- `starship init zsh` → `starship-init.zsh`
- `zoxide init zsh` → `zoxide-init.zsh`
- `devbox global shellenv` → `devbox-shellenv.zsh`
- `compinit` → `.zcompdump` (completion cache)
- Nix plugin paths (autosuggestions, syntax-highlighting)

This ensures **all** reloads after `goodMorning` are consistently fast (~40ms) instead of having one slow reload (~275ms).

**Note:** `goodMorning()` also runs `refresh-global` directly (not the alias) since aliases don't expand inside functions.

**Savings:** ~30ms

---

### 2. ~~Deferred Plugin Loading~~ → Immediate Loading (Updated Jan 2026)

**Problem:** `zsh-syntax-highlighting` (~19ms) and `zsh-autosuggestions` (~13ms) load at startup.

**Original Solution (Deferred Loading):** Load plugins via `preexec` hook after first command to save ~32ms startup time.

**Why We Changed It:**
- Plugins didn't work until after first command completed
- Poor UX when starting terminal with `goodMorning` (plugins inactive during entire workflow)
- 5-10ms startup cost is negligible on modern machines

**Current Solution (Immediate Loading):**

```zsh
# .zshrc - Load plugins immediately for better UX
_load_nix_plugin "zsh-autosuggestions"
_load_nix_plugin "zsh-syntax-highlighting"
```

**Trade-off:** Adds ~5-10ms to startup but ensures autosuggestions and syntax highlighting work right away.

**Result:** Better user experience at minimal performance cost (~28ms vs ~20ms startup)

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

**Solution:** Rebuild cache once per day using `-C` flag. Cache is eagerly rebuilt by `goodMorning()`.

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

**Eager Rebuild:** `refresh_zsh_cache()` (called by `goodMorning`) rebuilds the completion cache immediately, ensuring all subsequent reloads are consistently fast (~40ms).

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

**Solution:** Cache command output to files, source cached files. Auto-rebuild if missing or older than 1 day.

```zsh
# prompt.zsh (using zsh native zstat)
_cache_init() {
  local name="$1" cmd="$2"
  local cache_file="$_ZSH_CACHE_DIR/${name}-init.zsh"

  if [[ ! -f "$cache_file" ]]; then
    eval "$cmd" > "$cache_file"  # Rebuild if missing
  else
    local file_mtime
    zstat -A file_mtime +mtime "$cache_file"
    (( EPOCHSECONDS - file_mtime > 86400 )) && eval "$cmd" > "$cache_file"  # Rebuild if old
  fi
  source "$cache_file"
}

_cache_init "starship" "starship init zsh"
_cache_init "zoxide" "zoxide init --cmd cd zsh"
```

**Cache Refresh Strategy:**
- `goodMorning()` calls `refresh_zsh_cache()` which **eagerly rebuilds** all caches immediately
- This ensures the first `reload` after `goodMorning` is fast (~28ms) instead of slow (~300ms)
- The rebuild cost (~300ms) happens during `goodMorning` when you're waiting anyway

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
- `goodMorning` auto-refreshes after updates (rebuilds eagerly, so next `reload` is fast)

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
| `compinit -C` (cached) | ~15ms |
| `zsh-autosuggestions` | ~3ms |
| `zsh-syntax-highlighting` | ~5ms |
| **Total startup/reload** | **~40ms** |

Deferred (loads after first prompt):
- `you-should-use`: ~10ms

**Note:** All reloads are consistently ~40ms because `goodMorning()` eagerly rebuilds all caches (including completions).

---

## File Summary

| File | Purpose |
|------|---------|
| `.zprofile` | Brew shellenv (cached) |
| `.zshrc` | Main config, immediate plugin loading, devbox cache, compinit |
| `prompt.zsh` | Starship, zoxide, zsh modules, cached init scripts, deferred `you-should-use` |
| `functions.zsh` | Cache functions, `reload()`, `refresh_zsh_cache()` (eager rebuild), `goodMorning()` |
| `alias.zsh` | Aliases including `refresh-global` |
| `tooling.zsh` | Dev tool configs |
| `k8s.zsh` | Kubernetes config |

---

## Key Principles

1. **Cache expensive operations** - Subprocess spawning is slow (~5-30ms each)
2. **Use zsh native builtins** - `zstat`, `EPOCHSECONDS`, `read`, `$+commands[]`
3. **Prioritize UX over extreme optimization** - Load essential plugins immediately for better experience
4. **Eager cache rebuild in `goodMorning`** - Rebuild caches immediately (not lazily) so subsequent reloads are fast
5. **Fall back gracefully** - If cache missing, `_cache_init()` rebuilds automatically
