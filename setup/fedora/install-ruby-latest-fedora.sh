#!/usr/bin/env zsh
# Exit on error, undefined var, or any failure in a pipeline
setopt ERR_EXIT
setopt nounset
setopt pipefail

# ensure rbenv is installed
if ! command -v rbenv &>/dev/null; then
  echo "❌ rbenv not found in \$PATH" >&2
  exit 1
fi

echo "🔄 Updating rbenv definitions…"
# if you have the ruby-build plugin, this will refresh the list
rbenv update &>/dev/null || true

# get the latest semver tag
LATEST=$(rbenv install -l \
  | sed 's/^[[:space:]]*//' \
  | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' \
  | sort -V \
  | tail -n1)

if [[ -z $LATEST ]]; then
  echo "⚠️  Could not determine latest Ruby version." >&2
  exit 1
fi

echo "✨ Latest Ruby version is $LATEST"

echo "📦 Installing Ruby $LATEST (skips if already installed)…"
rbenv install -s "$LATEST"

echo "🌐 Switching global Ruby to $LATEST"
rbenv global "$LATEST"
rbenv rehash

echo "✅ Now using: $(ruby -v)"
