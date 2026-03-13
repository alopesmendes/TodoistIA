---
name: dependency-upgrade
description: Upgrade AGP, Gradle, Kotlin, Compose, and all dependencies in libs.versions.toml with tier-aware verification (patch → sync, minor → sync+build+test, major → research+orchestrate migration). Use this skill proactively whenever the user mentions upgrading, bumping, updating dependencies, checking for outdated libraries, or wants to keep the project up to date — even if they don't say "dependency upgrade" explicitly. Also triggers when the user says "update Ktor", "bump Kotlin version", "are my dependencies outdated?", "upgrade everything", or "migrate to Ktor 4".
---

# Dependency Upgrade

Orchestrate safe, tier-aware dependency upgrades for this Kotlin Multiplatform project. Every dependency upgrade follows a strict verification ladder: the higher the risk, the more verification is required.

## How It Works

This skill coordinates three layers:
1. **Detection** — the `dependency-checker` agent scans for available updates
2. **Classification** — each update is classified as patch, minor, or major
3. **Execution** — the right verification strategy is applied per tier

The user always stays in control. Changes are never committed — the user commits when satisfied.

## Upgrade Tiers

### Patch (0.0.x) — Low Risk

A patch bump (e.g., 1.5.24 → 1.5.25) contains only bug fixes. Verification is light.

**Steps:**
1. Edit `gradle/libs.versions.toml` — bump the version
2. Run `./gradlew --no-daemon :composeApp:dependencies :server:dependencies :shared:dependencies` to verify resolution
3. If sync succeeds → report success, move to next dependency
4. If sync fails → report the error to the user, do NOT rollback automatically

**Batch behavior:** All patch upgrades can be applied together in one pass, then verified once.

### Minor (0.x.0) — Medium Risk

A minor bump (e.g., 1.10.0 → 1.11.0) may add new APIs or deprecate old ones, but should not break existing code.

**Steps:**
1. Edit `gradle/libs.versions.toml` — bump the version
2. Run `./gradlew --no-daemon build` to verify compilation across all targets
3. Run `./gradlew --no-daemon allTests` to verify tests still pass
4. If build + tests succeed → report success
5. If build fails → report the error with the full output, ask the user what to do
6. If tests fail → report which tests failed, ask the user what to do

**Batch behavior:** Minor upgrades are applied one at a time. Verify each before moving to the next. This isolates which upgrade broke what.

### Major (x.0.0) — High Risk

A major bump (e.g., 3.x → 4.0) likely has breaking changes. This tier requires research, user confirmation, and a migration plan before touching any code.

**Steps:**
1. **Explain the plan** — tell the user what you're going to do and what resources you'll look up
2. **Wait for user input** — the user may provide migration guides, blog posts, or specific instructions
3. **Research** — use WebSearch and WebFetch to find:
   - Official migration guide
   - Changelog / release notes
   - KMP-specific known issues
   - Compatibility requirements (Kotlin version, AGP version, Gradle version)
4. **Present findings** — summarize what changed, what breaks, and what needs migration
5. **Get user approval** — the user confirms the plan before any code changes
6. **Execute via `/orchestrate`** — use the orchestrate command with a `refactor` or `feature` workflow:
   - `architect` agent validates the migration won't break boundaries
   - `tdd-guide` agent ensures tests cover the migration
   - `code-reviewer-*` agents review the changes
7. **Verify incrementally** — build and test after each migration step, not just at the end
8. If anything fails → report to the user, collaborate to fix it, rollback only if the user says to give up

**Batch behavior:** Major upgrades are done one at a time, never batched.

## The Coupled Group: AGP / KGP / Compose

These three dependencies are tightly coupled and must always be upgraded together:

| Key in libs.versions.toml | What it is |
|---|---|
| `kotlin` | Kotlin Gradle Plugin (KGP) |
| `agp` | Android Gradle Plugin |
| `compose-multiplatform` | JetBrains Compose Multiplatform |
| `compose-hot-reload` | Compose Hot Reload (follows Compose) |

