# .claude/ — Claude Code Project Configuration

This directory configures Claude Code's behavior for the TodoistIA project.

| Directory       | Purpose                                            | Auto-loaded as context?         |
|-----------------|----------------------------------------------------|---------------------------------|
| `agents/`       | Specialized sub-agents launched for specific tasks | No — loaded on invocation       |
| `commands/`     | Slash commands (`/tdd`, `/build-fix`, etc.)        | No — loaded on invocation       |
| `hooks/`        | Lifecycle hooks (PreToolUse, PostToolUse, Stop)    | No — executed as shell commands |
| `rules/`        | Coding standards, patterns, security guidelines    | **Yes — always loaded**         |
| `skills/`       | Deep reference material for specific domains       | No — loaded when triggered      |
| `settings.json` | Plugin and tool configuration                      | Yes                             |

## Quick Reference

- **Run a command**: `/tdd`, `/build-fix`, `/code-review`, `/update-docs`, etc.
- **Agents are launched automatically** when the situation matches (e.g., build failure → `build-resolver`)
- **Hooks run silently** — they block dangerous actions and warn about code quality issues
- **Rules are always active** — they define the coding standards Claude must follow
- **Skills provide context** — deep knowledge loaded on demand when a topic matches

## Token Budget

Only `rules/` and `settings.json` consume context tokens on every conversation. Everything else is loaded on demand. Keep `rules/` files concise.

See each subdirectory's `README.md` for details.
