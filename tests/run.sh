#!/usr/bin/env bash
# run.sh — test framework entry point
#
# Discovers tests/*-test.sh, runs each suite as an isolated subprocess with a
# time bound, aggregates RESULT lines, and exits per the runner contract in
# BLUEPRINT.md. All side effects stay in the tmp/tests/ sandbox.
#
# Usage: tests/run.sh [name-filter]
#   name-filter  substring; only suites whose file name contains it are run
# Environment:
#   RUN_INTEGRATION=1  enable the network integration suite
# Exit: 0 no failures (skips allowed), 1 failures or crashed suite, 2 usage

set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
sandbox="$root/tmp/tests"
SUITE_TIMEOUT=300

if [[ $# -gt 1 ]]; then
	echo "Usage: $(basename "$0") [name-filter]" >&2
	exit 2
fi
filter="${1:-}"

mapfile -t suites < <(find "$root/tests" -maxdepth 1 -name '*-test.sh' | sort)
if [[ ${#suites[@]} -eq 0 ]]; then
	echo "ERROR: no suites found in $root/tests" >&2
	exit 1
fi

rm -rf "$sandbox"
mkdir -p "$sandbox"

total_pass=0
total_fail=0
total_skip=0
failed_suites=()

for suite in "${suites[@]}"; do
	name="$(basename "$suite")"
	if [[ -n "$filter" && "$name" != *"$filter"* ]]; then
		continue
	fi
	echo "=== $name ==="
	out="$(cd "$root" && timeout "$SUITE_TIMEOUT" bash "$suite" 2>&1)"
	rc=$?
	grep -v '^RESULT:' <<<"$out" || true

	line="$(grep '^RESULT:' <<<"$out" | tail -1)"
	if [[ -n "$line" ]]; then
		p="$(sed -E 's/RESULT: ([0-9]+) passed.*/\1/' <<<"$line")"
		f="$(sed -E 's/.* ([0-9]+) failed.*/\1/' <<<"$line")"
		s="$(sed -E 's/.* ([0-9]+) skipped.*/\1/' <<<"$line")"
		total_pass=$((total_pass + p))
		total_fail=$((total_fail + f))
		total_skip=$((total_skip + s))
		if ((f > 0)); then
			failed_suites+=("$name")
		fi
	else
		echo "FAIL  suite $name produced no RESULT line (rc=$rc)"
		failed_suites+=("$name (crashed, rc=$rc)")
	fi
	echo
done

rm -rf "$sandbox"

echo "TOTAL: $total_pass passed, $total_fail failed, $total_skip skipped"
if [[ ${#failed_suites[@]} -gt 0 ]]; then
	printf 'FAILED SUITES: %s\n' "${failed_suites[@]}"
	exit 1
fi
exit 0
