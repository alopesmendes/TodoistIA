> This file extends [common/coding-style.md](../common/coding-style.md) with Kotlin-specific content.

# Kotlin Coding Style

## Immutability

Prefer `val` over `var` everywhere. Use `copy()` on data classes instead of mutating fields.

```kotlin
// WRONG
var name = "Alice"
name = "Bob"

// CORRECT
val name = "Alice"
val updated = user.copy(name = "Bob")
```

## Null Safety

Never use the `!!` operator — it is a crash waiting to happen. Use `?.`, `?: `, `let`, or `requireNotNull` with a meaningful message.

```kotlin
// WRONG
val length = name!!.length

// CORRECT
val length = name?.length ?: 0
```

## Named Arguments

Use named arguments when a function has more than two parameters of the same type, or when the meaning isn't obvious from position alone.

```kotlin
// WRONG
createUser("Alice", "alice@example.com", true)

// CORRECT
createUser(name = "Alice", email = "alice@example.com", isActive = true)
```

## Sealed Classes for State

Model UI state and domain results as sealed classes, not flags or nullable fields.

```kotlin
sealed class TaskState {
    data object Loading : TaskState()
    data class Success(val tasks: List<Task>) : TaskState()
    data class Error(val message: String) : TaskState()
}
```

## `when` Over `if/else` Chains

Use `when` for exhaustive branching on sealed classes or enums. The compiler will warn if you miss a case.

```kotlin
// CORRECT
when (state) {
    is TaskState.Loading -> showLoader()
    is TaskState.Success -> showTasks(state.tasks)
    is TaskState.Error -> showError(state.message)
}
```

## Kotlin Coding Style Checklist

- [ ] `val` used instead of `var` wherever possible
- [ ] No `!!` operator in production code
- [ ] Named arguments used for multi-parameter functions
- [ ] State modeled with sealed classes, not nullable fields
- [ ] `when` used for exhaustive branching
- [ ] No logic in data classes (keep them as pure data carriers)
