> This file extends [common/testing.md](../common/testing.md) with Kotlin-specific content.

# Kotlin Testing

## Framework

Use `kotlin.test` for all shared/domain layer tests (KMP-compatible). Platform-specific tests may use JUnit 4/5 on Android or XCTest on iOS where needed.

## Coroutine Tests

Wrap all suspend function tests in `runTest`. Use `TestCoroutineDispatcher` or `UnconfinedTestDispatcher` to control timing.

```kotlin
@Test
fun `should return tasks when repository succeeds`() = runTest {
    val repository = FakeTaskRepository(tasks = listOf(task1, task2))
    val useCase = GetTasksUseCase(repository)

    val result = useCase()

    assertTrue(result.isSuccess)
    assertEquals(2, result.getOrThrow().size)
}
```

## Fake Repositories Over Mocks

Prefer hand-written `Fake` implementations of repository interfaces over mocking frameworks. Fakes are more readable, refactor-safe, and KMP-compatible.

```kotlin
class FakeTaskRepository(
    private val tasks: List<Task> = emptyList(),
    private val shouldFail: Boolean = false
) : TaskRepository {
    override suspend fun getAll(): List<Task> {
        if (shouldFail) error("Simulated failure")
        return tasks
    }
}
```

## Coverage Targets

| Layer                               | Minimum Coverage |
|-------------------------------------|------------------|
| Domain models                       | 90%              |
| Use cases                           | 90%              |
| ViewModels                          | 80%              |
| Repositories (interfaces via fakes) | 80%              |
| UI / Compose screens                | best-effort      |

## Test Naming

Use backtick names that read as plain English sentences describing behavior:

```kotlin
// CORRECT
@Test
fun `should return error when repository throws`() = runTest { ... }

// WRONG
@Test
fun testGetTasksError() { ... }
```

## Kotlin Testing Checklist

- [ ] All suspend functions tested with `runTest`
- [ ] Fake repositories used instead of mocking frameworks
- [ ] Test names are readable English sentences in backticks
- [ ] Domain and use case layers at 90%+ coverage
- [ ] ViewModel layer at 80%+ coverage
- [ ] No logic tested only through UI tests
