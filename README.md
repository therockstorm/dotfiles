# dotfiles

Configuration files

## Installation

1. Run `sh -c "$(curl -fsSL https://raw.githubusercontent.com/therockstorm/dotfiles/master/init.sh)"` to install dependencies
1. Run `cd ~/dev && curl -L $(curl -s https://api.github.com/repos/rhysd/dotfiles/releases/latest | grep browser_ | grep darwin_386 | cut -d\" -f4) -o dotfiles.zip && unzip dotfiles.zip && rm dotfiles.zip` to download [`dotfiles`](https://github.com/rhysd/dotfiles)
1. Run `cd ~/Dropbox/workspace/dotfiles && ~/dev/dotfiles link --dry` for a list of symbolic links to be created. Once you're happy with the output, run `~/dev/dotfiles link`
1. System Preferences
   - Keyboard > Keyboard > "Touch Bar shows" and "Press Fn key to"
   - Display > Night Shift > Schedule
1. Install Authy, Canvas Defender, LastPass, nBox, and uBlock Origin Chrome extensions
1. Install Canvas Defender, LastPass, Neat URL, and uBlock Origin Firefox add-ons
   - about:config
   - general.useragent.site_specific_overrides;true
   - general.useragent.override.instagram.com;Mozilla/5.0 (Linux; Android 7.0) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Focus/5.2 Chrome/67.0.3396.87 Mobile Safari/537.36
1. Install Copy'em Paste from the AppStore
