Blueprint for sync-github-repos.sh
===================================

Purpose
-------
Provide a small, dependable Bash script that clones or updates every GitHub
repository for a given user (or the authenticated user's account) to a local
directory. Simple to run, clear CLI flags, usable in automation (cron, CI,
manual runs).

Goals
-----
- Minimal runtime dependencies: `bash`, `git`, `curl`, `jq`, `mktemp`.
- Correctly handle GitHub API pagination and optional authentication via
  `GITHUB_TOKEN`.
- Default to SSH clone URLs (passwordless for SSH-key users), with an explicit
  `--use-https` override.
- Update existing clones: `git fetch --prune --tags` then attempt a safe
  `git pull --ff-only` when the working tree is clean and on a named branch.
- Configurable destination directory via `-d`/`--dest`.
- Optional `--no-submodules` flag to skip recursive submodule init/update.
- When `--use-https` is set, locally rewrite SSH/git-protocol submodule URLs
  in `.gitmodules` to HTTPS (backup kept as `.gitmodules.bak`).
- Print a summary of totals (cloned, updated, skipped, failed) at completion.
- Provide `-h`/`--help`, `-V`/`--version`, and `-v` verbosity flag.

Non-Goals
---------
- Performing destructive operations (force updates, resets).
- Managing branches beyond attempting a safe fast-forward on the current branch.
- Syncing forks vs upstreams — each repo is treated as an independent clone.
- Pushing any changes back to remote.

CLI specification
-----------------
- Name: `sync-github-repos.sh`
- Usage: `sync-github-repos.sh [options] <github-username>`
- Current version: `2.0.0`
- Options:
  - `-h`, `--help`: show help and exit
  - `-V`, `--version`: print version and exit
  - `-v`: increase verbosity (repeatable for more detail)
  - `--use-https`: use HTTPS clone URLs instead of SSH
  - `--no-submodules`: skip submodule initialization and updates
  - `-d DIR`, `--dest DIR`, `--dest=DIR`: destination base directory for all
    repositories (default: current directory `.`)

Environment Variables
---------------------
- `GITHUB_TOKEN` (optional): Bearer token used for:
  - Authenticated API calls (higher rate limits, access to private repos).
  - When the token's owner matches `<github-username>`, the script switches to
    `GET /user/repos?visibility=all&affiliation=owner,collaborator,organization_member`
    to include private and org repos.
  - Injected as an HTTP Basic Authorization header for HTTPS git operations
    (base64-encoded `x-access-token:<TOKEN>`), avoiding token exposure in URLs.

Behavior
--------
1. Validate dependencies (`git`, `curl`, `jq`, `mktemp`); exit 3 if any missing.
2. Create `DEST_DIR` (via `mkdir -p`) if needed; normalize to absolute path.
3. Determine API endpoint:
   - Default: `GET /users/<username>/repos`
   - If `GITHUB_TOKEN` is set AND the token's `/user` login matches the given
     username, use `GET /user/repos?visibility=all&affiliation=...` instead.
4. Paginate (`per_page=100`) until an empty page is returned; accumulate one
   JSON object per line in a temp file (cleaned up on EXIT).
5. Detect API errors (non-array response or `.message` field) and exit 6/7.
6. For each repository:
   - Resolve clone URL: `.ssh_url` (default) or `.clone_url` (with `--use-https`).
   - Target path: `<DEST_DIR>/<repo-name>` (no username subfolder).
   - **New repo:** `git clone <url> <path>` (with optional HTTP auth header for
     HTTPS+token). Then, unless `--no-submodules`:
     - If `.gitmodules` exists and `--use-https` is set, rewrite SSH/git://
       URLs to HTTPS in `.gitmodules`, sync config, then
       `git submodule update --init --recursive`.
   - **Existing repo:** `git fetch --prune --tags`. If clean working tree and on
     a named branch (not detached HEAD), attempt `git pull --ff-only`.
     Dirty or detached states are skipped (local work is never overwritten).
   - Path exists but is not a git repo: log error, count as failure, continue.
7. Print summary: total discovered, cloned, updated (ff), skipped (local
   changes), submodule warnings, failed operations.

Exit codes
----------
| Code | Meaning |
|------|---------|
| 0    | Completed successfully |
| 2    | Bad arguments / missing username |
| 3    | Missing required system dependencies |
| 4    | Failed to create temp file |
| 5    | `curl` network failure |
| 6    | GitHub API returned an error message |
| 7    | Unexpected (non-array) API response |
| 8    | Failed to create destination directory |

Implementation notes
--------------------
- Logging helpers: `log` (always), `logv` (verbosity ≥ 1), `logvv` (≥ 2).
- When `--use-https` + `GITHUB_TOKEN`: encode auth as Basic using `base64`,
  `python3`, or `openssl` (in that preference order); warn if none available.
- Use a `declare -a FAILED_LIST` to accumulate per-repo failure messages and
  print them to stderr at the end.

Edge cases & error handling
----------------------------
- Private repos: require `GITHUB_TOKEN` scoped to read private repos; omitted
  otherwise. Documented in README.
- Rate limiting: unauthenticated requests are limited; recommend `GITHUB_TOKEN`
  or fewer runs.
- Local modifications: only `fetch` is performed; pull is skipped.
- Clone failures: continue processing remaining repositories.
- Submodule failures: counted as warnings; processing continues.

Tests & verification
--------------------
Manual tests:
1. Run against a user with public repos (no token) — verify cloning into
   `<DEST_DIR>/<repo>`.
2. Run again — existing repos fetched and fast-forward pulled where possible.
3. Run with `--use-https` — confirm HTTPS clone URLs used.
4. Run with `GITHUB_TOKEN` set — verify private repos appear (if token permits).
5. Run with `--dest ~/some/path` — confirm destination created and used.
6. Run with `--no-submodules` — confirm submodule init is skipped.
7. Introduce local changes in a cloned repo — confirm pull is skipped.

Acceptance criteria
-------------------
- Script exits 0 on successful completion (even if some repos failed).
- Script reports errors for missing dependencies or API problems and exits
  non-zero.
- Documentation (`README.md`) explains flags, environment vars, and examples.

Files
-----
- `sync-github-repos.sh` — main script (version in `VERSION=` variable)
- `README.md` — user-facing documentation
- `scripts/bump-version.sh` — version bumping utility (takes `<new-semver>`)
- `agents/` — agent prompts and rules
- `docs/worklogs/` — worklog history (YYYY-MM-DD-HH-mm-{desc}.md)
