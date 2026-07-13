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

# ~/.local/bin first: mise lives there on mise-bootstrap machines and is
# invoked below, before the later PATH exports would run. mise's brew
# backend populates /opt/homebrew without the brew executable; shellenv
# only runs when real Homebrew is installed.
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(zoxide init zsh)"
export _ZO_MAXAGE=20000
export GPG_TTY=$(tty)

eval "$(starship init zsh)"
eval "$(mise activate zsh)"

HIST_STAMPS="yyyy-mm-dd"

# 1Password SSH agent. ssh itself uses IdentityAgent from ~/.ssh/config; the
# env var covers everything else that talks to an agent (ssh-add -L, git, …).
_op_agent="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
[ -S "$_op_agent" ] && export SSH_AUTH_SOCK="$_op_agent"
unset _op_agent

bindkey '^U' backward-kill-line
bindkey '^[[1;3C' forward-word
bindkey '^[[1;3D' backward-word

# Source files (aliases, exports); (N) so a missing ~/source doesn't abort.
for file in $HOME/source/*.zsh(N); do
  source "$file"
done

# Employer shell config, if this machine has one. Kept here because employer
# bootstraps can't append to a symlinked ~/.zshrc; inert elsewhere. unalias
# npm first — OMZP::npm's deferred alias would shadow the npm() wrapper
# defined inside, and it keeps re-sourcing this file idempotent.
unalias npm 2>/dev/null
[ -f "$HOME/.config/clipboard/shell.zsh" ] && source "$HOME/.config/clipboard/shell.zsh"

# Machine-local config (untracked): work exports/aliases, machine paths.
# See README "Migrating from an old machine".
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
