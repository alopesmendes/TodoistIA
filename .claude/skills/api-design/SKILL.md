---
name: api-design
description: Ktor REST API design patterns for TodoistIA. Use when creating new endpoints, defining request/response DTOs, configuring error responses, or setting up OpenAPI/Swagger. Covers URL conventions, versioned routing, standardized ApiResponse/ApiError wrappers, snake_case DTO serialization with @SerialName, pagination, and Swagger UI setup for Ktor 3.x with kotlinx.serialization. Use this skill proactively whenever the user mentions API routes, endpoints, DTOs, REST design, Swagger, OpenAPI, or response formatting — even if they don't explicitly ask for "API design."
---

# Ktor API Design Patterns

Conventions for designing consistent REST APIs in the TodoistIA Ktor 3.x backend. All endpoints follow hexagonal architecture: route handlers live in `adapter/input/rest/`, map DTOs, and delegate to use cases. Domain logic never appears in routes.

## When to Activate

- Creating a new REST endpoint or route file
- Defining request/response DTOs with `@Serializable`
- Configuring ContentNegotiation or StatusPages plugins
- Setting up OpenAPI/Swagger documentation
- Adding pagination or filtering to list endpoints
- Designing error handling with ApiError
- Reviewing API contracts between client and server

## Dependencies Required

Add these to `gradle/libs.versions.toml` under `[libraries]`:

```toml
ktor-server-content-negotiation = { module = "io.ktor:ktor-server-content-negotiation-jvm", version.ref = "ktor" }
ktor-server-status-pages = { module = "io.ktor:ktor-server-status-pages-jvm", version.ref = "ktor" }
ktor-server-swagger = { module = "io.ktor:ktor-server-swagger-jvm", version.ref = "ktor" }
ktor-server-openapi = { module = "io.ktor:ktor-server-openapi-jvm", version.ref = "ktor" }
ktor-serialization-kotlinx-json = { module = "io.ktor:ktor-serialization-kotlinx-json-jvm", version.ref = "ktor" }
hibernate-validator = { module = "org.hibernate.validator:hibernate-validator", version = "8.0.2.Final" }
jakarta-el = { module = "org.glassfish.expressly:expressly", version = "5.0.0" }
```

In `server/build.gradle.kts`:

```kotlin
implementation(libs.ktor.server.content.negotiation)
implementation(libs.ktor.server.status.pages)
implementation(libs.ktor.server.swagger)
implementation(libs.ktor.server.openapi)
implementation(libs.ktor.serialization.kotlinx.json)
implementation(libs.hibernate.validator)
implementation(libs.jakarta.el)
```

The `shared` module needs `kotlinx-serialization` plugin and runtime:

```kotlin
// shared/build.gradle.kts
plugins {
    kotlin("plugin.serialization")
}
// In commonMain dependencies:
implementation(libs.kotlinx.serialization.json)
```

## URL Structure

### Rules

| Rule                       | Example                                | Rationale                         |
|----------------------------|----------------------------------------|-----------------------------------|
| Plural nouns               | `/api/v1/tasks`                        | Collections are plural            |
| Kebab-case                 | `/api/v1/task-labels`                  | Consistent, URL-friendly          |
| No verbs                   | `/api/v1/tasks` not `/api/v1/getTasks` | HTTP method conveys the action    |
| Versioned                  | `/api/v1/...`                          | All routes under a version prefix |
| Path params in camelCase   | `/api/v1/tasks/{taskId}`               | Ktor convention for path params   |
| Query params in snake_case | `?page_size=20&due_date=...`           | Matches JSON field naming         |
| No trailing slash          | `/api/v1/tasks` not `/api/v1/tasks/`   | Avoid duplicate routes            |

### Resource Patterns

```
# Standard CRUD
GET    /api/v1/tasks                    # List tasks
GET    /api/v1/tasks/{taskId}           # Get single task
POST   /api/v1/tasks                    # Create task
PUT    /api/v1/tasks/{taskId}           # Full update
PATCH  /api/v1/tasks/{taskId}           # Partial update
DELETE /api/v1/tasks/{taskId}           # Delete task

# Sub-resources
GET    /api/v1/projects/{projectId}/tasks
POST   /api/v1/projects/{projectId}/tasks

# Actions (use verbs sparingly, only for non-CRUD operations)
POST   /api/v1/tasks/{taskId}/complete
POST   /api/v1/auth/login
POST   /api/v1/auth/refresh
```

