#!/bin/bash
set -e

# Script to migrate openEHR specification repository to Antora structure
# Usage: ./main-migrate-repo.sh /path/to/repo

REPO_PATH="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -z "$REPO_PATH" ]; then
    echo "Error: Repository path not provided"
    echo "Usage: $0 /path/to/repo"
    echo ""
    echo "Examples:"
    echo "  $0 /path/to/specifications-BASE"
    exit 1
fi

if [ ! -d "$REPO_PATH" ]; then
    echo "Error: Repository path does not exist: $REPO_PATH"
    exit 1
fi

REPO_NAME=$(basename "$REPO_PATH")
COMPONENT_NAME="${REPO_NAME#specifications-}"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  openEHR Antora Migration Script                          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Repository: $REPO_NAME"
echo "Component:  $COMPONENT_NAME"
echo "Path:       $REPO_PATH"
echo ""

cd "$REPO_PATH"

# Check if this is a git repository
if [ ! -d ".git" ]; then
    echo "Error: $REPO_PATH is not a git repository"
    exit 1
fi

# Safety check: Create a backup branch
BACKUP_BRANCH="backup-pre-antora-$(date +%Y%m%d-%H%M%S)"
echo "→ Creating backup branch: $BACKUP_BRANCH"
git branch "$BACKUP_BRANCH" HEAD
echo "✓ Backup created"
echo ""

# Step 1: Analyze structure and get MODULES (stdout), logs go to stderr
MODULES="$("$SCRIPT_DIR/1-analyze-structure.sh")"

# Step 2: Create Antora directory structure
"$SCRIPT_DIR/2-create-antora-structure.sh" $MODULES

# Step 3: Move UML content into ROOT
"$SCRIPT_DIR/3-move-uml.sh"

# Step 4: Migrating content files (your existing script)
"$SCRIPT_DIR/4-migrate_content_files.sh" $MODULES

# Step 5: Create antora.yml
"$SCRIPT_DIR/5-create-antora-yml.sh" "$COMPONENT_NAME" $MODULES

# Step 6: Create navigation files (your existing create_nav_files.sh)
"$SCRIPT_DIR/6-create_nav_files.sh" $MODULES

# Step 7: Create ROOT index page
"$SCRIPT_DIR/7-create-root-index.sh" "$COMPONENT_NAME" $MODULES

# Step 8: Create ROOT index page
"$SCRIPT_DIR/8-apply-manifest-vars.sh" $MODULES
