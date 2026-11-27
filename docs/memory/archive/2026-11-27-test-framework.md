---
topic: "Test framework: native Bash suites under tests/"
importance: high
category: decision
tags: [testing, tests, framework, bash]
created: 2026-11-27T20:49:59Z
model: kompis/qwen3.8-flash-next-iq3_s
---

Tests are plain Bash suites (`tests/<name>-test.sh`) run by `tests/run.sh`
with helpers in `tests/lib/assert.sh`; no external test dependencies were
added. Suites write only into `tmp/tests/` and must print a final
`RESULT: <n> passed, <n> failed, <n> skipped` line. The network integration
suite is opt-in via `RUN_INTEGRATION=1` and time-boxed so only a bounded set
of repositories is downloaded. Add new coverage by dropping a new
`*-test.sh` file in `tests/` — the runner discovers it automatically.
