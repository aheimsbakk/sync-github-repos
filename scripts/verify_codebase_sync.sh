#!/usr/bin/env bash
# verify_codebase_sync.sh — check that every file path cited in CODEBASE.md exists
#
# Extracts backtick-quoted, path-like tokens from CODEBASE.md and verifies
# each exists relative to the repository root. Missing paths mean CODEBASE.md
# is out of sync with the tree (AGENTS.md Synchronization Protocol).
#
# Usage: scripts/verify_codebase_sync.sh [doc-file]   (default: CODEBASE.md)
# Exit:  0 = all paths exist, 1 = missing paths, 2 = usage/file error

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $# -gt 1 ]]; then
	echo "Usage: $(basename "$0") [doc-file]" >&2
	exit 2
fi

doc="${1:-$root/CODEBASE.md}"
if [[ ! -f "$doc" ]]; then
	echo "ERROR: doc not found: $doc" >&2
	exit 2
fi

# Pull the first word of every backtick span, then keep path-like tokens:
# slash-separated segments, or a bare name ending in a known extension.
# Globs, versions, and prose spans are filtered out by the pattern.
mapfile -t tokens < <(
	grep -oE '`[^`]+`' "$doc" |
		tr -d '`' |
		awk '{print $1}' |
		grep -E '^\.?[A-Za-z0-9._-]+(/[A-Za-z0-9._-]+)*/?$' |
		grep -E '/|\.(md|sh|json|txt|ya?ml|toml)$' |
		sort -u
)

if ((${#tokens[@]} == 0)); then
	echo "ERROR: no path-like references found in $doc" >&2
	exit 1
fi

missing=0
for token in "${tokens[@]}"; do
	candidate="${token%/}"
	if [[ ! -e "$root/$candidate" ]]; then
		echo "MISSING: $candidate"
		missing=$((missing + 1))
	fi
done

echo
if ((missing > 0)); then
	echo "FAILED — $missing path(s) in $doc do not exist. Update $doc or restore the files."
	exit 1
fi

echo "OK — all ${#tokens[@]} referenced paths exist"
exit 0
