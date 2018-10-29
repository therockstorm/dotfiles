export ZSH="/Users/$USER/.oh-my-zsh"

ZSH_THEME="spaceship"
SPACESHIP_PROMPT_ORDER=(
  time
  dir
  git
  package
  node
  golang
  dotnet
  aws
  exec_time
  battery
  jobs
  exit_code
  char
)
SPACESHIP_PROMPT_ADD_NEWLINE=false
SPACESHIP_DIR_TRUNC='1'
SPACESHIP_GIT_PREFIX=""
SPACESHIP_GIT_STATUS_PREFIX=" "
SPACESHIP_GIT_STATUS_SUFFIX=""
SPACESHIP_PACKAGE_PREFIX=""
SPACESHIP_NODE_PREFIX=""
SPACESHIP_GOLANG_PREFIX=""
SPACESHIP_DOTNET_PREFIX=""
SPACESHIP_AWS_PREFIX=""
SPACESHIP_AWS_SYMBOL="☁️  "

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
  sbt
  urltools
  z
  zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

bindkey '^ ' autosuggest-accept
bindkey '^P' autosuggest-execute
