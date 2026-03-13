# Plan

Generate an implementation plan for a feature, epic, or refactoring task using the **planner** agent.

## Arguments

$ARGUMENTS — Describe what you want to plan: a feature, epic, or refactoring task. Be as specific as possible (e.g., "user authentication with JWT", "task CRUD with offline sync", "migrate from Room to SQLDelight").

## Instructions

Launch the **planner** agent (`subagent_type: planner`) with the following prompt:

---

**Context**: The user wants to plan the following work for the TodoistIA KMP project:

> $ARGUMENTS

**Your job**:

1. **Explore the codebase first** — use Glob and Grep to understand the current project structure, existing modules, and conventions before producing a plan. Check `shared/`, `server/`, `composeApp/`, `build-logic/`, `gradle/libs.versions.toml`, and any existing source files.

2. **Scope the epic** — state the goal in one sentence, list what is IN scope and OUT of scope, and identify which categories are affected (ci-cd, infra, backend, frontend, cross-cutting).

3. **Map dependencies** — build a dependency graph showing the order in which issues should be tackled.

4. **Generate issues bottom-up** following the wave system:
   - **Wave 1 — Foundation**: infra, ci-cd/build, backend/domain, frontend/design-system
   - **Wave 2 — Core**: backend/application, backend/infrastructure, backend/api, frontend/navigation, ci-cd/test
   - **Wave 3 — Features**: frontend/feature, frontend/responsive, frontend/platform, cross-cutting
   - **Wave 4 — Ship**: ci-cd/release, infra/monitoring, ci-cd/quality

5. **Each issue** must follow the template:
   ```
   ## [category/sub-category] Title
   **Description**: What and why (2-4 sentences)
   **Acceptance Criteria**:
   - [ ] Criterion 1
   - [ ] Criterion 2
   - [ ] Tests written and passing
   **Technical Notes**: Key files, dependencies, risk level
   **Size**: S / M / L (no XL — split instead)
   **Priority**: P0 / P1 / P2 / P3
   ```

6. **Enforce architecture rules**:
   - Backend: domain has zero framework imports, ports as interfaces in application/, adapters in infrastructure/, API controllers call use cases only
   - Frontend: WindowSizeClass drives layout, shared UI in shared/ui/, adaptive patterns over conditionals, expect/actual for platform needs

7. **Assign milestones** — map waves to milestones with exit criteria.

8. **List risks and mitigations**.

9. **Output the full plan** using the structured format from the planner agent definition.

---

After the planner agent returns, present the plan to the user and ask if they want to:
- Refine or adjust any issues
- Create the GitHub Issues directly
- Save the plan to a file
