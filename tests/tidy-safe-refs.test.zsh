#!/usr/bin/env zsh
set -euo pipefail
repo_root=${0:A:h:h}
tidy_safe=${TIDY_SAFE_BINARY:-"$repo_root/bin/tidy-safe"}
test_root=$(mktemp -d "${TMPDIR:-/tmp}/tidy-safe-refs.XXXXXX")
trap 'rm -rf -- "$test_root"' EXIT
export GIT_AUTHOR_NAME='Tidy Safe Test' GIT_COMMITTER_NAME='Tidy Safe Test'
export GIT_AUTHOR_EMAIL=tidy-safe@example.com GIT_COMMITTER_EMAIL=tidy-safe@example.com
fail() { print -u2 -- "FAIL: $1"; exit 1; }
git init -q --bare --initial-branch=main "$test_root/remote.git"
git clone -q "$test_root/remote.git" "$test_root/repository"
repository="$test_root/repository"
git -C "$repository" commit --allow-empty -qm initial
git -C "$repository" push -q origin main
mkdir "$test_root/bin"
printf '#!/bin/sh\nexit 1\n' > "$test_root/bin/gh"
chmod +x "$test_root/bin/gh"
export PATH="$test_root/bin:$PATH"

# Git's short ref names grow a heads/ prefix when a tag has the same name.
git -C "$repository" branch fbd/merged
git -C "$repository" tag --no-sign -m collision fbd/merged
git -C "$repository" switch -qc fbd/unmerged
git -C "$repository" commit --allow-empty -qm unmerged
unmerged_sha=$(git -C "$repository" rev-parse HEAD)
git -C "$repository" tag --no-sign -m collision fbd/unmerged
git -C "$repository" switch -q main
output=$(cd "$repository" && "$tidy_safe" --apply --yes)
[[ "$output" == *'REMOVED branch fbd/merged:'* ]] || fail 'did not remove merged branch colliding with a tag'
[[ "$(git -C "$repository" rev-parse refs/heads/fbd/unmerged)" == "$unmerged_sha" ]] || fail 'lost unmerged branch'
git -C "$repository" show-ref --verify --quiet refs/tags/fbd/merged || fail 'deleted colliding tag'

# A branch removed after enumeration must not abort cleanup of later branches.
git -C "$repository" branch vanishes
git -C "$repository" branch z-survives
export TIDY_SAFE_REFS_REAL_GIT=$(command -v git)
export TIDY_SAFE_REFS_RACE_ARM="$test_root/race-arm"
touch "$TIDY_SAFE_REFS_RACE_ARM"
cat > "$test_root/bin/git" <<'EOF'
#!/usr/bin/env zsh
if [[ "$*" == *'rev-parse --verify refs/heads/vanishes' && -f "$TIDY_SAFE_REFS_RACE_ARM" ]]; then
  rm -- "$TIDY_SAFE_REFS_RACE_ARM"
  "$TIDY_SAFE_REFS_REAL_GIT" -C "$2" update-ref -d refs/heads/vanishes
fi
exec "$TIDY_SAFE_REFS_REAL_GIT" "$@"
EOF
chmod +x "$test_root/bin/git"
output=$(cd "$repository" && "$tidy_safe" --apply --yes)
[[ "$output" == *'KEEP branch vanishes: revision unavailable'* ]] || fail 'missing branch was not reported'
[[ "$output" == *'REMOVED branch z-survives:'* ]] || fail 'missing branch aborted remaining cleanup'
print 'tidy-safe ref safety tests passed'
