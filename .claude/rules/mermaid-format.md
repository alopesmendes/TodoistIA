# Mermaid Diagram Formatting Standards

All diagrams in this project must follow these rules. They apply to every Mermaid block regardless of type or context.

## Universal Requirements

Every diagram MUST have a title defined in the frontmatter block:

```
---
title: My Diagram Title
---
sequenceDiagram
    ...
```

No diagram is complete without a title. A titleless diagram forces the reader to infer context from surrounding prose, which defeats the purpose.

## Label Rules

Keep node, class, and entity labels concise — labels name things, they don't describe them. If you need to add context, use a `note` block.

```
// WRONG
A["This is a service that processes incoming task data and writes it to the database"]

// CORRECT
A["TaskProcessor"]
note right of A: Validates and persists incoming tasks
```

## Line Routing

Never write descriptive text on connecting lines. Lines show direction and connection — not prose. Use notes for additional context.

```
// WRONG
A -->|"called when the user submits the form"| B

// CORRECT
A --> B
note right of B: Triggered on form submit
```

For flowcharts where routing cleanliness matters, prefer orthogonal curves:

```
%%{init: {'flowchart': {'curve': 'orthogonal'}}}%%
flowchart TD
    ...
```

## Diagram Size

A diagram should be understandable in under 30 seconds. If it's getting crowded:
- Cap at ~15–20 nodes for flowcharts and class diagrams
- Split into focused sub-diagrams, each with its own title
- Use `subgraph` blocks to group related concerns within a single flowchart

## Color Coding by Architectural Layer

Use `classDef` to visually distinguish the KMP architecture layers. Apply consistently across all technical diagrams:

```
classDef domain fill:#dbeafe,stroke:#2563eb,color:#1e3a5f
classDef data fill:#dcfce7,stroke:#16a34a,color:#14532d
classDef ui fill:#fef9c3,stroke:#ca8a04,color:#713f12
```

| Layer        | Class    | Applies To                                     |
|--------------|----------|------------------------------------------------|
| Domain       | `domain` | Entities, use cases, repository interfaces     |
| Data         | `data`   | Repository implementations, DAOs, API clients  |
| Presentation | `ui`     | ViewModels, Compose screens                    |

## classDiagram Arrow Types

Use semantic arrow types instead of labeled `-->` arrows. Let the arrow shape communicate the relationship.

| Arrow   | Meaning                    | Use for                                          |
|---------|----------------------------|--------------------------------------------------|
| `<\|--` | Inheritance                | Class extends another class                      |
| `..\|>` | Realization                | Class implements an interface                    |
| `..>`   | Dependency                 | Module/class uses or depends on another          |
| `-->`   | Association                | Has-a relationship (field or property)           |
| `*--`   | Composition                | Owns (lifecycle tied to parent)                  |
| `o--`   | Aggregation                | Contains (independent lifecycle)                 |

Never write `Class --> Other : text label`. Instead choose the arrow type that encodes the relationship semantically.

## Diagram Type Reference

| Type               | Use For                                        |
|--------------------|------------------------------------------------|
| `classDiagram`     | Domain models, interfaces, class hierarchy     |
| `sequenceDiagram`  | API calls, coroutine flows, event sequences    |
| `stateDiagram-v2`  | Sealed class states, ViewModel state machine   |
| `erDiagram`        | Database schema, entity relationships          |
| `flowchart`        | Business logic, decision trees, user journeys  |
| `graph`            | Module dependencies, component graphs          |
| `C4Context`        | System-level architecture, component boundaries|
| `timeline`         | Project phases, release history                |
| `mindmap`          | Concept maps, feature breakdowns               |
| `quadrantChart`    | Prioritization, trade-off analysis             |
