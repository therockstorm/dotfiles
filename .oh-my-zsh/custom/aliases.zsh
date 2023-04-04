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

# oh-my-zsh
alias omzup="rm -rf $HOME/.oh-my-zsh/custom && omz update && ln -s $HOME/dev/trs/dotfiles/.oh-my-zsh/custom $HOME/.oh-my-zsh/custom && source $HOME/.zshrc"

# prettier
alias pretty="prettier --write '{,!(dist|public|.cache|target)/**/}*.+(js|jsx|ts|tsx|json|yml|yaml|md|html|css|less|scss|graphql)'"
