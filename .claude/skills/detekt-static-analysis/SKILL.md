---
name: detekt-static-analysis
description: Set up and configure detekt for static code analysis in Kotlin Multiplatform projects. Covers full installation from scratch — plugin setup, YAML configuration files, Compose-specific rules for frontend modules, dimension-aware Gradle tasks (code smells, unused code, maintainability), SARIF/HTML report generation, and CI workflow integration. Use this skill proactively when the user asks to add detekt, configure static analysis for Kotlin, set up code smell detection, enforce complexity thresholds, add Compose lint rules, or wants to catch unused code and maintainability issues — even if they don't say "detekt" explicitly. Also trigger when the user mentions static analysis, code quality rules, complexity checks, or wants to configure analysis YAML files. Do NOT trigger for formatting or linting tasks — those belong to ktlint.
origin: ECC
tools: Read, Write, Edit, Bash, Grep, Glob
---

# Detekt Static Analysis — KMP Setup & Configuration

This skill walks through setting up detekt from scratch in a Kotlin Multiplatform multi-module project. It produces Gradle tasks with dimension-aware names (not tool-specific names) that align with the code-analysis skill's seven dimensions, and generates SARIF + HTML reports for each.

Detekt is a static analysis tool — it inspects source code structure without running it. It is not a formatter (ktlint handles that) and not a test runner. Its job is catching code smells, unused code, complexity violations, and maintainability issues before they become problems.

## Security Boundary

Follow `.claude/rules/common/security.md` and `.claude/rules/kotlin/security.md` at all times:

- Never hardcode secrets in configuration files or Gradle scripts
- Never modify `.env.*` files, `local.properties`, or secret-holding files
- If a tool integration requires credentials (e.g., SonarQube token upload), those come from environment variables or CI secrets — never from source code

---

## Which Dimensions Detekt Covers

Detekt addresses four of the seven code-analysis dimensions. The other three require different tools (Kover for coverage, OWASP/Snyk for dependency security, CPD/SonarQube for duplication).

| Dimension       | Detekt Rule Sets                                                    | Covered? |
|-----------------|---------------------------------------------------------------------|----------|
| Code Smells     | `complexity`, `style`, `naming`, `exceptions`, `coroutines`         | Yes      |
| Unused Code     | `style.UnusedPrivateMember`, `style.UnusedParameter`                | Yes      |
| Maintainability | `complexity.LargeClass`, `complexity.LongMethod`, `complexity.TooManyFunctions` | Yes |
| Security Review | `style.ForbiddenMethodCall`, custom rules for `!!`, logging secrets | Partial  |
| Duplication     | —                                                                   | No       |
| Code Coverage   | —                                                                   | No       |
| Security (CVEs) | —                                                                   | No       |

---

## Step 1: Add the Plugin to the Version Catalog

Add detekt and its Compose rules plugin to `gradle/libs.versions.toml`:

```toml
[versions]
detekt = "1.23.8"
detekt-compose-rules = "0.5.6"

[plugins]
detekt = { id = "io.gitlab.arturbosch.detekt", version.ref = "detekt" }
```

### Verify Step 1

```bash
grep -q "detekt" gradle/libs.versions.toml && echo "OK: detekt in version catalog" || echo "FAIL: detekt missing from version catalog"
```

---

## Step 2: Apply the Plugin in Root build.gradle.kts

Declare the plugin in the root `plugins {}` block with `apply false`, then apply it per-module via `allprojects`:

```kotlin
// build.gradle.kts — plugins block
plugins {
    // ... other plugins ...
    alias(libs.plugins.detekt) apply false
}
```

Then apply to all modules:

```kotlin
// build.gradle.kts — allprojects block
allprojects {
    apply(plugin = "io.gitlab.arturbosch.detekt")

    configure<io.gitlab.arturbosch.detekt.extensions.DetektExtension> {
        buildUponDefaultConfig = true
        allRules = false
        parallel = true

        config.setFrom(
            // Compose modules get both base + compose config
            if (project.name in composeModules) {
                listOf(detektBaseConfig, detektComposeConfig)
            } else {
                listOf(detektBaseConfig)
            }
        )
    }

    tasks.withType<io.gitlab.arturbosch.detekt.Detekt>().configureEach {
        reports {
            html.required.set(true)
            sarif.required.set(true)
            checkstyle.required.set(false)
        }
    }
}
```

