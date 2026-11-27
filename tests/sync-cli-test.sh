#!/usr/bin/env bash
# sync-cli-test.sh — argument parsing and exit-code contract of
# sync-github-repos.sh. Offline; no network or repository side effects.

set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/assert.sh
. "$root/tests/lib/assert.sh"

S="$root/sync-github-repos.sh"
sandbox="$root/tmp/tests/sync-cli"
rm -rf "$sandbox"
mkdir -p "$sandbox"
cd "$sandbox" || exit 1

version="$(sed -n 's/^VERSION="\(.*\)"/\1/p' "$S" | head -1)"

expect_out "help exits 0 and prints usage" 0 "Usage:" -- "$S" --help
expect_out "short help flag" 0 "Usage:" -- "$S" -h
expect_out "version matches VERSION variable" 0 "sync-github-repos.sh $version" -- "$S" --version
expect_out "short version flag" 0 "sync-github-repos.sh $version" -- "$S" -V
expect_out "no arguments is a usage error" 2 "missing GitHub username" -- "$S"
expect_out "unknown option is a usage error" 2 "Unknown option" -- "$S" --bogus user
expect_out "removed --no-submodules flag rejected (v3 breaking change)" 2 "" -- "$S" --no-submodules user
expect_out "dest without value is a usage error" 2 "requires a directory" -- "$S" -d
expect_out "flags without username still error" 2 "missing GitHub username" -- "$S" --use-https --submodules -v

suite_summary
