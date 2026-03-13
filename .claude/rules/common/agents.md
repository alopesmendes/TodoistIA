# Agent Orchestration

## Available Agents

Located in `.claude/agents/`:

| Agent                  | Purpose                                         | When to Use                                          |
|------------------------|-------------------------------------------------|------------------------------------------------------|
| planner                | Implementation planning                         | Complex features, refactoring                        |
| architect              | System design                                   | Architectural decisions                              |
| tdd-guide              | Test-driven development                         | New features, bug fixes                              |
| code-reviewer-backend  | Backend code review                             | After writing Ktor/server-side code                  |
| code-reviewer-domain   | Domain layer code review                        | After writing domain models, use cases, repositories |
| code-reviewer-frontend | Frontend code review                            | After writing UI, ViewModels, Compose screens        |
| build-resolver         | Fix build errors                                | When build or compilation fails                      |
| doc-updater            | Documentation (technical, functional, articles) | After features, business rule changes, or publishing |

## Immediate Agent Usage

No user prompt needed — launch proactively when the situation calls for it:

1. Complex feature request → Use **planner** agent first
2. Architectural decision → Use **architect** agent
3. Bug fix or new feature → Use **tdd-guide** agent
4. Code just written or modified → Use the appropriate **code-reviewer** agent
5. Build or compilation fails → Use **build-resolver** agent
6. Feature shipped or business rules updated → Use **doc-updater** agent

## Choosing the Right Code Reviewer

There are three specialized code reviewers — pick based on what changed:

| Changed area                                                    | Use                      |
|-----------------------------------------------------------------|--------------------------|
| Ktor routes, DTOs, API plugins, server config                   | `code-reviewer-backend`  |
| Domain models, use cases, repository interfaces, business logic | `code-reviewer-domain`   |
| Compose UI, ViewModels, navigation, platform UI code            | `code-reviewer-frontend` |

When a change spans multiple layers, launch all relevant reviewers in parallel.

## Parallel Task Execution

Always use parallel Task execution for independent operations:

```markdown
# GOOD: Parallel execution
Launch 3 agents in parallel:
1. Agent 1: Domain review of new Task entity
2. Agent 2: Backend review of new Task endpoint
3. Agent 3: Frontend review of new Task screen

# BAD: Sequential when unnecessary
First agent 1, then agent 2, then agent 3
```

## Multi-Perspective Analysis

For complex problems, use split-role sub-agents to get independent perspectives:

- Domain correctness reviewer
- Senior engineer (architecture and design)
- Security expert
- Consistency reviewer (naming, patterns, conventions)
- Test coverage reviewer
