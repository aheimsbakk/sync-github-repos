---
date: 2026-02-13T12:00:00Z
who: assistant@openai
why: provide a script to clone or update all GitHub repositories for a user
what: add blueprint, implementation script, and README for get-git-repos-for.sh
model: github-copilot/gpt-5-mini
tags: [scripts,automation]
---

Added a plan (BLUEPRINT.md), the implementation script (`get-git-repos-for.sh`), and a usage README (`README.md`). The script lists a user's GitHub repos and clones or fetches them into `./<username>/` using SSH by default; `--use-https` switches to HTTPS.
