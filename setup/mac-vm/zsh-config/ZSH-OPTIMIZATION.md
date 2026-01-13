# ZSH Prompt Optimization Guide

Optimizations to reduce zsh shell startup time from ~500ms to ~82ms.

## Results

| Metric | Before | After |
|--------|--------|-------|
| Shell reload time | ~500-600ms | **~82ms** |
| Improvement | - | **~86% faster** |

---

## Optimizations

### 1. Cached `compinit`

**Problem:** `compinit` scans all completion files every startup (~100-300ms).

**Solution:** Rebuild cache once per day using `-C` flag.

```zsh
# .zshrc
autoload -Uz compinit
if [[ -f ~/.zcompdump && $(date +'%j') == $(stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null) ]]; then
  compinit -C  # Cached (fast)
else
  compinit     # Full rebuild (once per day)
fi
```

**Savings:** ~100-200ms

---

### 2. Cached Nix Plugin Paths

**Problem:** Glob patterns like `/nix/store/*-zsh-autosuggestions-*/...` enumerate thousands of directories.

**Solution:** Resolve paths once, cache to files, read from cache on startup.

```zsh
# functions.zsh
_get_cached_nix_plugin() {
  local cache_file="$_ZSH_CACHE_DIR/nix-$1-path"
  if [[ -f "$cache_file" ]]; then
    local cached_path="$(cat "$cache_file")"
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
# prompt.zsh
_cache_init() {
  local cache_file="$_ZSH_CACHE_DIR/${1}-init.zsh"
  if [[ ! -f "$cache_file" || $(( $(date +%s) - $(stat -f %m "$cache_file") )) -gt 86400 ]]; then
    eval "$2" > "$cache_file"
  fi
  source "$cache_file"
}

_cache_init "starship" "starship init zsh"
_cache_init "zoxide" "zoxide init --cmd cd zsh"
```

```zsh
# .zshrc (devbox)
_devbox_cache="$_ZSH_CACHE_DIR/devbox-shellenv.zsh"
if [[ ! -f "$_devbox_cache" || $(( $(date +%s) - $(stat -f %m "$_devbox_cache") )) -gt 86400 ]]; then
  devbox global shellenv > "$_devbox_cache"
fi
source "$_devbox_cache"
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

**How it works:**

- `$commands` - Zsh maintains a hash table of all executables in `$PATH`
- `$+commands[nix]` - The `$+` prefix checks if key exists (returns 1 or 0)
- `(( ... ))` - Arithmetic evaluation treats 1 as true, 0 as false

```
command -v nix (slow):
┌─────────┐    fork()    ┌───────────┐   search   ┌───────┐
│   zsh   │ ──────────▶  │ subprocess│ ─────────▶ │ $PATH │
└─────────┘              └───────────┘            └───────┘
                              │
                          exit code
                              ▼
                          ~5-20ms

$+commands[nix] (fast):
┌─────────┐   hash lookup   ┌──────────────┐
│   zsh   │ ──────────────▶ │ commands hash│
└─────────┘                 └──────────────┘
                                  │
                               0 or 1
                                  ▼
                             ~0.001ms
```

**Savings:** ~10-20ms

---

### 5. Removed `bashcompinit`

Removed unused bash completion compatibility layer.

**Savings:** ~20-50ms

---

## Cache Management

### Cache Location

```
~/.cache/zsh/
├── starship-init.zsh
├── zoxide-init.zsh
├── devbox-shellenv.zsh
├── nix-zsh-autosuggestions-path
└── nix-zsh-syntax-highlighting-path

~/.zcompdump  # Completion cache
```

### Commands

```bash
reload              # Reload config, shows time in ms
refresh_zsh_cache   # Clear all caches
refresh_nix_plugin_cache  # Refresh Nix plugin paths only
```

### When to Refresh

- After `devbox global update`
- After updating starship, zoxide
- If shell behaves unexpectedly
- `goodMorning` auto-refreshes after updates

---

## Measuring Startup Time

```bash
# Quick
reload

# Benchmark new shell
time zsh -i -c exit

# Detailed profiling (add to .zshrc temporarily)
# Top of file:
zmodload zsh/zprof
# Bottom of file:
zprof
```

---

## File Summary

| File | Purpose |
|------|---------|
| `.zshrc` | Main config, sources other files, devbox cache, compinit |
| `prompt.zsh` | Starship, zoxide, cached init scripts |
| `functions.zsh` | Cache functions, `reload()`, `goodMorning()` |
| `alias.zsh` | Aliases |
| `tooling.zsh` | Dev tool configs |
| `k8s.zsh` | Kubernetes config |

---

## Future Optimizations

1. **Lazy load completions** - Defer kubectl/docker until first use
2. **zsh-defer** - Load syntax highlighting after prompt renders
3. **zcompile** - Bytecode compile .zsh files
4. **Profile plugins** - Check `you-should-use` overhead
