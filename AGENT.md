# Agent Protocol

## 1. Worklogs
**Rule:** Every change requires a worklog file.
- **Path:** `agent/worklogs/YYYY-MM-DD-HH-mm-{short-desc}.md`
  - **Date and time:** Use `date` command to fetch date and time.
- **Front Matter (Strict):** Must contain ONLY these keys:
  ```yaml
  ---
  date: 2026-02-14T12:00:00Z  # ISO 8601 UTC
  who: agent-id-or-email
  why: one-sentence reason
  what: one-line summary
  model: model-id (e.g. github-copilot/gpt-4)
  tags: [list, of, tags]
  ---
  ```
- **Body:** 1–3 sentences summarizing changes and files touched.
- **Safety:** NO secrets, API keys, or prompt text.

## 2. Workflow
1. **Context:** Read recent logs in `agent/worklogs/`.
2. **Create:** Generate the worklog file BEFORE committing.
3. **Commit:** Push changes + worklog.
   - **Commit message:** Conventional commit message format. 
4. **Diary (Optional):** If compressing context, append to `DIARY.md`:
   - Header: `## YYYY-MM-DD HH:mm`
   - Content: Bulleted summary of the session.

## 3. Versioning
- **Rule:** If a file contains `VERSION="x.y.z"`, you MUST update it (SemVer).
  - Patch: Bug fix.
  - Minor: Feature.
  - Major: Breaking change.
- **Action:** Mention the new version in the worklog body.

## 4. Enforcement
- Worklogs must validate against the schema above.
- If `scripts/bump-version.sh` exists, use it. Otherwise, update manually.