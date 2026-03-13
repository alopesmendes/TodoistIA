---
name: coding-standards
description: Universal coding standards that apply across all languages and platforms in this project. Covers naming conventions (interfaces, implementations, classes, files), code structure principles (KISS, DRY, YAGNI, early returns), comments policy, and cross-cutting patterns. Use this skill proactively when naming classes, creating interfaces, reviewing structure, or onboarding to conventions — regardless of language (Kotlin, Swift, TypeScript, etc.). For Kotlin-specific patterns (value classes, coroutines, sealed classes, flows), also consult the kotlin-coding-standards skill.
---

# Universal Coding Standards

Standards that apply across every language and platform in this project. These complement language-specific skills — they do not replace them.

> For Kotlin-specific idioms (value classes, sealed classes, coroutines, Flow, Result), see the `kotlin-coding-standards` skill.

## When to Activate

- Naming a new class, interface, file, or function in any language
- Reviewing code for consistency and maintainability
- Refactoring to follow project conventions
- Onboarding to the project's coding style

---

## Naming Conventions

### Interfaces

Interfaces always start with a capital `I`. The name describes the **capability or contract**, not the technology.

```
IUserDatasource
ITaskRepository
IAuthService
INotificationSender
```

This makes it immediately clear at a glance that a type is a contract, not a concrete thing — useful when reading dependency injection setup, constructor signatures, and use-case code.

### Implementations

Implementations of an interface get a name that follows this pattern:

```
<Subject><Qualifier><InterfaceSuffix>
```

The qualifier describes **how** or **where** the implementation works. Common qualifiers:

| Qualifier       | When to use                                         |
|-----------------|-----------------------------------------------------|
| `Local`         | Reads/writes from local storage, DB, or cache       |
| `Remote`        | Calls a network API or remote service               |
| `InMemory`      | Ephemeral, in-process storage (often used in tests) |
| `Fake` / `Mock` | Test doubles                                        |
| `Cached`        | Wraps another implementation and adds caching       |
| `Offline`       | Handles no-connectivity scenarios                   |

**Examples:**

```
IUserDatasource
├── UserLocalDatasource    — SQLite / Room / realm
├── UserRemoteDatasource   — REST API
└── UserInMemoryDatasource — test double

ITaskRepository
├── TaskRepositoryImpl     — single source, delegates to datasources
└── TaskInMemoryRepository — test double

IAuthService
├── FirebaseAuthService
└── FakeAuthService        — used in unit tests
```

When there is only one production implementation and it is unlikely to ever have another, `Impl` suffix is acceptable — but a qualified name is always preferred when the qualifier adds real information.

### Classes and Types

- **PascalCase** for all class, interface, enum, and type names — in every language.
- Name classes by **what they are**, not what they do. A class named `UserFetcher` is a hint that it should be a function or a use case instead.
- Avoid generic suffixes like `Manager`, `Handler`, `Helper`, `Util`, `Utils`. If you find yourself reaching for one, the class is probably doing too much or its purpose is unclear.

```
// BAD
UserManager
DataHelper
NetworkUtils

// GOOD
UserRepository
TaskSynchronizer
NetworkClient
```

### Functions and Methods

- **camelCase** in all languages that support it (Kotlin, TypeScript, Swift, Java).
- Use the **verb-noun** pattern: `fetchUser`, `calculateTotal`, `isValidEmail`, `handleError`.
- Boolean-returning functions or properties start with `is`, `has`, `can`, or `should`: `isCompleted`, `hasPermission`, `canEdit`.
- Avoid names that are vague about their effect: `process`, `handle`, `manage`, `doStuff`.

### Variables and Properties

- **camelCase** in all supported languages.
- Names should read like English: `userList`, `taskCount`, `isLoading`, `selectedProjectId`.
- Avoid single-letter names except in very short lambdas (`{ it }`, `{ a, b -> a + b }`) or loop counters.
- Avoid abbreviations unless they are universally understood (`url`, `id`, `dto`, `db`).

