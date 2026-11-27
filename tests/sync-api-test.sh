#!/usr/bin/env bash
# sync-api-test.sh — GitHub API interaction contract of sync-github-repos.sh:
# error propagation, destination setup, and pagination request. Uses one real
# API call per run; skips the whole suite when the network is unavailable.

set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/assert.sh
. "$root/tests/lib/assert.sh"

if ! network_available; then
	skip "network unavailable — API contract suite skipped"
	suite_summary
fi

S="$root/sync-github-repos.sh"
sandbox="$root/tmp/tests/sync-api"
rm -rf "$sandbox"
mkdir -p "$sandbox"
cd "$sandbox" || exit 1

out=$("$S" -v --dest ./dest no-such-user-zzz-9241 2>&1)
rc=$?
[[ $rc -eq 6 ]] && ok "unknown user exits 6 (API error)" || bad "unknown user exited $rc, expected 6; output: $(head -2 <<<"$out")"
expect_true "destination directory created before fetching" test -d ./dest
grep -qF 'page=1' <<<"$out" && ok "pagination page 1 requested" || bad "page 1 request not logged"

suite_summary
