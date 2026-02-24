#!/usr/bin/env bash
# Bump VERSION in project files and create a worklog entry
# Usage: scripts/bump-version.sh <patch|minor|major>

set -euo pipefail

usage() {
  cat <<USAGE
Usage: $(basename "$0") <patch|minor|major>

Reads the current VERSION from sync-github-repos.sh, increments it according
to the bump type, writes it back, and creates a worklog template under
docs/worklogs/ documenting the bump.
USAGE
}

if [[ ${#@} -lt 1 ]]; then
  usage
  exit 2
fi

bump_type="$1"

case "$bump_type" in
  patch|minor|major) ;;
  *)
    echo "Error: bump type must be one of: patch, minor, major" >&2
    usage
    exit 3
    ;;
esac

target_file="sync-github-repos.sh"

if [[ ! -f "$target_file" ]]; then
  echo "Error: $target_file not found in current directory" >&2
  exit 4
fi

# Read current version
current_version=$(grep -E '^VERSION=' "$target_file" | head -1 | sed 's/VERSION="//;s/"//')
if [[ -z "$current_version" ]]; then
  echo "Error: could not read VERSION from $target_file" >&2
  exit 5
fi

if ! [[ "$current_version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  echo "Error: current version '$current_version' is not valid SemVer" >&2
  exit 6
fi

major="${BASH_REMATCH[1]}"
minor="${BASH_REMATCH[2]}"
patch="${BASH_REMATCH[3]}"

case "$bump_type" in
  major) major=$((major+1)); minor=0; patch=0 ;;
  minor) minor=$((minor+1)); patch=0 ;;
  patch) patch=$((patch+1)) ;;
esac

new_version="$major.$minor.$patch"

# Replace VERSION in script
tmp=$(mktemp)
awk -v ver="$new_version" 'BEGIN{replaced=0} {
  if(!replaced && $0 ~ /^VERSION=.*$/){ print "VERSION=\"" ver "\""; replaced=1; next }
  print $0
}' "$target_file" > "$tmp"
mv "$tmp" "$target_file"

echo "Updated VERSION in $target_file: $current_version -> $new_version"

# Create worklog
ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
wl_dir="docs/worklogs"
mkdir -p "$wl_dir"
wl_file="$wl_dir/$(date -u +%Y-%m-%d-%H-%M)-bump-version-$new_version.md"
cat > "$wl_file" <<WORKLOG
---
when: $ts
why: Bump version from $current_version to $new_version ($bump_type).
what: Bumped VERSION in $target_file from $current_version to $new_version
model: github-copilot/claude-sonnet-4.6
tags: [version, bump, $bump_type]
---

Bumped VERSION to $new_version ($bump_type) in $target_file. Previous version was $current_version.
WORKLOG

echo "Created worklog: $wl_file"

exit 0
