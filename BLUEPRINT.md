Blueprint for sync-github-repos.sh
===================================

## Current Architecture

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
- Default to **skipping submodules** unless explicitly enabled via `--submodules` flag.

Non-Goals
---------
- Performing repository-wide destructive operations (force updates, resets).
- Managing branches beyond attempting a safe fast-forward on the current branch.
- Syncing forks vs upstreams — script treats each repo as an independent clone of its origin.

## CLI Specification (Version 3.0.0+)

Name: `sync-github-repos.sh`
Usage: `sync-github-repos.sh [options] <github-username>`

### Options
- `-h`, `--help`: show help and exit
- `-V`, `--version`: print version and exit
- `-v`: increase verbosity (repeat for more verbosity)
- `-d DIR`, `--dest DIR`: destination base directory (default: `.`)
- `--use-https`: use HTTPS clone URLs instead of SSH
- `--submodules`, `-s`: **[NEW]** enable submodule initialization/updates (default: OFF)

### Removed Options
- `--no-submodules`: **[DEPRECATED]** removed in favor of inverted default

## Breaking Change Summary (Version 2.0.0 → 3.0.0)

### Default Behavior Inversion
- **OLD (v2.0.0):** Submodules initialized by default; `--no-submodules` to skip
- **NEW (v3.0.0):** Submodules **skipped by default**; `--submodules`/`-s` to enable
- **Impact:** BREAKING CHANGE requiring minor version bump (2.0.0 → 3.0.0)

### Variable Changes
- `NO_SUBMODULES` default: `0` → `1` (line 39)
- Logic inversion: `if [[ $NO_SUBMODULES -eq 0 ]]` → `if [[ $NO_SUBMODULES -eq 0 ]]` (no change in logic, just default flip)

## Implementation Plan

### Files to Modify

#### 1. **sync-github-repos.sh** (Main Script)
**Section A: Variable Initialization (line 39)**
- Change: `NO_SUBMODULES=0` → `NO_SUBMODULES=1`
- Rationale: New default is "skip submodules"

**Section B: Help Text (lines 16-35)**
- Remove line 25: `--no-submodules        Do not init/update submodules for repositories`
- Add new line: `--submodules, -s       Enable submodule initialization/updates (default: OFF)`
- Update description: "Submodules are skipped by default. Use `--submodules` to enable."
- Update usage line: Add `-s` to examples showing submodule behavior

**Section C: Argument Parsing Loop (lines 42-101)**
- Remove case block for `--no-submodules` (lines 84-87)
- Add new case blocks for `--submodules` and `-s`:
  ```
  --submodules|-s)
    NO_SUBMODULES=0
    shift
    ;;
  ```

**Section D: Summary Help Text (lines 8-14)**
- Update short usage to remove `--no-submodules` reference if present

**Section E: Clone Section (lines 261-290)**
- **NO LOGIC CHANGES REQUIRED** - the condition `if [[ $NO_SUBMODULES -eq 0 ]]` will work correctly with new default
- Submodules will only init when flag is explicitly passed

#### 2. **README.md** (User Documentation)
**Section A: Options Table (lines 23-30)**
- Remove row: `| `--no-submodules` | Skip submodule initialization/updates. |`
- Add row: `| `--submodules`, `-s` | Enable submodule initialization (default: OFF). |`
- Update table header clarity

**Section B: Behavior Details - Submodules Section (lines 61-63)**
- Change heading: "Submodules" → "Submodules (OFF by Default)"
- Update first bullet: "Auto-Update: **Disabled by default**. Use `--submodules` to enable recursive initialization and updates."
- Remove/update references to "by default" auto-updating
- Keep HTTPS rewriting section unchanged

**Section C: Examples (lines 37-50)**
- Add new example showing `--submodules` flag usage:
  ```sh
  # Clone with submodules enabled
  ./sync-github-repos.sh --submodules -v octocat
  ```

**Section D: Migration Guide (NEW - add before "Roadmap")**
Add section titled "Migration from v2.x to v3.0"
- Explain breaking change: default submodule behavior inverted
- Show old command → new command mappings:
  - Old: `./sync-github-repos.sh user` (auto-init submodules) → New: `./sync-github-repos.sh --submodules user`
  - Old: `./sync-github-repos.sh --no-submodules user` (skip) → New: `./sync-github-repos.sh user` (same effect, no flag needed)
- Recommend scripts update all invocations to explicitly use `--submodules` if submodules are required

#### 3. **Version Management**
- Bump version using `scripts/bump-version.sh minor`
- Old: 2.0.0 → New: 2.1.0 (or 3.0.0 if treating as MAJOR breaking change)
- **Decision:** Use MINOR (2.1.0) per semver for behavior changes with migration path, OR MAJOR (3.0.0) for strict breaking change interpretation

#### 4. **CONTEXT.md** (Already Created)
- Update "Current Flag Structure" section to reflect new flags
- Update "Known Variables" to note inverted default
- Add note about breaking change in v3.0.0

### Implementation Details

**Condition Logic (NO CHANGE NEEDED):**
```bash
# Old code (still correct with new default):
if [[ $NO_SUBMODULES -eq 0 ]]  # Execute submodule logic when flag is 0
```
- With old default `NO_SUBMODULES=0`, submodules auto-init
- With new default `NO_SUBMODULES=1`, submodules skip
- When user passes `--submodules`, sets `NO_SUBMODULES=0`, submodules init
- Logic remains identical; only variable initialization flips

### Testing Strategy

1. **Default Behavior:** Run without flags → should NOT initialize submodules
2. **Explicit Enable:** Run with `--submodules` → should initialize submodules
3. **Short Form:** Run with `-s` → should work identically to `--submodules`
4. **Help Text:** Verify `--help` shows new flag and OFF-by-default behavior
5. **Error Cases:** Verify `--no-submodules` is no longer recognized (should error)
6. **Migration Validation:** Test before/after scripts with token and HTTPS settings

### Backward Compatibility Notes

- **Migration Path:** Scripts using `--no-submodules` will fail (flag no longer exists)
  - Users must either: (a) remove flag (new default matches old behavior), or (b) add `--submodules` if submodules are required
- **No Silent Failures:** Unrecognized flag causes exit code 2 (existing behavior preserved)
- **Documentation:** README migration guide explains upgrade path clearly

---

## Archive

### v2.0.0 Flag Structure
- `--no-submodules`: Skip submodule initialization (set `NO_SUBMODULES=1`)
- Default behavior: Submodules auto-initialized (default `NO_SUBMODULES=0`)

### Legacy Requirements (Pre-v3.0.0)
- Auto-init submodules by default
- Allow `--no-submodules` to disable
- Recursively process submodules with HTTPS rewriting
