---
name: kmp-devops
description: DevOps expertise for Kotlin Multiplatform monolith projects — GitHub Actions workflows, Gradle task design, Fastlane/iOS signing, Docker, release automation. Use this skill proactively whenever the user mentions CI, CD, workflows, pipelines, release automation, GitHub Actions, Fastlane, signing, Docker, deploy, "setup ci", "add workflow", "fix workflow", "refactor ci", per-module builds, path filters, matrix jobs, caching, Gradle tasks for CI, or any DevOps/automation concern in this KMP repo — even when they don't explicitly say "devops". Also trigger on phrases like "why is my build slow", "add a job", "run this on PR", "cache this", "reusable workflow", "unify the CI", or "change this library in the workflow". The skill enforces the rule that CI steps must call Gradle tasks, not raw library commands, so that swapping tools or refactoring does not cascade across workflows.
origin: project
tools: Read, Write, Edit, Bash, Grep, Glob
---

# KMP DevOps — Workflows, Gradle Tasks, Release Automation

This skill captures how to design, create, refactor, and fix CI/CD for this Kotlin Multiplatform monolith. The repo contains `androidApp`, `composeApp`, `iosApp`, `server`, `shared`, and a web target. Each module has its own release cadence and environment matrix. Workflows must be **per-module**, **reusable**, **cacheable**, and **library-agnostic** so that swapping a tool (e.g. Kover → JaCoCo, detekt → ktlint) changes one Gradle task, not every workflow.

---

## The Cardinal Rule: Gradle Task, Not Raw Command

**Never put a library CLI invocation directly in a workflow step.** Always call a Gradle task that wraps it. This single rule delivers every maintainability property the user cares about.

```yaml
# WRONG — workflow bound to a specific tool
- run: detekt --config detekt.yml --input shared/src
- run: npx @openapitools/openapi-generator-cli generate -i spec.yaml

# CORRECT — workflow bound to an intent
- run: ./gradlew :shared:staticAnalysis
- run: ./gradlew :server:generateApiClient
```

**Why:**
- Swap the tool behind `staticAnalysis` (detekt → ktlint) without touching `.github/workflows/`.
- Local `./gradlew staticAnalysis` reproduces CI exactly. No drift.
- Gradle's task graph handles ordering, caching, and up-to-date checks for free.
- Module targeting via `:module:task` is native; path filters stay cosmetic.

If a tool has no Gradle plugin, wrap its CLI in a custom `Exec` task in the module's `build.gradle.kts`. The workflow still calls `./gradlew :module:myTask`.

---

## Project Layout You Must Respect

| Module        | Platform    | Workflow file       | Release artifact                    |
|---------------|-------------|---------------------|-------------------------------------|
| `server`      | JVM (Ktor)  | `ci-server.yml`     | Docker image                        |
| `androidApp`  | Android     | `ci-mobile.yml`     | AAB / APK, Play Store               |
| `iosApp`      | iOS         | `ci-mobile.yml`     | IPA, App Store Connect (Fastlane)   |
| `composeApp`  | Desktop     | `ci-desktop.yml`    | DMG / MSI / DEB                     |
| `composeApp`  | Web/WASM    | `ci-webapp.yml`     | Static bundle                       |
| `shared`      | Common      | consumed by others  | no standalone release               |

Shared orchestrators: `ci.yml` (umbrella), `build.yml`, `test.yml`, `lint.yml`, `code-analysis.yml`, `dependency-audit.yml`, `deploy.yml`, `release.yml`, `version-bump.yml`, `sync-staging.yml`. Leaf workflows `ci-*.yml` wire module-specific steps and call the shared reusable ones with `uses: ./.github/workflows/xxx.yml`.

**Per-module means:** a change in `iosApp/` must not rebuild the server. Use `paths:` filters on `pull_request` plus `:module:` Gradle targeting. Shared module changes trigger every consumer — this is correct and expected.

---

## Workflow Design Checklist

Before writing or accepting any workflow, confirm:

