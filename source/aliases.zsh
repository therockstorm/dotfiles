# eza (modern ls replacement)
alias ls="eza --hyperlink --icons=auto"
alias l="eza -la --hyperlink --icons=auto"
alias ll="eza -l --hyperlink --icons=auto"
alias la="eza -la --hyperlink --icons=auto"
alias tree="eza -T --hyperlink --icons=auto"  # tree view

# Inject a scope of 1Password secrets into ONE subprocess — nothing is ever
# exported into the shell. Scopes are pointer files (op:// refs, no secret
# values) in ~/.config/op/<scope>.env. Usage: ops ai node script.mjs
ops() { op run --env-file="$HOME/.config/op/$1.env" -- "${@:2}"; }

# Update agent CLIs and every installed plugin marketplace. Sequential
# rather than &&-chained so one failure doesn't block the rest.
agentup() {
  claude update
  local m
  for m in "$HOME/.claude/plugins/marketplaces"/*(N/:t); do
    claude plugin marketplace update "$m"
  done
  codex update
}

# Homebrew system packages/casks, mise itself, and mise-managed runtimes.
miseup() {
  brew update && brew upgrade && brew cleanup
  # Older machines installed mise with Homebrew; stage-one installs update
  # themselves. Avoid asking a package-manager install to self-update.
  brew list mise >/dev/null 2>&1 || mise self-update -y
  mise upgrade
  agentup
}

# git
alias gunc="git reset --soft HEAD^"
alias grpo="git remote prune origin"

alias c=clear
alias dcp="docker compose"
alias nr="node --run"
alias code="zed"

zz() { cd "$(zoxide query -i "$@")" }

# ship: commit all changes, push, and open a PR.
#
# Usage: ship [options...] <commit message...>
#
# Behavior:
#   1. If on default branch with uncommitted changes, switch to new $USER/<random-hex> branch.
#   2. Commit all changes with provided message. Aborts on pre-commit hook failure.
#      Leading options are forwarded to git commit and git push.
#   3. Push branch to origin, setting upstream.
#   4. If PR exists for branch, open it in browser. Otherwise, create one and open it.
#   5. Refuse to push the default branch directly.
#   6. Running with no changes on a non-default branch skips commit and pushes/creates/opens PR
#      (useful to re-opening existing PR).
ship() {
  set +H

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "ship: not inside a git work tree"
    return 1
  fi

  local -a options
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --)
        shift
        break
        ;;
      -*)
        options+=("$1")
        shift
        ;;
      *)
        break
        ;;
    esac
  done

  local message="$*"
  local default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
  local current_branch=$(git branch --show-current)
  local has_changes=0

  if [ -z "$default_branch" ]; then
    echo "ship: could not determine default branch from origin/HEAD"
    return 1
  fi

  if [ -n "$(git status --porcelain)" ]; then
    has_changes=1
  fi

  if [ -z "$current_branch" ]; then
    echo "ship: refusing to ship from detached HEAD"
    return 1
  fi

  if [ "$current_branch" = "$default_branch" ] && [ "$has_changes" = "1" ]; then
    git checkout -b "$USER/$(openssl rand -hex 2)" || return 1
    current_branch=$(git branch --show-current)
  fi

  if [ "$current_branch" = "$default_branch" ]; then
    echo "ship: refusing to push default branch '$default_branch'"
    return 1
  fi

  if [ "$has_changes" = "1" ]; then
    if [ -z "${message//[[:space:]]/}" ]; then
      echo "Usage: ship [options...] <commit message...>"
      return 1
    fi

    git add -A && git commit "${options[@]}" --message "$message" || return 1
  fi

  git push "${options[@]}" --set-upstream origin "$current_branch" || return 1

  if gh pr view --json url >/dev/null 2>&1; then
    gh pr view --web
  else
    gh pr create --fill --body $'Summary\n===\nSee title.' && gh pr view --web
  fi
}

ghurl() {
  gh browse "$1" --no-browser | pbcopy
}

# tidy: remove all non-primary git worktrees and all non-current local branches.
#
# Lists worktrees, prompts for confirmation, force-removes them. Then lists
# local branches, prompts for confirmation, force-deletes them. Must be run
# from the primary worktree with a checked-out branch (not detached HEAD).
tidy() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "tidy: not inside a git work tree" >&2
    return 1
  fi

  local first_line=$(git worktree list --porcelain | head -n 1)
  local primary=${first_line#worktree }
  local current_wt=$(git rev-parse --show-toplevel)
  if [ "$current_wt" != "$primary" ]; then
    echo "tidy: run from the primary worktree ($primary), not $current_wt" >&2
    return 1
  fi

  local current_branch=$(git branch --show-current)
  if [ -z "$current_branch" ]; then
    echo "tidy: refusing to tidy from detached HEAD; check out a branch first so it's excluded from deletion" >&2
    return 1
  fi

  local default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')

  local worktrees=$(git worktree list --porcelain | sed -n 's/^worktree //p' | grep -Fxv -- "$primary")
  if [ -n "$worktrees" ]; then
    echo "Worktrees to remove:"
    echo "$worktrees\n"
    printf "Remove these worktrees? [y/N] "
    read -r confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      echo "$worktrees" | xargs -I {} git worktree remove --force {}
    else
      echo "Skipped worktree removal."
    fi
  else
    echo "No worktrees to remove.\n"
  fi

  local branches=$(git branch --format='%(refname:short)' | grep -v "^${current_branch}\$" | { [ -n "$default_branch" ] && grep -v "^${default_branch}\$" || cat; })
  if [ -n "$branches" ]; then
    echo "Branches to delete:"
    echo "$branches\n"
    printf "Force-delete these branches? [y/N] "
    read -r confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      echo "$branches" | xargs git branch -D
    else
      echo "Skipped branch deletion."
    fi
  else
    echo "No branches to delete.\n"
  fi
}
