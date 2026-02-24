#!/usr/bin/env bash
# validate-worklog.sh — validate a worklog file against the AGENTS.md spec
#
# Usage: scripts/validate-worklog.sh <worklog-file>
# Exit:  0 = valid, 1 = validation error, 2 = usage/file error

set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
ERRORS=()
WARNINGS=()

err()  { ERRORS+=("  ERROR: $*"); }
warn() { WARNINGS+=("  WARN:  $*"); }

usage() {
  cat <<USAGE
Usage: $(basename "$0") <worklog-file>

Validates a worklog Markdown file against the AGENTS.md front-matter spec:
  Required keys (ONLY these, no extras): when  why  what  model  tags
  when  — ISO 8601 UTC timestamp  (e.g. 2026-02-24T18:00:00Z)
  why   — one sentence ending with a period
  what  — non-empty single-line summary
  model — non-empty model identifier
  tags  — YAML inline list  (e.g. [fix, v1.2.3])
  body  — 1–4 sentences; no hardcoded secrets
USAGE
}

# ---------------------------------------------------------------------------
# Argument / file checks
# ---------------------------------------------------------------------------
if [[ $# -ne 1 ]]; then
  usage
  exit 2
fi

file="$1"

if [[ ! -f "$file" ]]; then
  echo "ERROR: file not found: $file" >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Parse front matter
# Front matter is the block between the first and second '---' lines.
# We capture it strictly: the file must start with '---' on line 1.
# ---------------------------------------------------------------------------
first_line=$(head -n1 "$file")
if [[ "$first_line" != "---" ]]; then
  echo "ERROR: file does not start with '---' (no front matter)" >&2
  exit 1
fi

# Extract lines between the two '---' delimiters (exclusive)
fm_raw=$(awk 'NR==1{next} /^---$/{exit} {print}' "$file")

if [[ -z "$fm_raw" ]]; then
  echo "ERROR: front matter is empty" >&2
  exit 1
fi

# Extract body: everything after the closing '---'
body=$(awk 'BEGIN{delim=0} /^---$/{delim++; next} delim>=2{print}' "$file")

# ---------------------------------------------------------------------------
# Helper: extract a single front-matter value by key (first match only)
# ---------------------------------------------------------------------------
fm_get() {
  local key="$1"
  # Match "key: value" — strips optional inline YAML comment (# ...)
  echo "$fm_raw" | awk -v k="$key" '
    $0 ~ "^" k ": " {
      sub("^" k ": *", "")
      sub(" *#.*$", "")   # strip trailing comment
      print
      exit
    }
  '
}

# ---------------------------------------------------------------------------
# 1. Allowed keys — no extras permitted
# ---------------------------------------------------------------------------
ALLOWED_KEYS=(when why what model tags)

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  # Only process lines that look like "key: value"
  if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*):[[:space:]] ]]; then
    key="${BASH_REMATCH[1]}"
    allowed=false
    for k in "${ALLOWED_KEYS[@]}"; do
      [[ "$key" == "$k" ]] && allowed=true && break
    done
    $allowed || err "unknown key '$key' (only: ${ALLOWED_KEYS[*]})"
  fi
done <<< "$fm_raw"

# ---------------------------------------------------------------------------
# 2. Required keys present
# ---------------------------------------------------------------------------
for key in "${ALLOWED_KEYS[@]}"; do
  if ! echo "$fm_raw" | grep -q "^${key}:"; then
    err "missing required key '$key'"
  fi
done

# ---------------------------------------------------------------------------
# 3. when — ISO 8601 UTC  YYYY-MM-DDTHH:MM:SSZ
# ---------------------------------------------------------------------------
when_val=$(fm_get "when")
if [[ -z "$when_val" ]]; then
  err "'when' value is empty"
