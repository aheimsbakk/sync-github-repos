---
topic: "Rule 16 file-size exceptions pending decision"
importance: medium
category: warning
tags: [rule-16, file-size, debt, sync-github-repos]
created: 2026-11-27T20:55:00Z
model: kompis/qwen3.8-flash-next-iq3_s
expires: 2027-05-31T00:00:00Z
---

`sync-github-repos.sh` (393 lines) and `.opencode/skills/clear-language-norwegian/SKILL.md`
(372 lines) both exceed the 300-line limit in RULES.md rule 16. The user deferred the
decision at v3.1.0 wrap-up. The script contradicts BLUEPRINT.md's single-file design;
splitting it requires a blueprint change first. The skill file is vendored upstream
template content that `.opencode/update.sh` overwrites, so splitting it locally is
futile. Ask again before the next change to either file.
