---
name: codeql-security
description: Configure CodeQL security scanning for Kotlin/Java projects in GitHub Actions. CI-only tool — no Gradle plugin needed. Covers the Security and Security Review dimensions from the code-analysis skill, complementing detekt (which handles code smells, unused code, and maintainability). Use this skill proactively when the user asks to add security scanning, configure CodeQL, set up SAST (Static Application Security Testing), detect vulnerabilities in source code, enable GitHub Security tab alerts, or integrate security analysis into CI — even if they don't say "CodeQL" explicitly. Also trigger when the user mentions security-extended queries, SARIF security uploads, or wants to find injection vulnerabilities, insecure deserialization, or authentication flaws in their Kotlin code. Do NOT trigger for dependency vulnerability scanning (OWASP Dependency Check handles that) or for code style/complexity issues (detekt handles those).
origin: ECC
tools: Read, Write, Edit, Bash, Grep, Glob
---

# CodeQL Security Scanning — GitHub Actions CI Setup

CodeQL is GitHub's semantic code analysis engine. Unlike detekt (which checks code structure and style), CodeQL understands data flow — it can trace user input through your code and detect where it reaches a dangerous sink (SQL query, file write, HTTP response) without sanitization. This makes it the right tool for the **Security** and **Security Review** dimensions from the code-analysis skill.

CodeQL runs exclusively in GitHub Actions — there is no Gradle plugin to install. The setup is entirely in the workflow YAML.

## Security Boundary

Follow `.claude/rules/common/security.md` and `.claude/rules/kotlin/security.md` at all times:

- Never hardcode secrets in workflow files
- CodeQL itself requires no API keys — it uses GitHub's built-in infrastructure
- SARIF uploads to the Security tab use the built-in `GITHUB_TOKEN` — no manual secret configuration needed

---

## Which Dimensions CodeQL Covers

CodeQL fills the two dimensions that detekt cannot:

| Dimension       | What CodeQL Finds                                              | Covered? |
|-----------------|----------------------------------------------------------------|----------|
| Security        | SQL injection, path traversal, SSRF, insecure deserialization  | Yes      |
| Security Review | OWASP Top 10 patterns, hardcoded credentials, weak crypto      | Yes      |
| Code Smells     | —                                                              | No (detekt) |
| Unused Code     | —                                                              | No (detekt) |
| Maintainability | —                                                              | No (detekt) |
| Duplication     | —                                                              | No (CPD/SonarQube) |
| Code Coverage   | —                                                              | No (Kover) |

Together, detekt + CodeQL cover 6 of the 7 code-analysis dimensions (only duplication and coverage need additional tools).

---

## Step 1: Add the CodeQL Job to the Workflow

Add a CodeQL job to `.github/workflows/code-analysis.yml`. This job initializes CodeQL, builds the project, and runs the security analysis.

```yaml
  # ── CodeQL security scanning ─────────────────────────────────────────────
  codeql:
    name: CodeQL Analysis
    runs-on: ubuntu-latest
    timeout-minutes: 30

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: "17"
          distribution: "temurin"

      - name: Initialize CodeQL
        uses: github/codeql-action/init@v3
        with:
          languages: java-kotlin
          queries: security-extended

      - name: Autobuild
        uses: github/codeql-action/autobuild@v3

      - name: Perform CodeQL Analysis
        uses: github/codeql-action/analyze@v3
        with:
          category: codeql-kotlin
```

### Key Configuration Choices

**`languages: java-kotlin`** — CodeQL analyzes Kotlin through the Java/Kotlin extractor. This covers all JVM-target code in the project (shared, server, composeApp, androidApp). It does not analyze JS/WASM targets, but security-critical code typically lives on the JVM side.

**`queries: security-extended`** — This is the recommended query suite for catching real vulnerabilities without too many false positives. The alternatives are:

| Query Suite         | What It Includes                                     | When to Use                    |
|---------------------|------------------------------------------------------|--------------------------------|
| `default`           | High-confidence findings only                        | If `security-extended` is too noisy |
| `security-extended` | Default + medium-confidence security queries          | Recommended starting point     |
| `security-and-quality` | Security + code quality (overlaps with detekt)    | Avoid — detekt handles quality |

Avoid `security-and-quality` because detekt already covers code quality. Running both would produce duplicate findings and slow down the pipeline.

**`autobuild`** — CodeQL needs to observe the build to understand the code. The `autobuild` action automatically detects Gradle and runs the appropriate build commands. For most KMP projects this works out of the box. If it fails, replace `autobuild` with an explicit build step:

```yaml
      - name: Build
        run: ./gradlew assembleDebug --no-daemon
```

### Verify Step 1

```bash
grep -q "codeql-action/init" .github/workflows/code-analysis.yml && echo "OK: CodeQL init configured" || echo "FAIL: CodeQL init missing"
grep -q "codeql-action/analyze" .github/workflows/code-analysis.yml && echo "OK: CodeQL analyze configured" || echo "FAIL: CodeQL analyze missing"
```

---

## Step 2: Connect Reports to the Aggregate Job

The code-analysis workflow should have an aggregate job that collects reports from all analysis tools. Make sure the aggregate job lists `codeql` in its `needs` array so it waits for CodeQL to finish before aggregating.

