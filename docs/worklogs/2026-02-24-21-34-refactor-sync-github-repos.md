---
when: 2026-02-24T21:34:54Z
why: Eliminate code duplication, fix a bug with hard-coded git binary, and normalize indentation.
what: refactor sync-github-repos.sh for code quality (v3.0.2)
model: github-copilot/claude-sonnet-4.6
tags: [refactor, bash, code-quality]
---

Merged the duplicated `-d`/`--dest` arg parsing into one `case` branch and removed the redundant `command -v git` guard in the submodule URL sync loop. Fixed a bug where that loop hard-coded `"git"` instead of `"${git_cmd[@]}"`, silently skipping HTTPS auth headers. Normalized all inconsistent indentation in the submodule and update/pull blocks; updated `CONTEXT.md` line references. Bumped to v3.0.2.
