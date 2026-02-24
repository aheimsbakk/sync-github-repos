---
when: 2026-02-24T18:45:34Z
why: Added missing validate-worklog.sh script to ensure worklog format compliance before commits.
what: Created Bash validation script with checks for front matter keys, formats, body sentences, and basic secrets detection.
model: github-copilot/grok-code-fast-1
tags: [feature, validation, script]
---

Added scripts/validate-worklog.sh with executable permissions. Updated CONTEXT.md to document the new validation script. Bumped version to 2.1.0 for this new feature.