- [ ] Every build/test/lint step calls `./gradlew :module:task`, never a library CLI.
- [ ] Reusable workflows live in dedicated files and are called with `uses: ./.github/workflows/xxx.yml`.
- [ ] `concurrency` group set per workflow + ref to cancel superseded runs.
- [ ] Path filters scoped to the module + `shared/` + relevant gradle files.
- [ ] `actions/setup-java@v5` + `gradle/actions/setup-gradle@v5` with `cache-read-only` true off protected branches.
- [ ] Secrets passed via `secrets: inherit` or explicit map — never hardcoded.
- [ ] Timeouts set on every job (`timeout-minutes`).
- [ ] `needs:` uses `!cancelled() && result == 'success'` patterns so optional jobs don't block.
- [ ] `workflow_dispatch` exposes inputs for env, version bump, skip_tests, deploy toggle.
- [ ] Matrix jobs only when genuinely parallel; otherwise separate jobs for clearer logs.

---

## Caching Strategy

Gradle's own cache via `gradle/actions/setup-gradle@v5` is almost always enough. Add a second layer only when:

- **iOS**: cache `~/Library/Developer/Xcode/DerivedData` and CocoaPods (`Pods/`, `~/Library/Caches/CocoaPods`).
- **Node/Web**: cache `~/.gradle/nodejs` and `kotlin-js-store/`.
- **Docker**: use `docker/build-push-action@v5` with `cache-from`/`cache-to: type=gha`.
- **Fastlane**: cache `vendor/bundle` keyed on `Gemfile.lock`.

**Skip caching when:** the job runs under 30 seconds or the cache hit rate will be < 50% (e.g. version-bump, release tagging, sync-staging). Noise beats benefit.

Key pattern: `${{ runner.os }}-<scope>-${{ hashFiles('<lockfiles>') }}`. Always include a fallback `restore-keys` without the hash.

---

## Release & Deploy Patterns

- **Versioning**: `version-bump.yml` is the single source of truth. It reads `gradle.properties` keys like `server.version`, bumps, commits, outputs `version` and `version_changed`. Never embed `sed`/`yq` in leaf workflows.
- **Releases**: `release.yml` receives `module`, `version`, `previous_tag`, `module_paths`. It tags `<module>-v<version>`, builds a changelog from path-scoped commits, creates GH release.
- **Android release**: Fastlane `supply` — wrap in a Gradle task (`:androidApp:publishPlayStore`) that shells out to Fastlane. Workflow calls the Gradle task.
- **iOS release**: Fastlane `pilot`/`deliver` on `macos-latest`. Signing via `fastlane match` with a private certificates repo. Store `MATCH_PASSWORD`, `APP_STORE_CONNECT_API_KEY` as secrets. Wrap in `:iosApp:deployTestFlight` Gradle task.
- **Server release**: Docker build → push to registry → deploy. `:server:dockerBuild` (Gradle) builds the image; workflow handles push/deploy. Never `docker build` directly in the workflow step unless no Gradle plugin applies.
- **Desktop release**: `:composeApp:packageReleaseDistributionForCurrentOS` via Compose plugin. Matrix over `macos`/`windows`/`ubuntu` runners.
- **Web release**: `:composeApp:wasmJsBrowserDistribution` → deploy static bundle.

Protected branches (`master`, `develop`, `staging`) get `cache-read-only: false`; feature branches get `true` to avoid cache pollution.

---

## Library Swap Safety

Because every CI step calls a Gradle task, swapping a library means:

1. Change the plugin/dep in `libs.versions.toml` and the module `build.gradle.kts`.
2. Keep the task name stable (`staticAnalysis`, `coverageReport`, `securityScan`).
3. Workflows keep working untouched.

When you must rename a task, grep every workflow file before committing:

```bash
grep -rn "gradlew.*:oldTaskName" .github/workflows/
```

---

## When Creating a New Workflow

Follow this order:

1. Identify the intent (lint, build, test, deploy, release, analyze).
2. Check if a reusable workflow already exists — extend or call it.
3. For every step that runs a tool, ensure a Gradle task wraps it. Create the task first if missing.
4. Scope path filters to the target module(s) + `shared/` + `gradle/`, `*.gradle.kts`, `libs.versions.toml`.
5. Wire concurrency, timeouts, secrets, cache.
6. Add `workflow_dispatch` with inputs if humans need to trigger it.
7. Test by pushing to a draft branch — never test on `master`.

