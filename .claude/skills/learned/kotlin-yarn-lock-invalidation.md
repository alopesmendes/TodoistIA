# Kotlin Version Bump Invalidates Yarn Lock

**Extracted:** 2026-03-13
**Context:** KMP project with JS or WasmJS targets after any Kotlin version bump

## Problem

After bumping the Kotlin version in `gradle/libs.versions.toml`, the build fails with:

```
> Lock file was changed. Run the `kotlinUpgradeYarnLock` task to actualize lock file
```

The WasmJS or JS targets cannot resolve dependencies until the Yarn lock file is regenerated.

## Solution

Run the Gradle task to regenerate the Yarn lock:

```bash
./gradlew kotlinUpgradeYarnLock
```

Then re-run the full build:

```bash
./gradlew build
```

The lock file is regenerated automatically based on the new Kotlin version.

## When to Use

- Any time the Kotlin version is bumped in `gradle/libs.versions.toml` in a KMP project
- Projects that have JS or WasmJS targets configured
- Mid-migration when upgrading coupled groups (AGP, KGP, Compose Multiplatform)

## Why This Happens

The `kotlin-js-store/` and `kotlin-js-store/wasm/` directories maintain cached yarn dependencies for JavaScript and WebAssembly targets. When the Kotlin version changes, these caches become stale and must be regenerated to match the new version's JS/Wasm artifacts.

## Prevention

Include `kotlinUpgradeYarnLock` in your CI/CD pipeline immediately after version bumps to prevent surprise build failures downstream.