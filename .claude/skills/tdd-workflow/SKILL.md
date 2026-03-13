---
name: tdd-workflow
description: TDD workflow for Kotlin Multiplatform (KMP) projects. Use this skill proactively when writing new features, fixing bugs, or refactoring — especially for business logic in the shared module. Enforces Red-Green-Refactor with 80%+ coverage on domain, use case, and ViewModel layers using kotlin.test. Trigger whenever the user introduces a new feature, business rule, domain model, use case, ViewModel, or repository interface — even if they don't explicitly ask for "TDD" or "tests."
origin: ECC
tools: Read, Write, Edit, Bash, Grep, Glob
---

# TDD Workflow — Kotlin Multiplatform

This skill enforces test-driven development for KMP projects using `kotlin.test`. The focus is on unit tests in `commonTest`, keeping tests platform-agnostic and fast.

## Project Structure

```
shared/
  src/
    commonMain/kotlin/   ← business logic: domain, use cases, repositories (interfaces)
    commonTest/kotlin/   ← unit tests (kotlin.test, platform-agnostic)

composeApp/
  src/
    commonMain/kotlin/   ← ViewModels, UI state
    commonTest/kotlin/   ← ViewModel unit tests
```

Tests live in `commonTest` so they run on all targets (JVM, Android, iOS, JS).

## Core Principles

1. **Tests first** — write test method names before any implementation.
2. **Red → Green → Refactor** — each step is deliberate; don't skip ahead.
3. **80%+ coverage** on domain, use case, and ViewModel layers.
4. **No platform dependencies in tests** — use interfaces + fakes, not Mockito or platform-specific mocks.

## TDD Cycle

### Step 1 — Scaffold test method names (RED setup)

Before writing any implementation, list all test method names grouped by layer. Consult the `tdd-guide` agent for this step — it will produce the full test scaffold and ask you to validate the names.

Example output from tdd-guide:
```kotlin
// shared/src/commonTest/kotlin/.../domain/TodoUseCaseTest.kt

class AddTodoUseCaseTest {
    fun `given valid title when adding todo then succeeds`() {}
    fun `given blank title when adding todo then throws IllegalArgumentException`() {}
    fun `given valid todo when adding then persists via repository`() {}
    fun `given existing todo when adding duplicate then returns failure`() {}
}
```

### Step 2 — Write failing tests (RED)

Implement the test bodies using `kotlin.test`. Tests must fail at this point.

```kotlin
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

class AddTodoUseCaseTest {

    private val repository = FakeTodoRepository()
    private val useCase = AddTodoUseCase(repository)

    @Test
    fun `given valid title when adding todo then succeeds`() {
        val result = useCase("Buy groceries")
        assertTrue(result.isSuccess)
    }

    @Test
    fun `given blank title when adding todo then throws IllegalArgumentException`() {
        assertFailsWith<IllegalArgumentException> {
            useCase("   ")
        }
    }

    @Test
    fun `given valid todo when adding then persists via repository`() {
        useCase("Read a book")
        assertEquals(1, repository.todos.size)
        assertEquals("Read a book", repository.todos.first().title)
    }
}
```

### Step 3 — Write minimal implementation (GREEN)

Only write enough code to make the tests pass. Resist adding anything extra.

### Step 4 — Refactor (IMPROVE)

Clean up duplication, naming, and structure. All tests must stay green.

### Step 5 — Verify coverage

```bash
./gradlew shared:koverHtmlReport
# or for all modules:
./gradlew allTests koverHtmlReport
```

Target: **80%+ lines and branches** on business logic layers.

## Fakes Over Mocks

KMP has no Mockito. Use hand-written fakes that implement your repository/service interfaces. This is idiomatic KMP and keeps tests readable.

```kotlin
// shared/src/commonTest/kotlin/.../fake/FakeTodoRepository.kt
class FakeTodoRepository : TodoRepository {
    val todos = mutableListOf<Todo>()
    var shouldThrow = false

    override suspend fun save(todo: Todo) {
        if (shouldThrow) throw RuntimeException("DB error")
        todos.add(todo)
    }

    override suspend fun findAll(): List<Todo> = todos.toList()
}
```

Use `shouldThrow` or similar flags to simulate error paths without extra libraries.

