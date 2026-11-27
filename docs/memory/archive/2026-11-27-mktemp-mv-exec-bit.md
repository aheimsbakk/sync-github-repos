---
topic: "mktemp+mv clears exec bit; bump-version.sh restores it"
importance: medium
category: warning
tags: [mktemp, permissions, bump-version, pitfall]
created: 2026-11-27T20:50:00Z
model: kompis/qwen3.8-flash-next-iq3_s
---

Replacing a file via `mktemp` + `mv` silently downgrades it to mode 0600,
which stripped the exec bit from `sync-github-repos.sh` during a version
bump. Any script that rewrites another script in place must capture the
original mode (`stat -c %a`) and `chmod` it back after `mv`. The smoke-test
suite caught this regression.
