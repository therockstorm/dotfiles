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
export PATH="$HOME/.local/bin:$PATH"

# Source files (aliases, exports, work)
for file in $HOME/source/*.zsh; do
  source "$file"
done

# Clipboard shell config (includes op completion; compdef calls are
# replayed by zicdreplay once zinit's deferred compinit runs).
# unalias npm so re-sourcing this file works — OMZP::npm sets an `npm`
# alias on deferred load, which would conflict with the `npm()` function
# defined in clipboard/shell.sh.
unalias npm 2>/dev/null
[ -f "$HOME/.config/clipboard/shell.sh" ] && source "$HOME/.config/clipboard/shell.sh"



# remove aliases by running `pmg setup remove` or deleting the line 
[ -f '/Users/rocky/.pmg.rc' ] && source '/Users/rocky/.pmg.rc'  # PMG source aliases

# remove PMG shims by running `pmg setup remove` or deleting the line
export PATH="/Users/rocky/.pmg/bin:$PATH"  # PMG shims

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/rocky/dev/c/clipboard/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/rocky/dev/c/clipboard/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/rocky/dev/c/clipboard/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/rocky/dev/c/clipboard/google-cloud-sdk/completion.zsh.inc'; fi
