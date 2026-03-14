# Data Flow — Technical Documentation

**Last Updated:** 2026-03-14

## Overview

This document explains how data moves through TodoistIA — from the platform entry points down to shared domain logic, and from the HTTP client through the Ktor server.

The key idea: every platform starts the app differently, but they all converge on the same `App()` composable from `:composeApp`, which in turn calls into `:shared` for business logic.

---

## Platform Entry Points

Each platform boots the app in its own way, but all of them call the same `App()` composable from `:composeApp/commonMain`.

```mermaid
---
title: Platform Entry Points
---
%%{init: {'flowchart': {'curve': 'orthogonal'}}}%%
graph TD
    classDef entry fill:#fef9c3,stroke:#ca8a04,color:#713f12
    classDef shared fill:#dbeafe,stroke:#2563eb,color:#1e3a5f
    classDef domain fill:#dcfce7,stroke:#16a34a,color:#14532d

    MA["MainActivity.kt"]:::entry
    JVMMAIN["main.kt jvmMain"]:::entry
    WEBMAIN["main.kt webMain"]:::entry
    IOSVC["MainViewController.kt"]:::entry

    APP["App() — commonMain"]:::shared
    GREETING["Greeting().greet()"]:::domain
    PLATFORM["getPlatform() — platform actual"]:::domain

    MA --> APP
    JVMMAIN --> APP
    WEBMAIN --> APP
    IOSVC --> APP

    APP --> GREETING
    GREETING --> PLATFORM
```

> `getPlatform()` is an `expect` function declared in `:shared/commonMain`. Each platform provides its own `actual` implementation that returns the platform name (e.g. `"Android 34"`, `"iOS 17.0"`, `"JVM 17"`).

---

## Server Request Flow

The Ktor server handles HTTP requests independently. It also uses `:shared` for the `Greeting` logic and port constant.

```mermaid
---
title: Server Request Flow
---
sequenceDiagram
    participant Client as HTTP Client
    participant Server as Application.kt
    participant Shared as Greeting

    Client->>Server: GET /
    Server->>Shared: Greeting().greet()
    note right of Shared: calls getPlatform().name
    Shared-->>Server: "Hello, JVM!"
    Server-->>Client: 200 OK — "Ktor: Hello, JVM!"
```

**Server Port:** `SERVER_PORT = 8080` — defined in `shared/commonMain/Constants.kt` and shared with the server module.

---

## Expect/Actual Platform Resolution

The `Platform` interface is the `expect`/`actual` contract that lets `:shared` work on every platform without platform-specific imports.

```mermaid
---
title: Expect/Actual Platform Resolution
---
classDiagram
    classDef domain fill:#dcfce7,stroke:#16a34a,color:#14532d
    classDef platform fill:#fef9c3,stroke:#ca8a04,color:#713f12

    class Platform {
        <<interface expect>>
        +name: String
    }

    class AndroidPlatform {
        +name: String
    }
    class IOSPlatform {
        +name: String
    }
    class JvmPlatform {
        +name: String
    }
    class JsPlatform {
        +name: String
    }
    class WasmJsPlatform {
        +name: String
    }

    Platform <|.. AndroidPlatform
    Platform <|.. IOSPlatform
    Platform <|.. JvmPlatform
    Platform <|.. JsPlatform
    Platform <|.. WasmJsPlatform

    note for AndroidPlatform "actual in androidMain"
    note for IOSPlatform "actual in iosMain"
    note for JvmPlatform "actual in jvmMain"
    note for JsPlatform "actual in jsMain"
    note for WasmJsPlatform "actual in wasmJsMain"
```

---

## Module Data Flow

At the module level, data flows in one direction: from entry points down to `:shared`.

```mermaid
---
title: Module Data Flow
---
%%{init: {'flowchart': {'curve': 'orthogonal'}}}%%
flowchart LR
    classDef module fill:#dbeafe,stroke:#2563eb,color:#1e3a5f
    classDef output fill:#dcfce7,stroke:#16a34a,color:#14532d

    androidApp[":androidApp"]:::module --> composeApp[":composeApp"]:::module
    composeApp --> shared[":shared"]:::module
    server[":server"]:::module --> shared

    shared --> sharedOut["Platform name\nSERVER_PORT"]:::output
    composeApp --> composeOut["App() composable\nMainViewController"]:::output
    androidApp --> androidOut["Android APK\nMainActivity"]:::output
    server --> serverOut["REST API — port 8080"]:::output
```

---

## Related Documentation

- [Architecture overview](architecture.md)
- [AGP 9 Migration](agp9-migration.md)