---
name: code-analysis
description: Code analysis orchestration for the KMP project — Gradle task creation, report generation, and report evaluation across seven dimensions (code smells, duplication, unused code, coverage, security, security review, maintainability). Use this skill proactively when the user asks to analyze code quality, set up static analysis, add a linting or security tool, create analysis Gradle tasks, generate or evaluate analysis reports, integrate detekt/SonarQube/CodeQL, or improve project health — even if they don't say "code analysis" explicitly. Also trigger when the user mentions SARIF, code quality reports, vulnerability scanning, or wants to check the health of the codebase.
origin: ECC
tools: Read, Write, Edit, Bash, Grep, Glob
---

# Code Analysis — Gradle Task Orchestration & Report Evaluation

This skill defines how to wire code analysis tools into the Gradle build, generate structured reports, and evaluate those reports across seven quality dimensions. It does not prescribe which tools to use — separate skills and plugins handle tool-specific configuration (detekt, SonarQube, CodeQL, etc.). This skill is the orchestration layer.

## Security Boundary

Code analysis must never compromise the project's security posture:

- **Never read, write, log, or reference** environment variables, secrets, API keys, or tokens
- **Never modify** `.env.*` files, `local.properties`, or any file listed in `.gitignore` that holds secrets
- **Never include secrets** in report outputs, Gradle task configurations, or CI workflow files
- If a tool requires an API key (e.g., NVD for OWASP, SonarQube token), the key must come from the environment or CI secrets — never from source code
- Follow `.claude/rules/common/security.md` and `.claude/rules/kotlin/security.md` at all times

If you encounter a situation where a tool seems to require hardcoding a secret, stop and ask the user how they want to provide it (environment variable, CI secret, secret manager).

---

## The Seven Dimensions

Every analysis pass evaluates the codebase across these dimensions. Each maps to specific Gradle tasks and report types.

| # | Dimension       | What It Catches                                       | Gradle Task Pattern                | Report Format |
|---|-----------------|-------------------------------------------------------|------------------------------------|---------------|
| 1 | Code Smells     | Complexity, long methods, deep nesting, magic numbers | `detekt`, `sonar`                  | SARIF, HTML   |
| 2 | Duplication     | Copy-pasted blocks, near-duplicate logic              | `cpd`, `sonar`                     | XML, HTML     |
| 3 | Unused Code     | Dead functions, unreferenced classes, unused imports  | `detekt` (UnusedPrivateMember)     | SARIF, HTML   |
| 4 | Code Coverage   | Untested paths, low branch coverage                   | `koverReport`, `jacocoReport`      | XML, HTML     |
| 5 | Security        | Known CVEs in dependencies, insecure patterns         | `dependencyCheckAnalyze`, `codeql` | SARIF, HTML   |
| 6 | Security Review | OWASP Top 10 in source code, secrets in code          | `detekt` custom rules, `codeql`    | SARIF         |
| 7 | Maintainability | Coupling, cohesion, file size, function count         | `detekt`, `sonar`                  | SARIF, HTML   |

These dimensions overlap — detekt covers smells, unused code, and maintainability simultaneously. The mapping above shows the primary tool for each concern, but a single tool run can feed multiple dimensions.

---

## Gradle Task Architecture

### Principle: One Aggregation Task per Dimension

Each dimension gets a dedicated aggregate task in the root `build.gradle.kts`. This task depends on the per-module tasks provided by whichever plugin handles that concern. The aggregate task itself does no analysis — it just wires dependencies and collects reports.

### Naming Convention

```
<dimension>All        — aggregates across all modules
<dimension>Report     — generates a human-readable report
<dimension>Verify     — fails the build if thresholds are violated
```

Examples: `detektAll`, `coverageAll`, `coverageReport`, `coverageVerify`, `securityAll`.

### Creating an Aggregate Task

When adding a new analysis tool, follow this pattern in the root `build.gradle.kts`:

```kotlin
// 1. Register the aggregate task
tasks.register("<toolName>All") {
    group = "verification"
    description = "Runs <toolName> on all modules"
    dependsOn(subprojects.map { "${it.path}:<perModuleTaskName>" })
}

// 2. Register a verification task with thresholds (if the tool supports it)
tasks.register("<toolName>Verify") {
    group = "verification"
    description = "Verifies <toolName> thresholds across all modules"
    dependsOn("<toolName>All")
    doLast {
        // Parse reports and check thresholds
        // Throw GradleException if thresholds are violated
    }
}
```

### Report Output Locations

All reports follow a consistent path structure:

```
<module>/build/reports/<tool>/
    ├── <module>.<format>     (e.g., shared.sarif, shared.html)
    └── ...

build/reports/<tool>/                 (root — aggregated reports only)
    ├── aggregate.<format>
    └── ...
```

Prefer SARIF as the machine-readable format (GitHub Security tab consumes it). Always generate HTML alongside SARIF for human review.

---

## Wiring a New Analysis Tool — Step by Step

This is the sequence a senior developer would follow to integrate a new tool (e.g., detekt, SonarQube, Kover). The skill tells you the pattern; the tool-specific skill or plugin tells you the configuration details.

