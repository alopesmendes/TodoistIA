---
description: Analyze test coverage with Kover, identify gaps, and generate missing tests to reach 80%+ coverage across shared, server, and composeApp modules.
---

# Test Coverage

Analyze test coverage using **Kotlinx Kover**, identify gaps, and generate missing tests to reach 80%+ coverage.

## Step 1: Ensure Kover is Configured

Check that the Kover Gradle plugin is applied. If not, add it:

**Root `build.gradle.kts`:**
```kotlin
plugins {
    id("org.jetbrains.kotlinx.kover") version "<latest>" apply false
}
```

**Each module's `build.gradle.kts` (`shared`, `server`, `composeApp`):**
```kotlin
plugins {
    id("org.jetbrains.kotlinx.kover")
}
```

**Root-level merged report (optional, in `build.gradle.kts`):**
```kotlin
dependencies {
    kover(project(":shared"))
    kover(project(":server"))
    kover(project(":composeApp"))
}
```

## Step 2: Run Coverage

| Scope                  | Command                                 |
|------------------------|-----------------------------------------|
| Shared module only     | `./gradlew :shared:koverHtmlReport`     |
| Server module only     | `./gradlew :server:koverHtmlReport`     |
| ComposeApp module only | `./gradlew :composeApp:koverHtmlReport` |
| All modules (merged)   | `./gradlew koverHtmlReport`             |
| Verify thresholds      | `./gradlew koverVerify`                 |
| XML report (CI)        | `./gradlew koverXmlReport`              |

**Report locations:**
- HTML: `<module>/build/reports/kover/html/index.html`
- XML: `<module>/build/reports/kover/report.xml`
- Merged: `build/reports/kover/html/index.html`

## Step 3: Configure Coverage Thresholds

Add verification rules to enforce minimum coverage per module:

```kotlin
// shared/build.gradle.kts
kover {
    reports {
        verify {
            rule {
                minBound(80) // 80% minimum line coverage
            }
        }
        filters {
            excludes {
                // Exclude generated code and UI from coverage
                classes(
                    "*.BuildConfig",
                    "*.ComposableSingletons*",
                    "*_Factory",
                    "*.di.*Module*"
                )
                packages(
                    "*.generated",
                    "*.theme"
                )
            }
        }
    }
}
```

## Step 4: Analyze Coverage Report

1. Run `./gradlew koverHtmlReport` (or per-module variant)
2. Open the HTML report in a browser
3. List files **below 80% coverage**, sorted worst-first
4. For each under-covered file, identify:
   - Untested functions or methods
   - Missing branch coverage (`when`, `if/else`, `?.let`, `?: `)
   - Dead code that inflates the denominator
   - Uncovered `catch` blocks and error paths

## Step 5: Generate Missing Tests

For each under-covered file, generate tests following this priority:

1. **Happy path** — Core functionality with valid inputs
2. **Error handling** — `Result.failure`, exceptions, null returns
3. **Edge cases** — Empty lists, `null`, boundary values, blank strings
4. **Branch coverage** — Each `when` branch, `if/else`, `?.let` / `?: ` paths

### Test Generation Rules

Follow project conventions from `rules/kotlin/testing.md`:

- Use `kotlin.test` for shared module, JUnit for server-only code
- Wrap suspend function tests in `runTest`
- Use `FakeXxxRepository` over mocking frameworks
- Use backtick test names: `` `should return error when repository throws` ``
- Use Turbine for `Flow`/`StateFlow` assertions
- Each test must be independent — no shared mutable state
- Place tests in the matching source set:
  - `shared/src/commonTest/kotlin/...` for shared code
  - `server/src/test/kotlin/...` for server code
  - `composeApp/src/commonTest/kotlin/...` for UI logic

### Coverage Targets by Layer

| Layer                      | Minimum     |
|----------------------------|-------------|
| Domain models              | 90%         |
| Use cases                  | 90%         |
| ViewModels                 | 80%         |
| Repository implementations | 80%         |
| Ktor routes / adapters     | 80%         |
| UI / Compose screens       | best-effort |
| DI modules, generated code | excluded    |

## Step 6: Verify

1. Run the full test suite — all tests must pass:
   ```bash
   ./gradlew :shared:cleanAllTests :shared:allTests
   ./gradlew :server:test
   ```
2. Re-run coverage — verify improvement:
   ```bash
   ./gradlew koverHtmlReport
   ```
3. Run threshold verification — must not fail:
   ```bash
   ./gradlew koverVerify
   ```
4. If still below 80%, repeat Step 5 for remaining gaps

## Step 7: Report

Show before/after comparison:

```
Coverage Report (Kover)
──────────────────────────────────────────────────────────
Module / Package                          Before   After
shared / domain.model                      72%      94%
shared / domain.usecase                    55%      92%
shared / presentation.tasklist             40%      85%
server / adapter.in.web                    38%      82%
server / adapter.out.persistence           60%      83%
──────────────────────────────────────────────────────────
Overall:                                   53%      87%
```

## Focus Areas

- **Use cases** — Every `invoke()` path including success, failure, and edge cases
- **ViewModels** — All state transitions (`Loading` → `Success`, `Loading` → `Error`)
- **`when` branches** — Especially on sealed classes where the compiler enforces exhaustiveness
- **`Result` handling** — Both `.onSuccess` and `.onFailure` paths
- **Repository fakes** — Ensure fakes cover the `shouldFail` path
- **Ktor routes** — All HTTP status codes (200, 201, 400, 404, 500)
- **Null / empty inputs** — `null` dates, empty task lists, blank titles
- **Coroutine error propagation** — `catch` blocks in `Flow` pipelines

## CI Integration

Add Kover verification to CI so coverage regressions fail the build:

```yaml
# In your CI pipeline
- name: Verify test coverage
  run: ./gradlew koverVerify
```

## Integration with Other Commands

- Use `/tdd` to write tests before implementation
- Use `/test-coverage` to verify and fill coverage gaps after implementation
- Use `/build-fix` if adding Kover or tests breaks the build
- Use `/code-review` to validate test quality alongside coverage numbers
