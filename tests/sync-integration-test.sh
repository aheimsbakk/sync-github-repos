#!/usr/bin/env bash
# sync-integration-test.sh — end-to-end clone/update/dirty-skip behavior
# against a real GitHub user. Opt-in: set RUN_INTEGRATION=1.
#
# Each pass runs inside a hard time box so only a bounded number of
# repositories is ever downloaded; the script's SIGTERM mid-loop means no
# summary output, so assertions read per-repo log lines instead.

set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/assert.sh
. "$root/tests/lib/assert.sh"

if [[ "${RUN_INTEGRATION:-0}" != "1" ]]; then
	skip "integration suite disabled (set RUN_INTEGRATION=1)"
	suite_summary
fi
if ! network_available; then
	skip "network unavailable — integration suite skipped"
	suite_summary
fi

USER_NAME="aheimsbakk"
S="$root/sync-github-repos.sh"
sandbox="$root/tmp/tests/sync-integration"
clone_dir="$sandbox/clone"
rm -rf "$sandbox"
mkdir -p "$clone_dir"

echo "-- pass 1: clone path --"
timeout 60 "$S" --use-https -v --dest "$clone_dir" "$USER_NAME" >"$sandbox/pass1.log" 2>&1
cloned=$(grep -c '^Cloned ' "$sandbox/pass1.log")
((cloned >= 5)) && ok "cloned $cloned repositories on first pass" || bad "only $cloned clones on first pass"

invalid=0
for d in "$clone_dir"/*/; do
	git -C "$d" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
		echo "INVALID: $d"
		invalid=$((invalid + 1))
	}
done
((invalid == 0)) && ok "all clones are valid git repositories" || bad "$invalid clone(s) are not valid git repositories"

echo "-- pass 2: update path --"
timeout 90 "$S" --use-https -v --dest "$clone_dir" "$USER_NAME" >"$sandbox/pass2.log" 2>&1
reclones_ok=$(grep -c '^Updated ' "$sandbox/pass2.log")
((reclones_ok >= 5)) && ok "$reclones_ok existing repos updated (fetch + fast-forward)" || bad "only $reclones_ok updated lines on second pass"
dupes=$(grep -oP '(?<=^Updated )\S+' "$sandbox/pass2.log" | sort | uniq -d | wc -l)
((dupes == 0)) && ok "no repository updated twice in one pass" || bad "$dupes repositories updated twice in one pass"

echo "-- pass 3: dirty-worktree guard --"
echo "local edit" >>"$clone_dir/$(ls "$clone_dir" | head -1)/INTEGRATION-DIRTY-TEST"
first=$(ls "$clone_dir" | head -1)
timeout 30 "$S" --use-https -v --dest "$clone_dir" "$USER_NAME" >"$sandbox/pass3.log" 2>&1
grep -qF "Local changes present in $first; skipping pull" "$sandbox/pass3.log" &&
	ok "dirty repo $first skipped instead of pulled" ||
	bad "dirty repo $first was not reported as skipped"
grep -qF "Updated $first " "$sandbox/pass3.log" && bad "dirty repo $first was updated anyway" || ok "dirty repo $first not updated"

rm -rf "$sandbox"
suite_summary
