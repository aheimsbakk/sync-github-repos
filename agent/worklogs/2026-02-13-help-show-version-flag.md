---
date: 2026-02-13T21:50:00Z
who: assistant@openai
why: ensure help lists the short version flag
what: update the detailed help text in `get-git-repos-for.sh` to include `-V` alias for `--version`
model: github-copilot/gpt-5-mini
tags: [docs,cli]
---

Updated the script detailed help (`help()` output) to show the short `-V` alias alongside `--version` so users see both options when requesting `--help`. Files changed: `get-git-repos-for.sh`.
