#!/usr/bin/env bash
# analyze-session.sh — Extract learnable patterns from a Claude Code session transcript
#
# Usage:
#   bash analyze-session.sh [transcript_path]
#
# If transcript_path is not provided, reads from stdin (piped from Stop hook).
# Outputs a JSON array of candidate learnings to stdout.
#
# This script does lightweight text extraction. The heavy analysis
# (deduplication, quality gate, categorization) is done by the
# continuous-learning agent that consumes this output.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
LIBRARY_DIR="$SKILL_DIR/library"
INDEX_FILE="$LIBRARY_DIR/index.json"

# --- Input ---
if [ -n "${1:-}" ] && [ -f "$1" ]; then
  TRANSCRIPT="$1"
else
  TRANSCRIPT=$(mktemp)
  cat > "$TRANSCRIPT"
  trap "rm -f $TRANSCRIPT" EXIT
fi

# --- Extraction functions ---

extract_corrections() {
  # Find user corrections: "no", "not that", "instead do", "don't", "stop", "wrong"
  grep -inE "(^|\s)(no[,.]?\s|not that|instead do|don't|do not|stop\s|wrong|actually,?\s)" "$TRANSCRIPT" 2>/dev/null | head -20
}

extract_errors() {
  # Find build/test failures and error messages
  grep -inE "(BUILD FAILED|FAILURE|Error:|Exception:|Unresolved reference|test.*failed|compilation error|cannot find)" "$TRANSCRIPT" 2>/dev/null | head -20
}

extract_tool_sequences() {
  # Find tool usage patterns (Edit, Write, Bash, Grep, Glob sequences)
  grep -inE "(Edit|Write|Bash|Grep|Glob|Agent)\s" "$TRANSCRIPT" 2>/dev/null | head -30
}

extract_conventions() {
  # Find naming patterns in Kotlin files mentioned
  grep -inE "\.(kt|kts)\"?" "$TRANSCRIPT" 2>/dev/null | grep -oE "[A-Z][a-zA-Z]+(UseCase|Repository|ViewModel|Service|Port|Adapter|Route|State|Event|Intent|Module)" | sort -u | head -20
}

# --- Build output ---

corrections=$(extract_corrections | wc -l | tr -d ' ')
errors=$(extract_errors | wc -l | tr -d ' ')
conventions=$(extract_conventions | wc -l | tr -d ' ')

# Read current session count
session_count=0
if [ -f "$INDEX_FILE" ]; then
  session_count=$(jq -r '.session_count // 0' "$INDEX_FILE" 2>/dev/null || echo 0)
fi

cat <<EOF
{
  "session_analysis": {
    "transcript": "$(basename "${1:-stdin}")",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "session_number": $((session_count + 1)),
    "signals": {
      "corrections_found": $corrections,
      "errors_found": $errors,
      "conventions_detected": $conventions
    },
    "has_learnable_content": $([ "$corrections" -gt 0 ] || [ "$errors" -gt 2 ] && echo "true" || echo "false"),
    "library_path": "$LIBRARY_DIR",
    "index_path": "$INDEX_FILE"
  }
}
EOF
