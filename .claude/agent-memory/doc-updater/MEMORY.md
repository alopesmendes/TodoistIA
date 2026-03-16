# Documentation Updater Agent Memory

## Project: TodoistIA

### Key Documentation Files
- `docs/technical/README.md` — Index of all technical documentation
- `docs/technical/ci-cd.md` — GitHub Actions workflows and ktlint configuration (NEW - 2026-03-16)
- `docs/technical/dependency-management.md` — Renovate, OWASP scans, version catalog
- `docs/technical/architecture.md` — Module structure and compilation targets
- `docs/technical/agp9-migration.md` — AGP 8 to 9 migration guide

### Latest Documentation Update (2026-03-16)
Expanded CI/CD documentation to include Git Hooks section:

#### CI/CD Pipeline (existing)
1. **Reusable lint workflow** (`.github/workflows/lint.yml`):
   - Called via `workflow_call` from principal workflows
   - Runs `./gradlew lintCheck --no-daemon` on ubuntu-latest with JDK 17
   - 15-minute timeout, concurrency-aware

2. **Four Principal CI Workflows**:
   - `ci-mobile.yml` — Builds `:composeApp:assembleDebug` on macos-latest
   - `ci-desktop.yml` — Builds `:composeApp:jvmJar` on ubuntu-latest
   - `ci-server.yml` — Builds `:server:build` on ubuntu-latest
   - `ci-webapp.yml` — Builds `:composeApp:wasmJsBrowserDistribution` on ubuntu-latest

3. **Ktlint Configuration**:
   - Plugin: `org.jlleitschuh.gradle.ktlint` v12.2.0
   - Root config in `build.gradle.kts` (lines 102-128)
   - Per-file rules in `.editorconfig`
   - Gradle tasks: `lintCheck` and `lintFormat` (aggregate across all modules)

#### Git Hooks (NEW)
1. **Pre-commit Hook** (`scripts/git-hooks/pre-commit.sh`):
   - Runs `ktlintFormat` only on staged `.kt`/`.kts` files
   - Maps files to Gradle modules: androidApp, composeApp, server, shared
   - Root-level files trigger aggregate `ktlintFormat`
   - Re-stages formatted files automatically for commit
   - Aborts if formatting fails — must fix before retrying
   - Bash 3 compatible (works on macOS default bash)

2. **Prepare-commit-msg Hook** (`scripts/git-hooks/prepare-commit-msg.sh`):
   - Auto-formats commit messages from branch name
   - Branch convention: `prefix/number-description`
   - Extracts: prefix (feat, fix, hotfix, chore, docs, style, refactor, test, perf, ci, build, revert) and ticket number
   - Example: branch `feat/123-add-login` + input `Add login screen` → `feat(#123): Add login screen`

3. **Installation & Usage**:
   - Install: `./gradlew installGitHooks`
   - Runs `scripts/git-hooks/install-hooks.sh --force` which copies to `.git/hooks/`
   - Hooks run automatically on every commit
   - Skip if needed: `git commit --no-verify` (use sparingly)

### Documentation Standards (Mermaid, timestamps, verified file paths)
- All technical docs timestamped with `Last Updated: YYYY-MM-DD`
- Mermaid diagrams use proper titles and color-coded architectural layers
- All file paths verified to exist in the codebase
- Links cross-reference related docs (e.g., ci-cd.md → architecture.md → dependency-management.md)
