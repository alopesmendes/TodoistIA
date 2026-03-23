---
name: GitHub Actions environment variable pattern (vars. vs secrets.)
category: tool-usage
seen_count: 1
first_seen: 2026-03-22
last_seen: 2026-03-22
source: auto-extracted
---

# GitHub Actions Environment Variable Pattern

## Context
In GitHub Actions workflows, you often need to pass configuration and credentials to build steps. Understanding the difference between `vars.*` (repository variables) and `secrets.*` (encrypted secrets) is critical for secure, maintainable CI/CD.

## Pattern

Use two separate namespaces for environment variables in workflows:

### Non-Sensitive Configuration (vars.*)

Repository variables are visible in the workflow file and UI. Use these for:
- Environment names (dev, staging, prod)
- Non-sensitive configuration (port numbers, hostnames, timeouts)
- Feature flags and build options

Example:
```yaml
env:
  APP_ENV: ${{ vars.APP_ENV || 'dev' }}
  SERVER_PORT: ${{ vars.SERVER_PORT }}
  SERVER_HOST: ${{ vars.SERVER_HOST }}
```

### Sensitive Credentials (secrets.*)

Secrets are encrypted and redacted in logs. Use these for:
- API keys (NVD_API_KEY, TODOIST_TOKEN)
- Authentication tokens
- Passwords and private keys
- Any credential that grants access to external services

Example:
```yaml
env:
  NVD_API_KEY: ${{ secrets.NVD_API_KEY }}
  TODOIST_TOKEN: ${{ secrets.TODOIST_TOKEN }}
```

### Fallback Pattern

Use the `||` operator to provide sensible defaults for non-sensitive vars:
```yaml
APP_ENV: ${{ vars.APP_ENV || 'dev' }}
```

This ensures workflows continue if a repository variable is not set, but never do this for secrets (they must always be present).

### Configuration in Workflows

Define environment variables in the job or step level:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Build
        run: ./gradlew build --no-daemon
        env:
          # Non-sensitive (vars namespace)
          APP_ENV: ${{ vars.APP_ENV || 'dev' }}
          SERVER_PORT: ${{ vars.SERVER_PORT }}
          SERVER_HOST: ${{ vars.SERVER_HOST }}

          # Sensitive (secrets namespace)
          NVD_API_KEY: ${{ secrets.NVD_API_KEY }}
          TODOIST_TOKEN: ${{ secrets.TODOIST_TOKEN }}
```

## Why This Matters

- **Separation of concerns**: Configuration is separate from secrets
- **Security by design**: Secrets are encrypted and never logged; configuration vars are not
- **Maintainability**: Easy to see at a glance which values are sensitive
- **Flexibility**: Repository variables can be changed without touching secrets manager
- **Audit trail**: GitHub logs which values changed when (for vars, not for secrets)

## Related Patterns
- `project-specific/github-actions-workflow-structure` — How to organize multiple CI workflows
- `security/secret-management-in-ci-cd` — Best practices for handling secrets in pipelines