### Naming Examples

```
# GOOD
/api/v1/task-labels              # kebab-case for multi-word resources
/api/v1/tasks?status=pending     # query params for filtering
/api/v1/projects/123/tasks       # sub-resource for ownership

# BAD
/api/v1/getUsers                 # verb in URL
/api/v1/task                     # singular (use plural)
/api/v1/task_labels              # snake_case in URLs (use kebab-case)
/api/v1/tasks/123/getTags        # verb in nested resource
```

## HTTP Methods and Status Codes

### Method-to-Ktor Mapping

| Method | Purpose              | Success Code   | Ktor Pattern                                                    |
|--------|----------------------|----------------|-----------------------------------------------------------------|
| GET    | Retrieve resource(s) | 200 OK         | `call.respond(HttpStatusCode.OK, ApiResponse(data = ...))`      |
| POST   | Create resource      | 201 Created    | `call.respond(HttpStatusCode.Created, ApiResponse(data = ...))` |
| PUT    | Full replacement     | 200 OK         | `call.respond(HttpStatusCode.OK, ApiResponse(data = ...))`      |
| PATCH  | Partial update       | 200 OK         | `call.respond(HttpStatusCode.OK, ApiResponse(data = ...))`      |
| DELETE | Remove resource      | 204 No Content | `call.respond(HttpStatusCode.NoContent)`                        |

### Error Status Codes

| Code                      | When                               | ApiError `code` value  |
|---------------------------|------------------------------------|------------------------|
| 400 Bad Request           | Malformed JSON, validation failure | `validation_error`     |
| 401 Unauthorized          | Missing or invalid auth token      | `unauthorized`         |
| 403 Forbidden             | Authenticated but not authorized   | `forbidden`            |
| 404 Not Found             | Resource does not exist            | `not_found`            |
| 409 Conflict              | Duplicate entry, state conflict    | `conflict`             |
| 422 Unprocessable Entity  | Business rule violation            | `unprocessable_entity` |
| 500 Internal Server Error | Unexpected failure                 | `internal_error`       |

Never return 200 for errors. Never expose stack traces or SQL errors in responses.

## ApiResponse and ApiError

These classes live in the **shared module** (`shared/src/commonMain/.../api/model/`) so both client and server can use them.

### ApiResponse<T>

```kotlin
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class ApiResponse<T>(
    val data: T,
    val meta: Meta? = null,
) {
    @Serializable
    data class Meta(
        val page: Int? = null,
        @SerialName("page_size") val pageSize: Int? = null,
        @SerialName("total_count") val totalCount: Long? = null,
        @SerialName("has_next") val hasNext: Boolean? = null,
    )
}
```

### ApiError

```kotlin
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class ApiError(
    val code: String,
    val message: String,
    val details: List<FieldError>? = null,
) {
    @Serializable
    data class FieldError(
        val field: String,
        val message: String,
    )
}
```

Route handlers never catch exceptions — errors propagate to the StatusPages plugin (see Plugin Configuration). See the Versioned Routing section for full usage examples.

## DTO Conventions

### Rules

1. **Naming**: Every DTO class ends with `Dto` — e.g., `CreateTaskRequestDto`, `TaskResponseDto`
2. **Kotlin properties**: `camelCase` — standard Kotlin naming
3. **JSON fields**: `snake_case` via explicit `@SerialName` annotations
4. **Request and response DTOs are separate classes** — never reuse domain entities as DTOs
5. **DTOs are pure data carriers** — no mapper functions, no business logic inside the class
6. **Mapping lives in extension functions** — defined in separate mapper files in the adapter layer
7. **Validation via Jakarta annotations** — use `@field:` target on constructor parameters, not manual `require()` blocks
8. **Shared DTOs** go in `shared/src/commonMain/.../api/dto/`; server-only DTOs go in `adapter/input/rest/dto/`

