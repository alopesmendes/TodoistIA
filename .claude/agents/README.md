# agents/ — Specialized Sub-Agents

Sub-agents are autonomous workers launched for focused tasks. Each has its own model, tools, and memory.

## Available Agents

| Agent                    | Trigger                                                             | Model |
|--------------------------|---------------------------------------------------------------------|-------|
| `planner`                | Complex feature → needs implementation plan                         | —     |
| `architect`              | Architectural decision or module design                             | —     |
| `tdd-guide`              | New feature, bug fix, or refactor needing tests                     | —     |
| `code-reviewer-backend`  | After writing Ktor routes, DTOs, server config                      | —     |
| `code-reviewer-domain`   | After writing domain models, use cases, repos                       | —     |
| `code-reviewer-frontend` | After writing Compose UI, ViewModels, navigation                    | —     |
| `build-resolver`         | Gradle build or compilation failure                                 | —     |
| `dependency-checker`     | Scan libs.versions.toml for available updates, classify by tier     | sonnet|
| `doc-updater`            | After features ship, business rules change, or content ideas emerge | haiku |

## How They Work

- Agents are launched via the `Agent` tool, either by commands or proactively
- Each agent file defines: name, description, model, and a system prompt
- Agents can have persistent memory in `agent-memory/<agent-name>/`

## Example

```
# Claude detects a build failure and launches automatically:
Agent(subagent_type="build-resolver", prompt="Fix: Unresolved reference 'TaskId' in server module")

# User runs /code-review, which launches the right reviewer:
Agent(subagent_type="code-reviewer-backend", prompt="Review the new POST /tasks endpoint")
```

## Adding a New Agent

Create `<agent-name>.md` with this frontmatter:

```yaml
---
name: my-agent
description: "When and why to use this agent"
model: haiku  # optional: haiku, sonnet, opus
---

System prompt for the agent goes here.
```
