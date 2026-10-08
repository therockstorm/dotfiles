#!/usr/bin/env zsh
set -euo pipefail
unsetopt bg_nice

repo_root=${0:A:h:h}
tidy_safe="$repo_root/bin/tidy-safe"
aliases_file="$repo_root/source/aliases.zsh"
test_root=$(mktemp -d "${TMPDIR:-/tmp}/tidy-safe-test.XXXXXX")
test_root=${test_root:A}
trap 'rm -rf -- "$test_root"' EXIT

export GIT_AUTHOR_EMAIL=tidy-safe@example.com
export GIT_AUTHOR_NAME='Tidy Safe Test'
export GIT_COMMITTER_EMAIL=tidy-safe@example.com
export GIT_COMMITTER_NAME='Tidy Safe Test'

fail() {
  print -u2 -- "FAIL: $1"
  exit 1
}

assert_contains() {
  local actual=$1 expected=$2
  if [[ "$actual" != *"$expected"* ]]; then
    print -u2 -- 'Actual output:'
    print -u2 -r -- "$actual"
    fail "expected output to contain: $expected"
  fi
}

assert_exists() {
  [[ -e "$1" ]] || fail "expected path to exist: $1"
}

assert_missing() {
  [[ ! -e "$1" ]] || fail "expected path to be absent: $1"
}

git_in() {
  local directory=$1
  shift
  git -C "$directory" "$@"
}

fixtures="$test_root/fixtures"
scope="$test_root/scope"
remote="$fixtures/remote.git"
seed="$fixtures/seed"
repository="$scope/repository"
mkdir -p "$fixtures" "$scope"

git_in "$fixtures" init --bare --initial-branch=main "$remote" >/dev/null
git_in "$fixtures" init --initial-branch=main "$seed" >/dev/null
print initial > "$seed/README.md"
git_in "$seed" add README.md
git_in "$seed" commit -m 'initial commit' >/dev/null
git_in "$seed" remote add origin "$remote"
git_in "$seed" push -u origin main >/dev/null
git_in "$scope" clone "$remote" "$repository" >/dev/null

git_in "$repository" switch -c merged-clean >/dev/null
print merged > "$repository/merged.txt"
git_in "$repository" add merged.txt
git_in "$repository" commit -m 'merged change' >/dev/null
git_in "$repository" switch main >/dev/null
git_in "$repository" merge --ff-only merged-clean >/dev/null
git_in "$repository" push origin main >/dev/null
git_in "$repository" worktree add "$scope/merged-clean" merged-clean >/dev/null

git_in "$repository" worktree add -b unmerged-clean "$scope/unmerged-clean" main >/dev/null
print unmerged > "$scope/unmerged-clean/unmerged.txt"
git_in "$scope/unmerged-clean" add unmerged.txt
git_in "$scope/unmerged-clean" commit -m 'unmerged change' >/dev/null
export TIDY_SAFE_TEST_UNMERGED_SHA=$(git_in "$scope/unmerged-clean" rev-parse HEAD)

git_in "$repository" worktree add -b dirty-merged "$scope/dirty-merged" main >/dev/null
print dirty > "$scope/dirty-merged/untracked.txt"

git_in "$repository" worktree add -b squash-merged "$scope/squash-merged" main >/dev/null
print squash > "$scope/squash-merged/squash.txt"
git_in "$scope/squash-merged" add squash.txt
git_in "$scope/squash-merged" commit -m 'squash merged change' >/dev/null
export TIDY_SAFE_TEST_MERGED_SHA=$(git_in "$scope/squash-merged" rev-parse HEAD)
git_in "$repository" branch local-pr-alias "$TIDY_SAFE_TEST_MERGED_SHA"

git_in "$repository" worktree add -b mismatched-pr "$scope/mismatched-pr" main >/dev/null
print mismatch > "$scope/mismatched-pr/mismatch.txt"
git_in "$scope/mismatched-pr" add mismatch.txt
git_in "$scope/mismatched-pr" commit -m 'local commit after merged PR' >/dev/null
export TIDY_SAFE_TEST_MISMATCHED_SHA=$(git_in "$scope/mismatched-pr" rev-parse HEAD)

