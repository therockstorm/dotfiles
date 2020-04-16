# dotfiles

Configuration files

## Installation

1. Run `curl -fsSL https://raw.githubusercontent.com/therockstorm/dotfiles/master/init.sh --output ~/Desktop/init.sh && chmod +x ~/Desktop/init.sh && ~/Desktop/init.sh --init`
1. Once Dropbox is installed and synced, run `~/Desktop/init.sh --restore`
1. System Preferences
   - Keyboard > Keyboard > "Touch Bar shows" and "Press Fn key to"
   - Display > Night Shift > Schedule
1. Install LastPass, Neat URL, uBlock Origin, Airbnb Price Per Night Correcter, Github + Mermaid, and Conex or Firefox Multi-Account Containers Firefox add-ons
1. Install Copy'em Paste from the AppStore
1. Import `iterm.json` into iTerm2
1. Restart your computer

## Editing configs

1. List available configs with `ls ~/Library/Preferences/`
1. List a program's configs with `defaults read <program>`
1. Print a config with `/usr/libexec/PlistBuddy -c 'Print :<key>' ~/Library/Preferences/<program>.plist`, e.g., `/usr/libexec/PlistBuddy -c 'Print :"New Bookmarks":0:"Normal Font"' ~/Library/Preferences/com.googlecode.iterm2.plist`
1. Add a config with `/usr/libexec/PlistBuddy -c 'Add :<key> <value>' ~/Library/Preferences/<program>.plist`, e.g., `/usr/libexec/PlistBuddy -c 'Add :GlobalKeyMap Dict' ~/Library/Preferences/com.googlecode.iterm2.plist`
1. Set a config with `/usr/libexec/PlistBuddy -c 'Set :<key> <value>' ~/Library/Preferences/<program>.plist`, e.g., `/usr/libexec/PlistBuddy -c 'Set :"New Bookmarks":0:"Normal Font" "FiraCode-Regular 12"' ~/Library/Preferences/com.googlecode.iterm2.plist`
