# Use colors if supported
if which tput >/dev/null 2>&1; then
  ncolors=$(tput colors)
fi

if [ -t 1 ] && [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
  GREEN="$(tput setaf 2)"
  YELLOW="$(tput setaf 3)"
  NORMAL="$(tput sgr0)"
else
  GREEN=""
  YELLOW=""
  NORMAL=""
fi

printf "${YELLOW}Hello $(whoami)!${NORMAL}\n"

# Ask for password upfront
sudo -v

if [ ! -f ~/.ssh/id_rsa.pub ]; then
  printf "${GREEN}Enter the email address associated with your GitHub account:${NORMAL}\n"
  read -r email

  printf "${YELLOW}Generating ssh key...${NORMAL}\n"
  ssh-keygen -t rsa -b 4096 -C "$email"
  echo "Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_rsa
  ForwardAgent yes" | tee ~/.ssh/config
  eval "$(ssh-agent -s)"
fi

if [ ! -f /usr/local/bin/brew ]; then
  printf "${YELLOW}Installing Homebrew...${NORMAL}\n"
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

printf "${YELLOW}Installing dependencies...${NORMAL}\n"
brew install \
  ack \
  awscli \
  bat \
  diff-so-fancy \
  fd \
  fzf \
  git \
  tldr

brew tap caskroom/fonts

for app in dropbox firefox font-fira-code iterm2 google-chrome postman signal spectacle visual-studio-code; do
  brew cask install $app
done

code --install-extension shan.code-settings-sync

if [ ! -d ~/.oh-my-zsh ]; then
  printf "${YELLOW}Installing oh-my-zsh...${NORMAL}\n"
  ZSH_CUSTOM="~/.oh-my-zsh/custom"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
  git clone git://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
  git clone git://github.com/lukechilds/zsh-nvm $ZSH_CUSTOM/plugins/zsh-nvm
fi

# Set icon size, remove default icons, auto-hide, remove and don't show Dashboard as Space in Dock
defaults write com.apple.dock tilesize -int 36
defaults write com.apple.dock persistent-apps -array
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dashboard mcx-disabled -bool true
defaults write com.apple.dock dashboard-in-overlay -bool true
killall Dock

# Enable Tab in modal dialogs, map Caps Lock to ESC
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000029}]}'

# Show hidden files, keep folders on top, show list view, allow quitting (also hides desktop icons) in Finder
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.finder QuitMenuItem -bool true
killall Finder

# Don’t display dialog when quitting in iTerm
defaults write com.googlecode.iterm2 PromptOnQuit -bool false

pbcopy < ~/.ssh/id_rsa.pub
printf "${GREEN}Add generated SSH key (copied to your clipboard) to your GitHub account: https://github.com/settings/keys${NORMAL}\n"

source ~/.zshrc