## Testing Coroutines and Flows

Add `kotlinx-coroutines-test` to `commonTest` for suspend functions and StateFlow:

```kotlin
// build.gradle.kts (commonTest)
implementation(libs.kotlinx.coroutines.test)
```

```kotlin
import kotlinx.coroutines.test.runTest

class TodoViewModelTest {

    @Test
    fun `given existing todos when loading then emits list to state`() = runTest {
        val repository = FakeTodoRepository()
        repository.todos.add(Todo("1", "Task A"))
        val viewModel = TodoViewModel(repository)

        viewModel.loadTodos()

        assertEquals(1, viewModel.uiState.value.todos.size)
    }

    @Test
    fun `given repository failure when loading todos then emits error state`() = runTest {
        val repository = FakeTodoRepository().apply { shouldThrow = true }
        val viewModel = TodoViewModel(repository)

        viewModel.loadTodos()

        assertTrue(viewModel.uiState.value.isError)
    }
}
```

For `Flow` emission testing, add **Turbine** when needed:
```kotlin
// commonTest
implementation(libs.turbine)
```

## Coverage Requirements

| Layer                         | Required                  |
|-------------------------------|---------------------------|
| Domain models / value objects | **80%+**                  |
| Use cases                     | **80%+**                  |
| ViewModels                    | **80%+**                  |
| Repository interfaces / fakes | N/A (test infrastructure) |
| Compose UI                    | Relaxed — happy path only |

## Edge Cases to Always Cover

For every business rule, include tests for:
1. Happy path
2. Null / empty inputs
3. Boundary values (min, max, zero, negative)
4. Error / exception paths
5. Duplicate or conflict scenarios
6. Concurrent operations (use `runTest` with `TestCoroutineScheduler` if relevant)

## Test Naming Convention

All test method names use backtick strings and follow one of two patterns:

**Pattern 1 — full context:**
```
given <precondition> when <action> then <expected outcome>
```

**Pattern 2 — action-focused (use when the precondition is obvious):**
```
should <expected outcome> when <action>   // "when" is optional if the action is self-evident
```

```kotlin
// Pattern 1 — preferred when precondition matters
fun `given blank title when adding todo then throws IllegalArgumentException`() {}
fun `given existing subscription when subscribing again then returns conflict error`() {}
fun `given empty repository when loading todos then emits empty list`() {}

// Pattern 2 — preferred for simple happy-path or error-path tests
fun `should persist todo when title is valid`() {}
fun `should return failure when repository is unavailable`() {}
fun `should emit loading state when fetch starts`() {}
```

Choose **Pattern 1** when the precondition changes the behavior meaningfully. Choose **Pattern 2** when the action alone makes the context clear. Never use `test_1()`, `testWorks()`, or names that describe implementation details.

## Running Tests

```bash
# All targets
./gradlew allTests

# Specific module, JVM only (fastest feedback loop)
./gradlew shared:jvmTest
./gradlew composeApp:jvmTest

# Watch mode (re-run on change)
./gradlew shared:jvmTest --continuous
```

## Anti-Patterns to Avoid

| Wrong                                           | Right                                              |
|-------------------------------------------------|----------------------------------------------------|
| Testing private methods or internal state       | Test observable behavior and outputs               |
| Tests that depend on execution order            | Each test sets up its own state                    |
| `assert(result != null)` with no value check    | `assertEquals("expected", result.title)`           |
| Platform-specific mocking libraries             | Hand-written fakes implementing interfaces         |
| Skipping error path tests                       | Always test at least one failure scenario per rule |
| One test asserting multiple unrelated behaviors | One behavior per test                              |

## Quality Checklist

Before marking a feature done:

- [ ] Test method names reviewed and approved before implementation
- [ ] All tests fail before implementation (RED confirmed)
- [ ] All tests pass after implementation (GREEN confirmed)
- [ ] Business logic coverage is 80%+
- [ ] Error paths tested, not just happy paths
- [ ] All fakes implement project interfaces (no platform-specific mocking)
- [ ] Tests are independent — no shared mutable state between tests
- [ ] Test names follow `given … when … then …` or `should … when …` convention
- [ ] `tdd-guide.md` updated with the new feature section
