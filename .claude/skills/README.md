# skills/ — Deep Reference Material

Skills provide detailed, domain-specific knowledge that Claude loads on demand when a topic matches. They are heavier than rules — think "reference manual" vs "checklist".

## Available Skills

| Skill                     | Triggers On                                                   |
|---------------------------|---------------------------------------------------------------|
| `api-design`              | Endpoints, DTOs, REST design, Swagger, OpenAPI                |
| `article-writing`         | Writing, publishing, blogging, community content              |
| `coding-standards`        | Naming, structure, KISS/DRY/YAGNI, cross-language conventions |
| `continuos-learning`      | Pattern extraction and learning across sessions               |
| `eval-harness`            | Success criteria, regression tests, pass@k metrics            |
| `functional-docs`         | Business rules, features, DDD glossary, user scenarios        |
| `kotlin-coding-standards` | Value classes, sealed classes, coroutines, Flows, Result      |
| `tdd-workflow`            | Red-Green-Refactor, kotlin.test, fake repos, coverage         |
| `technical-docs`          | Architecture, modules, data flows, Mermaid diagrams           |
| `verification-loop`       | Local/feature/full verification after code changes            |

## How They Work

- Each skill lives in its own directory with a `SKILL.md` file
- Skills can have a `references/` subdirectory for supporting material
- The `description` in SKILL.md frontmatter determines when Claude activates it
- Skills are loaded into context only when triggered — they don't consume tokens otherwise

## Example: When `kotlin-coding-standards` activates

```
User: "Create a TaskId type for the domain model"
→ Claude matches "domain model" + "type" → loads kotlin-coding-standards
→ Skill provides guidance: use @JvmInline value class, not a type alias
```

## Skills vs Rules

|                | Rules (`rules/`)              | Skills (`skills/`)                  |
|----------------|-------------------------------|-------------------------------------|
| **Loaded**     | Always (every conversation)   | On demand (when triggered)          |
| **Token cost** | Constant                      | Only when relevant                  |
| **Content**    | Short checklists, conventions | Deep reference, examples, workflows |
| **Purpose**    | "What to do"                  | "How to do it"                      |

## Adding a New Skill

```
skills/
└── my-skill/
    ├── SKILL.md           # Frontmatter + detailed content
    └── references/        # Optional supporting files
```

Frontmatter:

```yaml
---
name: my-skill
description: When and why this skill should activate. Be specific — this text determines trigger accuracy.
---
```
