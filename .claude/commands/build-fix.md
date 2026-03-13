# Build and Fix

Incrementally fix build and type errors with minimal, safe changes.

## Step 1: Identify the Failing Module

This is a Kotlin Multiplatform project with three Gradle modules:

| Module        | Build Command                                | Purpose                                           |
|---------------|----------------------------------------------|---------------------------------------------------|
| `:shared`     | `./gradlew :shared:compileKotlinDesktop`     | Shared KMP code (domain, use cases, repositories) |
| `:composeApp` | `./gradlew :composeApp:compileKotlinDesktop` | Compose Multiplatform frontend                    |
| `:server`     | `./gradlew :server:compileKotlin`            | Ktor backend                                      |
| All           | `./gradlew build 2>&1`                       | Full project build                                |

Start with `./gradlew build 2>&1` to capture all errors, then target individual modules.

## Step 2: Parse and Group Errors

1. Run the build command and capture stderr
2. Group errors by module (`:shared`, `:composeApp`, `:server`)
3. Within each module, group by file path
4. Sort by dependency order: fix `:shared` first, then `:server` and `:composeApp`
5. Count total errors for progress tracking

## Step 3: Fix Loop (One Error at a Time)

For each error:

1. **Read the file** — Use Read tool to see error context (10 lines around the error)
2. **Diagnose** — Identify root cause (missing import, wrong type, syntax error, unresolved reference)
3. **Fix minimally** — Use Edit tool for the smallest change that resolves the error
4. **Re-run build** — Target the specific module: `./gradlew :module:compileKotlin 2>&1`
5. **Move to next** — Continue with remaining errors

## Step 4: Guardrails

Stop and ask the user if:

- A fix introduces **more errors than it resolves**
- The **same error persists after 3 attempts** (likely a deeper issue)
- The fix requires **architectural changes** (not just a build fix)
- Build errors stem from **missing dependencies** (need version catalog or `build.gradle.kts` changes)
- Errors involve **Gradle plugin or version catalog misconfiguration**

## Step 5: Summary

Show results:

- Errors fixed (with file paths and modules)
- Errors remaining (if any)
- New errors introduced (should be zero)
- Suggested next steps for unresolved issues

## Recovery Strategies

| Situation                             | Action                                                                             |
|---------------------------------------|------------------------------------------------------------------------------------|
| Unresolved reference / missing import | Check if the class exists in `:shared`; add missing import                         |
| Type mismatch                         | Read both type definitions; fix the narrower type                                  |
| Missing dependency                    | Check `libs.versions.toml` and module `build.gradle.kts`; add dependency           |
| Expect/actual mismatch                | Compare `expect` declaration in `commonMain` with `actual` in platform source sets |
| Serialization error                   | Verify `@Serializable` annotation and `@SerialName` fields                         |
| Compose compiler error                | Check `@Composable` annotations and state usage                                    |
| Ktor route error                      | Verify route DSL syntax and plugin configuration in `:server`                      |
| Gradle sync failure                   | Run `./gradlew --refresh-dependencies` or check version catalog                    |
| Circular dependency                   | Identify cycle between modules; suggest extraction to `:shared`                    |
| Version conflict                      | Check `libs.versions.toml` for version constraints                                 |

Fix one error at a time for safety. Prefer minimal diffs over refactoring.

Use the **build-resolver** agent for complex dependency or migration issues.
