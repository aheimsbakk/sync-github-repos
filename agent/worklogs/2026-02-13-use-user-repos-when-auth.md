---
date: 2026-02-13T22:20:00Z
who: assistant@openai
why: include private repos when authenticated as the target user
what: use the `/user/repos` API endpoint when `GITHUB_TOKEN` belongs to the requested GitHub user so private repos are included
model: github-copilot/gpt-5-mini
tags: [scripts,automation]
---

When `GITHUB_TOKEN` is set and the authenticated user matches the requested username, the script now lists repositories via `/user/repos?visibility=all` instead of `/users/:username/repos`. This ensures private repositories are included in the result set for cloning/updating. Files changed: `get-git-repos-for.sh`.
