# Technical Documentation — TodoistIA

**Last Updated:** 2026-03-14

## Overview

TodoistIA is a Kotlin Multiplatform project targeting Android, iOS, Desktop (JVM), Web (Wasm/JS), and a Ktor backend. This documentation covers architecture, module structure, and the AGP 8 → 9 migration.

## Entry Points

| Platform | Entry Point                                                                    |
|----------|--------------------------------------------------------------------------------|
| Android  | `androidApp/src/main/kotlin/com/ailtontech/todoistia/MainActivity.kt`          |
| Desktop  | `composeApp/src/jvmMain/kotlin/com/ailtontech/todoistia/main.kt`               |
| Web      | `composeApp/src/webMain/kotlin/com/ailtontech/todoistia/main.kt`               |
| iOS      | `composeApp/src/iosMain/kotlin/com/ailtontech/todoistia/MainViewController.kt` |
| Server   | `server/src/main/kotlin/com/ailtontech/todoistia/Application.kt`               |

## Documentation Index

| Document                                       | Description                                              |
|------------------------------------------------|----------------------------------------------------------|
| [architecture.md](architecture.md)             | High-level module and dependency graph                   |
| [agp9-migration.md](agp9-migration.md)         | Step-by-step AGP 8 → 9 migration with diffs and diagrams |
| [data-flow.md](data-flow.md)                   | How data flows from entry points through modules         |
| [modules/androidApp.md](modules/androidApp.md) | `:androidApp` — Android application shell                |
| [modules/composeApp.md](modules/composeApp.md) | `:composeApp` — Compose Multiplatform UI                 |
| [modules/shared.md](modules/shared.md)         | `:shared` — Domain logic and platform abstractions       |
| [modules/server.md](modules/server.md)         | `:server` — Ktor backend server                          |

## Key Versions

| Tool                  | Version |
|-----------------------|---------|
| Kotlin                | 2.3.10  |
| AGP                   | 9.1.0   |
| Compose Multiplatform | 1.10.2  |
| Ktor                  | 3.4.1   |
| Compile SDK           | 36      |
| Min SDK               | 24      |

## Build Commands

```bash
# Android
./gradlew :composeApp:assembleDebug

# Desktop
./gradlew :composeApp:run

# Server
./gradlew :server:run

# Web (Wasm)
./gradlew :composeApp:wasmJsBrowserDevelopmentRun

# Web (JS)
./gradlew :composeApp:jsBrowserDevelopmentRun
```

iOS is built via the Xcode project at `/iosApp`.