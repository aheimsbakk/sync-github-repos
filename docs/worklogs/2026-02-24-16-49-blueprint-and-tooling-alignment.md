---
when: 2026-02-24T16:49:41Z
why: Align documentation and tooling with actual v2.0.0 implementation
what: Update BLUEPRINT.md, create CONTEXT.md, refactor bump-version.sh to use patch|minor|major
model: github-copilot/claude-sonnet-4.6
tags: [docs, blueprint, tooling, bump-version]
---

Rewrote `BLUEPRINT.md` to match the v2.0.0 implementation: corrected script name, added `--dest`, `--no-submodules`, HTTPS submodule rewriting, authenticated endpoint logic, summary reporting, and exit code table. Created `CONTEXT.md` as a current-state snapshot for future agents. Refactored `scripts/bump-version.sh` to accept `patch|minor|major` (auto-incrementing from the current version) and write worklogs to `docs/worklogs/` with correct `AGENTS.md`-compliant front matter. Version remains `2.0.0` (no code changes).
