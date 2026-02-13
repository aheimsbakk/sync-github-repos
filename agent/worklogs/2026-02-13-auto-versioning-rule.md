---
date: 2026-02-13T21:18:00Z
who: assistant@openai
why: require automatic SemVer bumps for files that declare VERSION
what: add automation rule and guidance to AGENT.md to ensure version updates follow SemVer and are applied automatically when helper scripts exist
model: github-copilot/gpt-5-mini
tags: [docs,workflow]
---

Updated `AGENT.md` to require agents to run an automated version-bump helper (when present) or otherwise update `VERSION` declarations manually following SemVer rules. Files changed: `AGENT.md`.
