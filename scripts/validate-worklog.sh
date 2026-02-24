#!/usr/bin/env bash
# Validate all worklog files under docs/worklogs/ against the schema in AGENTS.md
# Exit 0 if all pass, >0 if any fail.

set -euo pipefail

WORKLOG_DIR="${1:-docs/worklogs}"
errors=0
checked=0

required_keys=(when why what model tags)

if [[ ! -d "$WORKLOG_DIR" ]]; then
  echo "No worklog directory found at $WORKLOG_DIR; nothing to validate."
  exit 0
fi

for f in "$WORKLOG_DIR"/*.md; do
  [[ -e "$f" ]] || continue
  checked=$((checked + 1))
  file_errors=0

  # Must start with ---
  if ! head -1 "$f" | grep -q '^---'; then
    echo "FAIL [$f]: missing opening '---' front matter delimiter"
    errors=$((errors + 1))
    continue
  fi

  # Extract front matter (between first and second ---)
  fm=$(awk '/^---/{found++; if(found==2) exit; next} found==1{print}' "$f")

  for key in "${required_keys[@]}"; do
    if ! echo "$fm" | grep -qE "^${key}:"; then
      echo "FAIL [$f]: missing required front matter key '${key}'"
      file_errors=$((file_errors + 1))
    fi
  done

  # Check no forbidden keys present (only allow the 5 required keys)
  while IFS= read -r line; do
    k=$(echo "$line" | sed -n 's/^\([a-z_][a-z_]*\):.*/\1/p' || true)
    [[ -z "$k" ]] && continue
    valid=0
    for rk in "${required_keys[@]}"; do
      [[ "$k" == "$rk" ]] && valid=1 && break
    done
    if [[ $valid -eq 0 ]]; then
      echo "FAIL [$f]: unexpected front matter key '${k}'"
      file_errors=$((file_errors + 1))
    fi
  done <<< "$fm"

  # 'when' must look like ISO 8601 UTC
  when_val=$(echo "$fm" | grep -E '^when:' | sed 's/when:[[:space:]]*//' | awk '{print $1}')
  if ! echo "$when_val" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'; then
    echo "FAIL [$f]: 'when' value '${when_val}' is not ISO 8601 UTC (YYYY-MM-DDTHH:MM:SSZ)"
    file_errors=$((file_errors + 1))
  fi

  # Body must not be empty (at least one non-blank line after front matter)
  body=$(awk '/^---/{found++; next} found>=2{print}' "$f" | grep -v '^[[:space:]]*$' || true)
  if [[ -z "$body" ]]; then
    echo "FAIL [$f]: body is empty"
    file_errors=$((file_errors + 1))
  fi

  if [[ $file_errors -eq 0 ]]; then
    echo "OK   [$f]"
  else
    errors=$((errors + file_errors))
  fi
done

echo
echo "Validated $checked worklog(s). Errors: $errors"
[[ $errors -eq 0 ]]
