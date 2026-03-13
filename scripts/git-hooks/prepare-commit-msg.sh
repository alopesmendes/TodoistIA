#!/usr/bin/env bash
# prepare-commit-msg.sh - Automatically formats commit messages
# Format: [gitmoji] prefix(#issue): message
# Example: :sparkles: feat(#123): add login feature
#
# Branch naming convention: prefix/number-description
# Supported prefixes: feat, fix, hotfix, chore, docs, style, refactor, test, perf, ci, build, revert
#
# Behavior:
# - Extracts issue number from branch name
# - Uses branch prefix by default
# - Preserves user-provided prefix if different
# - Preserves gitmoji if provided (doesn't add default)
# - Skips main, master, develop, staging branches

COMMIT_MSG_FILE=$1
COMMIT_SOURCE=$2

# Only process regular commits (not merge, squash, amend with message, etc.)
# Empty COMMIT_SOURCE = regular commit or -m flag
# "message" = -m flag used
# "commit" = amend with -C/-c
# "merge" = merge commit
# "squash" = squash commit
if [[ "$COMMIT_SOURCE" != "" && "$COMMIT_SOURCE" != "message" ]]; then
    exit 0
fi

# Get the current branch name
BRANCH_NAME=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")

# Exit if not on a branch (detached HEAD)
if [[ -z "$BRANCH_NAME" ]]; then
    exit 0
fi

# Skip formatting for main/develop/staging/master branches
if [[ "$BRANCH_NAME" =~ ^(main|master|develop|staging|release/.*)$ ]]; then
    exit 0
fi

# Supported prefixes (conventional commits + extras)
VALID_PREFIXES="feat|fix|hotfix|chore|docs|style|refactor|test|perf|ci|build|revert"

# Extract prefix and issue number from branch name
# Expected format: prefix/number-description (e.g., feat/123-add-login)
BRANCH_PATTERN="^($VALID_PREFIXES)/([0-9]+)-"
if [[ "$BRANCH_NAME" =~ $BRANCH_PATTERN ]]; then
    BRANCH_PREFIX="${BASH_REMATCH[1]}"
    ISSUE_NUMBER="${BASH_REMATCH[2]}"
else
    # Branch doesn't match expected pattern, exit without modifying
    exit 0
fi

# Read the current commit message
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# Get first non-comment line for processing
COMMIT_MSG_CLEAN=$(echo "$COMMIT_MSG" | grep -v "^#" | grep -v "^$" | head -n 1)

# If message is empty, exit
if [[ -z "$COMMIT_MSG_CLEAN" || "$COMMIT_MSG_CLEAN" =~ ^[[:space:]]*$ ]]; then
    exit 0
fi

# Check if message already has the correct format (already processed or manually formatted)
# Pattern: [optional gitmoji] prefix(#number): message
ALREADY_FORMATTED_PATTERN="^(:[a-z_]+:[[:space:]]|.+[[:space:]])?($VALID_PREFIXES)\(#[0-9]+\):"
if [[ "$COMMIT_MSG_CLEAN" =~ $ALREADY_FORMATTED_PATTERN ]]; then
    exit 0
fi

# Gitmoji detection - supports both :shortcode: format and Unicode emojis
GITMOJI=""
USER_MESSAGE="$COMMIT_MSG_CLEAN"

# Pattern 1: Shortcode format like :wrench:, :bug:, :sparkles:
if [[ "$COMMIT_MSG_CLEAN" =~ ^(:[a-z_]+:)[[:space:]]*(.*) ]]; then
    GITMOJI="${BASH_REMATCH[1]}"
    USER_MESSAGE="${BASH_REMATCH[2]}"
# Pattern 2: Unicode emoji at start
elif [[ "$COMMIT_MSG_CLEAN" =~ ^([🀀-🧿⚀-⚿✀-➿🌀-🗿♈-♓⬀-⯿‼-⁉]+)[[:space:]]*(.*) ]]; then
    GITMOJI="${BASH_REMATCH[1]}"
    USER_MESSAGE="${BASH_REMATCH[2]}"
fi

# Check if user provided a different prefix in their message
# Pattern: prefix: message (with colon) - NOT just "fix something"
USER_PREFIX=""
PREFIX_PATTERN="^($VALID_PREFIXES):[[:space:]]*(.*)"
if [[ "$USER_MESSAGE" =~ $PREFIX_PATTERN ]]; then
    USER_PREFIX="${BASH_REMATCH[1]}"
    USER_MESSAGE="${BASH_REMATCH[2]}"
fi

# Clean up message (remove leading/trailing whitespace)
USER_MESSAGE=$(echo "$USER_MESSAGE" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

# If message became empty after parsing, exit
if [[ -z "$USER_MESSAGE" ]]; then
    exit 0
fi

# Determine which prefix to use
# If user provided a prefix, use it; otherwise use branch prefix
FINAL_PREFIX="${USER_PREFIX:-$BRANCH_PREFIX}"

# Build the final commit message
if [[ -n "$GITMOJI" ]]; then
    FINAL_MSG="$GITMOJI $FINAL_PREFIX(#$ISSUE_NUMBER): $USER_MESSAGE"
else
    FINAL_MSG="$FINAL_PREFIX(#$ISSUE_NUMBER): $USER_MESSAGE"
fi

# Preserve the rest of the commit message (body and comments)
COMMIT_BODY=$(echo "$COMMIT_MSG" | tail -n +2)

# Write the new commit message
if [[ -n "$COMMIT_BODY" ]]; then
    printf "%s\n%s" "$FINAL_MSG" "$COMMIT_BODY" > "$COMMIT_MSG_FILE"
else
    echo "$FINAL_MSG" > "$COMMIT_MSG_FILE"
fi
