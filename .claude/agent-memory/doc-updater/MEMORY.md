# Documentation Updater Agent Memory

## Project: TodoistIA

### Key Documentation Files
- `docs/technical/README.md` — Index of all technical documentation
- `docs/technical/ci-cd.md` — GitHub Actions workflows and ktlint configuration (NEW - 2026-03-16)
- `docs/technical/dependency-management.md` — Renovate, OWASP scans, version catalog
- `docs/technical/architecture.md` — Module structure and compilation targets
- `docs/technical/agp9-migration.md` — AGP 8 to 9 migration guide

### Latest Documentation Update (2026-03-22)
Updated CI/CD documentation to reflect compile-only architecture and workflow changes:

#### CI/CD Pipeline (Compile-Only Architecture)
1. **Pipeline stages**:
   - Lint + Audit (parallel gating jobs)
   - Compile (platform-specific, compile-only — NOT full build/packaging)
   - Code Analysis (detekt + CodeQL)
   - Tests/Coverage (not implemented yet)
   - Release/Deploy (not implemented yet)

2. **Four Principal CI Workflows** (now compile-only):
   - `ci-mobile.yml` **Android**: `:androidApp:compileDebugKotlin` on ubuntu-latest (30 min) [was: assembleDebug on macos-latest]
   - `ci-mobile.yml` **iOS**: `:composeApp:compileKotlinIosSimulatorArm64` on macos-latest (45 min) [was: placeholder]
   - `ci-desktop.yml`: `:composeApp:compileKotlinJvm` on ubuntu-latest (20 min) [was: jvmJar]
   - `ci-server.yml`: `:server:classes` on ubuntu-latest (20 min) [was: server:build]
   - `ci-webapp.yml`: `:composeApp:compileKotlinWasmJs` on ubuntu-latest (20 min) [was: wasmJsBrowserDistribution]

3. **Key Design Decisions**:
   - Android now runs on ubuntu-latest (faster, cheaper) instead of macos-latest
   - iOS stays on macos-latest (Kotlin/Native requirement)
   - All workflows inject env vars: APP_ENV, NVD_API_KEY, TODOIST_TOKEN, SERVER_PORT, SERVER_HOST
   - iOS build includes Konan cache (~/.konan) keyed on libs.versions.toml hash
   - iOS memory: GRADLE_OPTS: "-Xmx4g" (Kotlin/Native is memory-intensive)

4. **Ktlint Configuration** (unchanged):
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