elif ! [[ "$when_val" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
  err "'when' must be ISO 8601 UTC (YYYY-MM-DDTHH:MM:SSZ), got: '$when_val'"
else
  # Sanity-check the date components are in range
  IFS='-T:Z' read -r yr mo dy hr mi se <<< "$when_val"
  (( 10#$mo >= 1 && 10#$mo <= 12 )) || err "'when' month out of range: $mo"
  (( 10#$dy >= 1 && 10#$dy <= 31 )) || err "'when' day out of range: $dy"
  (( 10#$hr <= 23 ))                 || err "'when' hour out of range: $hr"
  (( 10#$mi <= 59 ))                 || err "'when' minute out of range: $mi"
  (( 10#$se <= 59 ))                 || err "'when' second out of range: $se"
fi

# ---------------------------------------------------------------------------
# 4. why — non-empty, ends with a sentence-terminating character
# ---------------------------------------------------------------------------
why_val=$(fm_get "why")
if [[ -z "$why_val" ]]; then
  err "'why' value is empty"
elif ! [[ "$why_val" =~ [.!?]$ ]]; then
  err "'why' must end with '.', '!', or '?', got: '$why_val'"
fi

# ---------------------------------------------------------------------------
# 5. what — non-empty
# ---------------------------------------------------------------------------
what_val=$(fm_get "what")
if [[ -z "$what_val" ]]; then
  err "'what' value is empty"
fi

# ---------------------------------------------------------------------------
# 6. model — non-empty, basic format check
# ---------------------------------------------------------------------------
model_val=$(fm_get "model")
if [[ -z "$model_val" ]]; then
  err "'model' value is empty"
elif ! [[ "$model_val" =~ ^[A-Za-z0-9_/.-]+$ ]]; then
  err "'model' contains unexpected characters: '$model_val'"
fi

# ---------------------------------------------------------------------------
# 7. tags — must be a non-empty inline YAML list:  [item, ...]
# ---------------------------------------------------------------------------
tags_val=$(fm_get "tags")
if [[ -z "$tags_val" ]]; then
  err "'tags' value is empty"
elif ! [[ "$tags_val" =~ ^\[.+\]$ ]]; then
  err "'tags' must be an inline YAML list like [a, b], got: '$tags_val'"
else
  # Warn if list appears empty: []
  inner="${tags_val:1:${#tags_val}-2}"
  inner="${inner//[[:space:]]/}"
  [[ -z "$inner" ]] && err "'tags' list must not be empty: $tags_val"
fi

# ---------------------------------------------------------------------------
# 8. Body — must exist and contain 1–4 sentences
#    Sentence = ends with . ! or ? followed by whitespace or end-of-text.
#    We deliberately exclude:
#      - dots in file extensions  (word.ext — no space after)
#      - dots in version numbers  (1.2.3 — surrounded by digits)
#      - dots in domain names / paths  (github.com — letter.letter, no space)
# ---------------------------------------------------------------------------
if [[ -z "${body// }" ]]; then
  err "body (after front matter) is missing or empty"
else
  # Normalise: collapse multiple spaces/newlines to single space
  flat_body=$(echo "$body" | tr '\n' ' ' | sed 's/  */ /g')

  # Count sentence-ending punctuation that is followed by a space, another
  # sentence-ending char, or sits at the very end of the string.
  sentence_count=$(echo "$flat_body" | grep -oE '[.!?]([[:space:]]|[.!?]|$)' | wc -l)
  sentence_count=$(( sentence_count ))   # trim whitespace from wc

  if (( sentence_count < 1 )); then
    err "body has no complete sentences (found $sentence_count)"
  elif (( sentence_count > 4 )); then
    err "body must be 1–4 sentences, found $sentence_count"
  fi
fi

# ---------------------------------------------------------------------------
# 9. Safety — no hardcoded secrets in body or front matter
#    Patterns: assignment-style  key=value  or  key: value  for secret nouns;
#    40-char hex strings (Git-style tokens / SHA-1 secrets).
#    Does NOT flag variable *names* or prose references.
# ---------------------------------------------------------------------------
full_text=$(cat "$file")
secret_patterns=(
  '(password|passwd|secret|api_key|private_key|access_token|auth_token)\s*[:=]\s*[^${\s][^\s]{4,}'
  '[0-9a-fA-F]{40}'   # 40-char hex (raw token / SHA-1 secret)
  'ghp_[A-Za-z0-9]{36,}'  # GitHub personal access token
  'sk-[A-Za-z0-9]{20,}'   # OpenAI-style secret key
)
for pattern in "${secret_patterns[@]}"; do
  if echo "$full_text" | grep -qiE "$pattern"; then
    err "potential hardcoded secret detected (pattern: $pattern)"
  fi
done

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
echo "Validating: $file"
echo

if (( ${#WARNINGS[@]} > 0 )); then
  for w in "${WARNINGS[@]}"; do echo "$w"; done
  echo
fi

if (( ${#ERRORS[@]} > 0 )); then
  echo "FAILED — ${#ERRORS[@]} error(s):"
  for e in "${ERRORS[@]}"; do echo "$e"; done
  exit 1
fi

echo "OK — all checks passed"
exit 0
