alias c=clear

# brew
alias brewup='brew update && brew upgrade && brew cleanup'

# git
alias gunc='git reset --soft HEAD^'
alias grpo='git remote prune origin'

# node
alias nr='npm run'
alias npmig='npm i -g @therockstorm/generator-serverless npm npm-check-updates prettier serverless yo --ignore-scripts'
alias npmup='npm upgrade && ncu -u && npm install && npm test && npm outdated'

# prettier
alias pretty="prettier --write --no-semi '{,!(dist|public|.cache|.serverless|.webpack)/**/}*.+(js|jsx|ts|tsx|json|yml|yaml|md|html|css|less|scss|graphql)'"
