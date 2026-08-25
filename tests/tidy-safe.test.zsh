#!/usr/bin/env zsh
set -euo pipefail

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

git_in "$repository" worktree add -b dirty-merged "$scope/dirty-merged" main >/dev/null
print dirty > "$scope/dirty-merged/untracked.txt"

git_in "$repository" worktree add -b squash-merged "$scope/squash-merged" main >/dev/null
print squash > "$scope/squash-merged/squash.txt"
git_in "$scope/squash-merged" add squash.txt
git_in "$scope/squash-merged" commit -m 'squash merged change' >/dev/null
export TIDY_SAFE_TEST_MERGED_SHA=$(git_in "$scope/squash-merged" rev-parse HEAD)

git_in "$repository" worktree add -b mismatched-pr "$scope/mismatched-pr" main >/dev/null
print mismatch > "$scope/mismatched-pr/mismatch.txt"
git_in "$scope/mismatched-pr" add mismatch.txt
git_in "$scope/mismatched-pr" commit -m 'local commit after merged PR' >/dev/null

fake_bin="$test_root/fake-bin"
mkdir "$fake_bin"
cat > "$fake_bin/gh" <<'EOF'
#!/usr/bin/env zsh
head_branch=
while (( $# > 0 )); do
  if [[ "$1" == --head ]]; then
    head_branch=$2
    break
  fi
  shift
done
case "$head_branch" in
  squash-merged) print -- "$TIDY_SAFE_TEST_MERGED_SHA" ;;
  mismatched-pr) print -- 0000000000000000000000000000000000000000 ;;
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
assert_contains "$dry_run" "KEEP worktree $scope/unmerged-clean: unmerged"
assert_contains "$dry_run" "KEEP worktree $scope/dirty-merged: dirty"
assert_contains "$dry_run" "KEEP worktree $scope/mismatched-pr: unmerged"
assert_contains "$dry_run" 'Dry run: rerun with --apply to delete only the SAFE items.'
assert_exists "$scope/merged-clean"
assert_exists "$scope/squash-merged"

apply_output=$(cd "$repository" && "$tidy_safe" --apply --yes)
assert_contains "$apply_output" "REMOVED worktree $scope/merged-clean"
assert_contains "$apply_output" "REMOVED worktree $scope/squash-merged"
assert_contains "$apply_output" 'REMOVED branch merged-clean'
assert_contains "$apply_output" 'REMOVED branch squash-merged'
assert_missing "$scope/merged-clean"
assert_missing "$scope/squash-merged"
assert_exists "$scope/unmerged-clean"
assert_exists "$scope/dirty-merged"
assert_exists "$scope/mismatched-pr"
git_in "$repository" show-ref --verify --quiet refs/heads/merged-clean && fail 'merged-clean branch still exists'
git_in "$repository" show-ref --verify --quiet refs/heads/squash-merged && fail 'squash-merged branch still exists'
git_in "$repository" show-ref --verify --quiet refs/heads/unmerged-clean || fail 'unmerged-clean branch was deleted'
git_in "$repository" show-ref --verify --quiet refs/heads/mismatched-pr || fail 'mismatched-pr branch was deleted'

recursive_output=$(cd "$scope" && "$tidy_safe" --recursive)
assert_contains "$recursive_output" 'Repositories scanned: 1'
excluded_output=$(cd "$scope" && "$tidy_safe" --recursive --exclude repository)
assert_contains "$excluded_output" "EXCLUDED repository $repository"
assert_contains "$excluded_output" 'Repositories scanned: 0'

if grep -qi groundcrew "$tidy_safe"; then
  fail 'tidy-safe contains Groundcrew-specific code'
fi

print 'tidy-safe integration tests passed'
