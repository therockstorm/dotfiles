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
    --restore   Restore macOS and program settings
    -h, --help  Display help
  "
}

init() {
  echo "Initializing $(whoami)'s dev dependencies..."
  sudo -v

  mkdir -p "$HOME/dev"

  if [ ! -f "$HOME/.ssh/id_rsa.pub" ]; then
    read -rp "Enter the email address associated with your GitHub account: " email

    echo "Generating ssh key..."
    ssh-keygen -f "$HOME/.ssh/id_rsa" -t rsa -b 4096 -C "$email"
    eval "$(ssh-agent -s)"
  fi

  if [ ! -f /usr/local/bin/brew ]; then
    echo "Installing Homebrew..."
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi

  brew bundle

  [ -d "$HOME/.nvm" ] ||
    (curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash)

  ohMyZsh=$HOME/.oh-my-zsh
  if [ ! -d "$ohMyZsh" ]; then
    echo "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sed 's:env zsh -l::g')"
    rm "$HOME/.bash_profile"
  fi

  pbcopy < "$HOME/.ssh/id_rsa.pub"
  echo "Initialization complete. Add generated SSH key (copied to your clipboard) to your GitHub account: https://github.com/settings/keys"

  # Must be last, nothing after this command will execute
  env zsh -l
}

restore() {
  echo "Restoring settings..."

  mackup restore

  # For more, see https://github.com/herrbischoff/awesome-macos-command-line and https://github.com/mathiasbynens/dotfiles/blob/master/.macos
  # Map Caps Lock to ESC
  hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000029}]}'
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
