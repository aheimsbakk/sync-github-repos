# Codebase

Maps the architecture in `BLUEPRINT.md` to physical files. Verify this map
with `scripts/verify_codebase_sync.sh`.

## Target Stack

- Language: Bash (4+) for all executable code.
- Runtimes: `git`, `curl`, `jq` (external commands, no package manager).
- Configuration: JSON (`opencode.json`), Markdown for all docs.
- No build step; scripts run directly from the repository.

## Naming Conventions

- Files and directories: `kebab-case` (example: `scripts/bump-version.sh`).
- Fixed-name exceptions: `README.md`, `CHANGELOG.md`, `CODEBASE.md`,
  `CONTEXT.md`, `AGENTS.md`, `BLUEPRINT.md`, `CONTRIBUTING.md`.
- Shell variables: `UPPER_SNAKE_CASE` (`VERSION`, `DEST_DIR`, `VERBOSE`).

## Entry Points

- Main CLI: `sync-github-repos.sh` — clones or updates all GitHub repos for a user.
- Version tooling: `scripts/bump-version.sh` — increments `VERSION` in the main script.
- Doc gates: `scripts/validate-changelog.sh` and `scripts/verify_codebase_sync.sh`.

## Physical Path Map

### Product (Blueprint: CLI Specification, Clone/Update Logic)

| Blueprint component | Physical path |
|---|---|
| CLI contract (options, help, exit codes) | `sync-github-repos.sh` — `help()`, argument parsing loop |
| API fetch and pagination | `sync-github-repos.sh` — main processing loop |
| Submodule handling (OFF by default) | `sync-github-repos.sh` — `process_submodules()` |
| Version state | `VERSION` variable in `sync-github-repos.sh` |

### Documentation

| Role | Path |
|---|---|
| User guide | `README.md` |
| Release history (replaces the retired worklog convention) | `CHANGELOG.md` |
| Architecture specification | `BLUEPRINT.md` |
| This map | `CODEBASE.md` |
| Project context summary | `CONTEXT.md` |
| Developer guide and script usage | `CONTRIBUTING.md` |
| Agent master rules | `AGENTS.md` |

### Tooling (scripts/)

| Purpose | Path |
|---|---|
| SemVer bump of `VERSION` | `scripts/bump-version.sh` |
| CHANGELOG.md format gate | `scripts/validate-changelog.sh` |
| CODEBASE.md path verification | `scripts/verify_codebase_sync.sh` |

### Agent Framework (.opencode/)

| Role | Path |
|---|---|
| Project constraints | `.opencode/RULES.md` |
| Pair-programming agent | `.opencode/agents/vibe.md` |
| Citation/rigor agent | `.opencode/agents/facts.md` |
| Socratic agent | `.opencode/agents/reflect.md` |
| Linux/Bash advisor agent | `.opencode/agents/linux-expert.md` |
| Changelog/bump/commit procedure | `.opencode/skills/wrap-up/SKILL.md` |
| Plain-language writing rules | `.opencode/skills/clear-language/SKILL.md` |
| Norwegian language rules | `.opencode/skills/clear-language-norwegian/SKILL.md` |
| Project memory protocol | `.opencode/skills/memory/SKILL.md` |
| Task list protocol | `.opencode/skills/todo-txt/SKILL.md` |
| Framework installer/updater | `.opencode/update.sh` |
| OpenCode config | `opencode.json` |

### Memory (docs/)

| Role | Path |
|---|---|
| Memory index | `docs/memory/INDEX.md` |
| Archived decision records | `docs/memory/archive/` |

## Language Rationale

- Bash 4+ is required for arrays, `[[ ]]` conditionals, and `mapfile`, which
  the CLI and validators rely on.
- GitHub API JSON is parsed only with `jq`; no shell string parsing of API
  output.
- Validators use an error-collection pattern (collect all errors, report at
  end) instead of `set -e` early exit, so one run reports every defect.
- Changelog history replaced the per-task worklog convention; `CHANGELOG.md`
  is the single release record.
