# Upgrade Dependencies

Upgrade project dependencies with tier-aware verification using the `dependency-upgrade` skill.

## Arguments

$ARGUMENTS — Optional. Specify a dependency name and/or target version. If omitted, checks and upgrades all outdated dependencies.

## Examples

```
/upgrade                          → Check all deps, upgrade everything outdated
/upgrade ktor                     → Upgrade Ktor to latest stable
/upgrade ktor 4.0.0               → Upgrade Ktor to exactly 4.0.0
/upgrade kotlin                   → Upgrade the coupled group (KGP/AGP/Compose)
/upgrade --check                  → Only check for updates, don't apply anything
```

## Instructions

### Parse the arguments

- **No arguments** → Mode 3 (upgrade all)
- **`--check`** → Mode 1 (check only, no changes)
- **`<dependency>`** → Mode 2 (upgrade specific dependency to latest)
- **`<dependency> <version>`** → Mode 2 (upgrade specific dependency to given version)
- If the dependency is `kotlin`, `agp`, `compose-multiplatform`, or `compose` → treat as the coupled group (AGP/KGP/Compose)

### Step 1: Detection

Launch the `dependency-checker` agent to scan `gradle/libs.versions.toml` and produce the update report.

- If Mode 1 (`--check`): present the report and stop.
- If Mode 2 (specific dep): filter the report to only the named dependency (or coupled group).
- If Mode 3 (all): present the full report, ask the user which upgrades to apply.

### Step 2: Execution

Apply upgrades following the `dependency-upgrade` skill's tier strategy:

1. **Coupled group first** (AGP/KGP/Compose) — if included
2. **Patch upgrades** — batch together, verify with sync
3. **Minor upgrades** — one at a time, verify with build + tests
4. **Major upgrades** — research, explain plan, wait for user approval, use `/orchestrate`

### Step 3: Report

After all upgrades are applied (or attempted), present a summary:

```
Upgrade Summary
===============
Applied:  3 patch, 2 minor, 0 major
Skipped:  1 (user chose to skip)
Failed:   0
Pending:  1 major (awaiting user decision)

Changes in gradle/libs.versions.toml (not committed):
  ktor:       3.3.3 → 3.3.4
  coroutines: 1.10.2 → 1.11.0
  logback:    1.5.24 → 1.5.25
```

Remind the user that changes are NOT committed — they decide when to commit.
