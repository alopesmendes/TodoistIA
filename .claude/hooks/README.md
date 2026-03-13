# hooks/ — Lifecycle Hooks

Hooks are shell commands that run automatically at specific points in Claude's tool lifecycle. They enforce rules, warn about issues, and suggest commands.

## Hook Types

| Type          | When it Runs                     | Can Block?    |
|---------------|----------------------------------|---------------|
| `PreToolUse`  | Before a tool executes           | Yes (exit 2)  |
| `PostToolUse` | After a tool executes            | No (advisory) |
| `Stop`        | After Claude finishes responding | No (advisory) |

## Current Hooks

### PreToolUse (Blockers)
- **Destructive git commands** — Blocks `push --force`, `reset --hard`, `clean -fd`, `branch -D`
- **No-verify commits** — Blocks `--no-verify` to enforce pre-commit hooks

### PostToolUse (Warnings)
- **`!!` operator** — Warns when `!!` appears in production `.kt` files
- **Hardcoded secrets** — Warns about API keys, tokens, passwords in source
- **`println()`** — Warns about debug prints in production code
- **File size** — Warns when a `.kt` file exceeds 800 lines
- **Build failure** — Suggests `/build-fix` when Gradle fails
- **Test failure** — Suggests `/tdd` or `/test-coverage` when tests fail
- **PR created** — Suggests `/code-review` after `gh pr create`

### Stop (Final Checks)
- **`!!` scan** — Checks all git-modified `.kt` files for `!!` operator
- **Secret scan** — Checks all git-modified `.kt` files for hardcoded secrets

## How Hooks Work

- Hooks receive tool input as JSON on **stdin**
- They parse it with `jq` to inspect file paths, commands, and outputs
- **stdout** → feedback shown to Claude
- **stderr** → warning shown to the user
- **Exit 0** → proceed, **Exit 2** → block the tool call

## Example: How the `!!` check works

```
1. User asks Claude to edit a .kt file
2. Claude calls the Edit tool
3. PostToolUse hook runs:
   - Reads file_path from stdin JSON
   - Checks if the file is .kt and not a test
   - Greps for `!!` in the file
   - If found → outputs warning to Claude
4. Claude sees the warning and fixes the issue
```

## Adding a New Hook

Edit `hooks.json` and add an entry under the appropriate lifecycle:

```json
{
  "matcher": "Edit|Write",
  "hooks": [
    {
      "type": "command",
      "command": "bash -c 'input=$(cat); ...your logic...'",
      "timeout": 10
    }
  ],
  "description": "What this hook does"
}
```
