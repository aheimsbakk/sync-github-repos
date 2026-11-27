Blueprint for sync-github-repos.sh
===================================

## System Goals

Provide a small, dependable Bash script that clones or updates every GitHub repository for a given user (or organization-like user) to a local directory. The script is designed for manual runs, cron jobs, and CI automation.

## Goals

- Minimal runtime dependencies: `bash`, `git`, `curl`, `jq`, `mktemp`.
- Correctly handle GitHub API pagination and optional authentication via `GITHUB_TOKEN`.
- Default to SSH clone URLs; support `--use-https` override.
- Update existing clones via fetch/prune/tags and safe fast-forward pulls when the working tree is clean.
- Provide `--help`, `--version`, and `-v` verbosity flag.
- Skip submodules by default; enable with `--submodules`/`-s`.
- Provide a local test framework under `tests/` with offline contract
  suites and an opt-in network integration suite.

## Non-Goals

- Destructive repository operations (force updates, resets).
- Managing branches beyond attempting a safe fast-forward on the current branch.
- Syncing forks vs upstreams.

## Component Hierarchy

```
sync-github-repos.sh (single-file script)
├── Argument Parsing
│   ├── Short flags: -h, -V, -v, -d, -s
│   ├── Long flags: --help, --version, --dest, --use-https, --submodules
│   └── Positional: <github-username>
├── Dependency Checker
│   ├── git, curl, jq, mktemp
│   └── Exits with code 3 if any missing
├── Destination Setup
│   ├── mkdir -p
│   ├── Expand ~ to $HOME
│   └── Resolve to absolute path via realpath or pwd
├── Temporary File Management
│   ├── mktemp
│   └── trap cleanup on EXIT
├── Authentication
│   ├── GITHUB_TOKEN env var
│   ├── API header injection
│   └── git HTTP Basic Authorization header (HTTPS mode)
├── API Endpoint Selection
│   ├── Public: /users/{username}/repos
│   └── Authenticated: /user/repos (all visibility, all affiliations)
├── Repository Fetcher (Paginated)
│   ├── per_page=100
│   ├── Iterates pages until empty
│   └── Extracts: name, ssh_url, clone_url, private
├── Repository Processor (per repo)
│   ├── Clone path
│   │   ├── git clone (SSH or HTTPS)
│   │   └── Submodule init (if --submodules)
│   └── Update path
│       ├── git fetch --prune --tags
│       ├── Dirty-worktree guard (skip pull)
│       ├── Detached-HEAD guard (skip pull)
│       └── git pull --ff-only
├── Submodule Handler
│   ├── .gitmodules detection
│   ├── SSH-to-HTTPS URL rewriting (--use-https)
│   └── git submodule update --init --recursive
└── Summary Reporter
    └── Totals: Total, Cloned, Updated, Skipped, Submodule Warnings, Failed
```

## Data Flow

```
User Input (CLI args)
    │
    ▼
Argument Parser ──► USERNAME, DEST_DIR, FLAGS
    │
    ▼
Dependency Check ──► Abort if missing
    │
    ▼
Destination Setup ──► Absolute DEST_DIR
    │
    ▼
Auth Setup ──► auth_header / git_cmd prefix
    │
    ▼
API Endpoint ──► /users/{u}/repos OR /user/repos
    │
    ▼
Paginated Fetch ──► tmpfile (JSON lines: name, ssh_url, clone_url, private)
    │
    ▼
Per-Repo Loop ──► For each repo line:
    │   ├─ Clone? git clone ──► process_submodules? ──► Done
    │   └─ Update? git fetch ──► dirty? skip ──► detached? skip ──► git pull --ff-only
    │
    ▼
Summary Output ──► Exit 0
```

## State Management

### Variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `VERSION` | string | `"3.0.3"` | Script version |
| `SCRIPT_NAME` | string | basename of $0 | Script identifier |
| `VERBOSE` | int | `0` | Verbosity level |
| `USE_HTTPS` | int | `0` | HTTPS mode flag |
| `NO_SUBMODULES` | int | `1` | Skip submodules flag |
| `DEST_DIR` | string | `"."` | Destination base directory |
| `USERNAME` | string | (from CLI) | GitHub username |
| `tmpfile` | path | mktemp result | Temp file for repo list |
| `TOTAL` | int | `0` | Repos discovered |
| `CLONED` | int | `0` | Repos cloned |
| `UPDATED` | int | `0` | Repos updated |
| `SKIPPED_LOCAL` | int | `0` | Repos skipped (dirty) |
| `FAILED` | int | `0` | Failed operations |
| `SUBMODULE_WARN` | int | `0` | Submodule warnings |
| `FAILED_LIST` | array | `()` | Failure details |
| `auth_header` | array | `()` | curl auth header |
| `git_cmd` | array | `(git)` | git command with optional headers |
| `API` | string | `https://api.github.com` | API base URL |
| `PER_PAGE` | int | `100` | API pagination size |
| `curl_timeout` | array | `--connect-timeout 10 --max-time 60` | Timeout bounds on every curl call |
| `api_url` | string | `/users/{u}/repos` | API endpoint |
| `page` | int | `1` | Current API page |
| `auth_b64` | string | `""` | Base64 auth token for HTTPS |

### Exit Codes

| Code | Meaning |
|---|---|
| 0 | Success |
| 2 | Usage error (bad args, missing username) |
| 3 | Missing dependency |
| 4 | Temp file creation failed |
| 5 | API fetch failed |
| 6 | GitHub API error (message from response) |
| 7 | Unexpected API response |
| 8 | Destination directory creation failed |

