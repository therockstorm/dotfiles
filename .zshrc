export ZSH="$HOME/.oh-my-zsh"

plugins=(
  aws
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"

eval "$(/opt/homebrew/bin/brew shellenv)"

eval "$(zoxide init zsh)"
export _ZO_MAXAGE=20000
export GPG_TTY=$(tty)

eval "$(starship init zsh)"
HIST_STAMPS="yyyy-mm-dd"
COMPLETION_WAITING_DOTS="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"
HYPHEN_INSENSITIVE="true"
SSH_AUTH_SOCK="$HOME/.ssh/agent"

bindkey '^ ' forward-word
bindkey '^P' autosuggest-execute

# Fix zsh-syntax-highlighting paste slowness
# DISABLE_MAGIC_FUNCTIONS="true"
# zstyle ':bracketed-paste-magic' active-widgets '.self-*'

source /opt/homebrew/opt/asdf/libexec/asdf.sh
source $ZSH/oh-my-zsh.sh
