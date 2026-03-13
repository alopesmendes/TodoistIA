# Orchestrate Command

Sequential and parallel agent workflow for complex tasks.

## Usage

`/orchestrate [workflow-type] [task-description]`

## Arguments

$ARGUMENTS:
- `feature <description>` — Full feature workflow
- `bugfix <description>` — Bug investigation and fix workflow
- `refactor <description>` — Safe refactoring workflow
- `review <description>` — Full code review across all layers
- `ship <description>` — Pre-merge validation workflow
- `custom <agents> <description>` — Custom agent sequence (comma-separated agent names)

## Available Agents

| Agent                    | Type     | Purpose                                           |
|--------------------------|----------|---------------------------------------------------|
| `planner`                | Planning | Break features into issues with dependency chains |
| `architect`              | Design   | System design, ADRs, boundary validation          |
| `tdd-guide`              | Testing  | Test-first development, coverage enforcement      |
| `code-reviewer-backend`  | Review   | Ktor/hexagonal architecture review                |
| `code-reviewer-domain`   | Review   | Domain models, use cases, repository interfaces   |
| `code-reviewer-frontend` | Review   | MVI architecture, responsive views                |
| `build-resolver`         | Fix      | Gradle build errors, dependency migrations        |
| `doc-updater`            | Docs     | Technical, functional, and article documentation  |
| `continuous-learning`    | Learn    | Extract reusable patterns from the session        |

## Workflow Definitions

### feature
Full feature implementation — plan, test, implement, review, document.
```
planner → tdd-guide → [code-reviewer-*] → doc-updater
```

### bugfix
Bug investigation and fix with regression test.
```
tdd-guide → [code-reviewer-*] → continuous-learning
```

### refactor
Safe refactoring with architecture validation.
```
architect → tdd-guide → [code-reviewer-*]
```

### review
Full code review across all affected layers (run relevant reviewers in parallel).
```
parallel: [code-reviewer-backend, code-reviewer-domain, code-reviewer-frontend]
```

### ship
Pre-merge validation — review, build, docs.
```
[code-reviewer-*] → build-resolver (verify build) → doc-updater
```

## Execution Pattern

For each agent in the workflow:

1. **Launch agent** with context from previous agent's output
2. **Collect output** as a structured handoff document
3. **Pass to next agent** in the chain
4. **Aggregate results** into the final report

For parallel phases (e.g., `review` workflow), launch all relevant agents simultaneously and merge their outputs.

## Choosing the Right Reviewers

The `[code-reviewer-*]` placeholder means: launch only the reviewers that match the changed layers.

| Changed area                                                    | Reviewer                 |
|-----------------------------------------------------------------|--------------------------|
| Ktor routes, DTOs, API plugins, server config                   | `code-reviewer-backend`  |
| Domain models, use cases, repository interfaces, business logic | `code-reviewer-domain`   |
| Compose UI, ViewModels, navigation, platform UI                 | `code-reviewer-frontend` |

When a change spans multiple layers, launch all relevant reviewers **in parallel**.

## Handoff Document Format

Between agents, create a handoff document:

```markdown
## HANDOFF: [previous-agent] → [next-agent]

### Context
[Summary of what was done]

### Findings
[Key discoveries or decisions]

### Files Modified
[List of files touched]

### Open Questions
[Unresolved items for next agent]

### Recommendations
[Suggested next steps]
```

## Example: Feature Workflow

```
/orchestrate feature "Add task prioritization with P0-P3 levels"
```

Executes:

1. **Planner Agent**
   - Explores codebase, scopes the feature
   - Creates implementation plan with issues by wave
   - Identifies affected layers: domain, backend API, frontend UI
   - Output: `HANDOFF: planner → tdd-guide`

2. **TDD Guide Agent**
   - Reads planner handoff
   - Scaffolds test method names for all layers
   - Waits for user validation
   - Implements RED → GREEN → REFACTOR cycle
   - Output: `HANDOFF: tdd-guide → code-reviewer`

3. **Code Reviewers (parallel)**
   - `code-reviewer-domain`: Reviews Priority value class, use cases
   - `code-reviewer-backend`: Reviews API endpoint, DTO, hexagonal boundaries
   - `code-reviewer-frontend`: Reviews MVI state, responsive views
   - Output: `HANDOFF: code-reviewer → doc-updater`

4. **Doc Updater Agent**
   - Updates technical docs (new module, data flow)
   - Updates functional docs (business rules, glossary)
   - Output: Final Report

## Example: Bugfix Workflow

```
/orchestrate bugfix "Users can create tasks with empty titles"
```

Executes:

1. **TDD Guide Agent**
   - Writes a failing regression test that reproduces the bug
   - Implements the minimal fix to make it pass
   - Output: `HANDOFF: tdd-guide → code-reviewer`

2. **Code Reviewer (matching layer)**
   - Reviews the fix for correctness and architecture compliance
   - Output: `HANDOFF: code-reviewer → continuous-learning`

3. **Continuous Learning Agent**
   - Extracts the bug pattern for future prevention
   - Output: Final Report

## Example: Custom Workflow

```
/orchestrate custom "architect,tdd-guide,code-reviewer-backend" "Redesign caching layer for server module"
```

Executes the specified agents in order, passing handoffs between each.

## Final Report Format

```
ORCHESTRATION REPORT
====================
Workflow: [type]
Task: [description]
Agents: [agent1] → [agent2] → [agent3]

SUMMARY
-------
[One paragraph summary of what was accomplished]

AGENT OUTPUTS
-------------
[Agent 1 name]: [summary of findings/output]
[Agent 2 name]: [summary of findings/output]
[Agent 3 name]: [summary of findings/output]

FILES CHANGED
-------------
[List all files created, modified, or deleted]

TEST RESULTS
------------
[Test pass/fail summary, coverage numbers]

REVIEW STATUS
-------------
| Reviewer | Verdict | CRITICAL | HIGH | MEDIUM |
|----------|---------|----------|------|--------|

RECOMMENDATION
--------------
[SHIP / NEEDS WORK / BLOCKED — with justification]
```

## Tips

1. **Start with planner** for complex features — it maps dependencies and prevents wasted work
2. **Always include a code reviewer** before merge — match reviewer to the layer changed
3. **Use tdd-guide first for bugfixes** — write the regression test before touching implementation
4. **Run reviewers in parallel** when changes span multiple layers
5. **End with doc-updater** after shipping features — keep docs in sync with code
6. **Use continuous-learning** at session end to capture reusable patterns
