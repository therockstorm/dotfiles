#!/usr/bin/env zsh
set -euo pipefail
repo_root=${0:A:h:h}
tidy_safe=${TIDY_SAFE_BINARY:-"$repo_root/bin/tidy-safe"}
test_root=$(mktemp -d "${TMPDIR:-/tmp}/tidy-safe-list.XXXXXX")
test_root=${test_root:A}
trap 'rm -rf -- "$test_root"' EXIT
export GIT_AUTHOR_NAME='Tidy Safe Test' GIT_COMMITTER_NAME='Tidy Safe Test'
export GIT_AUTHOR_EMAIL=tidy-safe@example.com GIT_COMMITTER_EMAIL=tidy-safe@example.com
git init -q --bare --initial-branch=main "$test_root/remote.git"
git clone -q "$test_root/remote.git" "$test_root/repository"
repository="$test_root/repository"
git -C "$repository" config gc.auto 0
git -C "$repository" config maintenance.auto false
git -C "$repository" commit --allow-empty -qm initial
git -C "$repository" push -q origin main
mkdir "$test_root/excluded"
long_name=w
long_name=${(l:180::w:)long_name}
for index in {1..1024}; do
  registration="$repository/.git/worktrees/linked-$index"
  mkdir -p "$registration"
  print -r -- "$test_root/excluded/$long_name/linked-$index/.git" > "$registration/gitdir"
  print 'ref: refs/heads/main' > "$registration/HEAD"
  print '../..' > "$registration/commondir"
done
output=$(cd "$repository" && "$tidy_safe" --exclude "$test_root/excluded")
[[ "$output" == *'Repositories scanned: 1'* && "$output" == *'Kept items: 1024'* ]] || {
  print -u2 -r -- "$output"
  print -u2 -- 'FAIL: did not consume the large worktree list'
  exit 1
}
print 'tidy-safe large worktree list test passed'
