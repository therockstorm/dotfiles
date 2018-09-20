export ZSH="/Users/$USER/.oh-my-zsh"

ZSH_THEME="robbyrussell"
HYPHEN_INSENSITIVE="true"
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
HIST_STAMPS="yyyy-mm-dd"

plugins=(
  aws
  docker
  git
  zsh-nvm
  osx
  zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# tabtab source for serverless package
# uninstall by removing these lines or running `tabtab uninstall serverless`
[[ -f /Users/rwarren/dev/bambot/node_modules/tabtab/.completions/serverless.zsh ]] && . /Users/rwarren/dev/bambot/node_modules/tabtab/.completions/serverless.zsh
# tabtab source for sls package
# uninstall by removing these lines or running `tabtab uninstall sls`
[[ -f /Users/rwarren/dev/bambot/node_modules/tabtab/.completions/sls.zsh ]] && . /Users/rwarren/dev/bambot/node_modules/tabtab/.completions/sls.zsh