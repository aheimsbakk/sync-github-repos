#!/bin/bash

set -e

if [ $# -ne 1 ]; then
  echo "Usage: $0 <worklog-file>"
  exit 1
fi

file="$1"

if [ ! -f "$file" ]; then
  echo "File not found: $file"
  exit 1
fi

# Extract front matter
front_matter=$(sed -n '/^---$/,/^---$/p' "$file" | sed '1d;$d')

if [ -z "$front_matter" ]; then
  echo "No front matter found"
  exit 1
fi

# Check required keys
required_keys="when why what model tags"

for key in $required_keys; do
  if ! echo "$front_matter" | grep -q "^$key:"; then
    echo "Missing key: $key"
    exit 1
  fi
done

# Check no extra keys
extra_keys=$(echo "$front_matter" | grep '^[^:]*:' | sed 's/:.*//' | grep -v -E '(when|why|what|model|tags)')
if [ -n "$extra_keys" ]; then
  echo "Extra keys found: $extra_keys"
  exit 1
fi

# Check when format (basic ISO 8601 UTC)
when_value=$(echo "$front_matter" | grep '^when:' | sed 's/when: *//')
if ! echo "$when_value" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'; then
  echo "Invalid when format: $when_value"
  exit 1
fi

# Check why is one sentence (ends with .)
why_value=$(echo "$front_matter" | grep '^why:' | sed 's/why: *//')
if ! echo "$why_value" | grep -q '\.$'; then
  echo "why should end with . : $why_value"
  exit 1
fi

# what one line (no newlines)
what_value=$(echo "$front_matter" | grep '^what:' | sed 's/what: *//')
if echo "$what_value" | grep -q $'\n'; then
  echo "what should be one line"
  exit 1
fi

# model: present (no specific check)

# tags: starts with [
tags_value=$(echo "$front_matter" | grep '^tags:' | sed 's/tags: *//')
if ! echo "$tags_value" | grep -q '^\['; then
  echo "tags should be a list: $tags_value"
  exit 1
fi

# Body: after second ---
body=$(sed -n '/^---$/ {n; /^---$/ {q}; p}' "$file" | sed '1,/^---$/d')

if [ -z "$body" ]; then
  echo "No body found"
  exit 1
fi

# Count sentences (count . ! ?)
sentence_count=$(echo "$body" | grep -o '[.!?]' | wc -l)
if [ "$sentence_count" -lt 1 ] || [ "$sentence_count" -gt 4 ]; then
  echo "Body should have 1-4 sentences, found $sentence_count"
  exit 1
fi

# Basic secrets check
if echo "$body" | grep -qi 'api.*key\|token\|secret'; then
  echo "Potential secrets found in body"
  exit 1
fi

echo "Validation passed"
exit 0