git_in "$repository" worktree add -b wrong-base-pr "$scope/wrong-base-pr" main >/dev/null
print wrong-base > "$scope/wrong-base-pr/wrong-base.txt"
git_in "$scope/wrong-base-pr" add wrong-base.txt
git_in "$scope/wrong-base-pr" commit -m 'PR merged to a non-default base' >/dev/null
export TIDY_SAFE_TEST_WRONG_BASE_SHA=$(git_in "$scope/wrong-base-pr" rev-parse HEAD)

fake_bin="$test_root/fake-bin"
mkdir "$fake_bin"
cat > "$fake_bin/gh" <<'EOF'
#!/usr/bin/env zsh
if [[ "$1" == api ]]; then
  endpoint=$2
  shift 2
  jq_filter=
  while (( $# > 0 )); do
    [[ "$1" == --jq ]] && jq_filter=$2
    shift
  done
  head_sha=${endpoint:h:t}
  base_branch=main
  merged_at=2026-09-01T00:00:00Z
  case "$head_sha" in
    "$TIDY_SAFE_TEST_MERGED_SHA") ;;
    "$TIDY_SAFE_TEST_MISMATCHED_SHA") head_sha=0000000000000000000000000000000000000000 ;;
    "$TIDY_SAFE_TEST_WRONG_BASE_SHA") base_branch=release ;;
    "$TIDY_SAFE_TEST_UNMERGED_SHA") merged_at= ;;
    *) print '[]' | jq -r "$jq_filter"; exit ;;
  esac
  jq -nc --arg sha "$head_sha" --arg base "$base_branch" --arg merged "$merged_at" \
    '[{head: {sha: $sha}, base: {ref: $base}, merged_at: (if $merged == "" then null else $merged end)}]' |
    jq -r "$jq_filter"
  exit
fi
head_branch=
base_branch=
while (( $# > 0 )); do
  [[ "$1" == --head ]] && head_branch=$2
  [[ "$1" == --base ]] && base_branch=$2
  shift
done
case "$head_branch" in
  squash-merged) [[ "$base_branch" == main ]] && print -- "$TIDY_SAFE_TEST_MERGED_SHA" ;;
  mismatched-pr) print -- 0000000000000000000000000000000000000000 ;;
  wrong-base-pr) [[ "$base_branch" == release ]] && print -- "$TIDY_SAFE_TEST_WRONG_BASE_SHA" ;;
esac
EOF
chmod +x "$fake_bin/gh"
export PATH="$fake_bin:$PATH"

function_kinds=$(zsh -c "source '$aliases_file'; whence -w tidy; whence -w tidy-safe")
assert_contains "$function_kinds" 'tidy: function'
assert_contains "$function_kinds" 'tidy-safe: function'

dry_run=$(cd "$repository" && "$tidy_safe")
assert_contains "$dry_run" "SAFE worktree $scope/merged-clean"
assert_contains "$dry_run" "SAFE worktree $scope/squash-merged"
assert_contains "$dry_run" 'SAFE branch local-pr-alias'
assert_contains "$dry_run" "KEEP worktree $scope/unmerged-clean: unmerged"
assert_contains "$dry_run" "KEEP worktree $scope/dirty-merged: dirty"
assert_contains "$dry_run" "KEEP worktree $scope/mismatched-pr: unmerged"
assert_contains "$dry_run" "KEEP worktree $scope/wrong-base-pr: unmerged"
assert_contains "$dry_run" 'Dry run: rerun with --apply to delete only the SAFE items.'
assert_exists "$scope/merged-clean"
assert_exists "$scope/squash-merged"

