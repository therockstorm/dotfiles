HOME=/Users/$(whoami) # zsh installation affects `~`
eval "$(curl -fsSL https://raw.githubusercontent.com/therockstorm/dotfiles/master/colors.sh)"

printf "${YELLOW}Hello $(whoami)!${NORMAL}\n"

# Ask for password upfront, exit script on error
sudo -v
set -e

if [ ! -f $HOME/.ssh/id_rsa.pub ]; then
  read -rp "${GREEN}Enter the email address associated with your GitHub account: ${NORMAL}" email

  printf "${YELLOW}Generating ssh key...${NORMAL}\n"
  ssh-keygen -t rsa -b 4096 -C "$email"
  echo "Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_rsa
  ForwardAgent yes" | tee $HOME/.ssh/config
  eval "$(ssh-agent -s)"
fi

if [ ! -f /usr/local/bin/brew ]; then
  printf "${YELLOW}Installing Homebrew...${NORMAL}\n"
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

printf "${YELLOW}Installing dependencies...${NORMAL}\n"
for app in ack awscli bat diff-so-fancy fd git tldr; do
  brew ls --versions $app || brew install $app
done

if ! brew ls --versions fzf > /dev/null; then
  brew install fzf
  $(brew --prefix)/opt/fzf/install
fi

brew tap caskroom/fonts

for app in dropbox firefox font-fira-code iterm2 google-chrome postman signal spectacle visual-studio-code; do
  brew cask ls --versions $app || brew cask install $app
done

code --install-extension shan.code-settings-sync

OH_MY_ZSH=$HOME/.oh-my-zsh
if [ ! -d $OH_MY_ZSH ]; then
  printf "${YELLOW}Installing oh-my-zsh...${NORMAL}\n"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sed 's:env zsh -l::g')"
  ZSH_CUSTOM=$OH_MY_ZSH/custom
  git clone git://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
  git clone git://github.com/lukechilds/zsh-nvm $ZSH_CUSTOM/plugins/zsh-nvm

  rm -/.bash_profile
  source $HOME/.zshrc
fi

printf "${YELLOW}Modifying macOS settings...${NORMAL}\n"
# For more, see https://github.com/herrbischoff/awesome-macos-command-line and https://github.com/mathiasbynens/dotfiles/blob/master/.macos

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
chflags nohidden ~/Library
killall Finder

# Don’t display dialog when quitting in iTerm
defaults write com.googlecode.iterm2 PromptOnQuit -bool false

pbcopy < $HOME/.ssh/id_rsa.pub
printf "${GREEN}Add generated SSH key (copied to your clipboard) to your GitHub account: https://github.com/settings/keys${NORMAL}\n"

# Must be last, nothing after this command will execute
env zsh -l