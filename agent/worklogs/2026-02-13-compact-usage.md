---
date: 2026-02-13T20:30:00Z
who: assistant@openai
why: make CLI show compact usage when no arguments are provided
what: add short usage message to get-git-repos-for.sh and avoid printing full help on missing args
model: github-copilot/gpt-5-mini
tags: [scripts,workflow]
---

Show a compact one-line usage (and hint to use `--help`) when the script is invoked without parameters. This prevents the full help block from being displayed in non-interactive or quick-check scenarios. File changed: `get-git-repos-for.sh`.
