#!/usr/bin/env zsh
set -euo pipefail
unsetopt bg_nice
repo_root=${0:A:h:h}
tidy_safe=${TIDY_SAFE_BINARY:-"$repo_root/bin/tidy-safe"}
test_root=$(mktemp -d "${TMPDIR:-/tmp}/tidy-safe-inactive.XXXXXX")
test_root=${test_root:A}
trap 'rm -rf -- "$test_root"' EXIT
export GIT_AUTHOR_NAME='Tidy Safe Test' GIT_COMMITTER_NAME='Tidy Safe Test'
export GIT_AUTHOR_EMAIL=tidy-safe@example.com GIT_COMMITTER_EMAIL=tidy-safe@example.com
fail() { print -u2 -r -- "${output:-}"; print -u2 -- "FAIL: $1"; exit 1; }
git init -q --bare --initial-branch=main "$test_root/remote.git"
git clone -q "$test_root/remote.git" "$test_root/repository"
repository="$test_root/repository"
print initial > "$repository/tracked.txt"
print 'cache/' > "$repository/.gitignore"
git -C "$repository" add .
git -C "$repository" commit -qm initial
git -C "$repository" push -q origin main
mkdir "$test_root/bin"
printf '#!/bin/sh\nexit 1\n' > "$test_root/bin/gh"
export TIDY_SAFE_PROCESS_SNAPSHOT="$test_root/processes"
print n/unrelated > "$TIDY_SAFE_PROCESS_SNAPSHOT"
cat > "$test_root/bin/lsof" <<'EOF'
#!/bin/sh
cat "$TIDY_SAFE_PROCESS_SNAPSHOT"
EOF
chmod +x "$test_root/bin/gh" "$test_root/bin/lsof"
export PATH="$test_root/bin:$PATH"
zmodload zsh/datetime
strftime -s inactive_timestamp '%Y%m%d%H%M.%S' $(( EPOCHSECONDS - 172800 ))

age_worktree() {
  local directory=$1 metadata branch file
  metadata=$(git -C "$directory" rev-parse --absolute-git-dir)
  branch=$(git -C "$directory" symbolic-ref HEAD)
  for file in "$metadata/HEAD" "$metadata/index" "$metadata/logs/HEAD" "$repository/.git/$branch" "$repository/.git/logs/$branch"; do
    [[ ! -f "$file" ]] || touch -t "$inactive_timestamp" "$file"
  done
}

create_worktree() {
  local name=$1
  git -C "$repository" worktree add -qb "$name" "$test_root/$name" main
  git -C "$test_root/$name" commit --allow-empty -qm "unmerged $name"
  age_worktree "$test_root/$name"
}

create_worktree inactive
inactive_sha=$(git -C "$test_root/inactive" rev-parse HEAD)
output=$(cd "$repository" && "$tidy_safe")
[[ "$output" == *"KEEP worktree $test_root/inactive: unmerged"* ]] || fail 'default policy changed'
output=$(cd "$repository" && "$tidy_safe" --inactive-worktrees)
[[ "$output" == *"SAFE worktree $test_root/inactive: commit retained by local branch inactive"* ]] || fail 'did not offer inactive cleanup'
[[ -e "$test_root/inactive/.git" ]] || fail 'dry run removed worktree'
output=$(cd "$repository" && "$tidy_safe" --inactive-worktrees --apply --yes)
[[ "$output" == *"REMOVED worktree $test_root/inactive:"* && ! -d "$test_root/inactive" ]] || fail 'inactive worktree remains'
[[ "$(git -C "$repository" rev-parse refs/heads/inactive)" == "$inactive_sha" ]] || fail 'lost unmerged commit'

create_worktree orphan
orphan_sha=$(git -C "$test_root/orphan" rev-parse HEAD)
rm -- "$test_root/orphan/.git" "$test_root/orphan/tracked.txt" "$test_root/orphan/.gitignore"
mkdir "$test_root/orphan/cache"
print generated > "$test_root/orphan/cache/generated"
output=$(cd "$repository" && "$tidy_safe" --inactive-worktrees --apply --yes)
[[ "$output" == *"REMOVED worktree $test_root/orphan: stale registration with recoverable files; commit retained by local branch orphan"* ]] || fail 'orphan was not recovered'
[[ ! -d "$test_root/orphan" ]] || fail 'orphan remains'
[[ "$(git -C "$repository" rev-parse refs/heads/orphan)" == "$orphan_sha" ]] || fail 'lost orphan commit'

