#!/usr/bin/env bash
set -euo pipefail

# 👇 Install dependencies (adjust as needed)
echo "🔧 Installing system packages..."
sudo dnf install -y gcc make patch zlib-devel libffi-devel libyaml-devel \
  openssl-devel readline-devel gdbm-devel ncurses-devel curl git

# 📌 Ruby version and prefix
RUBY_VERSION="3.1.3"
RUBY_PREFIX="$HOME/.rbenv/versions/$RUBY_VERSION"

# 🧹 Clean previous install if needed
if rbenv versions | grep -q "$RUBY_VERSION"; then
  echo "🧽 Removing existing Ruby $RUBY_VERSION..."
  rbenv uninstall -f "$RUBY_VERSION"
fi

# 🚧 Set compiler flags to avoid GCC 15 issues (use C99 mode for _Bool and loop‐local declarations)
export CFLAGS="-std=gnu99 -Wno-array-bounds -Wno-unterminated-string-initialization"
export CPPFLAGS="$CFLAGS"
export CXXFLAGS="$CFLAGS"
export RUBY_CONFIGURE_OPTS="--disable-install-doc --disable-nls --prefix=$RUBY_PREFIX"

# 📦 Install via rbenv
echo "📦 Installing Ruby $RUBY_VERSION..."
rbenv install "$RUBY_VERSION"

# 🎯 Set as global version
rbenv global "$RUBY_VERSION"
echo "✅ Ruby $(ruby -v) is ready"
