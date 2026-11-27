#!/usr/bin/env bash
# assert.sh — shared assertion helpers for test suites
#
# Contract (see BLUEPRINT.md "Test Framework"): a suite sources this file,
# calls expect_* helpers, and finishes with suite_summary. The suite prints
# "RESULT: <n> passed, <n> failed, <n> skipped" as its final line and exits
# 1 when any assertion failed.

PASS=0
FAIL=0
SKIP=0

ok() {
	PASS=$((PASS + 1))
	echo "PASS  $1"
}
bad() {
	FAIL=$((FAIL + 1))
	echo "FAIL  $1"
}
skip() {
	SKIP=$((SKIP + 1))
	echo "SKIP  $1"
}

# expect_rc <label> <expected-rc> -- <cmd...>
expect_rc() {
	local label=$1 want=$2
	shift 3
	local out rc
	out=$("$@" 2>&1)
	rc=$?
	if [[ $rc -eq $want ]]; then
		ok "$label (rc=$rc)"
	else
		bad "$label — expected rc=$want got rc=$rc; output: $(head -2 <<<"$out")"
	fi
	return 0
}

# expect_out <label> <expected-rc> <literal-pattern> -- <cmd...>
expect_out() {
	local label=$1 want_rc=$2 pattern=$3
	shift 4
	local out rc
	out=$("$@" 2>&1)
	rc=$?
	if [[ $rc -eq $want_rc ]] && grep -qF -- "$pattern" <<<"$out"; then
		ok "$label"
	else
		bad "$label — rc=$rc, pattern '$pattern' not found; output: $(head -2 <<<"$out")"
	fi
	return 0
}

# expect_true <label> <test-command...>
# Runs the command and passes when its exit status is 0.
expect_true() {
	local label=$1
	shift
	if "$@"; then
		ok "$label"
	else
		bad "$label — condition failed: $*"
	fi
	return 0
}

# network_available — probe the GitHub API once; succeed when reachable.
network_available() {
	local code
	code=$(curl -sS --connect-timeout 5 --max-time 10 -o /dev/null \
		-w '%{http_code}' https://api.github.com/zen 2>/dev/null) || code=000
	[[ $code == "200" ]]
}

# suite_summary — print the machine-parseable result line and exit per contract.
suite_summary() {
	echo
	echo "RESULT: $PASS passed, $FAIL failed, $SKIP skipped"
	if ((FAIL > 0)); then
		exit 1
	fi
	exit 0
}
