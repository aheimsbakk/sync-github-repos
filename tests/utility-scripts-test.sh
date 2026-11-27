#!/usr/bin/env bash
# utility-scripts-test.sh — contracts for scripts/bump-version.sh,
# scripts/validate-changelog.sh, and scripts/verify_codebase_sync.sh.
# Runs against sandbox copies so repository files are never modified.

set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/assert.sh
. "$root/tests/lib/assert.sh"

sandbox="$root/tmp/tests/utility-scripts"
rm -rf "$sandbox"
mkdir -p "$sandbox/bump"

echo "-- bump-version.sh --"
cp "$root/sync-github-repos.sh" "$sandbox/bump/"
cp "$root/scripts/bump-version.sh" "$sandbox/bump/bv.sh"
cd "$sandbox/bump" || exit 1
ver() { grep -E '^VERSION=' sync-github-repos.sh | sed 's/VERSION="//;s/"//'; }

base="$(ver)"
IFS=. read -r b_maj b_min b_pat <<<"$base"
bash bv.sh patch >/dev/null
[[ "$(ver)" == "$b_maj.$b_min.$((b_pat + 1))" ]] && ok "patch bump $base -> $(ver)" || bad "patch bump gave $(ver)"
chmod +x sync-github-repos.sh
bash bv.sh minor >/dev/null
[[ "$(ver)" == "$b_maj.$((b_min + 1)).0" ]] && ok "minor bump $base -> $(ver)" || bad "minor bump gave $(ver)"
chmod +x sync-github-repos.sh
bash bv.sh major >/dev/null
[[ "$(ver)" == "$((b_maj + 1)).0.0" ]] && ok "major bump $base -> $(ver)" || bad "major bump gave $(ver)"
chmod +x sync-github-repos.sh
expect_rc "invalid bump type exits 3" 3 -- bash bv.sh banana
expect_rc "missing argument exits 2" 2 -- bash bv.sh
expect_true "no worklog/docs side effects" test ! -e docs
# Regression: mktemp+mv used to reset the target to mode 0600.
expect_true "target keeps exec bit after bump" test -x sync-github-repos.sh

echo "-- validate-changelog.sh --"
V="$root/scripts/validate-changelog.sh"
expect_rc "real CHANGELOG.md is valid" 0 -- bash "$V" "$root/CHANGELOG.md"
expect_rc "missing file exits 2" 2 -- bash "$V" "$root/nope.md"
expect_rc "too many arguments exit 2" 2 -- bash "$V" a.md b.md
printf '# Changelog\n\n## [1.0.0] - 2026-01-01\n\n- **why:** test\n\n### Added\n\n- thing\n' >"$sandbox/bad-meta.md"
expect_rc "missing model/tags bullets fail" 1 -- bash "$V" "$sandbox/bad-meta.md"
printf 'Not a changelog\n' >"$sandbox/bad-head.md"
expect_rc "wrong first line fails" 1 -- bash "$V" "$sandbox/bad-head.md"

echo "-- verify_codebase_sync.sh --"
W="$root/scripts/verify_codebase_sync.sh"
expect_rc "real CODEBASE.md paths all exist" 0 -- bash "$W"
printf 'See `does-not-exist/phantom.sh` and `sync-github-repos.sh`.\n' >"$sandbox/fake.md"
expect_rc "phantom path reported as failure" 1 -- bash "$W" "$sandbox/fake.md"

suite_summary
