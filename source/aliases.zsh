# eza (modern ls replacement)
alias ls="eza --hyperlink --icons=auto"
alias l="eza -la --hyperlink --icons=auto"
alias ll="eza -l --hyperlink --icons=auto"
alias la="eza -la --hyperlink --icons=auto"
alias tree="eza -T --hyperlink --icons=auto"  # tree view

# brew
alias brewup="brew update && brew upgrade && brew upgrade --cask && brew cleanup && claude plugin marketplace update claude-plugins-official && claude plugin marketplace update clipboard"

# git
alias gunc="git reset --soft HEAD^"
alias grpo="git remote prune origin"

alias c=clear
alias dcp="docker compose"
alias nr="node --run"
alias code="zed"
zz() { cd "$(zoxide query -i "$@")" }

function codeup {
  local orig_dir=$(pwd)
  cd "${1:-.}"
  code .
  gl
  grpo

  if [ "$orig_dir" != "$(pwd)" ]; then
    cd "$orig_dir"
  fi
}

ship() {
  # disable ! expansion within this function so messages can contain '!' without escaping
  set +H

  # If on the default branch, switch to a new rocky/ branch
  local default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
  local current_branch=$(git branch --show-current)
  if [ "$current_branch" = "$default_branch" ]; then
    git checkout -b "rocky/$(openssl rand -hex 4)"
  fi

  # Using "$*" lets you add the message without quotes
  gcam "$*" && \
  gpsup && \
  gh pr create -w
}

ghurl() {
  gh browse "$1" --no-browser | pbcopy
}
