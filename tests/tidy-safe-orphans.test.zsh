#!/usr/bin/env zsh
set -euo pipefail
unsetopt bg_nice
repo_root=${0:A:h:h}
tidy_safe=${TIDY_SAFE_BINARY:-"$repo_root/bin/tidy-safe"}
test_root=$(mktemp -d "${TMPDIR:-/tmp}/tidy-safe-orphans.XXXXXX")
test_root=${test_root:A}
trap 'rm -rf -- "$test_root"' EXIT
export GIT_AUTHOR_NAME='Tidy Safe Test' GIT_COMMITTER_NAME='Tidy Safe Test'
export GIT_AUTHOR_EMAIL=tidy-safe@example.com GIT_COMMITTER_EMAIL=tidy-safe@example.com
fail() { print -u2 -- "FAIL: $1"; exit 1; }
git init -q --bare --initial-branch=main "$test_root/remote.git"
git clone -q "$test_root/remote.git" "$test_root/repository"
repository="$test_root/repository"
print initial > "$repository/tracked.txt"
print -rl -- 'cache/' '*.generated' '!important.generated' > "$repository/.gitignore"
mkdir "$repository/nested" "$repository/untracked-ignore"
print tracked > "$repository/untracked-ignore/tracked.txt"
print '!keep.generated' > "$repository/nested/.gitignore"
git -C "$repository" add tracked.txt .gitignore nested/.gitignore untracked-ignore/tracked.txt
git -C "$repository" config core.ignoreCase false
git -C "$repository" commit -qm initial
git -C "$repository" push -q origin main

# Deleted ignore files must not turn disposable caches into unique data,
# or hide files that committed negation rules explicitly protected.
ignored="$test_root/ignored-orphan"
protected="$test_root/protected-orphan"
nested_protected="$test_root/nested-protected-orphan"
case_protected="$test_root/case-protected-orphan"
self_protected="$test_root/self-protected-orphan"
for directory in "$ignored" "$protected" "$nested_protected" "$case_protected" "$self_protected"; do
  git -C "$repository" worktree add -qb "${directory:t}" "$directory" main
  rm -- "$directory/.git" "$directory/.gitignore" "$directory/tracked.txt"
done
mkdir "$ignored/cache"
print generated > "$ignored/cache/build-output"
print unique > "$protected/important.generated"
print unique > "$nested_protected/nested/keep.generated"
mkdir "$case_protected/CACHE"
print unique > "$case_protected/CACHE/unique.txt"
print '!.gitignore' > "$self_protected/untracked-ignore/.gitignore"
print '**/.gitignore' >> "$repository/.git/info/exclude"
print '*.generated' >> "$repository/.git/info/exclude"
ignored_output=$(cd "$repository" && "$tidy_safe" --apply --yes)
[[ "$ignored_output" == *"REMOVED worktree $ignored"* ]] || fail 'retained only ignored generated data after .gitignore was removed'
[[ ! -e "$ignored" ]] || fail 'ignored orphan directory remains'
[[ -f "$protected/important.generated" ]] || fail 'lost file protected by committed root ignore negation'
[[ -f "$nested_protected/nested/keep.generated" ]] || fail 'lost file protected by nested ignore negation'
[[ -f "$case_protected/CACHE/unique.txt" ]] || fail 'lost file because ignore matching changed case sensitivity'
[[ -f "$self_protected/untracked-ignore/.gitignore" ]] || fail 'lost untracked ignore file that protected itself'

# Removing a whole directory must not discard staged-only data in its index.
missing_staged="$test_root/missing-staged"
git -C "$repository" worktree add -qb missing-staged "$missing_staged" main
print 'unique staged-only content' > "$missing_staged/staged-only.txt"
git -C "$missing_staged" add staged-only.txt
missing_admin=$(git -C "$missing_staged" rev-parse --absolute-git-dir)
rm -rf -- "$missing_staged"
missing_output=$(cd "$repository" && "$tidy_safe" --apply --yes)
[[ "$missing_output" == *"KEEP worktree $missing_staged: staged changes"* ]] || fail 'discarded staged-only data from missing worktree'
[[ "$(git --git-dir="$missing_admin" show :staged-only.txt)" == 'unique staged-only content' ]] || fail 'lost the staged-only blob'

# Staged data must survive even if the file has since been removed.
staged="$test_root/staged-orphan"
git -C "$repository" worktree add -qb staged-orphan "$staged" main
print 'unique staged data' > "$staged/tracked.txt"
git -C "$staged" add tracked.txt
rm -- "$staged/tracked.txt" "$staged/.git"
output=$(cd "$repository" && "$tidy_safe" --apply --yes)
[[ "$output" == *"KEEP worktree $staged: modified or untracked files"* ]] || fail 'staged data was not protected'
[[ -d "$staged" ]] || fail 'staged worktree was removed'

# New data arriving after the audit must prevent forced removal.
raced="$test_root/raced-orphan"
git -C "$repository" worktree add -qb raced-orphan "$raced" main
rm -- "$raced/.git" "$raced/tracked.txt"
mkfifo "$test_root/confirmation"
exec {confirmation_fd}<> "$test_root/confirmation"
(cd "$repository" && "$tidy_safe" --apply < "$test_root/confirmation" > "$test_root/output" 2>&1) &
cleanup_pid=$!
for _ in {1..250}; do
  rg -q 'Delete all items marked SAFE\?' "$test_root/output" 2>/dev/null && break
  sleep 0.02
done
rg -q 'Delete all items marked SAFE\?' "$test_root/output" || fail 'timed out waiting for confirmation'
print unique > "$raced/new.txt"
print -u "$confirmation_fd" y
exec {confirmation_fd}>&-
if wait "$cleanup_pid"; then
  fail 'cleanup accepted new data after audit'
fi
[[ -f "$raced/new.txt" ]] || fail 'lost new data'
[[ ! -e "$raced/.git" ]] || fail 'repaired a worktree that failed revalidation'
git -C "$repository" show-ref --verify --quiet refs/heads/raced-orphan || fail 'lost branch for raced worktree'
# The same race protection applies when the .git link is still present.
partial="$test_root/partial-race"
git -C "$repository" worktree add -qb partial-race "$partial" main
rm -- "$partial/tracked.txt"
mkfifo "$test_root/partial-confirmation"
exec {partial_fd}<> "$test_root/partial-confirmation"
(cd "$repository" && "$tidy_safe" --apply < "$test_root/partial-confirmation" > "$test_root/partial-output" 2>&1) &
partial_pid=$!
for _ in {1..250}; do
  rg -q 'Delete all items marked SAFE\?' "$test_root/partial-output" 2>/dev/null && break
  sleep 0.02
done
rg -q 'Delete all items marked SAFE\?' "$test_root/partial-output" || fail 'timed out waiting for partial confirmation'
print unique > "$partial/new.txt"
print -u "$partial_fd" y
exec {partial_fd}>&-
if wait "$partial_pid"; then
  fail 'cleanup accepted new data in partial worktree after audit'
fi
[[ -f "$partial/new.txt" ]] || fail 'lost new data in partial worktree'
git -C "$repository" show-ref --verify --quiet refs/heads/partial-race || fail 'lost branch for partial raced worktree'

print 'tidy-safe orphan safety tests passed'
