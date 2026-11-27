# Contributing

Developer guide: setup, scripts, and the change workflow. User documentation
lives in `README.md`.

## Setup

No build step. Requirements: Bash 4+, `git`, `curl`, `jq`. Clone the repo and
run scripts directly.

## Utility Scripts

Run all commands from the repository root.

### scripts/bump-version.sh

Increments the `VERSION` variable in `sync-github-repos.sh` by SemVer rule.
Creates no files; the changelog entry is written separately (see Workflow).

```sh
scripts/bump-version.sh patch   # 3.0.3 -> 3.0.4
scripts/bump-version.sh minor   # 3.0.3 -> 3.1.0
scripts/bump-version.sh major   # 3.0.3 -> 4.0.0
```

Exit codes: 0 success, 2 missing argument, 3 invalid bump type, 4 target
file missing, 5/6 version read or parse failure.

### scripts/validate-changelog.sh

Checks `CHANGELOG.md` against the changelog format: `# Changelog` first
line, `## [X.Y.Z] - YYYY-MM-DD` version sections, `why`/`model`/`tags`
metadata bullets, allowed category headings (Added, Changed, Fixed,
Removed, Security), descending version order, and no hardcoded secrets.

```sh
scripts/validate-changelog.sh            # validates CHANGELOG.md
scripts/validate-changelog.sh other.md   # validates another file
```

Exit codes: 0 valid, 1 validation errors, 2 usage or file error.

### scripts/verify_codebase_sync.sh

Checks that every file path cited in `CODEBASE.md` exists in the tree. Run
it after any change to directory structure or file names.

```sh
scripts/verify_codebase_sync.sh
```

Exit codes: 0 all paths exist, 1 missing paths, 2 usage or file error.

## Change Workflow

1. Update `BLUEPRINT.md` (architecture) before coding a feature or
   architectural change.
2. Implement and test.
3. Update `CODEBASE.md` paths, then run `scripts/verify_codebase_sync.sh`.
4. On wrap-up: bump the version once with `scripts/bump-version.sh`, prepend
   a changelog entry to `CHANGELOG.md` (format enforced by
   `scripts/validate-changelog.sh`), then commit with Conventional Commits
   (`<type>(<scope>): <summary>`).
5. Release history lives in `CHANGELOG.md`. The old `docs/worklogs/`
   convention and its validator are retired.

## Testing

Test framework: plain Bash suites under `tests/`, no external test
dependencies. Run from the repository root.

```sh
tests/run.sh                     # contract suites (offline + one API probe)
RUN_INTEGRATION=1 tests/run.sh   # also run the network integration suite
tests/run.sh cli                 # only suites whose file name contains "cli"
```

- Suites are files named `tests/<name>-test.sh`. Each prints a final
  `RESULT: <n> passed, <n> failed, <n> skipped` line and exits 1 on failure.
- `tests/run.sh` exit codes: 0 no failures (skips allowed), 1 failures or a
  crashed suite, 2 usage error.
- Suite side effects stay in `tmp/tests/`, which is gitignored and cleaned
  after each run.
- The integration suite is opt-in (`RUN_INTEGRATION=1`) and time-boxed: it
  clones a bounded set of public repositories for one real GitHub user, then
  verifies the update path and the dirty-worktree skip guard.
- Additionally run `bash -n` and `shellcheck -S warning` on all shell
  scripts; the project has no other test tooling.

## Workspace Hygiene

`todo.txt`, `done.txt`, `tmp/`, and `.env` are gitignored. Never gitignore
source, configuration, or documentation files.
