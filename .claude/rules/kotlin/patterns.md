> This file extends [common/patterns.md](../common/patterns.md) with Kotlin-specific content.

# Kotlin Patterns

## Repository Pattern

Define repositories as interfaces in the domain layer. Implementations live in the data layer. Business logic depends only on the interface.

```kotlin
// domain/repository/TaskRepository.kt
interface TaskRepository {
    suspend fun getAll(): List<Task>
    suspend fun getById(id: TaskId): Task?
    suspend fun save(task: Task): Task
    suspend fun delete(id: TaskId)
}

// data/repository/TaskRepositoryImpl.kt
class TaskRepositoryImpl(private val dao: TaskDao) : TaskRepository {
    override suspend fun getAll(): List<Task> = dao.findAll().map { it.toDomain() }
    // ...
}
```

## Use Cases (Interactors)

One use case = one responsibility. Use cases live in the domain layer and depend only on repository interfaces.

```kotlin
// domain/usecase/GetTasksUseCase.kt
class GetTasksUseCase(private val repository: TaskRepository) {
    suspend operator fun invoke(): Result<List<Task>> = runCatching {
        repository.getAll()
    }
}
```

## Result Type for Error Handling

Use `Result<T>` (or a sealed class equivalent) to represent operations that can fail. Never throw from use cases — return the error.

```kotlin
// CORRECT
suspend fun execute(): Result<Task> = runCatching {
    repository.save(task)
}

// Then at the call site
result.onSuccess { showTask(it) }
      .onFailure { showError(it.message) }
```

## Flow for Reactive Streams

Use `Flow` for data streams that update over time (e.g., database changes, live lists). Use `StateFlow` or `SharedFlow` in ViewModels.

```kotlin
// Repository
fun observeTasks(): Flow<List<Task>>

// ViewModel
val tasks: StateFlow<TaskState> = repository.observeTasks()
    .map { TaskState.Success(it) }
    .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), TaskState.Loading)
```

## Value Classes for Domain Primitives

Wrap primitive identifiers and domain-specific values in `value class` to prevent mixing them up.

```kotlin
@JvmInline
value class TaskId(val value: String)

@JvmInline
value class UserId(val value: String)

// Now the compiler won't let you pass a UserId where a TaskId is expected
```
