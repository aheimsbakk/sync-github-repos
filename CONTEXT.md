# CONTEXT.md — Current Project State

## Project
`sync-github-repos.sh` — a self-contained Bash script to clone or update all
GitHub repositories for a given user.

## Current Version
`2.0.0` (in `sync-github-repos.sh`, line 6)

## Key Files
| Path | Role |
|------|------|
| `sync-github-repos.sh` | Main script |
| `README.md` | User-facing docs |
| `BLUEPRINT.md` | Architecture & spec |
| `scripts/bump-version.sh` | SemVer bump utility (takes full semver string) |
| `agents/RULES.md` | Agent rules |
| `agents/WORKLOG_TEMPLATE.md` | Worklog template |
| `agents/prompts/` | Role-specific agent prompts |
| `docs/worklogs/` | Worklog history |
| `.gitignore` | Ignores `tmp/` and `.env` |

## What Was Last Implemented (v2.0.0)
- `-d`/`--dest DIR` flag for configurable destination directory
- `--no-submodules` flag to skip submodule init/update
- HTTPS submodule URL rewriting (SSH/git:// → HTTPS) when `--use-https` is set
- Authenticated git HTTPS via `http.extraHeader` (base64 Basic auth)
- Auto-switch to `/user/repos?visibility=all&...` when token owner matches username
- Summary report (total, cloned, updated, skipped, failed) at end of run
- `FAILED_LIST` array for per-repo error details
- Destination path normalization (absolute path via `realpath` or `cd && pwd`)
- Exit codes 2–8 covering all failure modes

## Known Gaps / Roadmap (from README)
- Unit/integration tests (mocking API) not yet written
- Organization support (`--org` flag) not yet implemented
- No CI pipeline

## Agent Notes
- `scripts/bump-version.sh` takes `patch|minor|major` (auto-increments from
  current version in `sync-github-repos.sh`). Outputs a worklog to `docs/worklogs/`.
- `CONTEXT.md` was absent prior to 2026-02-24 and was created during blueprint
  alignment.
- Worklogs live under `docs/worklogs/` (per `AGENTS.md`); the legacy
  `agent/worklogs/` path referenced in `AGENT.md` is superseded.
