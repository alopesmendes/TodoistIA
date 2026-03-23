---
name: Multi-target KMP CI/CD workflow structure
category: workflow
seen_count: 1
first_seen: 2026-03-22
last_seen: 2026-03-22
source: auto-extracted
---

# Multi-Target KMP CI/CD Workflow Structure

## Context
Kotlin Multiplatform (KMP) projects often have multiple build targets (mobile, server, webapp, desktop). Each target may have different build requirements and timelines. Structuring CI/CD to support this without duplication is essential.

## Pattern

Use **reusable workflows** (`workflow_call`) combined with **per-target entry workflows** to reduce duplication and improve maintainability.

### Workflow Hierarchy

```
Entry Workflows (per target)
├── ci-mobile.yml
├── ci-server.yml
├── ci-webapp.yml
└── ci-desktop.yml
         ↓
     Shared Reusable Jobs
├── lint.yml (workflow_call)
├── code-analysis.yml (workflow_call)
├── version-bump.yml (workflow_call)
├── release.yml (workflow_call)
└── dependency-audit.yml (workflow_call)
```

### Entry Workflow (ci-mobile.yml)

Each target-specific workflow:
1. Defines input parameters (via `workflow_dispatch`)
2. Calls shared workflows where appropriate
3. Runs target-specific build jobs
4. Chains jobs with `needs:` to create a DAG

```yaml
name: ci-mobile
on:
  pull_request:
    branches: ["master", "develop", "staging"]
  workflow_dispatch:
    inputs:
      environment:
        type: choice
        options: [development, test, staging, production]
      build_android:
        type: boolean
        default: true
      build_ios:
        type: boolean
        default: true

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  lint:
    uses: ./.github/workflows/lint.yml

  audit:
    uses: ./.github/workflows/dependency-audit.yml
    secrets: inherit

  build-android:
    needs: [lint, audit]
    if: github.event_name != 'workflow_dispatch' || inputs.build_android
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./gradlew :androidApp:compileDebugKotlin --no-daemon

  build-ios:
    needs: [lint, audit]
    if: github.event_name != 'workflow_dispatch' || inputs.build_ios
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./gradlew :composeApp:compileKotlinIosSimulatorArm64 --no-daemon
```

### Reusable Workflow (lint.yml)

Shared workflows use `on: workflow_call`:

```yaml
name: lint

on:
  workflow_call:
  workflow_dispatch:

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          java-version: "17"
          distribution: "temurin"
      - uses: gradle/actions/setup-gradle@v4
      - run: ./gradlew lintCheck --no-daemon
```

### Conditional Job Execution

Use `workflow_dispatch` inputs to allow flexible scheduling:

```yaml
build-android:
  if: >-
    !cancelled() &&
    (github.event_name != 'workflow_dispatch' || inputs.build_android)
  runs-on: ubuntu-latest
```

This means:
- **On PR**: Always run (`!cancelled()`)
- **On manual dispatch**: Only run if explicitly enabled

### Environment-Specific Configuration

Use inputs for deployment and version management:

```yaml
inputs:
  environment:
    description: "Target environment"
    type: choice
    options:
      - development
      - test
      - staging
      - production
    default: development
  version_patch:
    type: boolean
    default: false
  version_minor:
    type: boolean
    default: false
  deploy:
    type: boolean
    default: false

version:
  if: ${{ github.event_name == 'workflow_dispatch' }}
  uses: ./.github/workflows/version-bump.yml
  with:
    module: ${{ inputs.module }}
    version_patch: ${{ inputs.version_patch }}
    is_production: ${{ inputs.environment == 'production' }}
```

### Job Dependency Chain

Use `needs:` to create explicit DAG of job execution:

```
lint → ──┐
audit ──→ build-android → code-analysis → release
         └ build-ios ───┘
```

Example:
```yaml
code-analysis:
  needs: [build-android, build-ios]
  if: >-
    !cancelled() &&
    (needs.build-android.result == 'success' || needs.build-android.result == 'skipped') &&
    (needs.build-ios.result == 'success' || needs.build-ios.result == 'skipped')
```

## Why This Matters

- **DRY principle**: Lint, audit, and analysis workflows are defined once and reused
- **Flexibility**: Each target can opt into specific builds (mobile builds both, server builds only server)
- **Parallelization**: Independent jobs run in parallel (android + ios build at same time)
- **Clear dependencies**: DAG makes it obvious which jobs block which
- **Maintainability**: Changes to shared workflow automatically apply to all targets

## Best Practices

1. **Always use `secrets: inherit`** when calling workflows that need credentials
2. **Use `concurrency` groups** to cancel in-progress runs on the same ref
3. **Conditionally skip jobs** via `workflow_dispatch` inputs for cost control
4. **Pass outputs between workflows** for version info, artifacts, etc.
5. **Version per module**: Each target (mobile, server, etc.) has independent versioning

## Related Patterns
- `workflow/kmp-gradle-compile-tasks` — Correct Gradle tasks for each KMP target
- `tool-usage/github-actions-environment-variable-pattern` — Managing configuration and secrets
