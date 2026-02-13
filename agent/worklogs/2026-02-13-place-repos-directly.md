---
date: 2026-02-13T20:55:00Z
who: assistant@openai
why: place repositories directly under the destination directory
what: remove per-user subdirectory so repos are cloned directly under `-d DIR`
model: github-copilot/gpt-5-mini
tags: [scripts,workflow]
---

Changed `get-git-repos-for.sh` so that repositories are placed directly under the destination directory provided with `-d/--dest` instead of creating a `DIR/<username>/` hierarchy. This simplifies backup layouts and matches common CLI expectations. Files changed: `get-git-repos-for.sh`, `README.md`.
