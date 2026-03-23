---
name: KMP Gradle compile tasks by target
category: workflow
seen_count: 1
first_seen: 2026-03-22
last_seen: 2026-03-22
source: auto-extracted
---

# KMP Gradle Compile Tasks by Target

## Context
When building CI/CD pipelines for Kotlin Multiplatform (KMP) Compose projects with multiple targets (Android, iOS, Server, Desktop, Web), you need the correct Gradle task name for each target to compile code without a full build. This is essential for fast CI verification.

## Pattern

Use **compile-only Gradle tasks** instead of full builds in CI pipelines. Each target has a specific compile task:

| Target    | Gradle Task                              | Platform      | Notes                                                    |
|-----------|------------------------------------------|---------------|----------------------------------------------------------|
| Android   | `:androidApp:compileDebugKotlin`        | JVM (Kotlin)  | Compiles app + shared transitively                       |
| iOS       | `:composeApp:compileKotlinIosSimulatorArm64` | Kotlin/Native | Requires Konan cache; run on macos-latest only           |
| Server    | `:server:classes`                        | JVM (Kotlin)  | Compiles server module + shared transitively             |
| Desktop   | `:composeApp:compileKotlinJvm`          | JVM (Kotlin)  | Compiles JVM desktop target                              |
| Webapp    | `:composeApp:compileKotlinWasmJs`       | Kotlin-to-JS  | Compiles WASM/JS web target                              |

### Key Implementation Details

1. **No need to compile shared separately**: The shared module is compiled transitively when you compile a target that depends on it. Compiling `:androidApp:compileDebugKotlin` automatically compiles shared.

2. **Use `--no-daemon` in CI**: Always include `--no-daemon` flag to avoid Gradle daemon issues in ephemeral CI environments:
   ```bash
   ./gradlew :androidApp:compileDebugKotlin --no-daemon
   ```

3. **Konan caching for iOS**: iOS (Kotlin/Native) compilation downloads and caches the Konan toolchain. Cache this to speed up repeated iOS builds:
   ```yaml
   - name: Cache Kotlin/Native (Konan)
     uses: actions/cache@v4
     with:
       path: ~/.konan
       key: konan-${{ runner.os }}-${{ hashFiles('gradle/libs.versions.toml') }}
       restore-keys: |
         konan-${{ runner.os }}-
   ```

4. **Runner selection**:
   - Android, Server, Desktop, Webapp: `ubuntu-latest` (sufficient for JVM)
   - iOS: `macos-latest` (required for Kotlin/Native compilation)

5. **Memory tuning for iOS**:
   ```yaml
   env:
     GRADLE_OPTS: "-Xmx4g"
   ```

## Why This Matters

- **Fast feedback in CI**: Compile tasks finish in 10–20 minutes instead of 45+ for full builds
- **Transitive compilation**: Avoids redundant compilation steps by leveraging Gradle's dependency graph
- **Cost reduction**: iOS on `macos-latest` is expensive; minimize time by caching Konan
- **Reduced CI latency**: Faster compilation = faster PR feedback

## Related Patterns
- `workflow/github-actions-gradle-cache-strategy` — How to optimize Gradle caching in CI
- `project-specific/kmp-module-structure` — Understanding your project's module layout