The `composeModules` set and config file references need to be defined before the `allprojects` block:

```kotlin
val detektBaseConfig = file(".detekt/detekt-base.yml")
val detektComposeConfig = file(".detekt/detekt-compose.yml")
val composeModules = setOf("composeApp", "androidApp")  // adjust to your module names
```

### Verify Step 2

```bash
./gradlew tasks --group=verification --no-daemon 2>/dev/null | grep -i detekt && echo "OK: detekt tasks registered" || echo "FAIL: no detekt tasks found"
```

---

## Step 3: Add Compose Rules for Frontend Modules

Frontend modules using Compose need additional rules that understand `@Composable` functions, modifiers, and state management. Add the dependency only to Compose modules:

```kotlin
subprojects {
    if (name in composeModules) {
        val detektComposeRulesVersion = rootProject.extensions
            .getByType<VersionCatalogsExtension>()
            .named("libs")
            .findVersion("detekt-compose-rules")
            .get()
            .requiredVersion
        dependencies {
            "detektPlugins"("io.nlopez.compose.rules:detekt:$detektComposeRulesVersion")
        }
    }
}
```

### Verify Step 3

```bash
./gradlew composeApp:dependencies --no-daemon 2>/dev/null | grep "compose.rules" && echo "OK: Compose rules added" || echo "FAIL: Compose rules missing"
```

---

## Step 4: Create the Base Configuration File

Create `.detekt/detekt-base.yml`. This file controls thresholds and rule activation for all modules. The values below align with the code-analysis evaluation rubric.

```yaml
# .detekt/detekt-base.yml
#
# Base detekt configuration for all modules.
# Covers three code-analysis dimensions: Code Smells, Unused Code, Maintainability.

build:
  maxIssues: 0  # Zero tolerance — any finding breaks the build

complexity:
  active: true
  ComplexCondition:
    active: true
    threshold: 4
  CyclomaticComplexMethod:
    active: true
    threshold: 15
  LargeClass:
    active: true
    threshold: 600            # Code-analysis rubric: >600 = warning, >800 = critical
  LongMethod:
    active: true
    threshold: 60
  LongParameterList:
    active: true
    functionThreshold: 6
    constructorThreshold: 8
  NestedBlockDepth:
    active: true
    threshold: 4
  TooManyFunctions:
    active: true
    thresholdInFiles: 20
    thresholdInClasses: 15
    thresholdInInterfaces: 10
    thresholdInObjects: 10
    thresholdInEnums: 10

coroutines:
  active: true
  GlobalCoroutineUsage:
    active: true
  SuspendFunSwallowedCancellation:
    active: true

exceptions:
  active: true
  SwallowedException:
    active: true
    allowedExceptionNameRegex: '_|(ignore|expected).*'
  TooGenericExceptionCaught:
    active: true

naming:
  active: true
  FunctionNaming:
    active: true
    functionPattern: '[a-z][a-zA-Z0-9]*'
    excludes: ['**/test/**', '**/androidTest/**', '**/commonTest/**']
  TopLevelPropertyNaming:
    active: true
    constantPattern: '[A-Z][A-Za-z0-9]*'

performance:
  active: true
  SpreadOperator:
    active: true
  UnnecessaryPartOfBinaryExpression:
    active: true

style:
  active: true
  ForbiddenComment:
    active: true
    comments: ['FIXME', 'STOPSHIP', 'HACK']
    allowedPatterns: 'TODO'
  MagicNumber:
    active: true
    ignoreNumbers: ['-1', '0', '1', '2']
    ignorePropertyDeclaration: true
    ignoreLocalVariableDeclaration: true
    ignoreAnnotation: true
    ignoreEnums: true
  ReturnCount:
    active: true
    max: 3
    excludeReturnFromLambda: true
  ThrowsCount:
    active: true
    max: 2
  UnusedPrivateMember:
    active: true
  UnusedParameter:
    active: true

# Formatting is disabled — ktlint handles it
formatting:
  active: false
```