Use explicit `@SerialName` instead of `Json { namingStrategy = JsonNamingStrategy.SnakeCase }` — explicit annotations are self-documenting and prevent accidental breakage when renaming properties.

### Request DTO Example

```kotlin
import jakarta.validation.constraints.*
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class CreateTaskRequestDto(
    @field:NotBlank(message = "Title is required")
    @field:Size(max = 255, message = "Title must not exceed 255 characters")
    val title: String,

    val description: String? = null,

    @SerialName("due_date")
    val dueDate: String? = null,

    @field:Min(value = 0, message = "Priority level must be at least 0")
    @field:Max(value = 4, message = "Priority level must be at most 4")
    @SerialName("priority_level")
    val priorityLevel: Int = 0,

    @SerialName("project_id")
    val projectId: String? = null,
)
```

### Response DTO Example

```kotlin
@Serializable
data class TaskResponseDto(
    val id: String,
    val title: String,
    val description: String? = null,
    @SerialName("due_date") val dueDate: String? = null,
    @SerialName("priority_level") val priorityLevel: Int,
    @SerialName("is_completed") val isCompleted: Boolean,
    @SerialName("project_id") val projectId: String? = null,
    @SerialName("created_at") val createdAt: String,
    @SerialName("updated_at") val updatedAt: String,
)
```

### Validation Infrastructure

DTOs are validated using Jakarta Bean Validation (Hibernate Validator). Set up a shared `Validator` instance and a reusable extension:

```kotlin
// infrastructure/validation/DtoValidator.kt
import jakarta.validation.Validation
import jakarta.validation.Validator

val validator: Validator = Validation.buildDefaultValidatorFactory().validator

fun <T : Any> T.validateDto(): T {
    val violations = validator.validate(this)
    if (violations.isNotEmpty()) {
        val details = violations.map { violation ->
            ApiError.FieldError(
                field = violation.propertyPath.toString(),
                message = violation.message,
            )
        }
        throw DtoValidationException(details)
    }
    return this
}

class DtoValidationException(
    val details: List<ApiError.FieldError>,
) : RuntimeException("DTO validation failed")
```

### Common Jakarta Annotations Reference

| Annotation                  | Use for                    | Example                |
|-----------------------------|----------------------------|------------------------|
| `@field:NotBlank`           | Required non-empty strings | `val title: String`    |
| `@field:NotNull`            | Required nullable fields   | `val age: Int?`        |
| `@field:Size(min, max)`     | String/collection length   | `val password: String` |
| `@field:Min` / `@field:Max` | Numeric range              | `val priority: Int`    |
| `@field:Email`              | Email format               | `val email: String`    |
| `@field:Pattern`            | Regex match                | `val code: String`     |
| `@field:Positive`           | Number > 0                 | `val quantity: Int`    |

Always use the `@field:` target — Kotlin constructor parameters default to parameter-site annotations, but Hibernate Validator reads field-site annotations.

## Plugin Configuration

### ContentNegotiation

```kotlin
fun Application.configureContentNegotiation() {
    install(ContentNegotiation) {
        json(Json {
            prettyPrint = false
            isLenient = false
            ignoreUnknownKeys = true
            encodeDefaults = true
        })
    }
}
```

### StatusPages with ApiError

Route handlers never catch domain exceptions. They propagate to StatusPages, which maps them to the correct HTTP status and ApiError response.

```kotlin
fun Application.configureStatusPages() {
    install(StatusPages) {
        exception<DtoValidationException> { call, cause ->
            call.respond(HttpStatusCode.BadRequest,
                ApiError(code = "validation_error", message = "Validation failed", details = cause.details))
        }
        exception<IllegalArgumentException> { call, cause ->
            call.respond(HttpStatusCode.BadRequest,
                ApiError(code = "validation_error", message = cause.message ?: "Invalid request"))
        }
        exception<NotFoundException> { call, cause ->
            call.respond(HttpStatusCode.NotFound,
                ApiError(code = "not_found", message = cause.message ?: "Resource not found"))
        }
        exception<ConflictException> { call, cause ->
            call.respond(HttpStatusCode.Conflict,
                ApiError(code = "conflict", message = cause.message ?: "Resource conflict"))
        }
        exception<Throwable> { call, cause ->
            application.log.error("Unhandled exception", cause)
            call.respond(HttpStatusCode.InternalServerError,
                ApiError(code = "internal_error", message = "An unexpected error occurred"))
        }
    }
}
```

