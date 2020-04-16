#!/bin/bash

cd "$(dirname "$0")"
set -o errexit -o noclobber -o nounset

help() {
  echo "
  Configure macOS for first-time use.

  USAGE:
    init [OPTION] [ARGS...]

  OPTIONS:
    --init              Idempotent initialization of dependencies
    -h, --help          Display help
  "
}

init() {
  HOME=/Users/$(whoami) # zsh installation affects `~`
  eval "$(curl -fsSL https://raw.githubusercontent.com/therockstorm/dotfiles/master/colors.sh)"
  printf "${YELLOW}Initializing $(whoami)'s dev dependencies...${NORMAL}\n"
  sudo -v

  mkdir -p $HOME/dev

  if [ ! -f "$HOME/.ssh/id_rsa.pub" ]; then
    read -rp "${GREEN}Enter the email address associated with your GitHub account: ${NORMAL}" email

    printf "${YELLOW}Generating ssh key...${NORMAL}\n"
    ssh-keygen -f $HOME/.ssh/id_rsa -t rsa -b 4096 -C "$email"
    eval "$(ssh-agent -s)"
  fi

  if [ ! -f /usr/local/bin/brew ]; then
    printf "${YELLOW}Installing Homebrew...${NORMAL}\n"
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi

  brew bundle

  code --install-extension shan.code-settings-sync

  [ -d "$HOME/.nvm" ] ||
    (curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash)

  OH_MY_ZSH=$HOME/.oh-my-zsh
  if [ ! -d "$OH_MY_ZSH" ]; then
    printf "${YELLOW}Installing oh-my-zsh...${NORMAL}\n"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sed 's:env zsh -l::g')"
    rm "$HOME/.bash_profile"
  fi

  printf "${YELLOW}Modifying macOS settings...${NORMAL}\n"

  mackup restore

  # For more, see https://github.com/herrbischoff/awesome-macos-command-line and https://github.com/mathiasbynens/dotfiles/blob/master/.macos
  # Enable Tab in modal dialogs, map Caps Lock to ESC
  defaults write NSGlobalDomain AppleKeyboardUIMode -int 2
  hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000029}]}'

  # Auto-hide menu bar
  defaults write NSGlobalDomain _HIHideMenuBar -int 1

  killall Dock
  killall Finder
  killall SystemUIServer

  pbcopy < "$HOME/.ssh/id_rsa.pub"
  printf "${GREEN}Initialization complete. Add generated SSH key (copied to your clipboard) to your GitHub account: https://github.com/settings/keys${NORMAL}\n"

  # Must be last, nothing after this command will execute
  env zsh -l
}

modify_settings() {
}

quiet() {
  "$@" >/dev/null 2>&1
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
