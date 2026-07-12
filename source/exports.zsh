#export EDITOR="zed --wait"
export EDITOR="hx"
export VISUAL="$EDITOR"

export JEST_RETRY_COUNT=0
export REACT_APP_ENVIRONMENT_NAME=development

export CLEARANCE_ALLOW_HOSTS_FILES="${DEV_DIR}/groundcrew/clearance-allow-hosts:$HOME/.config/clearance/personal-allow-hosts"
export GROUNDCREW_OP_ENV_FILE=~/.config/groundcrew/op.env

export SAFEHOUSE_ADD_DIRS_RO=$DEV_DIR:$HOME/.gitconfig:$HOME/.gitconfig-clipboard:$HOME/.claude:$HOME/.agents:$HOME/.config/groundcrew/crew.config.ts
export SAFEHOUSE_ADD_DIRS="$HOME/.local/state/watchman:$HOME/.codex:$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/vault:$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/vault/.tasks"
export SRC_ENDPOINT=https://clipboardhealth.sourcegraphcloud.com

export HOMEBREW_REQUIRE_TAP_TRUST=1
export HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1