create_worktree recent
touch "$repository/.git/logs/refs/heads/recent"
create_worktree active
mkdir "$test_root/active/subdirectory"
print -r -- "n$test_root/active/subdirectory" > "$TIDY_SAFE_PROCESS_SNAPSHOT"
create_worktree dirty
print unique > "$test_root/dirty/unique.txt"
create_worktree staged
print 'staged-only data' > "$test_root/staged/tracked.txt"
git -C "$test_root/staged" add tracked.txt
age_worktree "$test_root/staged"
rm -- "$test_root/staged/tracked.txt" "$test_root/staged/.git"
create_worktree operation
git -C "$test_root/operation" rev-parse HEAD > "$(git -C "$test_root/operation" rev-parse --git-path MERGE_HEAD)"
create_worktree locked
git -C "$repository" worktree lock "$test_root/locked"
git -C "$repository" worktree add -q --detach "$test_root/detached" refs/heads/inactive
detached_metadata=$(git -C "$test_root/detached" rev-parse --absolute-git-dir)
touch -t "$inactive_timestamp" "$detached_metadata/HEAD" "$detached_metadata/index" "$detached_metadata/logs/HEAD"
output=$(cd "$repository" && "$tidy_safe" --inactive-worktrees --apply --yes)
for expected in \
  "KEEP worktree $test_root/recent: Git activity within the last 24 hours" \
  "KEEP worktree $test_root/active: process working in directory" \
  "KEEP worktree $test_root/dirty: dirty" \
  "KEEP worktree $test_root/staged: modified or untracked files" \
  "KEEP worktree $test_root/operation: Git operation in progress" \
  "KEEP worktree $test_root/locked: locked" \
  "KEEP worktree $test_root/detached: unmerged"; do
  [[ "$output" == *"$expected"* ]] || fail "missing protection: $expected"
done
[[ "$(git --git-dir="$repository/.git/worktrees/staged" show :tracked.txt)" == 'staged-only data' ]] || fail 'lost staged contents'

create_worktree unavailable
print '#!/bin/sh\nexit 1' > "$test_root/bin/lsof"
output=$(cd "$repository" && "$tidy_safe" --inactive-worktrees --apply --yes)
[[ "$output" == *"KEEP worktree $test_root/unavailable: process activity unavailable"* ]] || fail 'process probe did not fail closed'
cat > "$test_root/bin/lsof" <<'EOF'
#!/bin/sh
cat "$TIDY_SAFE_PROCESS_SNAPSHOT"
EOF
print n/unrelated > "$TIDY_SAFE_PROCESS_SNAPSHOT"

# Process activity is checked again after the confirmation prompt.
create_worktree raced
mkfifo "$test_root/confirmation"
exec {confirmation_fd}<> "$test_root/confirmation"
(cd "$repository" && "$tidy_safe" --inactive-worktrees --apply < "$test_root/confirmation" > "$test_root/output" 2>&1) &
cleanup_pid=$!
for _ in {1..250}; do
  grep -q 'Delete all items marked SAFE?' "$test_root/output" 2>/dev/null && break
  sleep 0.02
done
grep -q 'Delete all items marked SAFE?' "$test_root/output" || fail 'timed out waiting for confirmation'
print -r -- "n$test_root/raced" > "$TIDY_SAFE_PROCESS_SNAPSHOT"
print -u "$confirmation_fd" y
exec {confirmation_fd}>&-
if wait "$cleanup_pid"; then
  fail 'removed worktree after a process started using it'
fi
[[ -f "$test_root/raced/.git" ]] || fail 'lost newly active worktree'
[[ "$(<"$test_root/output")" == *"FAILED worktree $test_root/raced: changed or no longer proven safe after audit"* ]] || fail 'race was not reported'

print 'tidy-safe inactive worktree tests passed'