apply_output=$(cd "$repository" && "$tidy_safe" --apply --yes)
assert_contains "$apply_output" "REMOVED worktree $scope/merged-clean"
assert_contains "$apply_output" "REMOVED worktree $scope/squash-merged"
assert_contains "$apply_output" 'REMOVED branch merged-clean'
assert_contains "$apply_output" 'REMOVED branch squash-merged'
assert_contains "$apply_output" 'REMOVED branch local-pr-alias'
assert_missing "$scope/merged-clean"
assert_missing "$scope/squash-merged"
assert_exists "$scope/unmerged-clean"
assert_exists "$scope/dirty-merged"
assert_exists "$scope/mismatched-pr"
assert_exists "$scope/wrong-base-pr"
git_in "$repository" show-ref --verify --quiet refs/heads/merged-clean && fail 'merged-clean branch still exists'
git_in "$repository" show-ref --verify --quiet refs/heads/squash-merged && fail 'squash-merged branch still exists'
git_in "$repository" show-ref --verify --quiet refs/heads/local-pr-alias && fail 'local-pr-alias branch still exists'
git_in "$repository" show-ref --verify --quiet refs/heads/unmerged-clean || fail 'unmerged-clean branch was deleted'
git_in "$repository" show-ref --verify --quiet refs/heads/mismatched-pr || fail 'mismatched-pr branch was deleted'
git_in "$repository" show-ref --verify --quiet refs/heads/wrong-base-pr || fail 'wrong-base-pr branch was deleted'

race_worktree="$scope/detached-race"
git_in "$repository" worktree add --detach "$race_worktree" main >/dev/null
race_fifo="$test_root/race-confirmation"
race_output_file="$test_root/race-output"
mkfifo "$race_fifo"
exec {race_fd}<> "$race_fifo"
(cd "$repository" && "$tidy_safe" --apply < "$race_fifo" > "$race_output_file" 2>&1) &
race_pid=$!
for _ in {1..250}; do
  grep -q 'Delete all items marked SAFE?' "$race_output_file" 2>/dev/null && break
  sleep 0.02
done
grep -q 'Delete all items marked SAFE?' "$race_output_file" 2>/dev/null || fail 'timed out waiting for apply confirmation'
print race > "$race_worktree/race.txt"
git_in "$race_worktree" add race.txt
git_in "$race_worktree" commit -m 'advance after audit' >/dev/null
print -u "$race_fd" y
exec {race_fd}>&-
if wait "$race_pid"; then
  race_status=0
else
  race_status=$?
fi
race_output=$(<"$race_output_file")
[[ "$race_status" == 1 ]] || fail "expected raced apply to exit 1, got $race_status"
assert_contains "$race_output" "FAILED worktree $race_worktree: changed or no longer proven safe after audit"
assert_exists "$race_worktree"

recursive_output=$(cd "$scope" && "$tidy_safe" --recursive)
assert_contains "$recursive_output" 'Repositories scanned: 1'
assert_contains "$recursive_output" 'Kept items: 5'

no_origin_repository="$scope/no-origin"
git_in "$scope" init --initial-branch=main "$no_origin_repository" >/dev/null
print local > "$no_origin_repository/README.md"
git_in "$no_origin_repository" add README.md
git_in "$no_origin_repository" commit -m 'local experiment' >/dev/null
skipped_output=$(cd "$scope" && "$tidy_safe" --recursive)
assert_contains "$skipped_output" 'SKIP repository: origin remote is missing'
assert_contains "$skipped_output" 'Repositories scanned: 1'
assert_contains "$skipped_output" 'Kept items: 5'
assert_contains "$skipped_output" 'Repositories skipped: 1'

excluded_output=$(cd "$scope" && "$tidy_safe" --recursive --exclude repository)
assert_contains "$excluded_output" "EXCLUDED directory $repository"
assert_contains "$excluded_output" 'Repositories scanned: 0'

exclusion_scope="$test_root/exclusions"
for fixture in "$exclusion_scope/archive data/nested" "$exclusion_scope/archive data-sibling"; do
  mkdir -p "$fixture"
  git_in "$fixture" init --initial-branch=main >/dev/null
  git_in "$fixture" commit --allow-empty -m 'local experiment' >/dev/null
done
for exclusion in "$exclusion_scope/archive data" 'archive data'; do
  subtree_output=$(cd "$test_root" && "$tidy_safe" --recursive "$exclusion_scope" --exclude "$exclusion")
  [[ "$subtree_output" != *"REPOSITORY $exclusion_scope/archive data/nested"* ]] || fail 'scanned an excluded subtree'
  assert_contains "$subtree_output" "EXCLUDED directory $exclusion_scope/archive data"
  assert_contains "$subtree_output" "REPOSITORY $exclusion_scope/archive data-sibling"
  assert_contains "$subtree_output" 'Directories excluded: 1'
  assert_contains "$subtree_output" 'Repositories skipped: 1'
