---
description: Create a new CI/CD workflow for a module following kmp-devops rules.
---

Invoke the `kmp-devops` skill. Create a new GitHub Actions workflow for the user's requested module/intent.

Steps:
1. Ask (or infer from `$ARGUMENTS`) the target module and intent if unclear.
2. Check `.github/workflows/` for a reusable workflow covering the intent — prefer calling it over duplicating.
3. For every tool invocation needed, ensure a Gradle task wraps it. If missing, create the task in the module's `build.gradle.kts` (or a convention plugin) first.
4. Write the workflow with: path filters, concurrency, timeouts, `setup-java@v5`, `setup-gradle@v5`, `cache-read-only` conditioned on protected branches, `secrets: inherit`, `workflow_dispatch` inputs where useful.
5. Every `run:` step must be `./gradlew :module:task --no-daemon` — no raw library CLI.
6. Report the created files and the Gradle tasks added.

$ARGUMENTS