**Rules for the coupled group:**
- The group's tier is the **highest tier** among its members (if Kotlin is minor but AGP is major → treat as major)
- Always check the compatibility matrix before upgrading:
  - KGP ↔ AGP: https://kotlinlang.org/docs/gradle-configure-project.html
  - Compose ↔ KGP: https://github.com/JetBrains/compose-multiplatform/releases
- Upgrade all members of the group in a single `libs.versions.toml` edit, then verify together
- If the latest versions are not compatible, find the latest compatible set and propose that instead

## Execution Order

When upgrading multiple dependencies (default behavior with no arguments):

```
1. Coupled group (AGP/KGP/Compose) — always first, everything else depends on it
2. Patch upgrades — batched together
3. Minor upgrades — one at a time
4. Major upgrades — one at a time, with full research cycle each
```

This order matters: the coupled group defines the Kotlin version, which constrains what other libraries can be used.

## Invocation Modes

### Mode 1: Check Only (no changes)
The user wants to see what's outdated without applying anything.

Launch the `dependency-checker` agent and present its report. Stop there.

### Mode 2: Upgrade Specific Dependency
The user names a dependency and optionally a target version.

Example: "upgrade Ktor to 4.0.0" or "bump coroutines"

1. If version is given → classify and apply the right tier strategy
2. If no version given → check latest stable, classify, proceed

### Mode 3: Upgrade All (default)
No specific dependency named — upgrade everything that's outdated.

1. Launch `dependency-checker` agent to get the full report
2. Present the report to the user for review
3. Ask: "Which upgrades do you want to apply? All, or specific ones?"
4. Execute in the order defined above (coupled group → patch → minor → major)

## Failure Handling

**On sync failure (patch):**
- Show the Gradle error output
- Ask the user: "This patch upgrade broke sync. Want me to investigate, or skip this one?"

**On build failure (minor):**
- Show the build error
- Ask: "Build failed after upgrading [dep]. Want me to try fixing it, or revert this one?"

**On test failure (minor):**
- Show which tests failed and why
- Ask: "These tests failed after upgrading [dep]. Want me to investigate, or revert?"

**On any failure (major):**
- Report the full context
- Collaborate with the user to fix
- Only revert if the user explicitly says to give up

**Revert procedure:**
```bash
git checkout -- gradle/libs.versions.toml
# If source files were changed (major upgrade):
git checkout -- .
```

## Golden Rules

1. **Never commit.** The user always commits manually.
2. **Never force-push, reset, or destroy work.**
3. **Always report before acting.** Show what will change and get confirmation.
4. **One thing at a time for minor/major.** Isolate changes to identify what broke.
5. **Batch is OK for patches.** Low risk, fast verification.
6. **The coupled group travels together.** Never upgrade Kotlin without checking AGP and Compose.
7. **For major: explain first, code later.** The user must understand and approve the migration plan.
8. **Pre-release versions are excluded** unless the project already uses one for that dependency.

## Verification Commands Reference

```bash
# Sync / dependency resolution
./gradlew --no-daemon :composeApp:dependencies :server:dependencies :shared:dependencies

# Full build (all targets)
./gradlew --no-daemon build

# All tests
./gradlew --no-daemon allTests

# Server tests only
./gradlew --no-daemon :server:test

# Shared tests only
./gradlew --no-daemon :shared:allTests

# Android debug build
./gradlew --no-daemon :composeApp:assembleDebug
```

## Integration with Other Tools

- **`dependency-checker` agent** — used for detection and classification
- **`build-resolver` agent** — can be called if a build error needs deeper diagnosis
- **`/orchestrate` command** — used for major upgrades that need a full migration workflow
- **`architect` agent** — consulted during major upgrades for boundary impact analysis
- **`tdd-guide` agent** — ensures test coverage during major migrations
