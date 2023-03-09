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
    -h, --help  Display help
  "
}

init() {
  echo "Initializing $(whoami)'s dev dependencies..."
  sudo -v

  mkdir -p "$HOME/dev"

  ohMyZsh=$HOME/.oh-my-zsh
  if [ ! -d "$ohMyZsh" ]; then
    echo "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    rm "$HOME/.bash_profile"
  fi

  if [ ! -f /opt/homebrew/bin/brew ]; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> "$HOME/.zshrc"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  brew bundle
  asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git

  echo "Initialization complete, open a new terminal tab/window."

  # Must be last, nothing after this command will execute
  env zsh -l
}

parse_args() {
  [ "$#" -eq 0 ] && help && exit 0;
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --init) shift; do_init=1;;
      -h|--help) shift; help;;
      -*) echo "Unknown option: $1" >&2; help; exit 1;;
      *) shift;;
    esac
  done

  if [ -n "${do_init-}" ]; then init; fi
}

main() {
  parse_args "$@"
}

main "$@"