Define domain exceptions in `domain/exception/` (pure Kotlin, no framework imports):

```kotlin
class NotFoundException(message: String) : RuntimeException(message)
class ConflictException(message: String) : RuntimeException(message)
class ForbiddenException(message: String) : RuntimeException(message)
```

## Versioned Routing

### Application Module

```kotlin
fun Application.module() {
    configureContentNegotiation()
    configureStatusPages()

    routing {
        route("/api/v1") {
            taskRoutes()
            projectRoutes()
        }
        swaggerUI(path = "swagger", swaggerFile = "openapi/documentation.yaml")
    }
}
```

### Route Files

Each resource gets its own file in `adapter/input/rest/`. Route functions are extensions on `Route` and receive use cases via DI (Koin `inject()`).

```kotlin
// adapter/input/rest/TaskRoutes.kt
fun Route.taskRoutes() {
    val createTask by inject<CreateTaskUseCase>()
    val getTask by inject<GetTaskUseCase>()
    val listTasks by inject<ListTasksUseCase>()
    val updateTask by inject<UpdateTaskUseCase>()
    val deleteTask by inject<DeleteTaskUseCase>()

    route("/tasks") {
        get {
            val pagination = call.paginationParams()
            val (tasks, totalCount) = listTasks.execute(pagination.offset, pagination.pageSize)
            call.respond(HttpStatusCode.OK, ApiResponse(
                data = tasks.map { it.toResponseDto() },
                meta = ApiResponse.Meta(
                    page = pagination.page,
                    pageSize = pagination.pageSize,
                    totalCount = totalCount,
                    hasNext = (pagination.page * pagination.pageSize) < totalCount,
                ),
            ))
        }

        post {
            val dto = call.receive<CreateTaskRequestDto>().validateDto()
            val task = createTask.execute(dto.toCommand()) // extension in mapper file
            call.respond(HttpStatusCode.Created, ApiResponse(data = task.toResponseDto()))
        }

        route("/{taskId}") {
            get {
                val taskId = call.pathParam("taskId")
                val task = getTask.execute(taskId)
                call.respond(HttpStatusCode.OK, ApiResponse(data = task.toResponseDto()))
            }
            put {
                val taskId = call.pathParam("taskId")
                val dto = call.receive<UpdateTaskRequestDto>().validateDto()
                val task = updateTask.execute(taskId, dto.toCommand()) // extension in mapper file
                call.respond(HttpStatusCode.OK, ApiResponse(data = task.toResponseDto()))
            }
            delete {
                val taskId = call.pathParam("taskId")
                deleteTask.execute(taskId)
                call.respond(HttpStatusCode.NoContent)
            }
        }
    }
}
```

## Pagination

### PaginationParams

```kotlin
data class PaginationParams(
    val page: Int = 1,
    val pageSize: Int = 20,
) {
    init {
        require(page >= 1) { "page must be >= 1" }
        require(pageSize in 1..100) { "page_size must be between 1 and 100" }
    }

    val offset: Int get() = (page - 1) * pageSize
}

fun ApplicationCall.paginationParams(): PaginationParams {
    val page = request.queryParameters["page"]?.toIntOrNull() ?: 1
    val pageSize = request.queryParameters["page_size"]?.toIntOrNull() ?: 20
    return PaginationParams(page = page, pageSize = pageSize)
}

fun ApplicationCall.pathParam(name: String): String =
    parameters[name] ?: throw IllegalArgumentException("Missing $name")
```

### Filtering and Sorting

Pass query parameters as filter criteria to the use case. Extract `status`, `priority`, etc. from `call.request.queryParameters` and pass them as a filter object to the use case alongside pagination params.

```
GET /api/v1/tasks?status=pending&priority=3      # filtering
GET /api/v1/tasks?sort=-created_at               # descending by created_at
GET /api/v1/tasks?sort=priority,-updated_at      # multi-field sort
```

