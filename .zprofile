export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"

# Login shells do not read ~/.zshrc. Put mise's shims on PATH here so
# non-interactive commands and editor/script subprocesses honor local pins.
eval "$("$HOME/.local/bin/mise" activate zsh --shims)"
