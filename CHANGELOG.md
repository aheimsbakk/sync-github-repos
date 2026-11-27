# Changelog

All notable changes to `sync-github-repos.sh` and its tooling. Versions
follow [Semantic Versioning](https://semver.org/). This file consolidates
the seven entries formerly kept as worklogs in `docs/worklogs/` and is the
single release record for the project.

## [3.1.0] - 2026-11-27

- **why:** Replace the retired worklog convention with changelog gates and add a local test framework
- **model:** kompis/qwen3.8-flash-next-iq3_s
- **tags:** workflow, changelog, testing, tooling

### Added

- Test framework under `tests/`: `tests/run.sh` runner, `tests/lib/assert.sh`
  helpers, and four suites covering CLI contracts, utility scripts, the API
  contract, and a gated network integration suite (`RUN_INTEGRATION=1`).
- `scripts/validate-changelog.sh`: enforces the changelog format used by the
  wrap-up workflow.
- `scripts/verify_codebase_sync.sh`: checks every path cited in `CODEBASE.md`.
- `CONTRIBUTING.md`: developer guide with script usage and the change workflow.
- 10-second connect and 60-second total timeouts on the GitHub `curl` calls
  in `sync-github-repos.sh`.

### Changed

- `scripts/bump-version.sh` only bumps `VERSION`; it no longer writes worklog
  files and now preserves the target file's permissions.
- `CHANGELOG.md` consolidates the seven historical worklog entries with
  why/model/tags metadata and is the single release record.
- Agent framework and project rules updated to skills and permission front-matter.

### Removed

- `docs/worklogs/`: entries moved into `CHANGELOG.md`.
- `scripts/validate-worklog.sh`: replaced by `scripts/validate-changelog.sh`.

## [3.0.3] - 2026-03-17

- **why:** Improve readability and consistency without changing behavior
- **model:** opencode/claude-sonnet-4-6
- **tags:** refactor, cleanup, patch

### Changed

- Code cleanup of `sync-github-repos.sh` with no behavior change: added
  `set -euo pipefail`, moved submodule handling into a `process_submodules()`
  function, replaced `printf '%s' "$var" | jq` with here-strings, unified
  arithmetic to `(( VAR++ ))`, removed the unused `logvv` definition, reused
  `SCRIPT_NAME` in help output, and aligned summary output columns.
- Bumped VERSION from 3.0.2 to 3.0.3.

## [3.0.2] - 2026-02-24

- **why:** Eliminate code duplication, fix a bug with a hard-coded git binary, and normalize indentation
- **model:** github-copilot/claude-sonnet-4.6
- **tags:** refactor, bash, code-quality

### Fixed

- The submodule URL sync loop called a hard-coded `git` instead of the
  configured `"${git_cmd[@]}"`, silently skipping HTTPS auth headers.
- Merged the duplicated `-d`/`--dest` argument parsing into one `case` branch.

### Changed

- Normalized indentation in the submodule and update/pull blocks.
- Updated `CONTEXT.md` line references (file since removed).
- Bumped VERSION from 3.0.1 to 3.0.2.

### Removed

- Removed the redundant `command -v git` guard in the submodule URL sync loop.

## [3.0.1] - 2026-02-24

- **why:** Resolve conflicts from the AGENTS.md workflow migration and replace a fragile validation script
- **model:** github-copilot/claude-sonnet-4.6
- **tags:** fix, refactor, workflow, validation

### Fixed

- Restored `VERSION` in `sync-github-repos.sh` to 3.0.0 after a regression
  to 2.1.0.
- `scripts/bump-version.sh` now accepts `patch|minor|major`, writes worklog
  entries to `docs/worklogs/`, and emits correct front-matter keys.

### Changed

- Rewrote `scripts/validate-worklog.sh` from scratch: error-collection
  pattern, `awk`-based front-matter and body parsing, full per-field
  validation, sentence counting that ignores dots in filenames and version
  numbers, and tighter secret-detection patterns. All 12 edge-case tests passed.
- Bumped VERSION from 3.0.0 to 3.0.1.

### Removed

- Removed the stale `agent/` directory and its `.gitignore` entry.

## [3.0.0] - 2026-02-24

- **why:** Implement the breaking change that inverts the submodules default for v3.0.0
- **model:** github-copilot/claude-haiku-4.5
- **tags:** feature, breaking-change, v3.0.0, submodules

### Changed

- **Breaking change:** Submodules are now skipped by default. Pass
  `--submodules` or `-s` to initialize and update them.

### Removed

- **Breaking change:** Removed the deprecated `--no-submodules` flag.

### Added

- Migration guide "Migration from v2.x to v3.0" in `README.md`.

## [2.1.0] - 2026-02-24

- **why:** Add the missing validation script to enforce worklog format compliance before commits
- **model:** github-copilot/grok-code-fast-1
- **tags:** feature, validation, script

### Added

- `scripts/validate-worklog.sh`: checks worklog front-matter keys, formats,
  body sentences, and likely secrets (executable).
- Documented the new validation script in `CONTEXT.md` (file since removed).
