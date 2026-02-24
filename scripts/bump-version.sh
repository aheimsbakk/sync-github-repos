#!/usr/bin/env bash
# Bump VERSION in project files and create a worklog template
# Usage: scripts/bump-version.sh <new-semver> [file1 file2 ...]

set -euo pipefail

usage() {
  cat <<USAGE
Usage: $(basename "$0") <new-version> [files...]

Updates VERSION="..." in the specified files (defaults to sync-github-repos.sh)
and creates a worklog template under agent/worklogs documenting the bump.
USAGE
}

if [[ ${#@} -lt 1 ]]; then
  usage
  exit 2
fi

new_version=$1
shift || true

if ! [[ $new_version =~ ^[0-9]+\.[0-9]+\.[0-9]+([-+][A-Za-z0-9.-]+)?$ ]]; then
  echo "Error: version must be SemVer (e.g. 1.2.3 or 1.2.3-alpha)" >&2
  exit 3
fi

  files=("sync-github-repos.sh")
if [[ $# -gt 0 ]]; then
  files=()
  while [[ $# -gt 0 ]]; do
    files+=("$1")
    shift
  done
fi

changed=()
for f in "${files[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "Warning: file not found: $f" >&2
    continue
  fi
  # Replace the first line that defines VERSION="..."
  if grep -qE '^VERSION=.*' "$f"; then
    tmp=$(mktemp)
    # Use awk to only replace the first occurrence
    awk -v ver="$new_version" 'BEGIN{replaced=0} {
      if(!replaced && $0 ~ /^VERSION=.*$/){ print "VERSION=\"" ver "\""; replaced=1; next }
      print $0
    }' "$f" > "$tmp"
    mv "$tmp" "$f"
    changed+=("$f")
    echo "Updated VERSION in $f -> $new_version"
  else
    echo "No VERSION= line found in $f; skipping" >&2
  fi
done

if (( ${#changed[@]} == 0 )); then
  echo "No files changed; aborting worklog creation." >&2
  exit 0
fi

# Create worklog
ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
wl_dir="agent/worklogs"
mkdir -p "$wl_dir"
wl_file="$wl_dir/$(date -u +%Y-%m-%d)-bump-version-$new_version.md"
cat > "$wl_file" <<WORKLOG
---
date: $ts
who: automated-bump
why: Bump VERSION to $new_version
what: Updated VERSION in files: ${changed[*]}
model: github-copilot/gpt-5-mini
tags: [version,bump]
---

Bumped VERSION to $new_version in the following files:

$(printf '%s

Please add rationale and release notes before committing.
WORKLOG

echo "Created worklog: $wl_file"

exit 0
