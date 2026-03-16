#!/usr/bin/env bash
# install-hooks.sh - Installs all git hooks from scripts/git-hooks/
#
# Usage: ./scripts/git-hooks/install-hooks.sh [--force]
#
# Installs hooks directly to .git/hooks/ — recommended when NOT using
# the pre-commit framework for these hooks.

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

FORCE=false
if [[ "$1" == "--force" || "$1" == "-f" ]]; then
    FORCE=true
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Git Hooks Installer${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo -e "${RED}Error: Not in a git repository.${NC}"
    echo -e "Please run this script from the root of your git repository."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR=".git/hooks"

mkdir -p "$HOOKS_DIR"

install_hook() {
    local hook_name="$1"
    local source="$SCRIPT_DIR/$hook_name.sh"
    local dest="$HOOKS_DIR/$hook_name"

    if [ ! -f "$source" ]; then
        echo -e "${YELLOW}Skipping $hook_name — source not found${NC}"
        return
    fi

    if [ -f "$dest" ] && [ "$FORCE" = false ]; then
        # If not interactive, don't try to read
        if [ -t 0 ]; then
            echo -e "${YELLOW}Warning: $hook_name already exists${NC}"
            read -p "Overwrite? (y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo -e "${YELLOW}Skipped $hook_name${NC}"
                return
            fi
        else
            echo -e "${YELLOW}Warning: $hook_name already exists and not in interactive terminal. Use --force to overwrite.${NC}"
            echo -e "${YELLOW}Skipping $hook_name${NC}"
            return
        fi
    fi

    cp "$source" "$dest"
    chmod +x "$dest"
    echo -e "${GREEN}✓ $hook_name installed${NC}"
}

install_hook "pre-commit"
install_hook "prepare-commit-msg"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  How It Works${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${BLUE}pre-commit${NC}"
echo -e "  Runs ${YELLOW}ktlintFormat${NC} on staged .kt/.kts files only."
echo -e "  Only the modules that contain staged files are linted."
echo -e "  Formatted files are automatically re-staged."
echo ""
echo -e "${BLUE}prepare-commit-msg${NC}"
echo -e "Branch convention: ${YELLOW}prefix/number-description${NC}"
echo -e "Prefixes: feat, fix, hotfix, chore, docs, style, refactor, test, perf, ci, build, revert"
echo ""
echo -e "${BLUE}Examples:${NC}"
echo ""
echo -e "  Branch: ${YELLOW}feat/123-add-login${NC}"
echo -e "  Input:  ${YELLOW}Hello world${NC}"
echo -e "  Output: ${GREEN}feat(#123): Hello world${NC}"
echo ""
echo -e "  Branch: ${YELLOW}chore/42-cleanup${NC}"
echo -e "  Input:  ${YELLOW}🎨 Hello world${NC}"
echo -e "  Output: ${GREEN}🎨 chore(#42): Hello world${NC}"
echo ""
echo -e "  Branch: ${YELLOW}feat/123-add-login${NC}"
echo -e "  Input:  ${YELLOW}:bug: fix: correct validation${NC}"
echo -e "  Output: ${GREEN}:bug: fix(#123): correct validation${NC}"
echo ""
echo -e "${BLUE}Troubleshooting:${NC}"
echo -e "  Syntax check:  ${YELLOW}bash -n .git/hooks/prepare-commit-msg${NC}"
echo -e "  Permissions:   ${YELLOW}ls -la .git/hooks/prepare-commit-msg${NC}"
echo ""
