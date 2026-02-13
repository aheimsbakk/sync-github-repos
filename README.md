# get-git-repos-for.sh

Clone or update all GitHub repositories for a given user.

Overview
--------
`get-git-repos-for.sh` is a small Bash script that fetches all public (and optionally private, when using `GITHUB_TOKEN`) repositories for a specified GitHub user and clones them into a local folder named after the user, or updates the existing clones by fetching and attempting fast-forward pulls when safe.

Requirements
------------
- bash (tested with bash 4+)
- git
- curl
- jq

Installation
------------
Make the script executable:

```sh
chmod +x get-git-repos-for.sh
```

Usage
-----

```
get-git-repos-for.sh [options] <github-username>

Options:
  -h, --help       Show help and exit
  --version        Print version and exit
  -v               Increase verbosity (can be used multiple times)
  --use-https      Use HTTPS clone URLs instead of SSH

Environment:
  GITHUB_TOKEN     Optional GitHub token to increase rate limits and access private repos
```

Examples
--------

- Clone all public repos for user `octocat` (uses SSH by default):

```sh
./get-git-repos-for.sh octocat
```

- Clone using HTTPS (useful when SSH keys aren't configured):

```sh
./get-git-repos-for.sh --use-https octocat
```

- Increase verbosity to see more logs:

```sh
./get-git-repos-for.sh -v octocat
```

- Include private repos (requires a token with repo scope):

```sh
GITHUB_TOKEN=ghp_... ./get-git-repos-for.sh octocat
```

Behavior details
----------------
- The script calls the GitHub REST API to list repositories using pagination (`per_page=100`).
- By default, clones use the repository's SSH URL (`ssh_url`). Pass `--use-https` to use the HTTPS clone URL instead.
- Existing repositories are not overwritten. The script runs `git fetch --prune --tags` for existing clones and will attempt `git pull --ff-only` only if the working tree is clean and the current HEAD points to a branch.
- If a local repo has uncommitted changes or is in a detached HEAD state, the script will skip the `git pull` to avoid overwriting local work.

Error handling & notes
----------------------
- If dependencies (`git`, `curl`, `jq`) are missing, the script will exit with an error listing the missing tools.
- If API errors (404, rate limiting) occur, the script prints the GitHub API message and exits non-zero.
- Clone errors for an individual repository are logged to stderr and the script continues with other repositories.

Security
--------
- Do not hardcode `GITHUB_TOKEN` in scripts or version control. Prefer setting it in CI secret storage or an environment before running.
- SSH is the default clone method to avoid exposing credentials in machine-readable logs.

Next steps
----------
1. Add unit/integration tests that mock GitHub API responses.

License
-------
MIT
