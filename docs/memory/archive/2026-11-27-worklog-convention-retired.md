---
topic: "Worklog convention retired; changelog gates in place"
importance: high
category: decision
tags: [worklogs, changelog, workflow, validation, scripts]
created: 2026-11-27T20:13:09Z
model: kompis/qwen3.8-flash-next-iq3_s
---

`docs/worklogs/` is deleted and `CHANGELOG.md` (Keep a Changelog format with
why/model/tags metadata bullets) is the single release record. Do not write
worklog files. Gates: run `scripts/validate-changelog.sh` and
`scripts/verify_codebase_sync.sh` before wrap-up; `scripts/validate-worklog.sh`
was deleted. `scripts/bump-version.sh` only bumps VERSION; the changelog entry
is prepended manually per the wrap-up skill.
