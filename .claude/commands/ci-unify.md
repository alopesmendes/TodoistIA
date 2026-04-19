---
description: Unify shared CI/CD parts across modules via reusable workflows — without collapsing the per-module split.
---

Invoke the `kmp-devops` skill. Unify the duplicated parts of the workflows the user names (or audit all `ci-*.yml`).

Important: per-module leaf workflows exist on purpose — blast radius. Do not merge them into one monolithic workflow. Unify by extracting **shared parts** into reusable workflows and keeping leaves thin.

Steps:
1. Diff the named workflows; list steps and env blocks that repeat.
2. For each repeated block, create (or extend) a reusable workflow with `on: workflow_call`, parameterized by `module`, `module_paths`, `version`, etc. Pass secrets via `secrets: inherit`.
3. Replace the duplicated blocks in leaves with `uses: ./.github/workflows/xxx.yml` calls.
4. Ensure every step in the reusable workflow runs a Gradle task; if it doesn't, create the task first.
5. Preserve per-module path filters, concurrency, and workflow_dispatch inputs on the leaves.
6. Report: what was extracted, what stayed per-module, and why.

$ARGUMENTS