## When Fixing a Broken Workflow

1. Read the failing run log before changing anything.
2. Reproduce locally with the same Gradle task. If it passes locally, suspect environment (secrets, runner OS, Java version).
3. Prefer fixing the Gradle task over adding workflow workarounds. A `shell: bash` patch in YAML is almost always a smell.
4. If you must add a workflow-only step, leave a comment explaining why it can't be a Gradle task.

## When Refactoring Workflows

1. Extract duplicated steps into a reusable workflow (`.github/workflows/xxx.yml` with `on: workflow_call`).
2. Collapse per-library steps (`- run: detekt`, `- run: ktlint`) into one Gradle aggregate task (`staticAnalysis`).
3. Move env/secret wiring into the reusable workflow so callers pass `secrets: inherit`.
4. Validate with `act` or a draft PR. Keep a rollback commit ready.

## When Unifying CI

When the user asks to "unify" — merge multiple leaf workflows into one — resist unless the modules truly share everything. The per-module split exists to keep blast radius small. Instead, unify by extracting the **shared parts** into reusable workflows, keeping leaves thin.

---

## Gradle Task Naming Conventions

Group by intent, not tool. Intent-named tasks survive library swaps.

| Intent                 | Task name                  | Typical backing tool           |
|------------------------|----------------------------|--------------------------------|
| Static analysis        | `staticAnalysis`           | detekt / ktlint                |
| Coverage report        | `coverageReport`           | Kover / JaCoCo                 |
| Security scan (deps)   | `securityScan`             | OWASP DC / dependency-check    |
| Security scan (code)   | `securityReview`           | CodeQL / detekt rules          |
| API client gen         | `generateApiClient`        | OpenAPI Generator              |
| Docker image           | `dockerBuild` / `dockerPush` | jib / bmuschko-docker        |
| Play Store upload      | `publishPlayStore`         | Fastlane supply                |
| TestFlight upload      | `deployTestFlight`         | Fastlane pilot                 |
| Desktop package        | `packageRelease`           | Compose Desktop plugin         |
| Web bundle             | `buildWebBundle`           | KotlinJS / WASM                |

Put these in `buildSrc/` or `build-logic/` convention plugins so every module inherits consistent tasks.

---

## Red Flags to Push Back On

If the user (or existing code) does any of these, raise it:

- Installing a library in a workflow step (`npm i -g ...`, `brew install ...`) when a Gradle plugin exists.
- Duplicating build steps across `ci-android.yml` and `ci-ios.yml` instead of a reusable workflow.
- Hardcoded versions in workflow YAML (Java, Gradle, Node) when they belong in `.tool-versions` or `libs.versions.toml`.
- `--no-daemon` missing on CI Gradle calls. Include it — the daemon is wasted on one-shot runners.
- Secrets written to logs, or `echo $TOKEN`-style debugging left in.
- Running all modules' tests on every PR regardless of path.

---

## Quick Reference: Environment Matrix

This repo's envs map cleanly to GitHub `vars`/`secrets` and `APP_ENV`:

| Environment  | Branch    | `APP_ENV` | Deploy target          |
|--------------|-----------|-----------|------------------------|
| development  | feature/* | `dev`     | none (build only)      |
| test         | develop   | `test`    | ephemeral / CI         |
| staging      | staging   | `staging` | staging cluster        |
| production   | master    | `prod`    | prod cluster / stores  |

Workflow `workflow_dispatch` input `environment` picks the value explicitly. Otherwise infer from `github.ref`.

---

## See Also

- `.claude/rules/common/security.md` — no secrets in YAML, ever.
- `.claude/skills/code-analysis/SKILL.md` — how analysis tasks plug into CI.
- `.claude/skills/dependency-upgrade/SKILL.md` — coordinating upgrades that touch CI.
- `.github/workflows/ci-server.yml` — reference pattern for a leaf workflow done right.