### Verify Step 4

```bash
test -f .detekt/detekt-base.yml && echo "OK: base config exists" || echo "FAIL: base config missing"
```

---

## Step 5: Create the Compose Configuration File

Create `.detekt/detekt-compose.yml`. This is layered on top of the base config and only loaded for Compose modules. It catches Compose-specific issues like missing modifiers, forgotten `remember`, and incorrect naming.

```yaml
# .detekt/detekt-compose.yml
#
# Compose-specific detekt rules for frontend modules.
# Requires: io.nlopez.compose.rules:detekt plugin

Compose:
  ComposableAnnotationNaming:
    active: true
  ComposableNaming:
    active: true
  ComposableParamOrder:
    active: true
  ContentEmitterReturningValues:
    active: true
  ModifierMissing:
    active: true
  ModifierNotUsedAtRoot:
    active: true
  ModifierWithoutDefault:
    active: true
  MutableParameters:
    active: true
  RememberMissing:
    active: true
  UnstableCollections:
    active: false         # Disabled — too noisy during early development
  ViewModelForwarding:
    active: true
  ViewModelInjection:
    active: true
```

### Verify Step 5

```bash
test -f .detekt/detekt-compose.yml && echo "OK: compose config exists" || echo "FAIL: compose config missing"
```

---

## Step 6: Register Dimension-Aware Gradle Tasks

The code-analysis skill requires tasks named after dimensions, not tools. Register these in the root `build.gradle.kts`. Each task depends on the underlying detekt tasks but presents a tool-agnostic name.

```kotlin
// ── Dimension-Aware Analysis Tasks ──────────────────────────────────────────

// Umbrella task: runs all static analysis dimensions
tasks.register("staticAnalysisAll") {
    group = "verification"
    description = "Runs all static analysis checks (code smells, unused code, maintainability)"
    dependsOn(subprojects.map { "${it.path}:detekt" })
}

// Code Smells — complexity, naming, style violations
tasks.register("codeSmellsAll") {
    group = "verification"
    description = "Checks for code smells across all modules"
    dependsOn("staticAnalysisAll")
}

// Unused Code — dead functions, unreferenced classes
tasks.register("unusedCodeAll") {
    group = "verification"
    description = "Checks for unused code across all modules"
    dependsOn("staticAnalysisAll")
}

// Maintainability — file size, function count, complexity
tasks.register("maintainabilityAll") {
    group = "verification"
    description = "Checks maintainability thresholds across all modules"
    dependsOn("staticAnalysisAll")
}

// Verification task — fails build if any dimension threshold is violated
tasks.register("staticAnalysisVerify") {
    group = "verification"
    description = "Verifies static analysis thresholds (zero issues allowed)"
    dependsOn("staticAnalysisAll")
    doLast {
        // detekt already fails on maxIssues: 0, so this task just confirms
        // the analysis ran. For custom threshold parsing, read the SARIF reports.
        val sarifFiles = subprojects.flatMap { sub ->
            fileTree("${sub.projectDir}/build/reports/detekt/") {
                include("*.sarif")
            }.files
        }
        if (sarifFiles.isEmpty()) {
            throw GradleException("No SARIF reports found — did the analysis run?")
        }
        println("Static analysis verified: ${sarifFiles.size} report(s) generated")
    }
}
```

Because detekt evaluates all dimensions in a single pass, the dimension-specific tasks (`codeSmellsAll`, `unusedCodeAll`, `maintainabilityAll`) all depend on `staticAnalysisAll`. Separating them gives CI workflows and developers the vocabulary to reason about dimensions independently, even though the underlying engine runs once.

### Verify Step 6

```bash
./gradlew tasks --group=verification --no-daemon 2>/dev/null | grep -E "(staticAnalysis|codeSmells|unusedCode|maintainability)" && echo "OK: dimension tasks registered" || echo "FAIL: dimension tasks missing"
```

