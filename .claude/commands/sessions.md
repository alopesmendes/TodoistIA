---
description: "Manage Claude Code session history — list, inspect, and search sessions for the current project. Uses bash + jq to read JSONL session files directly."
---

# Sessions Command

Browse and inspect Claude Code session history for this project.

Sessions are stored as `.jsonl` files in `~/.claude/projects/`. Each file contains typed messages (`user`, `assistant`, `system`, `progress`) with timestamps and metadata.

## Usage

```
/sessions                          # List recent sessions (default)
/sessions list                     # Same — list all sessions
/sessions list --limit 5           # Show only 5 sessions
/sessions info <session-id>        # Show details for a session
/sessions search <keyword>         # Search user messages across sessions
/sessions summary <session-id>     # Show user prompts from a session
```

## How It Works

When `/sessions` is invoked, Claude should run the appropriate bash commands below based on the subcommand.

### List Sessions

List all sessions for the current project, sorted by most recent:

```bash
PROJECT_DIR="$HOME/.claude/projects/-Users-ailtonlopesmendes-Dev-mobile-personal-kmp-TodoistIA"

echo "Sessions for TodoistIA"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "%-38s  %-12s  %-6s  %-8s  %s\n" "ID" "Date" "Msgs" "Size" "First Prompt"
echo "──────────────────────────────────────────────────────────────────────────"

for f in $(ls -t "$PROJECT_DIR"/*.jsonl 2>/dev/null); do
  id=$(basename "$f" .jsonl)
  date=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$f" 2>/dev/null || date -r "$f" "+%Y-%m-%d %H:%M" 2>/dev/null)
  msgs=$(wc -l < "$f" | tr -d ' ')
  size=$(du -h "$f" | cut -f1 | tr -d ' ')
  first=$(jq -r 'select(.type == "user") | .message.content' "$f" 2>/dev/null | head -1 | cut -c1-40)
  printf "%-38s  %-12s  %-6s  %-8s  %s\n" "$id" "$date" "$msgs" "$size" "$first"
done
```

### Session Info

Show detailed stats for a specific session:

```bash
SESSION_FILE="$HOME/.claude/projects/-Users-ailtonlopesmendes-Dev-mobile-personal-kmp-TodoistIA/<session-id>.jsonl"

echo "Session: <session-id>"
echo ""

# Message type breakdown
echo "Message Types:"
jq -r '.type' "$SESSION_FILE" | sort | uniq -c | sort -rn

echo ""

# Time range
echo "First message: $(jq -r 'select(.timestamp) | .timestamp' "$SESSION_FILE" | head -1)"
echo "Last message:  $(jq -r 'select(.timestamp) | .timestamp' "$SESSION_FILE" | tail -1)"

echo ""

# Git branch
echo "Branch: $(jq -r 'select(.type == "user") | .gitBranch // empty' "$SESSION_FILE" | head -1)"

echo ""

# User prompts
echo "User Prompts:"
echo "─────────────"
jq -r 'select(.type == "user") | .message.content' "$SESSION_FILE" 2>/dev/null | head -c 2000
```

### Search Sessions

Search for a keyword across all sessions in this project:

```bash
PROJECT_DIR="$HOME/.claude/projects/-Users-ailtonlopesmendes-Dev-mobile-personal-kmp-TodoistIA"
KEYWORD="<search-term>"

echo "Searching for: $KEYWORD"
echo ""

for f in $(ls -t "$PROJECT_DIR"/*.jsonl 2>/dev/null); do
  matches=$(jq -r 'select(.type == "user") | .message.content' "$f" 2>/dev/null | grep -i "$KEYWORD" | head -3)
  if [ -n "$matches" ]; then
    id=$(basename "$f" .jsonl)
    date=$(stat -f "%Sm" -t "%Y-%m-%d" "$f" 2>/dev/null)
    echo "[$date] $id"
    echo "$matches" | sed 's/^/  /'
    echo ""
  fi
done
```

### Session Summary

Show all user prompts from a session (conversation outline):

```bash
SESSION_FILE="$HOME/.claude/projects/-Users-ailtonlopesmendes-Dev-mobile-personal-kmp-TodoistIA/<session-id>.jsonl"

echo "Session Summary: <session-id>"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

jq -r 'select(.type == "user") | "\(.timestamp // "??")  \(.message.content[0:120])"' "$SESSION_FILE" 2>/dev/null
```

## Arguments

- `list [--limit N]` — List sessions sorted by most recent (default: all)
- `info <session-id>` — Show message breakdown, time range, branch, and user prompts
- `search <keyword>` — Search user messages across all project sessions
- `summary <session-id>` — Show user prompts as a conversation outline

## Session File Structure

Each `.jsonl` file contains one JSON object per line:

```json
{"type": "user",     "message": {"role": "user", "content": "..."}, "timestamp": "...", "sessionId": "...", "gitBranch": "..."}
{"type": "assistant", "message": {"role": "assistant", "content": [...]}, "timestamp": "..."}
{"type": "system",   ...}
{"type": "progress", ...}
{"type": "file-history-snapshot", ...}
```

## Notes

- Sessions live at `~/.claude/projects/<project-slug>/`
- Session IDs are UUIDs — use the first 8 chars as shorthand
- The `jq` tool is required (available on this machine)
- Only the current project's sessions are shown by default