### Constants

- `SCREAMING_SNAKE_CASE` for compile-time constants.
- Group related constants in a companion object, object, or dedicated file — not scattered inline.

```kotlin
const val DEFAULT_PAGE_SIZE = 20
const val MAX_RETRY_COUNT = 3
const val REQUEST_TIMEOUT_MS = 5_000L
```

### Files

- One primary class or interface per file. File name matches the primary type.
- Extension functions that belong to a type can live in `<TypeName>Extensions.kt` / `<TypeName>+Extensions.swift`.
- Mapper files: `<TypeName>Mapper.kt` or `<TypeName>+Mapping.swift`.

---

## Code Structure Principles

### KISS — Keep It Simple
Solve today's problem. The simplest code that passes all tests and is easy to read is the right code. Complexity is a cost, not a feature.

### YAGNI — You Aren't Gonna Need It
Don't add abstractions, parameters, or configuration for requirements that don't exist yet. Add them when they're needed — not before.

### DRY — Don't Repeat Yourself
Extract logic when the same intent appears in three or more places. Don't extract just because two lines look similar — wait until the third occurrence makes the pattern undeniable.

### Early Returns Over Nesting

Guard clauses at the top of a function are easier to read than nested conditions. Fail fast, succeed late.

```kotlin
// BAD
fun process(task: Task?) {
    if (task != null) {
        if (!task.isCompleted) {
            // actual logic buried here
        }
    }
}

// GOOD
fun process(task: Task?) {
    task ?: return
    if (task.isCompleted) return
    // actual logic at the top level
}
```

### Function Length
A function should fit on one screen (~40 lines). If it doesn't, it is doing more than one thing. Split at natural boundaries and give each piece a name that describes its purpose.

### Magic Numbers and Strings
Every literal that carries domain meaning belongs in a named constant. The name is the documentation.

```kotlin
// BAD
if (priority > 3) sendAlert()
delay(500)

// GOOD
const val HIGH_PRIORITY_THRESHOLD = 3
const val ALERT_DEBOUNCE_MS = 500L

if (priority > HIGH_PRIORITY_THRESHOLD) sendAlert()
delay(ALERT_DEBOUNCE_MS)
```

---

## Comments Policy

Comment **why**, never **what**. If you need a comment to explain what the code does, the code should be rewritten to be self-explanatory first.

```kotlin
// BAD: restates the code
// increment retry count
retryCount++

// GOOD: explains a non-obvious decision
// Exponential backoff capped at 30s to avoid thundering herd on reconnect
val delayMs = minOf(1_000L * (1 shl retryCount), 30_000L)
```

Public APIs (interfaces, public functions, shared models) deserve KDoc / JSDoc when the purpose, parameters, or return value is not obvious from the name alone.

---

## Dependency Direction

Dependencies always point **inward**: infrastructure depends on domain, never the other way around.

```
domain/           ← pure business logic, no framework imports
  └── ITaskRepository  (interface)

data/             ← implements domain interfaces
  └── TaskRepositoryImpl
      └── TaskLocalDatasource
      └── TaskRemoteDatasource
```

A domain class must never import a database, network, or framework library. If it feels like it needs one, introduce an interface and inject the implementation.

---

## Checklist Before Committing

- [ ] Interfaces prefixed with `I` (`IUserDatasource`, `IAuthService`)
- [ ] Implementations qualified with `Local`, `Remote`, `InMemory`, etc. when applicable
- [ ] No `Manager`, `Handler`, `Helper`, `Utils` class names
- [ ] Boolean properties/functions start with `is`, `has`, `can`, or `should`
- [ ] Magic numbers extracted to named constants
- [ ] No nesting deeper than 2 levels — use early returns
- [ ] Functions fit on one screen; split if longer
- [ ] Comments explain *why*, not *what*
- [ ] Domain layer has no framework or infrastructure imports