## OpenAPI and Swagger UI

### Setup

Place the spec file at `server/src/main/resources/openapi/documentation.yaml`. Serve it in routing:

```kotlin
routing {
    route("/api/v1") { /* ... routes ... */ }
    swaggerUI(path = "swagger", swaggerFile = "openapi/documentation.yaml")
}
```

Swagger UI is available at `http://localhost:8080/swagger`.

### OpenAPI Spec Structure

Every endpoint and DTO must be documented. The spec follows this structure:

```yaml
openapi: 3.1.0
info:
  title: TodoistIA API
  version: 1.0.0
paths:
  /api/v1/{resource}:
    get:
      summary: List resources
      operationId: listResources
      parameters: [...]         # Query params with types and defaults
      responses:
        "200":
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/ResourceListResponse"
    post:
      requestBody:
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/CreateResourceRequest"
      responses:
        "201": { ... }
        "400":
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/ApiError"

components:
  schemas:
    CreateResourceRequest: { ... }    # All fields in snake_case
    ResourceResponse: { ... }         # Matches @SerialName fields
    ResourceSingleResponse:           # Wraps data field
      properties:
        data: { $ref: "#/components/schemas/ResourceResponse" }
    ResourceListResponse:             # Wraps data + meta
      properties:
        data: { type: array, items: { $ref: "..." } }
        meta: { $ref: "#/components/schemas/PaginationMeta" }
    PaginationMeta: { ... }
    ApiError: { ... }
    FieldError: { ... }
```

For the complete template with all schemas, read `references/openapi-template.yaml` in this skill directory. Copy it as the starting point for `server/src/main/resources/openapi/documentation.yaml`.

### When Adding a New Endpoint

1. Create the Ktor route in `adapter/input/rest/`
2. Define request/response DTOs (ending with `Dto`) with `@SerialName` and Jakarta validation annotations
3. Create mapper extension functions in a separate file
4. Add the path to the `paths:` section in `documentation.yaml`
5. Add any new schemas to the `components/schemas:` section
6. Include both success and error response schemas

## API Design Checklist

Before merging any API change, verify:

**URL and Routing**
- [ ] Resource path uses plural nouns in kebab-case
- [ ] Route is under `/api/v1/`
- [ ] No verbs in the URL path
- [ ] Path parameters use `{camelCase}` naming
- [ ] Query parameters use `snake_case` naming

**DTOs and Serialization**
- [ ] DTO class names end with `Dto` (e.g., `CreateTaskRequestDto`, `TaskResponseDto`)
- [ ] Request and response DTOs are separate `@Serializable` data classes
- [ ] All JSON fields use explicit `@SerialName("snake_case")` annotations
- [ ] DTOs are pure data carriers — no mapper functions or business logic inside
- [ ] Request DTOs use Jakarta `@field:` validation annotations (`@NotBlank`, `@Size`, `@Min`, etc.)
- [ ] Mapping functions are extension functions in separate mapper files

**Response Format**
- [ ] Success responses wrapped in `ApiResponse(data = ...)`
- [ ] Error responses use `ApiError(code = ..., message = ...)`
- [ ] Correct HTTP status code (201 for creation, 204 for deletion, etc.)
- [ ] List endpoints include `ApiResponse.Meta` with pagination info

**Error Handling**
- [ ] Domain exceptions mapped in StatusPages plugin
- [ ] No try/catch in route handlers (let StatusPages handle it)
- [ ] Error responses never leak stack traces or internal details
- [ ] Validation errors include field-level `details` in ApiError

**OpenAPI**
- [ ] Endpoint documented in `openapi/documentation.yaml`
- [ ] Request body schema defined with required fields and constraints
- [ ] Response schemas defined for success and error cases
- [ ] Query parameters documented with types and defaults
- [ ] New DTO schemas added to `components/schemas`

**Hexagonal Compliance**
- [ ] Route handler only maps DTOs and delegates to use cases
- [ ] No domain imports in route files (only adapter-layer types)
- [ ] DTO-to-domain mapping via extension functions, not inline in routes
- [ ] Use cases injected via Koin `inject()`, not instantiated directly
