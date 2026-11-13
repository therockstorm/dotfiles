# Every zsh reads this, including the non-interactive shells agents run.
# Source machine-local exports here so tokens in ~/.zshrc.local reach them;
# ~/.zshrc sources it again last so its overrides still win.
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
