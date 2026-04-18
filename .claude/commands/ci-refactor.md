---
description: Refactor existing CI/CD workflows to meet kmp-devops standards.
---

Invoke the `kmp-devops` skill. Refactor the workflow(s) the user names (or infer scope from context).

Steps:
1. List the workflows in scope. For each, flag violations: raw library CLI calls, duplicated steps, hardcoded versions, missing concurrency/timeouts/cache, wrong path filters, secrets mishandling.
2. For every raw CLI call, add or reuse a Gradle task wrapping it (intent-named: `staticAnalysis`, `coverageReport`, `dockerBuild`, etc.). Replace the step with `./gradlew :module:task --no-daemon`.
3. Extract duplicated blocks across workflows into reusable workflows (`on: workflow_call`) and call with `uses: ./.github/workflows/xxx.yml`.
4. Keep task names stable so future library swaps don't touch YAML.
5. Never widen secret scope or disable existing guards (concurrency, timeouts, protected-branch cache rules).
6. Report: violations found, Gradle tasks created, files changed, and a grep showing zero remaining raw-CLI steps.

$ARGUMENTS