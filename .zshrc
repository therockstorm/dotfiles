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

# Stub compdef so early completions (e.g. op) don't error before zinit's
# deferred compinit. zicdreplay replays them once the system is ready.
if (( ! $+functions[compdef] )); then
  compdef() { : }
fi

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

# Source files (aliases, exports, work)
for file in ~/source/*.zsh; do
  source "$file"
done

# Clipboard shell config (includes op completion; compdef calls are
# replayed by zicdreplay once zinit's deferred compinit runs)
[ -f "$HOME/.config/clipboard/shell.sh" ] && source "$HOME/.config/clipboard/shell.sh"

# BEGIN SCFW MANAGED BLOCK
export SCFW_HOME="/Users/rocky/.scfw"
# END SCFW MANAGED BLOCK

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
