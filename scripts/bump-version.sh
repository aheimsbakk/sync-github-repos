#!/usr/bin/env bash
# Bump VERSION in project files and create a worklog template
# Usage: scripts/bump-version.sh [patch|minor|major] [file1 file2 ...]

set -euo pipefail

usage() {
  cat <<USAGE
Usage: $(basename "$0") <patch|minor|major> [files...]

Increments the VERSION="x.y.z" field in the specified files (defaults to
sync-github-repos.sh) according to SemVer rules and creates a worklog entry
under docs/worklogs/.

  patch  Increment Z in x.y.Z  (bug fixes, refactors)
  minor  Increment Y in x.Y.0  (new features, enhancements)
  major  Increment X in X.0.0  (breaking changes)
USAGE
}

if [[ ${#@} -lt 1 ]]; then
  usage
  exit 2
fi

bump_type=$1
shift || true

case "$bump_type" in
  patch|minor|major) ;;
  *)
    echo "Error: bump type must be one of: patch, minor, major" >&2
    usage
    exit 3
    ;;
esac

files=("sync-github-repos.sh")
if [[ $# -gt 0 ]]; then
  files=("$@")
fi

# Read current version from the first file that has one
current_version=""
for f in "${files[@]}"; do
  if [[ -f "$f" ]] && grep -qE '^VERSION=' "$f"; then
    current_version=$(grep -m1 -oE '[0-9]+\.[0-9]+\.[0-9]+' "$f" || true)
    break
  fi
done

if [[ -z "$current_version" ]]; then
  echo "Error: could not find VERSION=\"x.y.z\" in ${files[*]}" >&2
  exit 4
fi

# Parse and increment
IFS='.' read -r major minor patch <<< "$current_version"
case "$bump_type" in
  patch) patch=$((patch + 1)) ;;
  minor) minor=$((minor + 1)); patch=0 ;;
  major) major=$((major + 1)); minor=0; patch=0 ;;
esac
new_version="$major.$minor.$patch"

echo "Bumping $current_version -> $new_version ($bump_type)"

# Apply version to each file
changed=()
for f in "${files[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "Warning: file not found: $f" >&2
    continue
  fi
  if grep -qE '^VERSION=' "$f"; then
    tmp=$(mktemp)
    awk -v ver="$new_version" 'BEGIN{replaced=0} {
      if(!replaced && $0 ~ /^VERSION=/){ print "VERSION=\"" ver "\""; replaced=1; next }
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

# Create worklog under docs/worklogs/ (per AGENTS.md)
ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
wl_dir="docs/worklogs"
mkdir -p "$wl_dir"
wl_file="$wl_dir/$(date -u +%Y-%m-%d-%H-%M)-bump-version-$new_version.md"
cat > "$wl_file" <<WORKLOG
---
when: $ts
why: Bump VERSION to $new_version ($bump_type)
what: Updated VERSION in files: ${changed[*]}
model: github-copilot/claude-sonnet-4.6
tags: [version, bump, $bump_type]
---

Bumped VERSION from $current_version to $new_version ($bump_type) in: ${changed[*]}.
Please add rationale and release notes before committing.
WORKLOG

echo "Created worklog: $wl_file"

exit 0