done
root_excluded_output=$(cd "$test_root" && "$tidy_safe" --recursive "$exclusion_scope/archive data/nested" --exclude "$exclusion_scope/archive data")
assert_contains "$root_excluded_output" "EXCLUDED directory $exclusion_scope/archive data/nested"
assert_contains "$root_excluded_output" 'Repositories skipped: 0'
assert_contains "$root_excluded_output" 'Directories excluded: 1'

excluded_worktree="$exclusion_scope/archive data/linked"
git_in "$repository" worktree add -b excluded-linked "$excluded_worktree" main >/dev/null
excluded_apply=$(cd "$scope" && "$tidy_safe" --recursive --exclude "$exclusion_scope/archive data" --apply --yes)
assert_exists "$excluded_worktree"
assert_contains "$excluded_apply" "KEEP worktree $excluded_worktree: excluded"
git_in "$repository" show-ref --verify --quiet refs/heads/excluded-linked || fail 'excluded worktree branch was deleted'

feature_repository="$test_root/feature-primary"
git_in "$test_root" clone "$remote" "$feature_repository" >/dev/null
git_in "$feature_repository" switch -c primary-feature >/dev/null
git_in "$feature_repository" commit --allow-empty -m 'unmerged primary work' >/dev/null
primary_sha=$(git_in "$feature_repository" rev-parse HEAD)
print primary-dirty > "$feature_repository/untracked.txt"
feature_safe="$test_root/feature-safe"
feature_dirty="$test_root/feature-dirty"
feature_locked="$test_root/feature-locked"
git_in "$feature_repository" worktree add -b feature-safe "$feature_safe" origin/main >/dev/null
git_in "$feature_repository" worktree add -b feature-dirty "$feature_dirty" origin/main >/dev/null
print dirty > "$feature_dirty/untracked.txt"
git_in "$feature_repository" worktree add -b feature-locked "$feature_locked" origin/main >/dev/null
git_in "$feature_repository" worktree lock "$feature_locked"
feature_output=$(cd "$feature_repository" && "$tidy_safe" --apply --yes)
assert_contains "$feature_output" "REMOVED worktree $feature_safe"
assert_contains "$feature_output" "KEEP worktree $feature_dirty: dirty"
assert_contains "$feature_output" "KEEP worktree $feature_locked: locked"
assert_missing "$feature_safe"
assert_exists "$feature_dirty"
assert_exists "$feature_locked"
assert_exists "$feature_repository/untracked.txt"
[[ "$(git_in "$feature_repository" symbolic-ref --short HEAD)" == primary-feature ]] || fail 'changed the primary branch'
[[ "$(git_in "$feature_repository" rev-parse HEAD)" == "$primary_sha" ]] || fail 'changed the primary commit'

git_in "$feature_repository" switch --detach >/dev/null
detached_safe="$test_root/detached-primary-safe"
git_in "$feature_repository" worktree add -b detached-primary-safe "$detached_safe" origin/main >/dev/null
detached_output=$(cd "$feature_repository" && "$tidy_safe" --apply --yes)
assert_contains "$detached_output" "REMOVED worktree $detached_safe"
assert_contains "$detached_output" 'KEEP branch primary-feature: unmerged'
assert_missing "$detached_safe"
assert_exists "$feature_repository/untracked.txt"
[[ "$(git_in "$feature_repository" rev-parse HEAD)" == "$primary_sha" ]] || fail 'changed the detached primary commit'
git_in "$feature_repository" symbolic-ref --quiet HEAD && fail 'reattached the primary HEAD'

