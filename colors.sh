export GREEN=""
export YELLOW=""
export NORMAL=""

# Set colors if supported
if which tput >/dev/null 2>&1; then
  ncolors=$(tput colors)
fi

if [ -t 1 ] && [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
  GREEN="$(tput setaf 2)"
  YELLOW="$(tput setaf 3)"
  NORMAL="$(tput sgr0)"
fi
