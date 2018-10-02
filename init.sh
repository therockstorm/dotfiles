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

for app in dropbox firefox font-fira-code google-chrome iterm2 postman signal spectacle visual-studio-code; do
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

# Configure Spectacle
cp spectacle.json ~/Library/Application\ Support/Spectacle/Shortcuts.json

# Set icon size, remove default icons, auto-hide, remove and don't show Dashboard as Space, don't bounce icons in Dock
defaults write com.apple.dock tilesize -int 36
defaults write com.apple.dock persistent-apps -array
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dashboard mcx-disabled -bool true
defaults write com.apple.dock dashboard-in-overlay -bool true
defaults write com.apple.dock no-bouncing -bool false
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

# Configure iTerm
ITERM=$HOME/Library/Preferences/com.googlecode.iterm2.plist
defaults write com.googlecode.iterm2 PromptOnQuit -bool false
/usr/libexec/PlistBuddy -c 'Add GlobalKeyMap Dict' $ITERM
/usr/libexec/PlistBuddy -c 'Add GlobalKeyMap:0x19-0x60000 Dict' $ITERM
/usr/libexec/PlistBuddy -c 'Add GlobalKeyMap:0x19-0x60000:Action integer 2' $ITERM
/usr/libexec/PlistBuddy -c 'Add GlobalKeyMap:0x19-0x60000:Text string ""' $ITERM
/usr/libexec/PlistBuddy -c 'Add GlobalKeyMap:0x9-0x40000 Dict' $ITERM
/usr/libexec/PlistBuddy -c 'Add GlobalKeyMap:0x9-0x40000:Action integer 0' $ITERM
/usr/libexec/PlistBuddy -c 'Add GlobalKeyMap:0x9-0x40000:Text string ""' $ITERM
/usr/libexec/PlistBuddy -c 'Set :HideTab false' $ITERM
/usr/libexec/PlistBuddy -c 'Set :"NSWindow Frame SharedPreferences" "697 344 1016 512 0 0 1680 1027 "' $ITERM
/usr/libexec/PlistBuddy -c 'Set :"New Bookmarks":0:"Custom Directory" Yes' $ITERM
/usr/libexec/PlistBuddy -c 'Set :"New Bookmarks":0:"Keyboard Map":"0xf702-0x280000":Action 10' $ITERM
/usr/libexec/PlistBuddy -c 'Set :"New Bookmarks":0:"Keyboard Map":"0xf702-0x280000":Text b' $ITERM
/usr/libexec/PlistBuddy -c 'Set :"New Bookmarks":0:"Keyboard Map":"0xf703-0x280000":Action 10' $ITERM
/usr/libexec/PlistBuddy -c 'Set :"New Bookmarks":0:"Keyboard Map":"0xf703-0x280000":Text f' $ITERM
/usr/libexec/PlistBuddy -c 'Set :"New Bookmarks":0:"Option Key Sends" 2' $ITERM
/usr/libexec/PlistBuddy -c 'Set :"New Bookmarks":0:"Working Directory" "/Users/rwarren/dev"' $ITERM
/usr/libexec/PlistBuddy -c 'Set :"findMode_iTerm" 0' $ITERM

pbcopy < $HOME/.ssh/id_rsa.pub
printf "${GREEN}Add generated SSH key (copied to your clipboard) to your GitHub account: https://github.com/settings/keys${NORMAL}\n"

# Must be last, nothing after this command will execute
env zsh -l
