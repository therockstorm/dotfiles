alias preview="fzf --preview 'bat --color \"always\" {}'"
alias c=clear

# brew
alias brewup='brew update && brew upgrade && brew cleanup'

# docker
function docker_ps() {
  docker ps --format '{{.Names}}'
}

function docker_stop_all() {
  if [ "$(docker_ps)" ]; then
    echo 'Stopping containers...'
    docker stop $(docker_ps)
  else
    echo 'No containers running'
  fi
}

alias dsa=docker_stop_all

# git
alias gunc='git reset --soft HEAD^'
alias grpo='git remote prune origin'

# node
alias nr='npm run'
alias npmig='npm i -g @therockstorm/generator-serverless npm npm-check-updates prettier serverless yo --ignore-scripts'
alias npmup='npm upgrade && ncu -u && npm install && npm test && npm outdated'

# prettier
alias pretty="prettier --write '{,!(dist|lib|public|.cache|.serverless|.webpack)/**/}*.+(js|jsx|json|md|ts|tsx|yml)'"
