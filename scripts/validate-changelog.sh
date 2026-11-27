#!/usr/bin/env bash
# validate-changelog.sh — validate CHANGELOG.md against the wrap-up changelog format
#
# Format source: .opencode/skills/wrap-up/SKILL.md (Keep a Changelog 1.1.0
# plus why/model/tags metadata bullets per version entry).
#
# Usage: scripts/validate-changelog.sh [changelog-file]   (default: CHANGELOG.md)
# Exit:  0 = valid, 1 = validation error, 2 = usage/file error

set -euo pipefail

ERRORS=()
WARNINGS=()

err() { ERRORS+=("  ERROR: $*"); }
warn() { WARNINGS+=("  WARN:  $*"); }

usage() {
	cat <<USAGE
Usage: $(basename "$0") [changelog-file]

Validates CHANGELOG.md structure:
  - first line is '# Changelog'
  - version sections match  ## [X.Y.Z] - YYYY-MM-DD
  - each version section starts with '- **why:**', '- **model:**', '- **tags:**'
  - category headings are one of: Added, Changed, Fixed, Removed, Security
  - version numbers descend (newest first)
  - no hardcoded secrets
USAGE
}

# ---------------------------------------------------------------------------
# Argument / file checks
# ---------------------------------------------------------------------------
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
	usage
	exit 0
fi
if [[ $# -gt 1 ]]; then
	usage >&2
	exit 2
fi

file="${1:-CHANGELOG.md}"

if [[ ! -f "$file" ]]; then
	echo "ERROR: file not found: $file" >&2
	exit 2
fi

# ---------------------------------------------------------------------------
# Heading checks
# ---------------------------------------------------------------------------
if [[ "$(head -n1 "$file")" != "# Changelog" ]]; then
	err "first line must be '# Changelog', got: '$(head -n1 "$file")'"
fi

VERSION_RE='^## \[([0-9]+)\.([0-9]+)\.([0-9]+)\] - ([0-9]{4})-([0-9]{2})-([0-9]{2})$'
ALLOWED_HEADINGS=(Added Changed Fixed Removed Security)

mapfile -t lines <"$file"

# Collect version section start indices (0-based).
section_idx=()
for i in "${!lines[@]}"; do
	line="${lines[$i]}"
	if [[ "$line" == "## "* ]]; then
		if [[ "$line" =~ $VERSION_RE ]]; then
			section_idx+=("$i")
		else
			err "malformed version heading on line $((i + 1)): '$line' (expected '## [X.Y.Z] - YYYY-MM-DD')"
		fi
	fi
done

if ((${#section_idx[@]} == 0)); then
	err "no version sections found"
fi

# ---------------------------------------------------------------------------
# Per-section checks: metadata bullets, category headings
# ---------------------------------------------------------------------------
for s in "${!section_idx[@]}"; do
	start=${section_idx[$s]}
	end=$((s + 1 < ${#section_idx[@]} ? section_idx[s + 1] - 1 : ${#lines[@]} - 1))
	header="${lines[$start]}"
	saw_why=0 saw_model=0 saw_tags=0 saw_category=0
	for ((i = start + 1; i <= end; i++)); do
		line="${lines[$i]}"
		case "$line" in
		"### "*)
			saw_category=1
			heading="${line#\#\#\# }"
			# Metadata bullets must appear before the first category heading.
			[[ $saw_why -eq 1 && $saw_model -eq 1 && $saw_tags -eq 1 ]] ||
				err "metadata bullets (why/model/tags) must come before categories in section '$header'"
			found=0
			for h in "${ALLOWED_HEADINGS[@]}"; do
				[[ "$heading" == "$h" ]] && found=1 && break
			done
			[[ $found -eq 1 ]] || err "unknown category heading '$heading' on line $((i + 1)) (allowed: ${ALLOWED_HEADINGS[*]})"
			;;
		"- **why:** "*) saw_why=1 ;;
		"- **model:** "*) saw_model=1 ;;
		"- **tags:** "*) saw_tags=1 ;;
		esac
		# Category headings must be followed by at least one bullet; the
		# wrap-up skill's format allows blank lines between heading and list.
		if [[ "$line" == "### "* ]]; then
			j=$((i + 1))
			while ((j <= end)) && [[ -z "${lines[$j]}" ]]; do j=$((j + 1)); done
			[[ $j -le $end && "${lines[$j]}" == "- "* ]] ||
				err "category '$heading' on line $((i + 1)) has no bullets"
		fi
	done
	[[ $saw_why -eq 1 ]] || err "section '$header' is missing '- **why:**' bullet"
	[[ $saw_model -eq 1 ]] || err "section '$header' is missing '- **model:**' bullet"
	[[ $saw_tags -eq 1 ]] || err "section '$header' is missing '- **tags:**' bullet"
	[[ $saw_category -eq 1 ]] || warn "section '$header' has no category headings"
done

# ---------------------------------------------------------------------------
# Version order — must descend (newest first). Compares tuple numerically.
# ---------------------------------------------------------------------------
prev_tuple=""
for i in "${section_idx[@]}"; do
	[[ "${lines[$i]}" =~ $VERSION_RE ]] || continue
	tuple="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"
	if [[ -n "$prev_tuple" ]]; then
		IFS=. read -r a1 a2 a3 <<<"$prev_tuple"
		IFS=. read -r b1 b2 b3 <<<"$tuple"
		if ((10#$b1 > 10#$a1 || (10#$b1 == 10#$a1 && 10#$b2 > 10#$a2) || (\
			10#$b1 == 10#$a1 && 10#$b2 == 10#$a2 && 10#$b3 > 10#$a3))); then
			warn "versions not in descending order: [$tuple] follows [$prev_tuple]"
		fi
	fi
	prev_tuple="$tuple"
done

# ---------------------------------------------------------------------------
# Safety — no hardcoded secrets (same patterns as the retired worklog validator)
# ---------------------------------------------------------------------------
secret_patterns=(
	'(password|passwd|secret|api_key|private_key|access_token|auth_token)\s*[:=]\s*[^${\s][^\s]{4,}'
	'[0-9a-fA-F]{40}'
	'ghp_[A-Za-z0-9]{36,}'
	'sk-[A-Za-z0-9]{20,}'
)
for pattern in "${secret_patterns[@]}"; do
	if grep -qiE "$pattern" "$file"; then
		err "potential hardcoded secret detected (pattern: $pattern)"
	fi
done

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
echo "Validating: $file"
echo

if ((${#WARNINGS[@]} > 0)); then
	for w in "${WARNINGS[@]}"; do echo "$w"; done
	echo
fi

if ((${#ERRORS[@]} > 0)); then
	echo "FAILED — ${#ERRORS[@]} error(s):"
	for e in "${ERRORS[@]}"; do echo "$e"; done
	exit 1
fi

echo "OK — all checks passed"
exit 0
