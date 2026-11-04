# Personal Macs use the terminal's advertised color support.
# FORCE_COLOR=1 restricts Codex to basic colors, hiding Dali's input shading.
# Clear inherited overrides too, so a new shell fixes an older session.
# Leave TERM and COLORTERM unchanged, and honor explicit NO_COLOR requests.
unset FORCE_COLOR

# The personal-Mac Codex shortcuts share the Air's syntax theme.
typeset -g _dotfiles_codex_theme=dali
