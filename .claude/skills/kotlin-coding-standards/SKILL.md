---
name: kotlin-coding-standards
description: Kotlin coding standards and best practices for KMP projects. Covers value classes, data classes, sealed classes, enums, objects, interfaces, higher-order functions, coroutines, Flows, and the Result type. Use this skill proactively whenever writing or reviewing Kotlin code, modeling domain types, handling async operations, errors, or state — even if the user doesn't explicitly ask for "coding standards."
---

# Kotlin Coding Standards & Best Practices

Idiomatic Kotlin for a KMP project. For universal conventions (naming, structure, interfaces), see `coding-standards`.

## When to Activate

- Writing or reviewing any Kotlin class, function, or file
- Modeling domain entities, value objects, or state
- Handling errors with Result, sealed classes, or exceptions
- Writing async logic with coroutines or Flows
- Choosing between data class, value class, sealed class, enum, or object

---

## Choosing the Right Type

The type you choose communicates intent — this is the most important decision in Kotlin modeling.

### Value Classes — wrap primitives with meaning

`@JvmInline value class` gives you type safety at zero runtime cost. Use them for any primitive that carries domain meaning: IDs, validated strings, units.

```kotlin
@JvmInline value class TaskId(val value: String)
@JvmInline value class UserId(val value: String)

fun getTask(id: TaskId, userId: UserId): Task  // compiler catches argument-order mistakes

@JvmInline value class Email(val value: String) {
    init { require(value.contains('@')) { "Invalid email: $value" } }
}
```

### Data Classes — immutable records

Use `data class` for pure data carriers (entities, DTOs, query results). Always `val`, update via `.copy()`, no business logic inside.

```kotlin
data class Task(
    val id: TaskId,
    val title: String,
    val description: String?,
    val priority: Priority,
    val isCompleted: Boolean = false,
    val createdAt: Instant,
)

val completed = task.copy(isCompleted = true)
```

Public APIs expose read-only collection types (`List`, `Map`), not their mutable variants.

### Sealed Classes — exhaustive state modeling

Use `sealed interface` when a value is one of a fixed set of shapes and you want the compiler to enforce exhaustiveness. Prefer `sealed interface` over `sealed class` — it allows implementors to extend multiple hierarchies.

```kotlin
sealed interface TaskState {
    data object Loading : TaskState
    data object Empty : TaskState
    data class Success(val tasks: List<Task>) : TaskState
    data class Error(val message: String) : TaskState
}

// when forces handling every case — no runtime surprises
fun render(state: TaskState) = when (state) {
    is TaskState.Loading -> showSpinner()
    is TaskState.Empty   -> showEmptyView()
    is TaskState.Success -> showTasks(state.tasks)
    is TaskState.Error   -> showError(state.message)
}
```

### Enum Classes — named constants with behavior

Use `enum class` for a closed set of values, especially when they carry associated data or factory logic.

```kotlin
enum class Priority(val level: Int, val label: String) {
    NONE(0, "None"), LOW(1, "Low"), MEDIUM(2, "Medium"), HIGH(3, "High"), URGENT(4, "Urgent");

    companion object {
        fun fromLevel(level: Int): Priority = entries.firstOrNull { it.level == level } ?: NONE
    }
}
```

Don't use enums for sets that may grow — use a sealed interface instead.

### Objects — singletons and companions

Use `object` for stateless singletons (mappers, utilities). Use `companion object` for factory methods and class-level constants.

```kotlin
object TaskMapper {
    fun toDomain(dto: TaskResponseDto): Task = Task(
        id = TaskId(dto.id),
        title = dto.title,
        priority = Priority.fromLevel(dto.priorityLevel),
        isCompleted = dto.isCompleted,
        createdAt = Instant.parse(dto.createdAt),
        description = dto.description,
    )
}
```

Avoid dumping unrelated utilities into companion objects — prefer top-level functions in focused files.

### Interfaces — contracts for dependency inversion

Domain and use-case layers depend on interfaces, never on concrete implementations. See `coding-standards` for the `I`-prefix naming convention.

```kotlin
interface ITaskRepository {
    suspend fun findById(id: TaskId): Task?
    suspend fun save(task: Task): Task
    suspend fun delete(id: TaskId)
    fun observeAll(userId: UserId): Flow<List<Task>>
}
```

---

## Functions

### Expression bodies and extension functions

Prefer expression bodies for single-expression functions. Prefer extension functions over utility objects — they read naturally at the call site.

```kotlin
fun TaskId.toUuid(): UUID = UUID.fromString(value)
fun Task.isOverdue(now: Instant): Boolean = dueDate?.isBefore(now) ?: false
fun String.isValidEmail(): Boolean = contains('@')
```

### Higher-Order Functions — pass behavior, not flags

Pass a lambda when a function needs to vary its behavior. Reach for stdlib HOFs before writing your own loops.

