---
when: 2026-03-17T18:43:41Z
why: Refactor sync-github-repos.sh to improve readability and consistency without changing behaviour
what: Code cleanup of sync-github-repos.sh; version bumped to 3.0.3
model: opencode/claude-sonnet-4-6
tags: [refactor, cleanup, patch]
---

Refactored `sync-github-repos.sh` (3.0.2 → 3.0.3): added `set -euo pipefail`, extracted submodule logic into a `process_submodules()` function, replaced `printf '%s' "$var" | jq` with here-string `jq ... <<< "$var"`, unified arithmetic to `(( VAR++ ))`, removed the unused `logvv` definition, normalised `SCRIPT_NAME` reuse in help/usage, and aligned summary output columns. No behavioural changes.
