# Changelog

All notable changes to `sync-github-repos.sh`. Versions follow
[Semantic Versioning](https://semver.org/). This file consolidates the
worklogs formerly stored in `docs/worklogs/`.

## [3.1.0] - 2026-11-27

- **why:** Align the repository with the updated rules and agent framework; replace the worklog convention with `CHANGELOG.md`
- **model:** kompis/qwen3.8-flash-next-iq3_s
- **tags:** workflow, changelog, tooling, docs

### Added
- `CHANGELOG.md` consolidating the seven historical worklog entries
- `CODEBASE.md` path map and `CONTRIBUTING.md` developer guide
- `scripts/validate-changelog.sh` gating the changelog format
- `scripts/verify_codebase_sync.sh` checking paths cited in `CODEBASE.md`, plus `docs/memory/` decision archive

### Changed
- `scripts/bump-version.sh` now only bumps `VERSION`; it no longer writes a worklog file
- `CONTEXT.md` structure list updated to current files and script names
- `.gitignore` now excludes `todo.txt` and `done.txt`

### Removed
- `docs/worklogs/` — seven entries moved into `CHANGELOG.md`
- `scripts/validate-worklog.sh` — replaced by `scripts/validate-changelog.sh`

## [3.0.3] - 2026-03-17

- **why:** Improve readability and consistency without changing behaviour
- **model:** opencode/claude-sonnet-4-6
- **tags:** refactor, cleanup, patch

### Changed
- Code cleanup of `sync-github-repos.sh` with no behavior change: added
  `set -euo pipefail`, moved submodule handling into a `process_submodules()`
  function, simplified `jq` input with here-strings, unified arithmetic,
  removed the unused `logvv` function, reused `SCRIPT_NAME` in help output,
  and aligned summary output columns.

## [3.0.2] - 2026-02-24

- **why:** Eliminate code duplication, fix a bug with a hard-coded git binary, and normalize indentation
- **model:** github-copilot/claude-sonnet-4.6
- **tags:** refactor, bash, code-quality

### Fixed
- The submodule URL sync loop called a hard-coded `git` instead of the
  configured git command, which silently skipped HTTPS auth headers.

### Changed
- Merged the duplicated `-d`/`--dest` argument parsing into one branch.
- Normalized indentation in the submodule and update/pull blocks.

## [3.0.1] - 2026-02-24

- **why:** Resolve conflicts from the AGENTS.md workflow migration and replace a fragile validation script
- **model:** github-copilot/claude-sonnet-4.6
- **tags:** fix, refactor, workflow, validation

### Added
- `scripts/validate-worklog.sh`: checks worklog front-matter keys, formats,
  body sentences, and likely secrets. First added under a mislabeled 2.1.0
  version bump; rewritten from scratch in this release with an
  error-collection pattern and per-field validation.

### Fixed
- Restored `VERSION` in `sync-github-repos.sh` to 3.0.0 after a regression
  to 2.1.0.
- `scripts/bump-version.sh` now accepts `patch|minor|major`, writes worklog
  entries to `docs/worklogs/`, and emits correct front-matter keys.

### Removed
- Removed the stale `agent/` directory and its `.gitignore` entry.

## [3.0.0] - 2026-02-24

- **why:** Invert the submodules default for the v3.0.0 breaking change
- **model:** github-copilot/claude-haiku-4.5
- **tags:** feature, breaking-change, submodules

### Changed
- **Breaking change:** Submodules are now skipped by default. Pass `--submodules` or `-s` to initialize and update them.

### Removed
- **Breaking change:** Removed the `--no-submodules` flag. Scripts that pass it now fail with exit code 2; drop the flag to keep the same skip behavior.

### Added
- Migration guide "Migration from v2.x to v3.0" in `README.md`.