```yaml
  aggregate-reports:
    name: Aggregate Analysis Reports
    runs-on: ubuntu-latest
    timeout-minutes: 5
    needs: [detekt, codeql]   # <-- include codeql here
    if: always()

    steps:
      - name: Download all detekt reports
        uses: actions/download-artifact@v4
        with:
          pattern: detekt-report-*
          path: aggregated-reports/detekt/
          merge-multiple: false

      - name: Display report structure
        run: |
          echo "=== Aggregated Report Structure ==="
          find aggregated-reports -type f | head -50
          echo "==================================="

      - name: Upload aggregated report
        uses: actions/upload-artifact@v4
        with:
          name: code-analysis-report-${{ github.run_number }}
          path: aggregated-reports/
          retention-days: 30
```

CodeQL results don't need to be downloaded as artifacts — they go directly to the GitHub Security tab via the `analyze` action's built-in SARIF upload. The `category: codeql-kotlin` tag ensures they appear under a distinct category in the Security tab.

### Verify Step 2

```bash
grep -q "needs:.*codeql" .github/workflows/code-analysis.yml && echo "OK: aggregate depends on codeql" || echo "FAIL: aggregate doesn't wait for codeql"
```

---

## Step 3: Set Required Permissions

The workflow needs `security-events: write` permission so CodeQL can upload SARIF results to the GitHub Security tab. Add this at the workflow level:

```yaml
permissions:
  contents: read
  security-events: write
```

These are minimal permissions — `contents: read` for checkout, `security-events: write` for SARIF upload. No additional tokens or secrets are needed.

### Verify Step 3

```bash
grep -q "security-events: write" .github/workflows/code-analysis.yml && echo "OK: security-events permission set" || echo "FAIL: security-events permission missing"
```

---

## Step 4: Verify the Full Workflow

After configuring, the complete `code-analysis.yml` should have this structure:

```
code-analysis.yml
├── permissions: contents read, security-events write
├── concurrency: cancel-in-progress
│
├── Job: detekt (static analysis)
│   └── Runs: staticAnalysisAll
│   └── Uploads: SARIF + per-module artifacts
│
├── Job: codeql (security scanning)
│   └── Runs: init → autobuild → analyze
│   └── Uploads: SARIF to Security tab (automatic)
│
└── Job: aggregate-reports
    └── needs: [detekt, codeql]
    └── Downloads + aggregates all artifacts
```

### Verify Step 4

Push the workflow to a branch and check the Actions tab:

```bash
# Check workflow syntax is valid
cat .github/workflows/code-analysis.yml | python3 -c "import sys, yaml; yaml.safe_load(sys.stdin)" && echo "OK: valid YAML" || echo "FAIL: invalid YAML"
```

After pushing, verify in the GitHub Actions tab that:
1. The CodeQL job starts and initializes with `java-kotlin`
2. Autobuild completes (builds the Gradle project)
3. Analysis completes and results appear in the Security tab
4. The aggregate job waits for both detekt and codeql

---

## Report Location and Evaluation

CodeQL results appear in two places:

| Location                    | Format | How to Access                           |
|-----------------------------|--------|-----------------------------------------|
| GitHub Security tab         | SARIF  | Repository → Security → Code scanning   |
| GitHub Actions run summary  | Log    | Actions → Run → CodeQL Analysis job      |

There are no local report files — CodeQL is CI-only. To evaluate CodeQL findings, check the Security tab or use the GitHub API:

```bash
# List CodeQL alerts via GitHub CLI
gh api repos/{owner}/{repo}/code-scanning/alerts --jq '.[] | {rule: .rule.id, severity: .rule.security_severity_level, file: .most_recent_instance.location.path}'
```

### Mapping Findings to Dimensions

| CodeQL Alert Category       | Code-Analysis Dimension |
|-----------------------------|-------------------------|
| `security/cwe-*`            | Security                |
| `security/injection`        | Security                |
| `security/crypto`           | Security Review         |
| `security/credentials`      | Security Review         |
| `security/deserialization`   | Security                |

### Evaluation Rubric (from code-analysis skill)

| Dimension       | Healthy              | Warning                   | Critical                |
|-----------------|----------------------|---------------------------|-------------------------|
| Security        | 0 high/critical      | 1–3 medium                | Any high/critical       |
| Security Review | 0 findings           | 1–2 low-severity          | Any medium+ finding     |

---

## Complementing Detekt

Detekt and CodeQL serve different purposes and should both be present in the workflow:

| Aspect          | Detekt                              | CodeQL                              |
|-----------------|-------------------------------------|-------------------------------------|
| Analysis type   | Structural (AST patterns)           | Semantic (data flow, taint tracking)|
| Runs where      | Local + CI (Gradle task)            | CI only (GitHub Actions)            |
| Finds           | Code smells, unused code, complexity| Injection, SSRF, hardcoded secrets  |
| Dimensions      | 1, 3, 7 (smells, unused, maintain.) | 5, 6 (security, security review)   |
| Reports         | SARIF + HTML (local files)          | SARIF (GitHub Security tab)         |

They do not overlap or conflict — run both in the same workflow as parallel jobs.

---

## Troubleshooting

**Autobuild fails**: Replace with an explicit Gradle command. Common causes: missing SDK licenses, JDK version mismatch, or Gradle wrapper not committed.

```yaml
      - name: Build
        run: ./gradlew assembleDebug --no-daemon
```

**Too many alerts**: Switch from `security-extended` to `default` queries. Or dismiss false positives directly in the Security tab — dismissed alerts won't reappear.

**Analysis timeout**: The default 30-minute timeout is usually sufficient. If your project is very large, increase to 45 or 60 minutes. CodeQL analysis time scales with codebase size, not build time.

**SARIF upload fails**: Ensure `security-events: write` permission is set at the workflow level. For forked PRs, SARIF upload is restricted by GitHub — this is expected and not a configuration error.