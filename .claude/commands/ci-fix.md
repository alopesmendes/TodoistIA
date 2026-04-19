---
description: Diagnose and fix a broken CI/CD workflow using kmp-devops rules.
---

Invoke the `kmp-devops` skill. Fix the failing workflow the user names (or infer from recent git/log context).

Steps:
1. Read the failing workflow YAML and the run log if provided.
2. Reproduce locally with the same `./gradlew :module:task` — do not change anything yet.
3. If local passes: suspect environment (Java version, runner OS, secrets, cache pollution). Fix in YAML.
4. If local fails: fix the Gradle task, not the workflow. Workflow YAML patches for build logic are a smell.
5. Preserve `concurrency`, timeouts, secret wiring, path filters. Do not widen them silently.
6. Report root cause, the minimal diff, and why it was not a workflow-only workaround.

$ARGUMENTS