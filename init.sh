#!/usr/bin/env bash

cd "$(dirname "$0")"
set -o errexit -o noclobber -o nounset

help() {
  echo "
  Configure macOS for first-time use.

  USAGE:
    init [OPTION] [ARGS...]

  OPTIONS:
    --init      Idempotent initialization of dependencies
    --symlink   Symlink dotfiles in home directory
    -h, --help  Display help
  "
}

init() {
  echo "Initializing $(whoami)'s dev dependencies..."
  sudo -v

  mkdir -p "$HOME/dev"

  if ! command -v zinit &> /dev/null; then
    echo "Installing zinit..."
    bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
  fi

  if [ ! -f /opt/homebrew/bin/brew ]; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> "$HOME/.zshrc"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  brew bundle

  echo "Initialization complete, open a new terminal tab/window."

  # Must be last, nothing after this command will execute
  env zsh -l
}

symlink() {
  local dir="$HOME/dev/trs/dotfiles"
  local backup_dir="$HOME/dev/trs/dotfiles_backup"
  local files=".config/starship.toml .gnupg/gpg-agent.conf source .ssh/config .gitconfig .zshrc"

  # Backup existing, then create symlinks
  for f in $files; do
      if [ -L "$HOME/$f" ]; then
        echo "$HOME/$f is already a symlink, skipping..."
        continue
      fi
      echo "Backing up existing dotfiles and creating $HOME/$f symlink..."
      mkdir -p "$backup_dir/$(dirname "$f")"
      mv "$HOME/$f" "$backup_dir/$f"
      mkdir -p "$(dirname "$HOME/$f")"
      ln -s "$dir/$f" "$HOME/$f"
  done
}

parse_args() {
  [ "$#" -eq 0 ] && help && exit 0;
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --init) shift; do_init=1;;
      --symlink) shift; do_symlink=1;;
      -h|--help) shift; help;;
      -*) echo "Unknown option: $1" >&2; help; exit 1;;
      *) shift;;
    esac
  done

  if [ -n "${do_init-}" ]; then init; fi
  if [ -n "${do_symlink-}" ]; then symlink; fi
}

main() {
  parse_args "$@"
}

main "$@"
