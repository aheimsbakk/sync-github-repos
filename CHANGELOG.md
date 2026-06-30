# Changelog

All notable changes to this project are documented in worklog files under `docs/worklogs/`.

## [3.0.3] - 2026-03-17

### Refactor

- Improved readability and consistency in `sync-github-repos.sh` with no behavioral changes.
- Added `set -euo pipefail` for stricter error handling.
- Extracted submodule logic into a `process_submodules()` function.
- Replaced `printf '%s' "$var" | jq` with here-string `jq ... <<< "$var"`.
- Unified arithmetic to `(( VAR++ ))`.
- Removed unused `logvv` definition.
- Normalized `SCRIPT_NAME` reuse in help/usage and aligned summary output columns.

## [3.0.2] - 2026-02-24

### Fixed

- Merged duplicated `-d`/`--dest` argument parsing into one `case` branch.
- Removed redundant `command -v git` guard in the submodule URL sync loop.
- Fixed a bug where the submodule loop hard-coded `"git"` instead of `"${git_cmd[@]}"`, which silently skipped HTTPS auth headers.
- Normalized inconsistent indentation in the submodule and update/pull blocks.

## [3.0.1] - 2026-02-24

### Changed

- Bumped VERSION from 3.0.0 to 3.0.1.

## [3.0.0] - 2026-02-24

### Breaking Changes

- Inverted the default submodules behavior: submodules are now **OFF** by default. Users must explicitly pass `--submodules` or `-s` to enable them.
- Removed the deprecated `--no-submodules` flag.
- Updated help text and added a migration guide in `README.md`.

### Fixed

- Resolved seven conflicts from the AGENTS.md workflow migration:
  - Corrected `scripts/bump-version.sh` to accept `patch|minor|major`, write to `docs/worklogs/`, and emit correct front-matter keys.
  - Fixed `VERSION` regression in `sync-github-repos.sh` (2.1.0 → 3.0.0).
  - Updated `CONTEXT.md` to reflect v3.0.0 flag structure.
  - Removed the stale `agent/` directory and its gitignore entry.
- Rewrote `scripts/validate-worklog.sh` with robust error-collection logic, `awk`-based front-matter and body parsing, full per-field validation, smarter sentence counting, and tighter secret-detection patterns. All 12 edge-case tests pass.

## [2.1.0] - 2026-02-24

### Added

- `scripts/validate-worklog.sh` for worklog format compliance (executable).
- Validation checks for front-matter keys, formats, body sentences, and basic secrets detection.
- Updated `CONTEXT.md` to document the new validation script.
