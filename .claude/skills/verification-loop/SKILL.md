---
name: verification-loop
description: Verification system for Claude Code sessions on this KMP project. Three levels — local (just the added code), feature (the full feature being built), and full project (nothing is broken). Use this skill proactively after completing any code change, before proposing a commit, after refactoring, or when the user asks to verify, validate, check, or make sure things are working — even if they don't use the word "verify."
origin: ECC
tools: Read, Write, Bash, Grep, Glob
---

# Verification Loop — Kotlin Multiplatform

A three-level verification system for local quality checks. Run the appropriate level depending on the scope of the change.

---

## Level 1 — Local (just the added code)

Use after completing a small change, a single function, or a bug fix. Fast feedback loop.

### 1a. Compile the affected module

```bash
# shared module (business logic)
./gradlew shared:compileKotlinJvm

# composeApp (UI + ViewModels)
./gradlew composeApp:compileKotlinJvm

# server (Ktor)
./gradlew server:compileKotlin
```

If compilation fails, stop and fix before continuing.

### 1b. Run tests for the affected module (JVM only — fastest)

```bash
./gradlew shared:jvmTest
# or
./gradlew composeApp:jvmTest
# or
./gradlew server:test
```

### 1c. Lint check

```bash
./gradlew shared:ktlintCheck
./gradlew composeApp:ktlintCheck
./gradlew server:ktlintCheck
```

> If ktlint is not yet configured, skip this step and note it in the report.

### Level 1 Report

```
LEVEL 1 — LOCAL VERIFICATION
=============================
Module:      [shared / composeApp / server]
Compile:     [PASS / FAIL]
Tests:       [PASS / FAIL] (X passed, Y failed)
Lint:        [PASS / FAIL / NOT CONFIGURED]

Status: [READY / NEEDS FIXES]
```

---

## Level 2 — Feature (the full feature being developed)

Use when a feature spans multiple files or layers (e.g., domain + use case + ViewModel). Verifies the feature end-to-end within its module.

### 2a. Compile all affected modules

```bash
./gradlew shared:compileKotlinJvm composeApp:compileKotlinJvm
```

### 2b. Run all unit tests for affected modules

```bash
./gradlew shared:jvmTest composeApp:jvmTest
```

### 2c. Lint all affected modules

```bash
./gradlew shared:ktlintCheck composeApp:ktlintCheck
```

### 2d. Verify test coverage (if Kover is configured)

```bash
./gradlew shared:koverVerify
```

Target: **80%+ on business logic layers** (domain, use cases, ViewModels).

### 2e. Review changed files

```bash
git diff --stat
git diff --name-only
```

Check each changed file for:
- Missing error handling
- Untested edge cases
- Unintended side effects

### Level 2 Report

```
LEVEL 2 — FEATURE VERIFICATION
================================
Feature:     [feature name]
Modules:     [list of modules]
Compile:     [PASS / FAIL]
Tests:       [PASS / FAIL] (X passed, Y failed)
Coverage:    [X% / NOT CONFIGURED]
Lint:        [PASS / FAIL / NOT CONFIGURED]
Diff:        [X files changed]

Status: [READY / NEEDS FIXES]
Issues:
1. ...
```

---

## Level 3 — Full Project (nothing is broken)

Use before proposing a commit, after a refactor that touches shared interfaces, or when something feels risky. Verifies the entire project compiles and all tests pass.

### 3a. Full build

```bash
./gradlew build
```

### 3b. All tests (all modules)

```bash
./gradlew allTests
```

### 3c. Lint all modules

```bash
./gradlew ktlintCheck
```

### 3d. Coverage verification (if configured)

```bash
./gradlew koverVerify
```

### 3e. Diff review

```bash
git diff --stat HEAD
git status
```

Look for uncommitted files that shouldn't exist, unexpected changes, or missing additions.

### Level 3 Report

```
LEVEL 3 — FULL PROJECT VERIFICATION
=====================================
Build:       [PASS / FAIL]
Tests:       [PASS / FAIL] (X passed, Y failed)
Coverage:    [X% / NOT CONFIGURED]
Lint:        [PASS / FAIL / NOT CONFIGURED]
Diff:        [X files changed, Y untracked]

Status: [READY TO COMMIT / NEEDS FIXES]
Issues:
1. ...
```

---

## Choosing the Right Level

| Situation                          | Level |
|------------------------------------|-------|
| Finished a single function or test | 1     |
| Fixed a small bug                  | 1     |
| Completed a use case or ViewModel  | 2     |
| Feature spans domain + API + UI    | 2     |
| About to commit                    | 3     |
| Refactored a shared interface      | 3     |
| Something feels broken             | 3     |

---

## CI/CD Note

This skill covers local verification only. A CI/CD pipeline will be added later — this skill will be updated to reflect those steps when available.