---

## Step 7: Add CI Workflow Job

Add a job to `.github/workflows/code-analysis.yml`:

```yaml
static-analysis:
  runs-on: ubuntu-latest
  timeout-minutes: 20
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-java@v4
      with:
        distribution: temurin
        java-version: "17"
    - uses: gradle/actions/setup-gradle@v4
      with:
        cache-read-only: ${{ github.ref != 'refs/heads/master' && github.ref != 'refs/heads/develop' && github.ref != 'refs/heads/staging' }}
    - name: Run static analysis
      run: ./gradlew staticAnalysisAll --no-daemon --continue
    - name: Upload SARIF to GitHub Security
      if: always()
      uses: github/codeql-action/upload-sarif@v3
      with:
        sarif_file: .
        category: static-analysis
    - name: Upload reports
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: static-analysis-reports
        path: |
          **/build/reports/detekt/
        retention-days: 14
```

### Verify Step 7

```bash
grep -q "staticAnalysisAll" .github/workflows/code-analysis.yml && echo "OK: CI job configured" || echo "FAIL: CI job missing"
```

---

## Step 8: Run and Verify Locally

Run the full chain locally before pushing:

```bash
# 1. Run all static analysis
./gradlew staticAnalysisAll --no-daemon

# 2. Verify reports were generated
find . -path "*/build/reports/detekt/*.sarif" -type f | head -10

# 3. Verify dimension tasks work
./gradlew codeSmellsAll --no-daemon
./gradlew unusedCodeAll --no-daemon
./gradlew maintainabilityAll --no-daemon

# 4. Run verification
./gradlew staticAnalysisVerify --no-daemon
```

### Verify Step 8

```bash
./gradlew staticAnalysisAll --no-daemon 2>&1 | tail -5
find . -path "*/build/reports/detekt/*.sarif" -type f | wc -l | xargs -I{} echo "Reports generated: {}"
```

---

## Report Location and Format

After running, reports appear at:

```
<module>/build/reports/detekt/
    ├── detekt.html    (human review — open in browser)
    └── detekt.sarif   (machine-readable — GitHub Security tab, Claude evaluation)
```

When evaluating reports, map findings to dimensions using the rule set prefix:

| SARIF ruleId prefix | Dimension       |
|---------------------|-----------------|
| `complexity.*`      | Code Smells     |
| `style.*`           | Code Smells     |
| `naming.*`          | Code Smells     |
| `exceptions.*`      | Code Smells     |
| `coroutines.*`      | Code Smells     |
| `UnusedPrivateMember`, `UnusedParameter` | Unused Code |
| `LargeClass`, `LongMethod`, `TooManyFunctions` | Maintainability |
| `Compose.*`         | Code Smells (Compose-specific) |

---

## Adjusting Thresholds

To change thresholds, edit `.detekt/detekt-base.yml`. The values in this skill align with the code-analysis rubric:

| Metric           | Default | Code-Analysis Warning | Code-Analysis Critical |
|------------------|---------|-----------------------|------------------------|
| LargeClass       | 600     | 600–800 lines         | > 800 lines            |
| LongMethod       | 60      | —                     | > 60 lines             |
| ComplexMethod     | 15      | —                     | > 15 statements        |
| TooManyFunctions  | 20/15   | —                     | > threshold            |
| NestedBlockDepth  | 4       | —                     | > 4 levels             |

To make the build warn instead of fail, change `maxIssues: 0` to a higher number. But zero tolerance is recommended — it prevents technical debt from accumulating silently.

---

## Distinction from ktlint

| Concern       | Tool    | Skill           |
|---------------|---------|-----------------|
| Formatting    | ktlint  | (separate)      |
| Code smells   | detekt  | This skill      |
| Unused code   | detekt  | This skill      |
| Maintainability | detekt | This skill      |
| Compose rules | detekt  | This skill      |

Both tools can run in the same build. They do not conflict because detekt's `formatting` rule set is disabled (see Step 4). If both are active, formatting issues would be reported twice.