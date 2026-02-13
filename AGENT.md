# AGENT.md

Purpose
This file defines repository conventions for agent-originated worklogs and the required workflow agents must follow when making changes. Worklogs are the canonical history that explain when, who, why, what, and which model produced the change.

Location & filename pattern
- Store worklogs under: `agent/worklogs/`
- File name pattern: `agent/worklogs/YYYY-MM-DD-very-short-description.md`
  - Example: `agent/worklogs/2026-02-13-fix-readme-typos.md`
  - If multiple logs on the same day, ensure to update very-short-description so we don't get collitons, etc.

Worklog structure (minimal and required)
- The repository enforces a minimal, privacy-preserving worklog front matter. Worklogs MUST include a YAML front-matter block containing exactly the keys listed below and no additional keys.
- Required front matter keys (exact):
  - `date`: ISO 8601 timestamp (UTC, include `Z`)
  - `who`: actor who executed the change (agent id or human email/name)
  - `why`: one-sentence reason for the change
  - `what`: one-line summary of what was done
  - `model`: model identifier used to produce/assist the change (e.g., `github-copilot/gpt-5-mini`)
  - `tags`: list of short tags (e.g., `[docs,workflow]`)

- No other front-matter keys are allowed. Do not record commits, model versions, prompt texts, hashes, or other provenance fields in worklog YAML.

Body
- The human-readable short summary belongs in the body of the worklog file (below the closing `---`). The body should contain 1–3 short sentences describing the change, key files touched, and any follow-ups.

Template example
```yaml
---
date: 2026-02-13T16:27:00Z
who: alice@example.com
why: improve onboarding for non-technical users
what: rewrite README intro and add security notes
model: github-copilot/gpt-5-mini
tags: [docs,security]
---

Updated README to explain the container purpose in plain language, corrected typos, and added build/run instructions. Files changed: README.md. Follow-up: add CI check to enforce worklogs for agent-created commits.
```

Agent workflow (required)
1. Read recent worklogs in `agent/worklogs/` (newest → oldest) to build context for the planned task.
2. Create a new worklog file `agent/worklogs/YYYY-MM-DD-short.md` containing only the required front-matter keys (see above) and a 1–3 sentence body describing the change. This worklog MUST be created before each commit. Whenever possible create the worklog before making code or content changes; if that is impossible, create the worklog immediately after making changes but before committing. If you find this easy to forget, adopt the simple rule: always create the worklog before you run `git commit`.
3. Perform changes locally or inside the container.
4. Commit changes. Include the compact context summary in the PR description when appropriate; ensure the worklog exists in `agent/worklogs/` for every commit you push.
5. Do not add additional provenance data to the worklog file. If external audited provenance is required (commit SHA, model release), store that mapping in an access-controlled audit system outside the repository and reference it in communications, but not in worklogs.

Safety & best practices
- Never include secrets, API keys, or full prompt texts in worklogs.
- If a change touches sensitive areas, mark the worklog `tags: [sensitivity_high]` and notify a human reviewer, but do NOT add extra front-matter fields.
- Keep `why` and `what` concise — they enable reliable human review and automated compaction.

Validation & enforcement (recommended)
- Add a CI check that validates worklog YAML: files under `agent/worklogs/*.md` must include exactly the allowed keys (`date`, `who`, `why`, `what`, `model`, `tags`) and a non-empty body with 1–3 short sentences. The CI should fail on new or modified worklogs that violate this rule.
- Suggested local validator script: `scripts/validate-worklogs.py` (example available in AGENT.md history).

- Enforce semantic versioning for scripts: If a commit modifies a file that declares a top-level `VERSION` variable (for example `VERSION="0.1.0"`), the commit MUST also update that `VERSION` according to semantic versioning (MAJOR.MINOR.PATCH). Use these rules when choosing the increment:
  - PATCH: backwards-compatible bug fixes
  - MINOR: backwards-compatible new features or enhancements
  - MAJOR: incompatible API or behavioral changes

- Worklog requirement for version bumps: the worklog associated with the commit must include the new version string in the worklog body (not in front-matter) and a one-sentence rationale for the level of the version bump (patch/minor/major).

- CI enforcement suggestion: add a CI check that detects commits which modify files containing a `VERSION` declaration and verifies that the `VERSION` value was updated and matches SemVer syntax. The CI should fail the run when a script is changed without a corresponding version bump.

Automation suggestions
- Pre-commit helper: a small script to create a new worklog from a template so authors don't accidentally add forbidden keys.
- Optional: keep an off-repo audit log for sensitive provenance (commit SHAs, model versions). Reference the audit entry ID off-repo if needed; do not store it in the repo worklogs.

- Auto-version helper: If this repository includes a helper script such as `scripts/bump-version.sh` or similar, agents MUST run that helper to update `VERSION` values following SemVer when they modify files that declare a `VERSION` variable. If a helper is present but fails, agents must not commit the change until they either fix the helper or manually update `VERSION` in a new commit accompanied by the required worklog entry.

- Default policy when no helper exists: agents must update the `VERSION` variable manually following SemVer rules and include the new version string and short rationale in the worklog body. Prefer using helper scripts to avoid human error.

Migration note
- Historical worklogs that contain extra keys may be kept for audit/history. Configure CI to only enforce the rule on new or modified worklog files to avoid large-scale churn.

FAQ
- Q: Must the `model` field be present for all agent changes?
  - A: Yes — the `model` identifier (model family) must be present in the worklog front-matter. Do not include model versions or other model metadata in the repository worklog.

Where to add this file
- Save this file as `AGENT.md` at the repository root.

If you want, I can also add the validator script and a CI workflow to enforce these rules — tell me and I will prepare the patch.
