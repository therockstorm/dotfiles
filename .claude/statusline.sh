#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract current working directory and change to it
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
cd "$cwd" 2>/dev/null || exit 0

current_dir=$(basename "$cwd")
git_info=""
context_info=""

# Build git status info if in a git repo
if git rev-parse --no-optional-locks --git-dir >/dev/null 2>&1; then
    branch=$(git branch --show-current 2>/dev/null)

    # Handle detached HEAD
    [[ -z "$branch" ]] && branch=$(git rev-parse --no-optional-locks --short HEAD 2>/dev/null)

    if [[ -n "$branch" ]]; then
        git_status=$(git status --no-optional-locks --porcelain 2>/dev/null)
        status=""

        # Build status string matching starship's default format:
        # $conflicted$stashed$deleted$renamed$modified$staged$untracked$ahead_behind
        echo "$git_status" | grep -qE '^(U.|.U|AA|DD)' && status+="="
        [[ -n "$(git stash list 2>/dev/null | head -1)" ]] && status+="\$"
        echo "$git_status" | grep -qE '^.?D' && status+="✘"
        echo "$git_status" | grep -q '^R' && status+="»"
        echo "$git_status" | grep -q '^.M' && status+="!"
        echo "$git_status" | grep -qE '^[MARC]' && status+="+"
        echo "$git_status" | grep -q '^??' && status+="?"

        # Ahead/behind status
        if git rev-parse --no-optional-locks --abbrev-ref '@{upstream}' &>/dev/null; then
            ahead=$(git rev-list --no-optional-locks --count '@{upstream}..HEAD' 2>/dev/null)
            behind=$(git rev-list --no-optional-locks --count 'HEAD..@{upstream}' 2>/dev/null)

            if (( ahead > 0 && behind > 0 )); then
                status+="⇕"
            elif (( ahead > 0 )); then
                status+="⇡"
            elif (( behind > 0 )); then
                status+="⇣"
            fi
        fi

        # Format: "on  branch [status]" matching starship
        branch_icon=$'\xee\x82\xa0'
        if [[ -n "$status" ]]; then
            git_info=" on \033[1;35m${branch_icon} ${branch}\033[0m \033[1;31m[${status}]\033[0m"
        else
            git_info=" on \033[1;35m${branch_icon} ${branch}\033[0m"
        fi
    fi
fi

# Get model name
model_name=$(echo "$input" | jq -r '.model.display_name // empty')
model_info=""
if [[ -n "$model_name" ]]; then
    model_info=" 🤖 ${model_name}"
fi

# Get context window usage percentage
context_size=$(echo "$input" | jq -r '.context_window.context_window_size')
usage=$(echo "$input" | jq '.context_window.current_usage')

if [[ "$usage" != "null" && "$context_size" != "null" && "$context_size" != "0" ]]; then
    current_tokens=$(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
    percent_used=$((current_tokens * 100 / context_size))
    # Format token count as human-readable (e.g., 150k, 1.2M)
    if (( current_tokens >= 1000000 )); then
        raw_tokens="$(awk "BEGIN {printf \"%.1fM\", $current_tokens/1000000}")"
    elif (( current_tokens >= 1000 )); then
        raw_tokens="$(awk "BEGIN {printf \"%.0fk\", $current_tokens/1000}")"
    else
        raw_tokens="${current_tokens}"
    fi
    context_info=" 🧠 ${raw_tokens} (${percent_used}%)"
fi

# Output: directory on branch [model] [context%]
printf "\033[1;36m%s\033[0m%b\033[1;32m%s\033[0m\033[1;33m%s\033[0m" "$current_dir" "$git_info" "$model_info" "$context_info"
