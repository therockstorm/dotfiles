HISTSIZE=1000000000
SAVEHIST=$HISTSIZE
setopt EXTENDED_HISTORY

# Install zinit if not present
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# Load plugins with turbo mode (deferred loading)
zinit light-mode for \
  OMZL::git.zsh \
  OMZL::directories.zsh \
  OMZL::completion.zsh \
  OMZL::key-bindings.zsh \
  OMZP::git

zinit wait lucid for \
  OMZP::aws \
  OMZP::fzf \
  OMZP::npm

# Load autosuggestions first, then syntax-highlighting (order matters)
zinit wait lucid for \
  atload"_zsh_autosuggest_start; bindkey '^P' autosuggest-execute" \
    zsh-users/zsh-autosuggestions \
  atinit"zicompinit; zicdreplay" \
    zdharma-continuum/fast-syntax-highlighting

eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(zoxide init zsh)"
export _ZO_MAXAGE=20000
export GPG_TTY=$(tty)

eval "$(starship init zsh)"
eval "$(mise activate zsh)"

HIST_STAMPS="yyyy-mm-dd"
SSH_AUTH_SOCK="$HOME/.ssh/agent"

bindkey '^U' backward-kill-line
bindkey '^[[1;3C' forward-word
bindkey '^[[1;3D' backward-word

export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
export PATH="$PATH:/Users/rocky/.local/bin"

# Source custom source files (aliases, exports, work)
for file in ~/source/*.zsh; do
  source "$file"
done

# Entire CLI shell completion
autoload -Uz compinit && compinit && source <(entire completion zsh)

eval "$(op completion zsh)"; compdef _op op
