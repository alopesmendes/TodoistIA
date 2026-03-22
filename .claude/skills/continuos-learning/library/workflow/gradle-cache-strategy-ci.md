---
name: Gradle cache strategy in GitHub Actions CI
category: workflow
seen_count: 1
first_seen: 2026-03-22
last_seen: 2026-03-22
source: auto-extracted
---

# Gradle Cache Strategy in GitHub Actions CI

## Context
Gradle builds can be slow if you rebuild dependency caches on every run. GitHub Actions provides a Gradle setup action that handles caching, but the cache strategy differs between protected branches (master, develop, staging) and feature branches.

## Pattern

Use the **official Gradle setup action** with a **branch-aware cache-read-only strategy**:

```yaml
- name: Setup Gradle
  uses: gradle/actions/setup-gradle@v4
  with:
    cache-read-only: ${{ !contains(fromJson('["refs/heads/master","refs/heads/develop","refs/heads/staging"]'), github.ref) }}
```

### How It Works

| Branch Type        | `cache-read-only` | Behavior                                                 |
|--------------------|-------------------|----------------------------------------------------------|
| master/develop     | `false`           | Read **and write** to cache; save build artifacts        |
| Feature/PR branches| `true`            | Read cache only; don't save artifacts (save time, space) |

### Logic Breakdown

```yaml
!contains(fromJson('["refs/heads/master","refs/heads/develop","refs/heads/staging"]'), github.ref)
```

Translates to:
- If branch is in the list → contains returns `true` → `!true` = `false` → Cache is read/write
- If branch is not in the list → contains returns `false` → `!false` = `true` → Cache is read-only

### Protected Branches

These branches should write to cache:
- `refs/heads/master` — Main release branch
- `refs/heads/develop` — Integration branch
- `refs/heads/staging` — Staging/pre-prod

All other branches (feature branches, PRs) read from cache but don't write.

### Why This Strategy

1. **Cost**: Feature branches don't pollute cache with experimental builds
2. **Cache hit rate**: Keeping cache clean means better hit rates from protected branches
3. **Speed**: Reading from cache is much faster than rebuilding dependencies
4. **Disk space**: GitHub has cache storage limits; writing selectively keeps us under limits

### Full Example

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: "17"
          distribution: "temurin"

      - name: Setup Gradle
        uses: gradle/actions/setup-gradle@v4
        with:
          cache-read-only: ${{ !contains(fromJson('["refs/heads/master","refs/heads/develop","refs/heads/staging"]'), github.ref) }}

      - name: Compile
        run: ./gradlew :composeApp:compileKotlinJvm --no-daemon
```

## Why This Matters

- **Build time**: Cache hits reduce compile time from 10+ minutes to 2-3 minutes
- **Cost efficiency**: Especially important for macOS runners (iOS builds are expensive)
- **Predictable CI timing**: Protected branches have consistent timing; feature branches vary based on cache hits

## Common Mistakes

1. **Hardcoding `cache-read-only: true`** — Means cache is never updated, stale dependencies pile up
2. **Hardcoding `cache-read-only: false`** — Means every PR writes cache, polluting it
3. **Removing the action entirely** — No caching at all, builds are always slow

## Related Patterns
- `workflow/kmp-gradle-compile-tasks` — Which Gradle tasks to run in CI
- `tool-usage/github-actions-environment-variable-pattern` — Managing environment variables in CI
