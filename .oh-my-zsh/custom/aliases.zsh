alias c=clear
alias dcp=docker-compose
alias cat=bat
alias nr="npm run"
alias ls="exa -la"

# brew
alias brewup="brew update && brew upgrade && brew upgrade --cask && brew cleanup"

# git
alias gunc="git reset --soft HEAD^"
alias grpo="git remote prune origin"

# prettier
alias pretty="prettier --write '{,!(dist|public|.cache|target)/**/}*.+(js|jsx|ts|tsx|json|yml|yaml|md|html|css|less|scss|graphql)'"
