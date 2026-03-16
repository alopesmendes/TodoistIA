#!/usr/bin/env bash
# pre-commit.sh — Runs ktlintFormat on staged Kotlin files only.
#
# Uses git stash --keep-index to hide all unstaged changes before running
# ktlint, so only the files you selected to commit are visible to the formatter.
# Unstaged changes are fully restored after the hook completes.

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Known Gradle module directories (must match settings.gradle.kts include() entries)
KNOWN_MODULES="androidApp composeApp server shared"

# Collect staged Kotlin files (added, copied, modified — excludes deleted)
STAGED_KT_FILES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep -E '\.(kt|kts)$' || true)

if [[ -z "$STAGED_KT_FILES" ]]; then
    exit 0
fi

echo -e "${BLUE}[pre-commit] Linting staged Kotlin files...${NC}"

# Stash everything that is NOT staged so ktlint only sees committed + staged content.
# --keep-index        → leave staged changes in the working tree
# --include-untracked → also hides new untracked files
STASHED=false
if ! git diff --quiet || git ls-files --others --exclude-standard | grep -q .; then
    if git stash push --keep-index --include-untracked -q -m "pre-commit: stash unstaged" 2>/dev/null; then
        STASHED=true
    fi
fi

# Always restore the stash on exit (success, failure, or interrupt)
restore_stash() {
    if [[ "$STASHED" == true ]]; then
        git stash pop -q 2>/dev/null || true
    fi
}
trap restore_stash EXIT

# Map each staged file to its Gradle module task.
# Uses a pipe-delimited string for deduplication (bash 3 compatible).
SEEN_TASKS="|"
TASKS=()

add_task() {
    local task="$1"
    if [[ "$SEEN_TASKS" != *"|${task}|"* ]]; then
        SEEN_TASKS="${SEEN_TASKS}${task}|"
        TASKS+=("$task")
    fi
}

while IFS= read -r file; do
    module_dir=$(echo "$file" | cut -d'/' -f1)
    if echo "$KNOWN_MODULES" | grep -qw "$module_dir"; then
        add_task ":${module_dir}:ktlintFormat"
    else
        # Root-level file (e.g. build.gradle.kts)
        add_task "ktlintFormat"
    fi
done <<< "$STAGED_KT_FILES"

echo -e "${YELLOW}[pre-commit] Running: ./gradlew ${TASKS[*]} --no-daemon${NC}"

if ! ./gradlew "${TASKS[@]}" --no-daemon -q 2>&1; then
    echo -e "${RED}[pre-commit] ktlint format failed. Fix the errors above and try again.${NC}"
    exit 1
fi

# Re-stage every staged Kotlin file that still exists on disk.
# This picks up any formatting changes ktlint applied.
while IFS= read -r file; do
    if [[ -f "$file" ]]; then
        git add "$file"
    fi
done <<< "$STAGED_KT_FILES"

echo -e "${GREEN}[pre-commit] Done — formatted files re-staged.${NC}"