## Contracts

### CLI Interface

```
Usage: sync-github-repos.sh [options] <github-username>

Options:
  -h, --help             Show help and exit
  -V, --version          Print version and exit
  -v                     Increase verbosity (repeatable)
  --use-https            Use HTTPS clone URLs instead of SSH
  --submodules, -s       Enable submodule initialization/updates (default: OFF)
  -d DIR, --dest DIR     Destination base directory (default: current directory)
```

### Payload Schema (API Response Extraction)

Each repo line in the temp file is a JSON object:

```json
{
  "name": "<string>",
  "ssh_url": "<string>",
  "clone_url": "<string>",
  "private": <boolean>
}
```

### Environment Variables

| Variable | Required | Purpose |
|---|---|---|
| `GITHUB_TOKEN` | No | GitHub personal access token for rate limits and private repos |

## Persistence

- **No persistent storage.** The script operates as a stateless batch job.
- **Temporary file:** Created via `mktemp`, cleaned up via `trap` on EXIT.
- **Side effects:** Git repositories cloned/updated in `DEST_DIR`.

## Error Boundaries

- **Fatal errors** (dependency missing, API failure, directory creation failure) cause immediate exit with a non-zero code.
- **Network timeouts:** Every API call via `curl` is bounded by a 10-second connect timeout and a 60-second total timeout, so a hung connection fails as an API error (code 5) instead of stalling the batch.
- **Per-repo failures** are collected in `FAILED_LIST`, logged to stderr, and the script continues processing remaining repositories.
- **Submodule failures** produce a warning in `FAILED_LIST` and increment `SUBMODULE_WARN` without aborting other repos.

## External Dependencies

### Runtime Commands

| Command | Used For |
|---|---|
| `bash` | Script interpreter |
| `git` | Repository cloning, fetching, updating, submodules |
| `curl` | GitHub API requests |
| `jq` | JSON parsing of API responses |
| `mktemp` | Temporary file creation |
| `realpath` | Path resolution (optional; falls back to `cd + pwd`) |
| `base64` / `python3` / `openssl` | Base64 encoding for HTTPS auth (fallback chain) |

### API Endpoints

| Endpoint | Condition | Purpose |
|---|---|---|
| `GET /users/{username}/repos` | No token or unauthenticated | Public repos only |
| `GET /user/repos?visibility=all&affiliation=owner,collaborator,organization_member` | Authenticated as the target user | All repos (public + private) |

### Authentication Flow

1. If `GITHUB_TOKEN` is set, authenticate via `Authorization: token` header.
2. Verify token ownership by calling `GET /user` and comparing `login` to `USERNAME`.
3. If authenticated, switch to `/user/repos` endpoint for private repo access.
4. For HTTPS mode with token, inject `http.extraHeader=Authorization: Basic <base64>` into git config using `x-access-token:<token>` as credentials.

## Submodule Handling

### Trigger

Enabled only when `--submodules` or `-s` flag is passed (`NO_SUBMODULES=0`).

### Process

1. Check for `.gitmodules` file in the cloned repository.
2. If `--use-https` is active, rewrite SSH URLs (`git@github.com:...` and `git://github.com/...`) to HTTPS in `.gitmodules`, with a `.bak` backup.
3. Run `git submodule sync --recursive`.
4. Run `git submodule update --init --recursive`.
5. On failure, log warning to `FAILED_LIST` and increment `SUBMODULE_WARN`.

## Test Framework

A self-contained test framework under `tests/` verifies every change with no
runtime dependencies beyond the existing ones. Default runs stay offline and
finish in seconds.

### Component Hierarchy

```
Test Framework (tests/)
├── Test Runner
│   ├── Suite discovery: files named tests/<name>-test.sh
│   ├── Optional name-filter argument
│   ├── Per-suite isolated process with a 300-second bound
│   ├── Sandbox lifecycle: create tmp/tests/ before, remove after
│   └── Aggregate totals and process exit status
├── Assertion Library (shared)
│   ├── Counters: passed, failed, skipped
│   ├── Exit-code, output-pattern, and condition assertions
│   ├── Network-availability probe (10-second bound)
│   └── Machine-parseable suite summary line
├── CLI Contract Suite (offline): argument parsing, help/version, usage-error codes
├── Utility Scripts Suite (offline): bump arithmetic, file-mode preservation,
│   changelog validator, codebase sync validator
├── API Contract Suite (network; auto-skips when offline): API error
│   propagation, destination setup, pagination request
└── Integration Suite (network; only when RUN_INTEGRATION=1): clone path,
    update path, and dirty-worktree skip guard against a real GitHub user
```

### Contracts

Runner:

```
tests/run.sh [name-filter]
Exit: 0 = no failures (skips allowed)
      1 = at least one failure or crashed suite
      2 = usage error
```

Suite: standalone executable script; loads the assertion library; emits as
its final line `RESULT: <n> passed, <n> failed, <n> skipped`; exits 1 when
the failed count is greater than zero. The runner treats a missing summary
line as a suite crash.

### State Management

- All suite side effects stay inside a per-run sandbox under `tmp/tests/`.
- Network-dependent suites probe reachability first and skip as a whole
  when unreachable, keeping default runs deterministic.
- The integration suite bounds each sync pass with a hard time box so the
  amount of downloaded repository data stays finite.

### Environment Variables

| Variable | Required | Purpose |
|---|---|---|
| `RUN_INTEGRATION` | No | Set to `1` to enable the network integration suite |
