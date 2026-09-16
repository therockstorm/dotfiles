#!/usr/bin/env zsh
set -euo pipefail

aliases_file=${0:A:h:h}/source/aliases.zsh
test_root=$(mktemp -d "${TMPDIR:-/tmp}/tidy-test.XXXXXX")
test_root=${test_root:A}
trap 'rm -rf -- "$test_root"' EXIT

export GIT_AUTHOR_EMAIL=tidy@example.com
export GIT_AUTHOR_NAME='Tidy Test'
export GIT_COMMITTER_EMAIL=tidy@example.com
export GIT_COMMITTER_NAME='Tidy Test'

fail() {
  print -u2 -- "FAIL: $1"
  exit 1
}

assert_branch() {
  git -C "$repository" show-ref --verify --quiet "refs/heads/$1" ||
    fail "expected branch to remain: $1"
}

assert_no_branch() {
  if git -C "$repository" show-ref --verify --quiet "refs/heads/$1"; then
    fail "expected branch to be deleted: $1"
  fi
}

run_tidy() {
  zsh -c 'source "$1"; cd "$2"; tidy' tidy-test "$aliases_file" "$repository"
}

repository="$test_root/repository"
git init -q --initial-branch=main "$repository"
print initial > "$repository/README.md"
git -C "$repository" add README.md
git -C "$repository" -c core.hooksPath=/dev/null -c commit.gpgsign=false commit -qm initial
git -C "$repository" update-ref refs/remotes/origin/main HEAD
git -C "$repository" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main

# These registrations reproduce the user's missing-.git removal failure.
git -C "$repository" worktree add -qb missing-marker "$test_root/missing-marker"
git -C "$repository" worktree add -qb missing-directory "$test_root/missing-directory"
rm "$test_root/missing-marker/.git"
rm -rf "$test_root/missing-directory"
output=$(run_tidy <<< $'y\ny' 2>&1) || fail "tidy failed: $output"
[[ "$output" != *'fatal:'* && "$output" != *'error:'* ]] || fail "$output"
assert_no_branch missing-marker
assert_no_branch missing-directory
[[ $(git -C "$repository" worktree list --porcelain | rg -c '^worktree ') == 1 ]] ||
  fail 'stale worktree registrations remain'
[[ -f "$test_root/missing-marker/README.md" ]] || fail 'pruning deleted orphan files'

# A protected worktree can have a branch outside crew/; neither should be removed.
protected="$repository/.groundcrew/worktrees/protected"
git -C "$repository" worktree add -qb protected "$protected"
git -C "$repository" branch crew/retained
git -C "$repository" worktree add -qb disposable "$test_root/disposable"
output=$(run_tidy <<< $'y\ny' 2>&1) || fail "tidy failed: $output"
[[ "$output" != *'fatal:'* && "$output" != *'error:'* ]] || fail "$output"
[[ -f "$protected/.git" && ! -e "$test_root/disposable" ]] ||
  fail 'worktree protection or removal failed'
assert_branch main
assert_branch crew/retained
assert_branch protected
assert_no_branch disposable

# Declining worktree removal must exclude its branch from the deletion prompt.
git -C "$repository" worktree add -qb declined "$test_root/declined"
git -C "$repository" branch unused
output=$(run_tidy <<< $'n\ny' 2>&1) || fail "tidy failed: $output"
[[ "$output" != *'fatal:'* && "$output" != *'error:'* ]] || fail "$output"
[[ -f "$test_root/declined/.git" ]] || fail 'declined worktree was removed'
assert_branch declined
assert_no_branch unused
git -C "$repository" worktree remove "$test_root/declined"
git -C "$repository" branch -D declined >/dev/null

# The current branch and default branch are protected independently.
git -C "$repository" switch -qc current
git -C "$repository" branch unused-on-current
output=$(run_tidy <<< $'y\ny' 2>&1) || fail "tidy failed: $output"
assert_branch main
assert_branch current
assert_no_branch unused-on-current
git -C "$repository" switch -q main
git -C "$repository" branch -D current >/dev/null

# One --force cannot remove a locked worktree; its branch must still be protected.
git -C "$repository" worktree add -qb locked "$test_root/locked"
git -C "$repository" worktree lock "$test_root/locked"
git -C "$repository" branch unused-after-failure
output=$(run_tidy <<< $'y\ny' 2>&1) || fail "tidy failed: $output"
[[ -f "$test_root/locked/.git" ]] || fail 'locked worktree was removed'
[[ "$output" != *"cannot delete branch 'locked'"* ]] || fail "$output"
assert_branch locked
assert_no_branch unused-after-failure

print 'PASS: tidy prunes stale registrations and protects branches still in worktrees'
