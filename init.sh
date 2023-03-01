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

  if [ ! -f /opt/homebrew/bin/brew ]; then
    echo "Installing Homebrew..."
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi

  brew bundle
  asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git

  ohMyZsh=$HOME/.oh-my-zsh
  if [ ! -d "$ohMyZsh" ]; then
    echo "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sed 's:env zsh -l::g')"
    rm "$HOME/.bash_profile"
  fi

  echo "Initialization complete, open a new terminal tab/window."

  # Must be last, nothing after this command will execute
  env zsh -l
}

parse_args() {
  [ "$#" -eq 0 ] && help && exit 0;
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --init) shift; do_init=1;;
      --restore) shift; do_restore=1;;
      -h|--help) shift; help;;
      -*) echo "Unknown option: $1" >&2; help; exit 1;;
      *) shift;;
    esac
  done

  if [ -n "${do_init-}" ]; then init; fi
  if [ -n "${do_restore-}" ]; then restore; fi
}

main() {
  parse_args "$@"
}

main "$@"
