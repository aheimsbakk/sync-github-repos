---
when: 2026-02-24T18:36:44Z
why: Implement breaking change to invert submodules default behavior for v3.0.0.
what: Inverted submodules default from ON to OFF, replaced --no-submodules with --submodules flag
model: github-copilot/claude-haiku-4.5
tags: [feature,breaking-change,v3.0.0,submodules]
---

Inverted the default submodules behavior in sync-github-repos.sh v3.0.0. Submodules are now OFF by default; users must explicitly pass `--submodules` or `-s` to enable them. Updated version from 2.0.0 to 3.0.0, removed the deprecated `--no-submodules` flag, updated help text, and added comprehensive migration guide in README.md. All files modified: sync-github-repos.sh, README.md.