### Step 1: Add the Plugin

Add the plugin to `gradle/libs.versions.toml` and `build.gradle.kts`:

```toml
# libs.versions.toml
[versions]
toolName = "x.y.z"

[plugins]
toolName = { id = "com.example.tool", version.ref = "toolName" }
```

```kotlin
// build.gradle.kts — plugins block
alias(libs.plugins.toolName) apply false   // apply per-module, not globally
```

### Step 2: Apply Per-Module with Configuration

Apply the plugin to the relevant modules. Use `allprojects` or `subprojects` when the tool applies everywhere, or target specific modules when it doesn't.

```kotlin
// build.gradle.kts
allprojects {
    apply(plugin = "<plugin-id>")

    configure<ToolExtension> {
        // Tool-specific configuration goes here
        // Reports format, thresholds, exclusions, etc.
    }

    // Configure report formats
    tasks.withType<ToolTask>().configureEach {
        reports {
            html.required.set(true)
            sarif.required.set(true)
        }
    }
}
```

### Step 3: Create the Aggregate Task

Register the aggregate task in the root build file (see pattern above).

### Step 4: Configure Reports

Every tool must produce reports in at least one of these formats:

| Format | Purpose                          | Consumer                    |
|--------|----------------------------------|-----------------------------|
| SARIF  | Machine-readable, CI integration | GitHub Security tab, Claude |
| HTML   | Human review                     | Developer browser           |
| XML    | Legacy integration               | SonarQube, other tools      |
| JSON   | Custom processing                | Scripts, dashboards         |

SARIF is the preferred format because it is standardized, supported by GitHub, and parseable by Claude for automated evaluation.

### Step 5: Add CI Workflow Job

Add a job to `.github/workflows/code-analysis.yml` following this structure:

```yaml
<tool-name>:
  runs-on: ubuntu-latest
  timeout-minutes: <appropriate-timeout>
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-java@v4
      with:
        distribution: temurin
        java-version: "17"
    - uses: gradle/actions/setup-gradle@v4
      with:
        cache-read-only: ${{ github.ref != 'refs/heads/master' && ... }}
    - name: Run <tool>
      run: ./gradlew <toolName>All --no-daemon --continue
    - name: Upload SARIF
      if: always()
      uses: github/codeql-action/upload-sarif@v3
      with:
        sarif_file: <path-to-sarif>
        category: <tool-name>
    - name: Upload reports
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: <tool>-reports
        path: |
          **/build/reports/<tool>/
        retention-days: 14
```

### Step 6: Verify Locally

Before pushing, run the full analysis chain locally:

```bash
# Run all analysis
./gradlew <toolName>All --no-daemon

# Check report exists
ls -la */build/reports/<tool>/

# If verification task exists
./gradlew <toolName>Verify --no-daemon
```

---

## Evaluating Reports

When Claude is asked to evaluate code analysis reports, follow this process.

### Reading SARIF Reports

SARIF (Static Analysis Results Interchange Format) is a JSON structure. The key fields to extract:

```
runs[].results[] → each finding
  .ruleId        → which rule was violated
  .level         → "error", "warning", "note"
  .message.text  → human-readable description
  .locations[]   → file path and line number
```

### Evaluation Rubric

For each dimension, assess against these thresholds:

| Dimension       | Healthy                 | Warning                   | Critical                   |
|-----------------|-------------------------|---------------------------|----------------------------|
| Code Smells     | 0 errors, < 10 warnings | 10–30 warnings            | Any error or > 30 warnings |
| Duplication     | < 3% duplicated lines   | 3–5%                      | > 5%                       |
| Unused Code     | 0 findings              | 1–5 findings              | > 5 findings               |
| Code Coverage   | > 80% line coverage     | 60–80%                    | < 60%                      |
| Security        | 0 high/critical CVEs    | 1–3 medium CVEs           | Any high/critical CVE      |
| Security Review | 0 findings              | 1–2 low-severity findings | Any medium+ finding        |
| Maintainability | All files < 600 lines   | 1–3 files 600–800 lines   | Any file > 800 lines       |

### Report Summary Format

When presenting results to the user, use this structure:

```
## Code Analysis Report — <date>

| Dimension        | Status | Findings | Details              |
|------------------|--------|----------|----------------------|
| Code Smells      | ...    | ...      | ...                  |
| Duplication       | ...    | ...      | ...                  |
| Unused Code       | ...    | ...      | ...                  |
| Code Coverage     | ...    | ...      | ...                  |
| Security          | ...    | ...      | ...                  |
| Security Review   | ...    | ...      | ...                  |
| Maintainability   | ...    | ...      | ...                  |

### Critical Findings (fix before merge)
- ...

### Warnings (address soon)
- ...

### Recommendations
- ...
```

---

## Quick Reference — Common Commands

```bash
# Run aggregate tasks (replace with your actual tool names)
./gradlew <toolName>All --no-daemon --continue

# Run with verification thresholds
./gradlew <toolName>Verify --no-daemon

# Format before analysis
./gradlew <formatterTask> --no-daemon

# Check reports exist after a run
ls -la */build/reports/<tool>/
```
