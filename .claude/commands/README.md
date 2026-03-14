# commands/ — Slash Commands

Slash commands are user-invocable prompts triggered with `/command-name` in the conversation.

## Available Commands

| Command           | Purpose                                                                  |
|-------------------|--------------------------------------------------------------------------|
| `/tdd`            | TDD workflow: scaffold → test → implement → refactor → coverage          |
| `/build-fix`      | Diagnose and fix Gradle build errors                                     |
| `/code-review`    | Review code against project standards                                    |
| `/test-coverage`  | Analyze Kover coverage, fill gaps to 80%+                                |
| `/docs`           | Write or update a doc file — create new or reshape existing (clean/easier/detailed/custom) |
| `/update-docs`    | Structural doc operations: insert, delete, or correct across all axes    |
| `/plan`           | Plan implementation for a complex feature                                |
| `/verify`         | Verify code at local, feature, or project level                          |
| `/checkpoint`     | Save progress snapshot                                                   |
| `/refactor-clean` | Refactor code for clarity and simplicity                                 |
| `/sessions`       | Manage session context                                                   |
| `/eval`           | Run eval-driven development checks                                       |
| `/learn`          | Extract reusable patterns from the session                               |
| `/learn-eval`     | Learn + self-evaluate quality before saving                              |
| `/usage-token`    | Token usage summary: context remaining, project vs non-project breakdown |
| `/upgrade`        | Upgrade dependencies with tier-aware verification (patch/minor/major)    |
| `/orchestrate`    | Orchestrate multi-agent workflows                                        |

## How They Work

- User types `/tdd I need a use case for task prioritization`
- Claude loads the command's markdown file as a prompt
- The command's `description` field in frontmatter helps Claude match it to user intent

## Example

```
User: /tdd I need a GetTasksUseCase
→ Loads tdd.md, launches tdd-guide agent, follows RED-GREEN-REFACTOR cycle

User: /update-docs technical insert new shared module "task-ai"
→ Loads update-docs.md, launches doc-updater agent for technical axis
```

## Adding a New Command

Create `<command-name>.md` with this frontmatter:

```yaml
---
description: One-line description of what this command does.
---

# Command Name

Prompt instructions go here.
```
