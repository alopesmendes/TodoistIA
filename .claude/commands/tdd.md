---
description: Enforce test-driven development workflow. Scaffold interfaces, generate tests FIRST, then implement minimal code to pass. Ensure 80%+ coverage.
---

# TDD Command

This command invokes the **tdd-guide** agent to enforce test-driven development methodology.

## What This Command Does

1. **Scaffold Interfaces** - Define types/interfaces first
2. **Generate Tests First** - Write failing tests (RED)
3. **Implement Minimal Code** - Write just enough to pass (GREEN)
4. **Refactor** - Improve code while keeping tests green (REFACTOR)
5. **Verify Coverage** - Ensure 80%+ test coverage

## When to Use

Use `/tdd` when:
- Implementing new features
- Adding new functions/components
- Fixing bugs (write test that reproduces bug first)
- Refactoring existing code
- Building critical business logic

## How It Works

The tdd-guide agent will:

1. **Define interfaces** for inputs/outputs
2. **Write tests that will FAIL** (because code doesn't exist yet)
3. **Run tests** and verify they fail for the right reason
4. **Write minimal implementation** to make tests pass
5. **Run tests** and verify they pass
6. **Refactor** code while keeping tests green
7. **Check coverage** and add more tests if below 80%

## TDD Cycle

```
RED → GREEN → REFACTOR → REPEAT

RED:      Write a failing test
GREEN:    Write minimal code to pass
REFACTOR: Improve code, keep tests passing
REPEAT:   Next feature/scenario
```

## Example Usage — Domain Use Case (Shared Module)

```
User: /tdd I need a use case to calculate task priority score

Agent (tdd-guide):
# TDD Session: Task Priority Score Calculator

## Step 1: Define Interface (SCAFFOLD)
```

```kotlin
// shared/src/commonMain/kotlin/domain/model/Task.kt
@JvmInline
value class TaskId(val value: String)

data class Task(
    val id: TaskId,
    val title: String,
    val dueDate: Instant?,
    val labels: List<String>,
    val isCompleted: Boolean,
    val createdAt: Instant
)
```

```kotlin
// shared/src/commonMain/kotlin/domain/usecase/CalculateTaskPriorityUseCase.kt
class CalculateTaskPriorityUseCase {
    operator fun invoke(task: Task, now: Instant): Int {
        TODO("Not implemented")
    }
}
```

```
## Step 2: Write Failing Test (RED)
```

```kotlin
// shared/src/commonTest/kotlin/domain/usecase/CalculateTaskPriorityUseCaseTest.kt
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import kotlin.time.Duration.Companion.hours
import kotlin.time.Duration.Companion.days

class CalculateTaskPriorityUseCaseTest {

    private val useCase = CalculateTaskPriorityUseCase()
    private val now = Instant.parse("2026-03-12T10:00:00Z")

    @Test
    fun `should return high priority when task is due within 2 hours`() {
        val task = aTask(dueDate = now + 1.hours)

        val score = useCase(task, now)

        assertTrue(score > 80)
        assertTrue(score <= 100)
    }

    @Test
    fun `should return medium priority when task is due tomorrow`() {
        val task = aTask(dueDate = now + 1.days)

        val score = useCase(task, now)

        assertTrue(score in 40..70)
    }

    @Test
    fun `should return low priority when task has no due date`() {
        val task = aTask(dueDate = null)

        val score = useCase(task, now)

        assertTrue(score < 30)
    }

    @Test
    fun `should return zero for completed tasks`() {
        val task = aTask(isCompleted = true, dueDate = now + 1.hours)

        val score = useCase(task, now)

        assertEquals(0, score)
    }

    @Test
    fun `should boost priority when task has many labels`() {
        val withLabels = aTask(
            dueDate = now + 1.days,
            labels = listOf("urgent", "work", "client")
        )
        val withoutLabels = aTask(dueDate = now + 1.days, labels = emptyList())

        val scoreWith = useCase(withLabels, now)
        val scoreWithout = useCase(withoutLabels, now)

        assertTrue(scoreWith > scoreWithout)
    }

    private fun aTask(
        id: TaskId = TaskId("test-1"),
        title: String = "Test Task",
        dueDate: Instant? = null,
        labels: List<String> = emptyList(),
        isCompleted: Boolean = false,
        createdAt: Instant = now - 1.days
    ) = Task(
        id = id,
        title = title,
        dueDate = dueDate,
        labels = labels,
        isCompleted = isCompleted,
        createdAt = createdAt
    )
}
```

```
## Step 3: Run Tests - Verify FAIL
```

```bash
./gradlew :shared:cleanAllTests :shared:allTests --tests "*.CalculateTaskPriorityUseCaseTest"

> Task :shared:allTests FAILED

CalculateTaskPriorityUseCaseTest
  ✕ should return high priority when task is due within 2 hours
    kotlin.NotImplementedError: Not implemented

5 tests failed, 0 passed
```

Tests fail as expected. Ready to implement.

```
## Step 4: Implement Minimal Code (GREEN)
```

```kotlin
// shared/src/commonMain/kotlin/domain/usecase/CalculateTaskPriorityUseCase.kt
class CalculateTaskPriorityUseCase {

    operator fun invoke(task: Task, now: Instant): Int {
        if (task.isCompleted) return 0

        val urgencyScore = calculateUrgency(task.dueDate, now)
        val labelBoost = (task.labels.size * 5).coerceAtMost(15)

        return (urgencyScore + labelBoost).coerceIn(0, 100)
    }

    private fun calculateUrgency(dueDate: Instant?, now: Instant): Int {
        if (dueDate == null) return 20

        val hoursUntilDue = (dueDate - now).inWholeHours
        return when {
            hoursUntilDue <= 0 -> 100
            hoursUntilDue <= 2 -> 90
            hoursUntilDue <= 24 -> 60
            hoursUntilDue <= 72 -> 40
            else -> 20
        }
    }
}
```

```
## Step 5: Run Tests - Verify PASS
```

```bash
./gradlew :shared:cleanAllTests :shared:allTests --tests "*.CalculateTaskPriorityUseCaseTest"

> Task :shared:allTests PASSED

CalculateTaskPriorityUseCaseTest
  ✓ should return high priority when task is due within 2 hours
  ✓ should return medium priority when task is due tomorrow
  ✓ should return low priority when task has no due date
  ✓ should return zero for completed tasks
  ✓ should boost priority when task has many labels

5 tests passed
```

All tests passing!

```
## Step 6: Refactor (IMPROVE)
```

```kotlin
// shared/src/commonMain/kotlin/domain/usecase/CalculateTaskPriorityUseCase.kt
class CalculateTaskPriorityUseCase {

    operator fun invoke(task: Task, now: Instant): Int {
        if (task.isCompleted) return 0

        val urgencyScore = urgencyFrom(task.dueDate, now)
        val labelBoost = labelBoostFrom(task.labels)

        return (urgencyScore + labelBoost).coerceIn(SCORE_MIN, SCORE_MAX)
    }

    private fun urgencyFrom(dueDate: Instant?, now: Instant): Int {
        if (dueDate == null) return UrgencyScore.NO_DUE_DATE

        val hoursUntilDue = (dueDate - now).inWholeHours
        return when {
            hoursUntilDue <= 0 -> UrgencyScore.OVERDUE
            hoursUntilDue <= HOURS_CRITICAL -> UrgencyScore.CRITICAL
            hoursUntilDue <= HOURS_HIGH -> UrgencyScore.HIGH
            hoursUntilDue <= HOURS_MEDIUM -> UrgencyScore.MEDIUM
            else -> UrgencyScore.LOW
        }
    }

    private fun labelBoostFrom(labels: List<String>): Int =
        (labels.size * LABEL_BOOST_PER_LABEL).coerceAtMost(LABEL_BOOST_MAX)

    private companion object {
        const val SCORE_MIN = 0
        const val SCORE_MAX = 100
        const val HOURS_CRITICAL = 2L
        const val HOURS_HIGH = 24L
        const val HOURS_MEDIUM = 72L
        const val LABEL_BOOST_PER_LABEL = 5
        const val LABEL_BOOST_MAX = 15
    }

    private object UrgencyScore {
        const val OVERDUE = 100
        const val CRITICAL = 90
        const val HIGH = 60
        const val MEDIUM = 40
        const val LOW = 20
        const val NO_DUE_DATE = 20
    }
}
```

```
## Step 7: Verify Tests Still Pass
```

```bash
./gradlew :shared:cleanAllTests :shared:allTests --tests "*.CalculateTaskPriorityUseCaseTest"

> Task :shared:allTests PASSED

5 tests passed
```

Refactoring complete, tests still passing!

## Example Usage — Ktor Server Endpoint

```
User: /tdd I need a POST endpoint to create a task

Agent (tdd-guide):
# TDD Session: Create Task Endpoint

## Step 1: Define Interface (SCAFFOLD)
```

```kotlin
// server/src/main/kotlin/adapter/in/web/dto/CreateTaskRequest.kt
@Serializable
data class CreateTaskRequest(
    @SerialName("title") val title: String,
    @SerialName("due_date") val dueDate: String? = null,
    @SerialName("labels") val labels: List<String> = emptyList()
)
```

```kotlin
// server/src/main/kotlin/adapter/in/web/dto/TaskResponse.kt
@Serializable
data class TaskResponse(
    @SerialName("id") val id: String,
    @SerialName("title") val title: String,
    @SerialName("due_date") val dueDate: String?,
    @SerialName("labels") val labels: List<String>,
    @SerialName("is_completed") val isCompleted: Boolean
)
```

```kotlin
// server/src/main/kotlin/domain/port/in/CreateTaskPort.kt
interface CreateTaskPort {
    suspend fun execute(command: CreateTaskCommand): Result<Task>
}

data class CreateTaskCommand(
    val title: String,
    val dueDate: Instant?,
    val labels: List<String>
)
```

```
## Step 2: Write Failing Test (RED)
```

```kotlin
// server/src/test/kotlin/adapter/in/web/TaskRouteTest.kt
import io.ktor.client.request.*
import io.ktor.client.statement.*
import io.ktor.http.*
import io.ktor.server.testing.*
import kotlinx.serialization.json.Json
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

class TaskRouteTest {

    private val json = Json { ignoreUnknownKeys = true }

    @Test
    fun `POST tasks should create task and return 201`() = testApplication {
        application { configureTestApp(fakeCreateTaskPort()) }

        val response = client.post("/api/v1/tasks") {
            contentType(ContentType.Application.Json)
            setBody("""{"title":"Buy milk","labels":["groceries"]}""")
        }

        assertEquals(HttpStatusCode.Created, response.status)
        val body = json.decodeFromString<ApiResponse<TaskResponse>>(response.bodyAsText())
        assertNotNull(body.data)
        assertEquals("Buy milk", body.data.title)
        assertEquals(listOf("groceries"), body.data.labels)
    }

    @Test
    fun `POST tasks should return 400 when title is blank`() = testApplication {
        application { configureTestApp(fakeCreateTaskPort()) }

        val response = client.post("/api/v1/tasks") {
            contentType(ContentType.Application.Json)
            setBody("""{"title":""}""")
        }

        assertEquals(HttpStatusCode.BadRequest, response.status)
    }

    @Test
    fun `POST tasks should return 400 when title is missing`() = testApplication {
        application { configureTestApp(fakeCreateTaskPort()) }

        val response = client.post("/api/v1/tasks") {
            contentType(ContentType.Application.Json)
            setBody("""{}""")
        }

        assertEquals(HttpStatusCode.BadRequest, response.status)
    }

    @Test
    fun `POST tasks should return 500 when use case fails`() = testApplication {
        application { configureTestApp(fakeCreateTaskPort(shouldFail = true)) }

        val response = client.post("/api/v1/tasks") {
            contentType(ContentType.Application.Json)
            setBody("""{"title":"Buy milk"}""")
        }

        assertEquals(HttpStatusCode.InternalServerError, response.status)
    }

    private fun fakeCreateTaskPort(shouldFail: Boolean = false) = object : CreateTaskPort {
        override suspend fun execute(command: CreateTaskCommand): Result<Task> {
            if (shouldFail) return Result.failure(RuntimeException("DB error"))
            return Result.success(
                Task(
                    id = TaskId("generated-id"),
                    title = command.title,
                    dueDate = command.dueDate,
                    labels = command.labels,
                    isCompleted = false,
                    createdAt = Clock.System.now()
                )
            )
        }
    }
}
```

```
## Step 3: Run Tests - Verify FAIL
```

```bash
./gradlew :server:test --tests "*.TaskRouteTest"

> Task :server:test FAILED

TaskRouteTest
  ✕ POST tasks should create task and return 201
    Unresolved reference: configureTestApp

4 tests failed, 0 passed
```

Tests fail as expected. Ready to implement.

```
## Step 4: Implement Minimal Code (GREEN)
```

```kotlin
// server/src/main/kotlin/adapter/in/web/TaskRoute.kt
fun Route.taskRoutes(createTaskPort: CreateTaskPort) {
    route("/api/v1/tasks") {
        post {
            val request = call.receive<CreateTaskRequest>()

            if (request.title.isBlank()) {
                call.respond(
                    HttpStatusCode.BadRequest,
                    ApiResponse.error("Title must not be blank")
                )
                return@post
            }

            val command = CreateTaskCommand(
                title = request.title,
                dueDate = request.dueDate?.let { Instant.parse(it) },
                labels = request.labels
            )

            createTaskPort.execute(command)
                .onSuccess { task ->
                    call.respond(
                        HttpStatusCode.Created,
                        ApiResponse.success(task.toResponse())
                    )
                }
                .onFailure {
                    call.respond(
                        HttpStatusCode.InternalServerError,
                        ApiResponse.error("Failed to create task")
                    )
                }
        }
    }
}

private fun Task.toResponse() = TaskResponse(
    id = id.value,
    title = title,
    dueDate = dueDate?.toString(),
    labels = labels,
    isCompleted = isCompleted
)
```

```
## Step 5: Run Tests - Verify PASS
```

```bash
./gradlew :server:test --tests "*.TaskRouteTest"

> Task :server:test PASSED

TaskRouteTest
  ✓ POST tasks should create task and return 201
  ✓ POST tasks should return 400 when title is blank
  ✓ POST tasks should return 400 when title is missing
  ✓ POST tasks should return 500 when use case fails

4 tests passed
```

All tests passing!

## Example Usage — ViewModel (Compose Multiplatform)

```
User: /tdd I need a ViewModel for the task list screen

Agent (tdd-guide):
# TDD Session: TaskList ViewModel

## Step 1: Define Interface (SCAFFOLD)
```

```kotlin
// shared/src/commonMain/kotlin/domain/repository/TaskRepository.kt
interface TaskRepository {
    fun observeAll(): Flow<List<Task>>
    suspend fun getAll(): List<Task>
    suspend fun save(task: Task): Task
    suspend fun delete(id: TaskId)
}
```

```kotlin
// shared/src/commonMain/kotlin/presentation/tasklist/TaskListState.kt
sealed class TaskListState {
    data object Loading : TaskListState()
    data class Success(val tasks: List<Task>) : TaskListState()
    data class Error(val message: String) : TaskListState()
}
```

```kotlin
// shared/src/commonMain/kotlin/presentation/tasklist/TaskListViewModel.kt
class TaskListViewModel(
    private val repository: TaskRepository
) {
    val state: StateFlow<TaskListState> get() = TODO("Not implemented")

    fun onDeleteTask(id: TaskId) { TODO("Not implemented") }
}
```

```
## Step 2: Write Failing Test (RED)
```

```kotlin
// shared/src/commonTest/kotlin/presentation/tasklist/TaskListViewModelTest.kt
import app.cash.turbine.test
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs

class TaskListViewModelTest {

    private val task1 = Task(
        id = TaskId("1"), title = "Buy milk",
        dueDate = null, labels = emptyList(),
        isCompleted = false, createdAt = Clock.System.now()
    )
    private val task2 = Task(
        id = TaskId("2"), title = "Write tests",
        dueDate = null, labels = listOf("dev"),
        isCompleted = false, createdAt = Clock.System.now()
    )

    @Test
    fun `should emit Loading then Success when repository returns tasks`() = runTest {
        val repository = FakeTaskRepository(tasks = listOf(task1, task2))
        val viewModel = TaskListViewModel(repository)

        viewModel.state.test {
            assertEquals(TaskListState.Loading, awaitItem())
            val success = awaitItem()
            assertIs<TaskListState.Success>(success)
            assertEquals(2, success.tasks.size)
        }
    }

    @Test
    fun `should emit Error when repository throws`() = runTest {
        val repository = FakeTaskRepository(shouldFail = true)
        val viewModel = TaskListViewModel(repository)

        viewModel.state.test {
            assertEquals(TaskListState.Loading, awaitItem())
            val error = awaitItem()
            assertIs<TaskListState.Error>(error)
        }
    }

    @Test
    fun `should remove task after onDeleteTask is called`() = runTest {
        val repository = FakeTaskRepository(tasks = listOf(task1, task2))
        val viewModel = TaskListViewModel(repository)

        viewModel.state.test {
            skipItems(1) // Loading
            assertIs<TaskListState.Success>(awaitItem()) // Initial list

            viewModel.onDeleteTask(task1.id)

            val updated = awaitItem()
            assertIs<TaskListState.Success>(updated)
            assertEquals(1, updated.tasks.size)
            assertEquals(task2.id, updated.tasks.first().id)
        }
    }
}
```

```kotlin
// shared/src/commonTest/kotlin/fake/FakeTaskRepository.kt
class FakeTaskRepository(
    private val tasks: List<Task> = emptyList(),
    private val shouldFail: Boolean = false
) : TaskRepository {

    private val _tasks = MutableStateFlow(tasks)

    override fun observeAll(): Flow<List<Task>> {
        if (shouldFail) return flow { throw RuntimeException("DB error") }
        return _tasks.asStateFlow()
    }

    override suspend fun getAll(): List<Task> {
        if (shouldFail) error("DB error")
        return _tasks.value
    }

    override suspend fun save(task: Task): Task {
        _tasks.update { it + task }
        return task
    }

    override suspend fun delete(id: TaskId) {
        _tasks.update { list -> list.filter { it.id != id } }
    }
}
```

```
## Step 3: Run Tests - Verify FAIL
```

```bash
./gradlew :shared:cleanAllTests :shared:allTests --tests "*.TaskListViewModelTest"

> Task :shared:allTests FAILED

TaskListViewModelTest
  ✕ should emit Loading then Success when repository returns tasks
    kotlin.NotImplementedError: Not implemented

3 tests failed, 0 passed
```

Tests fail as expected. Ready to implement.

```
## Step 4: Implement Minimal Code (GREEN)
```

```kotlin
// shared/src/commonMain/kotlin/presentation/tasklist/TaskListViewModel.kt
class TaskListViewModel(
    private val repository: TaskRepository
) {
    private val _state = MutableStateFlow<TaskListState>(TaskListState.Loading)
    val state: StateFlow<TaskListState> = _state.asStateFlow()

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    init {
        scope.launch {
            repository.observeAll()
                .map { TaskListState.Success(it) as TaskListState }
                .catch { emit(TaskListState.Error(it.message ?: "Unknown error")) }
                .collect { _state.value = it }
        }
    }

    fun onDeleteTask(id: TaskId) {
        scope.launch { repository.delete(id) }
    }
}
```

```
## Step 5: Run Tests - Verify PASS
```

```bash
./gradlew :shared:cleanAllTests :shared:allTests --tests "*.TaskListViewModelTest"

> Task :shared:allTests PASSED

TaskListViewModelTest
  ✓ should emit Loading then Success when repository returns tasks
  ✓ should emit Error when repository throws
  ✓ should remove task after onDeleteTask is called

3 tests passed
```

All tests passing!

## TDD Best Practices

**DO:**
- Write the test FIRST, before any implementation
- Run tests and verify they FAIL before implementing
- Write minimal code to make tests pass
- Refactor only after tests are green
- Add edge cases and error scenarios
- Aim for 80%+ coverage (100% for critical code)
- Use `runTest` for all coroutine tests
- Use Fake repositories instead of mocking frameworks
- Use backtick test names that read as English sentences
- Use Turbine for testing `Flow`/`StateFlow` emissions

**DON'T:**
- Write implementation before tests
- Skip running tests after each change
- Write too much code at once
- Ignore failing tests
- Test implementation details (test behavior)
- Use `!!` in production code
- Use mocking frameworks (prefer hand-written fakes)
- Mutate state directly (use `copy()` and immutable collections)

## Test Types to Include

**Unit Tests** (Function-level):
- Happy path scenarios
- Edge cases (empty lists, null values, boundary values)
- Error conditions (`Result.failure`, exceptions)
- Value class invariants

**Integration Tests** (Component-level):
- Ktor endpoints with `testApplication`
- Database operations with test containers
- Repository implementations with in-memory storage
- Use cases wired to fake repositories

**E2E Tests** (Full stack):
- Critical user flows
- Server + client integration
- Multi-step processes

## Coverage Requirements

- **90% minimum** for domain models and use cases
- **80% minimum** for ViewModels and repositories
- **100% required** for:
  - Financial calculations
  - Authentication logic
  - Security-critical code
  - Core business logic

## Test Commands

```bash
# Run all shared module tests
./gradlew :shared:cleanAllTests :shared:allTests

# Run specific test class
./gradlew :shared:cleanAllTests :shared:allTests --tests "*.CalculateTaskPriorityUseCaseTest"

# Run server tests
./gradlew :server:test

# Run specific server test
./gradlew :server:test --tests "*.TaskRouteTest"

# Run with coverage (Kover)
./gradlew :shared:koverHtmlReport
```

## Important Notes

**MANDATORY**: Tests must be written BEFORE implementation. The TDD cycle is:

1. **RED** - Write failing test
2. **GREEN** - Implement to pass
3. **REFACTOR** - Improve code

Never skip the RED phase. Never write code before tests.

## Integration with Other Commands

- Use `/plan` first to understand what to build
- Use `/tdd` to implement with tests
- Use `/build-fix` if build errors occur
- Use `/code-review` to review implementation
- Use `/test-coverage` to verify coverage

## Related Agents

This command invokes the `tdd-guide` agent.

The related `tdd-workflow` skill is also available.

Source files:
- `agents/tdd-guide.md`
- `skills/tdd-workflow/SKILL.md`