lagging_repository="$test_root/lagging-primary"
git_in "$test_root" clone "$remote" "$lagging_repository" >/dev/null
lagging_sha=$(git_in "$lagging_repository" rev-parse HEAD)
git_in "$seed" fetch origin >/dev/null
git_in "$seed" merge --ff-only origin/main >/dev/null
git_in "$seed" branch old-upstream
git_in "$seed" commit --allow-empty -m 'advance remote main' >/dev/null
git_in "$seed" push origin main old-upstream >/dev/null
git_in "$lagging_repository" fetch origin >/dev/null
lagging_safe="$test_root/lagging-safe"
git_in "$lagging_repository" worktree add -b lagging-safe "$lagging_safe" origin/main >/dev/null
git_in "$lagging_repository" branch --unset-upstream lagging-safe
git_in "$lagging_repository" branch lagging-local-branch origin/main >/dev/null
git_in "$lagging_repository" branch --set-upstream-to=origin/old-upstream lagging-local-branch >/dev/null
lagging_output=$(cd "$lagging_repository" && "$tidy_safe" --apply --yes)
assert_contains "$lagging_output" "REMOVED worktree $lagging_safe"
assert_contains "$lagging_output" 'REMOVED branch lagging-safe'
assert_contains "$lagging_output" 'REMOVED branch lagging-local-branch'
assert_missing "$lagging_safe"
git_in "$lagging_repository" show-ref --verify --quiet refs/heads/lagging-safe && fail 'lagging-safe branch still exists'
git_in "$lagging_repository" show-ref --verify --quiet refs/heads/lagging-local-branch && fail 'lagging-local-branch still exists'
git_in "$lagging_repository" config --get branch.lagging-local-branch.remote && fail 'deleted branch configuration still exists'
[[ "$(git_in "$lagging_repository" rev-parse HEAD)" == "$lagging_sha" ]] || fail 'advanced the primary main'

# Advance a branch during apply's fetch, after its initial SHA check. The
# refreshed merge proof still applies to the audited SHA, not the new commit.
git_in "$lagging_repository" branch fetch-race origin/main >/dev/null
export TIDY_SAFE_TEST_REAL_GIT=$(whence -p git)
export TIDY_SAFE_TEST_FETCH_RACE_ARM="$test_root/fetch-race-arm"
export TIDY_SAFE_TEST_DELETE_RACE_SHA="$test_root/delete-race-sha"
cat > "$fake_bin/git" <<'EOF'
#!/usr/bin/env zsh
if [[ "$*" == *'fetch --prune origin'* && -e "$TIDY_SAFE_TEST_FETCH_RACE_ARM" ]]; then
  rm "$TIDY_SAFE_TEST_FETCH_RACE_ARM"
  directory=$2
  tree=$("$TIDY_SAFE_TEST_REAL_GIT" -C "$directory" rev-parse 'fetch-race^{tree}')
  old_sha=$("$TIDY_SAFE_TEST_REAL_GIT" -C "$directory" rev-parse fetch-race)
  new_sha=$(print 'unmerged change during fetch' | "$TIDY_SAFE_TEST_REAL_GIT" -C "$directory" commit-tree "$tree" -p "$old_sha")
  "$TIDY_SAFE_TEST_REAL_GIT" -C "$directory" update-ref refs/heads/fetch-race "$new_sha" "$old_sha"
fi
if [[ "$*" == *'branch -D -- delete-race'* || "$*" == *'update-ref --no-deref -d refs/heads/delete-race '* ]]; then
  directory=$2
  tree=$("$TIDY_SAFE_TEST_REAL_GIT" -C "$directory" rev-parse 'delete-race^{tree}')
  old_sha=$("$TIDY_SAFE_TEST_REAL_GIT" -C "$directory" rev-parse delete-race)
  new_sha=$(print 'unmerged change immediately before deletion' | "$TIDY_SAFE_TEST_REAL_GIT" -C "$directory" commit-tree "$tree" -p "$old_sha")
  "$TIDY_SAFE_TEST_REAL_GIT" -C "$directory" update-ref refs/heads/delete-race "$new_sha" "$old_sha"
  print -r -- "$new_sha" > "$TIDY_SAFE_TEST_DELETE_RACE_SHA"
