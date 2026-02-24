# Project Context

## Overview
`sync-github-repos.sh` is a lightweight Bash utility that clones or updates all GitHub repositories for a specific user or organization. It uses the GitHub REST API with optional token authentication and supports SSH or HTTPS clone URLs, submodule management, and customizable destination directories.

## Current Version
3.0.0 (SemVer)

## Project Structure
- **Main script:** `sync-github-repos.sh` (351 lines, executable Bash script)
- **Documentation:** `README.md` (comprehensive user guide)
- **Version management:** `scripts/bump-version.sh` (automated version bumping)
- **Validation:** `scripts/validate-worklog.sh` (worklog format validator)
- **Architecture:** `BLUEPRINT.md`
- **Agent framework:** `agents/` directory with rules, templates, and prompts

## Dependencies
- Bash 4+
- Git
- Curl
- Jq (JSON processor)

## Key Features
1. **GitHub API Integration:** Pagination support (100 repos per page), optional GITHUB_TOKEN for private repos
2. **Clone/Update Logic:** SSH by default, with HTTPS override; fast-forward pulls for existing repos
3. **Submodule Support:** Skipped by default; `--submodules`/`-s` flag to enable; HTTPS rewriting for SSH submodule URLs
4. **Destination Management:** Flexible `-d/--dest` flag for custom output directories
5. **Verbosity Control:** `-v` flag (stackable for increasing verbosity)

## Current Flag Structure
- `-h, --help`: Help text
- `-V, --version`: Version
- `-v`: Verbosity (stackable)
- `-d, --dest DIR`: Destination directory
- `--use-https`: Use HTTPS URLs instead of SSH
- `--submodules`, `-s`: Enable submodule initialization/updates (default: OFF)

## Known Variables
- `NO_SUBMODULES`: Controls submodule behavior (default: 1=skip; 0=process when `--submodules` passed)
- `USE_HTTPS`: Controls clone URL protocol (0 = SSH, 1 = HTTPS)
- `VERBOSE`: Verbosity level (0+ increments)
- `DEST_DIR`: Destination base directory
- `VERSION`: Hardcoded in script (currently 3.0.0)

## Integration Points
- Help text generation (lines 16-35 in sync-github-repos.sh)
- Argument parsing loop (lines 42-101)
- Submodule initialization logic (lines 261-290)
- Clone command execution (line 257)
- Summary reporting (lines 334-349)
