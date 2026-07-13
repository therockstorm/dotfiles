#!/usr/bin/env bash
# Stage-one installer: Xcode Command Line Tools, mise, repo clone, seed
# symlink, converge. Idempotent — rerun at any point.
#
#   curl -fsSL https://raw.githubusercontent.com/therockstorm/dotfiles/master/install.sh | bash
set -euo pipefail

DOTFILES="$HOME/dev/dotfiles"

# Everything below needs git, which needs Apple's Command Line Tools. Trigger
# the GUI installer and wait for it, so this stays one run instead of
# exit-and-rerun. Canceling the dialog leaves this loop waiting — Ctrl-C and
# rerun.
if ! xcode-select -p >/dev/null 2>&1; then
  echo "■ Requesting Command Line Tools install — accept Apple's dialog; waiting..."
  xcode-select --install >/dev/null 2>&1 || true
  until xcode-select -p >/dev/null 2>&1; do
    printf '.'
    sleep 10
  done
  echo " done"
fi

if ! command -v mise >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/mise" ]; then
  echo "■ Installing mise..."
  curl -fsSL https://mise.run | sh
fi
export PATH="$HOME/.local/bin:$PATH"

REPO_URL="https://github.com/therockstorm/dotfiles.git"
if [ -d "$DOTFILES/.git" ]; then
  origin="$(git -C "$DOTFILES" remote get-url origin 2>/dev/null || true)"
  if [ "$origin" != "$REPO_URL" ] && [ "$origin" != "${REPO_URL%.git}" ]; then
    echo "error: $DOTFILES is not a checkout of $REPO_URL; move it aside and rerun" >&2
    exit 1
  fi
elif [ -e "$DOTFILES" ]; then
  echo "error: $DOTFILES exists but is not a git repository; move it aside and rerun" >&2
  exit 1
else
  echo "■ Cloning dotfiles..."
  git clone "$REPO_URL" "$DOTFILES"
fi

# Seed symlink: mise can't symlink its own config before reading it; every
# other symlink is declared in [dotfiles].
config="$HOME/.config/mise/config.toml"
target="$DOTFILES/.config/mise/config.toml"
if [ -L "$config" ]; then
  if [ "$(readlink "$config")" != "$target" ]; then
    echo "error: $config points to $(readlink "$config"), not $target; move it aside and rerun" >&2
    exit 1
  fi
elif [ -e "$config" ]; then
  echo "error: $config exists and is not a symlink; move it aside and rerun" >&2
  exit 1
else
  mkdir -p "$HOME/.config/mise"
  ln -s "$target" "$config"
fi

exec mise bootstrap --yes
