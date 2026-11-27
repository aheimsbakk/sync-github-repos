Codebase Map for sync-github-repos.sh
======================================

## Directory Structure

```
/work/
├── AGENTS.md                          # Agent workflow rules
├── BLUEPRINT.md                       # Architecture specification (this file's counterpart)
├── CHANGELOG.md                       # Version history
├── CONTRIBUTING.md                    # Developer guide: setup, scripts, workflow
├── README.md                          # User documentation
├── opencode.json                      # Editor configuration
├── .gitignore                         # Git ignore rules
├── sync-github-repos.sh               # Main script (entry point)
├── scripts/
│   ├── bump-version.sh                # Version bumping utility
│   ├── validate-changelog.sh          # Changelog format validator
│   └── verify_codebase_sync.sh        # CODEBASE.md path verifier
├── docs/
│   └── memory/                        # Agent decision archive (INDEX.md + archive/)
├── tests/
│   ├── run.sh                         # Test framework entry point
│   ├── lib/assert.sh                  # Shared assertion helpers
│   ├── sync-cli-test.sh               # CLI contract suite (offline)
│   ├── sync-api-test.sh               # API contract suite (network, auto-skip)
│   ├── sync-integration-test.sh       # Integration suite (RUN_INTEGRATION=1)
│   └── utility-scripts-test.sh        # Utility scripts contract suite (offline)
└── .opencode/
    ├── agents/
    │   ├── facts.md                   # Facts agent definition
    │   ├── linux-expert.md            # Linux expert agent definition
    │   ├── reflect.md                 # Reflect agent definition
    │   └── vibe.md                    # Vibe agent definition
    ├── RULES.md                       # Project-specific rules
    ├── skills/
    │   ├── clear-language/SKILL.md     # Plain language skill
    │   ├── clear-language-norwegian/SKILL.md  # Norwegian plain language skill
    │   ├── memory/SKILL.md            # Memory/context skill
    │   ├── todo-txt/SKILL.md          # Todo tracking skill
    │   └── wrap-up/SKILL.md           # End-of-task ceremony skill
    └── update.sh                      # Opencode update script
```

## Physical Path Mappings

### Blueprint Components

| Blueprint Component | Physical Path |
|---|---|
| Main Script | `sync-github-repos.sh` |
| CLI Interface | `sync-github-repos.sh` (lines 16-41, 56-105) |
| Argument Parser | `sync-github-repos.sh` (lines 56-105) |
| Dependency Checker | `sync-github-repos.sh` (lines 119-126) |
| Logging Helpers | `sync-github-repos.sh` (lines 132-134) |
| Destination Setup | `sync-github-repos.sh` (lines 140-154) |
| Temp File Management | `sync-github-repos.sh` (lines 160-164) |
| Counter Initialization | `sync-github-repos.sh` (lines 170-177) |
| Authentication | `sync-github-repos.sh` (lines 182-212) |
| API Endpoint Selection | `sync-github-repos.sh` (lines 221-232) |
| Paginated Fetch | `sync-github-repos.sh` (lines 238-272) |
| Submodule Handler | `sync-github-repos.sh` (lines 278-312) |
| Repository Processor | `sync-github-repos.sh` (lines 314-370) |
| Summary Reporter | `sync-github-repos.sh` (lines 376-391) |
| Version Bumping Utility | `scripts/bump-version.sh` |
| Changelog Validation | `scripts/validate-changelog.sh` |
| Codebase Sync Verification | `scripts/verify_codebase_sync.sh` |
| Test Runner | `tests/run.sh` |
| Assertion Library | `tests/lib/assert.sh` |
| CLI Contract Suite | `tests/sync-cli-test.sh` |
| API Contract Suite | `tests/sync-api-test.sh` |
| Integration Suite | `tests/sync-integration-test.sh` |
| Utility Scripts Suite | `tests/utility-scripts-test.sh` |
| User Documentation | `README.md` |
| Developer Documentation | `CONTRIBUTING.md` |
| Changelog | `CHANGELOG.md` |

### Opencode Configuration

| Component | Physical Path |
|---|---|
| Agent Rules | `.opencode/RULES.md` |
| Agent Definitions | `.opencode/agents/*.md` |
| Skills | `.opencode/skills/*/SKILL.md` |
| Editor Config | `opencode.json` |

## Specifications

### Language

- **Bash** (version 4+, POSIX-incompatible features used: arrays, `(( ))` arithmetic, `<<<` here-strings)

### Dependency Manager

- None. The script uses system-installed commands only (`bash`, `git`, `curl`, `jq`, `mktemp`).

### Naming Conventions

- **Files:** kebab-case (`sync-github-repos.sh`, `scripts/bump-version.sh`, `scripts/validate-changelog.sh`). Exception: `scripts/verify_codebase_sync.sh` uses snake_case because `AGENTS.md` mandates that exact name.
- **Test suites:** kebab-case files with a -test.sh suffix, under `tests/`
- **Variables:** UPPER_SNAKE_CASE (`VERBOSE`, `USE_HTTPS`, `DEST_DIR`)
- **Functions:** snake_case (`usage`, `help`, `log`, `logv`, `logvv`, `process_submodules`)
- **Environment:** UPPER_SNAKE_CASE (`GITHUB_TOKEN`)

### Entry Points

| Entry Point | Path |
|---|---|
| Main script | `sync-github-repos.sh` |
| Version bump | `scripts/bump-version.sh` |
| Changelog validation | `scripts/validate-changelog.sh` |
| Codebase sync check | `scripts/verify_codebase_sync.sh` |
| Test framework | `tests/run.sh` |

## Version

Current version: **3.0.3** (defined in `sync-github-repos.sh` line 8)
