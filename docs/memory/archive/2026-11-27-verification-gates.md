---
topic: "Verification gates for this Bash repo"
importance: medium
category: pattern
tags: [verification, tests, shellcheck, lint, gates]
created: 2026-11-27T20:49:59Z
model: kompis/qwen3.8-flash-next-iq3_s
---

Before declaring any task done, run the full gate set: `tests/run.sh`
(test framework; add `RUN_INTEGRATION=1` for the end-to-end GitHub suite),
`bash -n` plus `shellcheck -S warning` on all shell scripts,
`scripts/validate-changelog.sh`, and `scripts/verify_codebase_sync.sh`.
No other test or lint tooling is configured.
