#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd -P)"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-colors.XXXXXX")"
trap 'rm -rf "$test_root"' EXIT

mkdir -p "$test_root/bin"
for tool in mise starship zoxide op uv; do
  printf '#!/bin/sh\nprintf ":\\n"\n' > "$test_root/bin/$tool"
  chmod +x "$test_root/bin/$tool"
done

cat > "$test_root/bin/codex" <<'CODEX'
#!/bin/sh
printf '%s\n' "$@"
CODEX
chmod +x "$test_root/bin/codex"

for profile in mac-air mac-pro mac-mini; do
  profile_home="$test_root/$profile"
  mkdir -p "$profile_home/Developer"
  ln -s "$REPO_DIR" "$profile_home/Developer/dotfiles-hd"
  ln -s "$REPO_DIR/hosts/$profile/.zshrc" "$profile_home/.zshrc"
  # Restore the fixture PATH after macOS's system login profile runs.
  printf 'export PATH="$COLOR_TEST_BIN:/usr/bin:/bin"\n' > "$profile_home/.zprofile"

  for color_mode in automatic inherited no-color; do
    color_env=(/usr/bin/env)
    if [[ "$color_mode" != automatic ]]; then
      color_env+=(FORCE_COLOR=1)
    fi
    if [[ "$color_mode" == no-color ]]; then
      color_env+=(NO_COLOR=1)
    fi
    env -i HOME="$profile_home" ZDOTDIR="$profile_home" \
      PATH="$test_root/bin:/usr/bin:/bin" COLOR_TEST_BIN="$test_root/bin" \
      HOMEBREW_PREFIX="$test_root/homebrew" TERM=xterm-256color \
      TERM_PROGRAM=rex COLORTERM=truecolor \
      "${color_env[@]}" /bin/zsh -lic '
        [[ -z ${FORCE_COLOR+x} ]] || {
          print -u2 "Inherited FORCE_COLOR still limits terminal colors"
          exit 1
        }
        [[ $COLORTERM == truecolor && $TERM_PROGRAM == rex ]] || exit 1
        [[ $_dotfiles_codex_theme == dali ]] || exit 1
        expected="$(printf "%s\n" -c "tui.theme=\"dali\"" --version)"
        [[ "$(cod --version)" == "$expected" ]] || exit 1
        expected="$(printf "%s\n" -c "tui.theme=\"dali\"" -c "tui.theme=\"nord\"" --version)"
        [[ "$(cod -c "tui.theme=\"nord\"" --version)" == "$expected" ]] || exit 1
        if [[ $1 == no-color ]]; then
          [[ ${NO_COLOR-} == 1 ]] || exit 1
        else
          [[ -z ${NO_COLOR+x} ]] || exit 1
        fi
        # A deliberate per-command override still works after shell startup.
        [[ "$(FORCE_COLOR=3 /usr/bin/printenv FORCE_COLOR)" == 3 ]] || exit 1
      ' zsh "$color_mode"
    printf 'PASS %s: %s, automatic colors, Dali, and per-command overrides\n' "$profile" "$color_mode"
  done
done

printf 'Personal Mac color tests passed.\n'