fi
exec "$TIDY_SAFE_TEST_REAL_GIT" "$@"
EOF
chmod +x "$fake_bin/git"
fetch_fifo="$test_root/fetch-race-confirmation"
fetch_output_file="$test_root/fetch-race-output"
mkfifo "$fetch_fifo"
exec {fetch_fd}<> "$fetch_fifo"
(cd "$lagging_repository" && "$tidy_safe" --apply < "$fetch_fifo" > "$fetch_output_file" 2>&1) &
fetch_pid=$!
for _ in {1..250}; do
  grep -q 'Delete all items marked SAFE?' "$fetch_output_file" 2>/dev/null && break
  sleep 0.02
done
grep -q 'Delete all items marked SAFE?' "$fetch_output_file" 2>/dev/null || fail 'timed out waiting for fetch race confirmation'
touch "$TIDY_SAFE_TEST_FETCH_RACE_ARM"
print -u "$fetch_fd" y
exec {fetch_fd}>&-
if wait "$fetch_pid"; then
  fail 'deleted a branch that advanced during fetch'
fi
assert_contains "$(<"$fetch_output_file")" 'FAILED branch fetch-race: changed or checked out during revalidation'
git_in "$lagging_repository" show-ref --verify --quiet refs/heads/fetch-race || fail 'fetch-race branch was deleted'

git_in "$lagging_repository" branch delete-race origin/main >/dev/null
if (cd "$lagging_repository" && "$tidy_safe" --apply --yes > "$test_root/delete-race-output" 2>&1); then
  fail 'deleted a branch that advanced immediately before deletion'
fi
assert_contains "$(<"$test_root/delete-race-output")" 'FAILED branch delete-race: delete failed'
[[ "$(git_in "$lagging_repository" rev-parse delete-race)" == "$(<"$TIDY_SAFE_TEST_DELETE_RACE_SHA")" ]] || fail 'lost the concurrent unmerged commit'
[[ "$(git_in "$lagging_repository" config --get branch.delete-race.remote)" == origin ]] || fail 'removed configuration for the retained branch'
git_in "$lagging_repository" reflog exists refs/heads/delete-race || fail 'removed the retained branch reflog'

default_scope="$test_root/default-change"
default_repository="$default_scope/repository"
mkdir "$default_scope"
git_in "$default_scope" clone "$remote" "$default_repository" >/dev/null
git_in "$seed" switch -c trunk >/dev/null
print trunk > "$seed/trunk.txt"
git_in "$seed" add trunk.txt
git_in "$seed" commit -m 'new remote default' >/dev/null
git_in "$seed" push -u origin trunk >/dev/null
git --git-dir="$remote" symbolic-ref HEAD refs/heads/trunk
git_in "$seed" switch main >/dev/null
git_in "$seed" commit --allow-empty -m 'main-only change after default switched' >/dev/null
git_in "$seed" push origin main >/dev/null
git_in "$default_repository" fetch origin >/dev/null
[[ "$(git_in "$default_repository" symbolic-ref --short refs/remotes/origin/HEAD)" == origin/main ]] || fail 'test requires a stale cached origin/HEAD'
main_only_worktree="$default_scope/main-only"
trunk_worktree="$default_scope/trunk-safe"
git_in "$default_repository" worktree add -b main-only "$main_only_worktree" origin/main >/dev/null
git_in "$default_repository" worktree add -b trunk-safe "$trunk_worktree" origin/trunk >/dev/null
default_output=$(cd "$default_repository" && "$tidy_safe")
assert_contains "$default_output" "KEEP worktree $main_only_worktree: unmerged"
assert_contains "$default_output" "SAFE worktree $trunk_worktree: merged into origin/trunk"
assert_contains "$default_output" 'Kept items: 1'
assert_contains "$default_output" 'Repositories scanned: 1'
assert_contains "$default_output" 'Repositories skipped: 0'
default_apply=$(cd "$default_repository" && "$tidy_safe" --apply --yes)
assert_contains "$default_apply" "REMOVED worktree $trunk_worktree"
assert_missing "$trunk_worktree"
assert_exists "$main_only_worktree"

if grep -qi groundcrew "$tidy_safe"; then
  fail 'tidy-safe contains Groundcrew-specific code'
fi

print 'tidy-safe integration tests passed'
