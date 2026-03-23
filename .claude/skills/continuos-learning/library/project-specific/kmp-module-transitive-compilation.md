---
name: KMP module transitive compilation strategy
category: project-specific
seen_count: 1
first_seen: 2026-03-22
last_seen: 2026-03-22
source: auto-extracted
---

# KMP Module Transitive Compilation Strategy

## Context
In Kotlin Multiplatform projects, you have a shared module that multiple targets depend on (android, ios, server, etc.). Understanding which module to compile and how Gradle's transitive compilation works is critical for fast CI builds.

## Pattern

### Module Dependency Model

```
shared/          ← Common code, domain models, use cases
├── src/commonMain
├── src/androidMain
├── src/iosMain
├── src/jvmMain
└── src/wasmJsMain

androidApp/      ← Android-specific wrapper
├── depends on shared
└── src/main

composeApp/      ← Multiplatform UI (Android, iOS, Desktop, Web)
├── depends on shared
├── src/androidMain
├── src/iosMain
├── src/desktopMain
└── src/jsMain (WASM)

server/          ← Server implementation
├── depends on shared
└── src/main

iosApp/          ← iOS-specific wrapper
├── depends on composeApp
└── (Swift code)
```

### Transitive Compilation

**DO NOT compile the shared module separately** in CI. Instead, compile the target that depends on it:

```bash
# WRONG — redundant, shared compiles twice
./gradlew :shared:compileKotlin
./gradlew :androidApp:compileDebugKotlin

# CORRECT — shared compiles once as a transitive dependency
./gradlew :androidApp:compileDebugKotlin
```

When you run `:androidApp:compileDebugKotlin`, Gradle automatically:
1. Detects that androidApp depends on shared
2. Compiles the shared module for the Android target
3. Compiles androidApp with the shared classes in its classpath

### Target-Specific Compilation

Each target has its own compile task because each target may have different source sets:

```bash
# Android (JVM)
./gradlew :androidApp:compileDebugKotlin

# iOS (Kotlin/Native)
./gradlew :composeApp:compileKotlinIosSimulatorArm64

# Server (JVM)
./gradlew :server:classes

# Desktop JVM
./gradlew :composeApp:compileKotlinJvm

# Web WASM
./gradlew :composeApp:compileKotlinWasmJs
```

Each compilation automatically includes shared code for that target.

### Why Not Compile Shared Separately?

1. **Redundant compilation**: Shared compiles once per target it's used in
2. **Gradle dependency resolution**: Gradle won't recompile shared if it's already in the classpath from the target compile
3. **CI efficiency**: Compiling the leaf module (target) is faster than compiling shared + all targets

## Why This Matters

- **CI speed**: One compile invocation instead of N (one per target). Saves minutes per build.
- **Correct behavior**: Shared is only compiled for the targets that actually use it
- **Dependency graph clarity**: Gradle's DAG handles everything; you don't need to manually orchestrate

## Related Patterns
- `workflow/kmp-gradle-compile-tasks` — Correct Gradle task names for each target
- `workflow/multi-target-kmp-ci-structure` — How to structure CI workflows for multi-target projects