```kotlin
// Pass behavior instead of a boolean flag
fun fetchTasks(transform: (List<Task>) -> List<Task> = { it }): List<Task>

// Useful stdlib HOFs
tasks.filter { !it.isCompleted }
tasks.groupBy { it.priority }
tasks.associateBy { it.id }
input.takeIf { it.isNotBlank() }

// Scope functions
task.also { log(it) }
dto.let { it.toCommand() }
builder.apply { title = "Buy milk" }
```

Use `inline` for lambdas on hot paths to avoid allocation overhead.

---

## Coroutines

### Structured Concurrency

Always launch within a scope tied to a lifecycle. Use cases and repositories expose `suspend` functions — they never create their own scope.

```kotlin
// ViewModel owns the scope
fun loadTask(id: TaskId) {
    viewModelScope.launch {
        _state.value = TaskState.Loading
        _state.value = try {
            TaskState.Success(getTask.execute(id))
        } catch (e: NotFoundException) {
            TaskState.Error(e.message ?: "Not found")
        }
    }
}

// Use case: just suspend, no scope
suspend fun execute(id: TaskId): Task =
    repository.findById(id) ?: throw NotFoundException("Task $id")
```

### Parallel Execution

Use `async/await` inside `coroutineScope` when independent operations can run concurrently.

```kotlin
suspend fun loadDashboard(userId: UserId): Dashboard = coroutineScope {
    val tasks    = async { taskRepo.findAll(userId) }
    val projects = async { projectRepo.findAll(userId) }
    Dashboard(tasks.await(), projects.await())
}
```

### Dispatcher Discipline

Switch dispatchers explicitly — never block the default coroutine thread pool.

| Work type                            | Dispatcher            |
|--------------------------------------|-----------------------|
| Network / file I/O                   | `Dispatchers.IO`      |
| CPU-intensive (parsing, computation) | `Dispatchers.Default` |
| UI updates                           | `Dispatchers.Main`    |

```kotlin
suspend fun readFile(): String = withContext(Dispatchers.IO) { File("data.txt").readText() }
```

---

## Flows

Use `Flow` for streams of values over time. Use `StateFlow` to hold and expose observable UI state.

```kotlin
// Repository exposes a cold flow
fun observeAll(userId: UserId): Flow<List<Task>> = flow {
    while (true) { emit(db.queryTasks(userId)); delay(POLL_INTERVAL) }
}

// ViewModel converts to StateFlow
private val _state = MutableStateFlow<TaskState>(TaskState.Loading)
val state: StateFlow<TaskState> = _state.asStateFlow()

init {
    viewModelScope.launch {
        listTasks.stream()
            .map { if (it.isEmpty()) TaskState.Empty else TaskState.Success(it) }
            .catch { e -> emit(TaskState.Error(e.message ?: "Error")) }
            .collect { _state.value = it }
    }
}
```

Key operators: `map`, `filter`, `flatMapLatest`, `combine`, `debounce`, `distinctUntilChanged`, `retry`, `catch`.

```kotlin
// Search with debounce
searchQuery
    .debounce(300)
    .distinctUntilChanged()
    .flatMapLatest { repo.search(it) }
```

---

## Error Handling

Three tools, three contexts:

| Context                                                 | Tool                        | Why                              |
|---------------------------------------------------------|-----------------------------|----------------------------------|
| Infrastructure boundary (repo, network)                 | `Result<T>` / `runCatching` | Caller decides how to recover    |
| Domain logic (use cases)                                | Typed exceptions            | Simple, no wrapper overhead      |
| Multi-branch outcomes the caller must handle explicitly | Sealed interface            | Compiler-enforced exhaustiveness |

```kotlin
// Infrastructure: return Result
suspend fun findById(id: TaskId): Result<Task> = runCatching {
    db.query(id) ?: throw NotFoundException("Task $id")
}

// Domain: throw typed exceptions
class NotFoundException(message: String) : RuntimeException(message)
class ConflictException(message: String) : RuntimeException(message)

// Multi-branch: sealed result
sealed interface SyncResult {
    data object Success : SyncResult
    data class PartialFailure(val failed: List<TaskId>) : SyncResult
    data object Unauthorized : SyncResult
}
```

---

## Checklist Before Committing

- [ ] Primitives with domain meaning wrapped in `@JvmInline value class`
- [ ] Data classes use `val`; updated via `.copy()`; no business logic inside
- [ ] Sealed interface used for exhaustive state/result modeling
- [ ] Enums carry associated data and a `fromX` factory when needed
- [ ] Domain layer depends on interfaces, not implementations
- [ ] `suspend` functions for async — no blocking calls on coroutine threads
- [ ] Parallel work uses `async/await` inside `coroutineScope`
- [ ] Correct dispatcher for I/O vs CPU vs UI work
- [ ] `Flow` for streams; `StateFlow` for UI state
- [ ] `Result` at infrastructure boundaries; typed exceptions in domain; sealed for multi-branch
- [ ] Public APIs expose read-only collection types
