Codebase Map for sync-github-repos.sh
======================================

## Directory Structure

```
/work/
├── AGENTS.md                          # Agent workflow rules
├── BLUEPRINT.md                       # Architecture specification (this file's counterpart)
├── CHANGELOG.md                       # Version history
├── README.md                          # User documentation
├── opencode.json                      # Editor configuration
├── .gitignore                         # Git ignore rules
├── sync-github-repos.sh               # Main script (entry point)
├── scripts/
│   ├── bump-version.sh                # Version bumping utility
│   └── validate-worklog.sh            # Worklog format validator
└── .opencode/
    ├── .gitignore                     # Opencode git ignore
    ├── agents/
    │   ├── facts.md                   # Facts agent definition
    │   ├── linux-expert.md            # Linux expert agent definition
    │   ├── reflect.md                 # Reflect agent definition
    │   └── vibe.md                    # Vibe agent definition
    ├── package.json                   # Opencode node dependencies
    ├── package-lock.json              # Lockfile
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
| API Endpoint Selection | `sync-github-repos.sh` (lines 218-229) |
| Paginated Fetch | `sync-github-repos.sh` (lines 235-269) |
| Submodule Handler | `sync-github-repos.sh` (lines 275-309) |
| Repository Processor | `sync-github-repos.sh` (lines 311-367) |
| Summary Reporter | `sync-github-repos.sh` (lines 373-388) |
| Version Bumping Utility | `scripts/bump-version.sh` |
| Worklog Validation | `scripts/validate-worklog.sh` |
| User Documentation | `README.md` |
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

- **Files:** kebab-case (`sync-github-repos.sh`, `bump-version.sh`, `validate-worklog.sh`)
- **Variables:** UPPER_SNAKE_CASE (`VERBOSE`, `USE_HTTPS`, `DEST_DIR`)
- **Functions:** snake_case (`usage`, `help`, `log`, `logv`, `logvv`, `process_submodules`)
- **Environment:** UPPER_SNAKE_CASE (`GITHUB_TOKEN`)

### Entry Points

| Entry Point | Path |
|---|---|
| Main script | `sync-github-repos.sh` |
| Version bump | `scripts/bump-version.sh` |
| Worklog validation | `scripts/validate-worklog.sh` |

## Version

Current version: **3.0.3** (defined in `sync-github-repos.sh` line 8)
