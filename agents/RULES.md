# Master Project Rules

## I. Workflow & Scoping
1. **Protocol Alignment:** Project-specific protocols (`AGENTS.md`, `BLUEPRINT.md`) are the absolute source of truth. Read them first and NEVER bypass their defined workflows.
2. **English-Only Artifacts:** All code, variables, comments, commits, and documentation MUST be in professional English, regardless of the chat language used.
3. **Strict Scoping:** Make surgical edits only. Do NOT perform "drive-by" refactoring or change existing logic outside the immediate scope of the task.

## II. Security & Data Hygiene
4. **Secrets & Logging:** NEVER hardcode secrets; always use environment variables. Do not log sensitive user data or tokens. Use obviously fake data (e.g., `test-token-123`) for tests.
5. **Zero Trust & Execution:** Validate and sanitize ALL external inputs. Prevent injection by using parameterized queries. NEVER use `eval()` or dynamically execute raw strings.
6. **Authorization:** Assume all endpoints are private by default. Always verify ownership/authorization, not just authentication. Never store sensitive state in plain text.
7. **System & Dependency Isolation:** NEVER install dependencies globally or modify the host operating system (e.g., using `--break-system-packages` or `npm install -g`). You MUST isolate all dependencies using project-level virtual environments, containers, or local `node_modules`.

## III. Architecture & Reliability
8. **Strict Boundaries:** Maintain clear separation of concerns. Do not mix client-side and server-side execution logic.
9. **Error Handling:** NO silent failures (empty `catch` blocks). Isolate faults to prevent app crashes, and ensure graceful degradation with clear error handling.
10. **Resource Management:** Implement rate-limiting, debouncing, and strict timeouts for network requests and async tasks. Validate asynchronous state to prevent race conditions.

## IV. Development & Maintenance
11. **Test-Driven Fixes:** When fixing bugs, you MUST write a failing unit test that reproduces the issue BEFORE modifying application code.
12. **Workspace Hygiene & Gitignore:** The repository MUST remain clean. All temporary AI-generated workflow files (e.g., `.qa-error.log`), build artifacts, dependency caches, environment files (e.g., `.env`), and virtual environment directories (e.g., `venv/`, `.venv/`) MUST be explicitly declared in `.gitignore`. The agent generating the files (typically the Builder) is strictly responsible for updating `.gitignore` before task completion.
13. **Backward Compatibility:** Do not break existing callers; use fallbacks for changed signatures. Flag major component replacements with `@deprecated` instead of instant deletion.
14. **Dependencies:** Use explicit, stable package versions (no `latest` or wildcards). Always sync manifests and lockfiles. Prefer native code over adding small, unnecessary dependencies.
15. **Automation & Scripting:** If you create a new utility script (e.g., in the `scripts/` directory), you MUST use the `bash` tool to make it executable (`chmod +x <path>`). Immediately document its exact purpose, required arguments, and usage examples in `README.md`.

## V. Documentation & Formatting
16. **Strict Templating:** Strictly adhere to required formats (e.g., YAML front-matter in worklogs). Do not invent new fields, change key casing, or exceed length limits.
17. **Synchronized Docs:** Code and docs must match. Immediately update inline comments, `README.md`, developer guides, and `.env.example` when changing logic or adding variables.
