---
date: 2026-02-13T12:45:00Z
who: assistant@openai
why: allow custom destination for cloned repositories
what: add --dest option to get-git-repos-for.sh
model: github-copilot/gpt-5-mini
tags: [scripts,automation]
---

Added `-d/--dest/--dest-dir` option to `get-git-repos-for.sh` so callers can set a base directory for all cloned repositories. File changed: `get-git-repos-for.sh`. Follow-up: update `README.md` to document the new option.
