# sync-github-repos.sh

**Clone or update all GitHub repositories for a specific user.**

## Overview
`sync-github-repos.sh` fetches all public repositories (and private ones via `GITHUB_TOKEN`) for a GitHub user. It clones new repositories or updates existing ones via fast-forward pulls.

## Requirements
* **bash** (4+)
* **git**, **curl**, **jq**

## Installation
```sh
chmod +x sync-github-repos.sh
```

## Usage
```sh
./sync-github-repos.sh [options] <github-username>
```

### Options
| Flag | Description |
| :--- | :--- |
| `-d`, `--dest <DIR>` | Destination directory (default: current directory `.` ). |
| `--use-https` | Use HTTPS clone URLs (default: SSH). |
| `--submodules`, `-s` | Enable submodule initialization/updates (default: OFF). |
| `-v` | Increase verbosity. |
| `-h`, `--help` | Show help. |
| `-V`, `--version` | Show version. |

### Environment
* **`GITHUB_TOKEN`**: Set this environment variable to increase API rate limits or access private repositories.

## Examples

**Clone public repos (SSH default):**
```sh
./sync-github-repos.sh octocat
```

**Clone via HTTPS to a specific folder:**
```sh
./sync-github-repos.sh --use-https --dest ~/backups/github octocat
```

**Clone private repos (requires token):**
```sh
GITHUB_TOKEN=ghp_... ./sync-github-repos.sh octocat
```

**Clone with submodules enabled:**
```sh
./sync-github-repos.sh --submodules -v octocat
```

## Behavior Details

* **Directory Structure:** Repositories are cloned directly into the destination `DIR/<repo>`. The script creates `DIR` if missing.
* **Pagination:** Fetches repositories in batches of 100 via GitHub REST API.
* **Updates:** Existing repos undergo `git fetch --prune --tags`. A `git pull --ff-only` is attempted only if the working tree is clean and on a branch. Dirty or detached states are skipped to protect local changes.
* **Error Handling:**
    * Missing dependencies or API errors (e.g., 404, rate limit) cause immediate exit.
    * Individual clone failures are logged to stderr; the script continues to the next repository.

### Submodules (OFF by Default)
* **Auto-Update:** Disabled by default. Use `--submodules` to enable recursive initialization and updates.
* **HTTPS Rewriting:** If `--use-https` is set, the script locally rewrites SSH submodule URLs (e.g., `git@github.com:...`) to HTTPS in `.gitmodules` to ensure access without SSH keys. This change is not pushed to origin.

## Security
* **Tokens:** Never hardcode `GITHUB_TOKEN`. Use environment variables or CI secrets.
* **Protocols:** SSH is the default to prevent credential leakage in logs.

## Migration from v2.x to v3.0

**Breaking Change:** In v3.0.0, the submodule default behavior has been inverted. Submodules are now **OFF by default** instead of auto-initializing.

### Before (v2.x)
```sh
# v2.x: Submodules auto-initialized
./sync-github-repos.sh octocat

# v2.x: Skip submodules with flag
./sync-github-repos.sh --no-submodules octocat
```

### After (v3.0.0+)
```sh
# v3.0+: Submodules are now OFF by default (same behavior as old --no-submodules)
./sync-github-repos.sh octocat

# v3.0+: Enable submodules with new flag
./sync-github-repos.sh --submodules octocat
```

**Migration Steps:**
- If your scripts rely on auto-initialized submodules, add `--submodules` or `-s` flag to maintain old behavior.
- If your scripts used `--no-submodules`, simply remove the flag (new default matches old behavior).

## Roadmap
1. Add unit/integration tests (mocking API).
2. Add CI pipeline.
3. Add Organization support (`--org`).

## License
MIT
