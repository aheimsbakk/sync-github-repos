Blueprint for get-git-repos-for.sh
=================================

Purpose
-------
Provide a small, dependable Bash script that clones or updates every GitHub repository for a single user (or organization-like user) to a local directory. The script will be simple to run, have clear command-line flags, and be usable in automation (CI, cron, manual runs).

Goals
-----
- Minimal runtime dependencies: `bash`, `curl`, `jq`, and `git`.
- Correctly handle GitHub API pagination and optional authentication via `GITHUB_TOKEN`.
- Default to SSH clone URLs (so users with SSH keys get passwordless clones), with an explicit `--use-https` override.
- Update existing clones by fetching/pruning tags and attempting safe fast-forward pulls when the working tree is clean.
- Provide helpful `--help`, `--version`, and `-v` verbosity flag.

Non-Goals
---------
- Performing repository-wide destructive operations (force updates, resets).
- Managing branches beyond attempting a safe fast-forward on the current branch.
- Syncing forks vs upstreams — script treats each repo as an independent clone of its origin.

CLI specification
-----------------
- Name: `get-git-repos-for.sh`
- Usage: `get-git-repos-for.sh [options] <github-username>`
- Options:
  - `-h`, `--help`: show help and exit
  - `--version`: print version and exit
  - `-v`: increase verbosity (repeat for more verbosity)
  - `--use-https`: use HTTPS clone URLs instead of SSH

Behavior
--------
1. Query GitHub API `GET /users/:username/repos` with `per_page=100` and iterate pages until no results.
2. Optionally supply an `Authorization: token $GITHUB_TOKEN` header when `GITHUB_TOKEN` is set.
3. For each repository object returned:
   - Determine clone URL: `.ssh_url` (default) or `.clone_url` (when `--use-https` present).
   - If `./<username>/<repo>` doesn't exist: `git clone --recurse-submodules` into that path.
   - If it exists and is a git repo: `git fetch --prune --tags`; if the working tree is clean, attempt `git pull --ff-only` on the current branch; otherwise skip the pull.

Implementation notes
--------------------
- Use `curl` for API calls and `jq` for JSON parsing; accumulate repo objects as one JSON object per line in a temporary file to avoid large in-memory shells.
- Detect API errors (e.g., 404 or rate limit messages) and fail with helpful message.
- Provide clear logging controlled by `-v` verbosity.

Edge cases & error handling
--------------------------
- Private repos: require `GITHUB_TOKEN` scoped to read private repos; otherwise they will be omitted (or API returns 404/403). Document this in README.
- Rate limiting: unauthenticated requests are limited; recommend `GITHUB_TOKEN` or fewer runs.
- Local modifications: script performs only fetch when local changes are present; do not overwrite local work.
- Clone failures: continue processing other repositories rather than stopping everything.

Tests & verification
--------------------
Manual tests:
1. Run against a user with a few public repos (no token) and verify cloning into `./<user>`.
2. Run again and ensure existing repos are fetched and fast-forward pulled where possible.
3. Run with `--use-https` and confirm HTTPS clone URLs are used.
4. Run with `GITHUB_TOKEN` set and verify private repos (if token permits) appear.

Acceptance criteria
-------------------
- Script exits 0 on successful completion when repos were processed or none found.
- Script reports errors for missing dependencies or API problems and exits non‑zero.
- Documentation (`README.md`) explains flags, environment vars, and examples.

Implementation tasks
--------------------
1. Write `get-git-repos-for.sh` implementing the behavior above.
2. Add `README.md` with usage, examples, environment variables, and notes about rate limits and SSH keys.
3. Add a concise agent worklog under `agent/worklogs/` documenting the change (per repository policy).
