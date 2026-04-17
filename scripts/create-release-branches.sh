#!/bin/bash
set -euo pipefail

# Script to create release branches from git tags and a development branch from master.
# Usage: ./create-release-branches.sh /path/to/repo

REPO_PATH="$1"

if [ -z "$REPO_PATH" ]; then
    echo "Error: Repository path not provided"
    echo "Usage: $0 /path/to/repo"
    exit 1
fi

if [ ! -d "$REPO_PATH" ]; then
    echo "Error: Repository path does not exist: $REPO_PATH"
    exit 1
fi

cd "$REPO_PATH"

# Check if this is a git repository
if [ ! -d ".git" ]; then
    echo "Error: $REPO_PATH is not a git repository"
    exit 1
fi

echo "Processing repository: $(basename $REPO_PATH)"
echo "=============================================="

# Fetch tags and remote heads so origin/master is available for development
echo "Fetching tags and remote refs..."
git fetch --tags
git fetch origin 2>/dev/null || true

# Get all tags that look like version numbers (e.g., Release-1.0.2, v1.0.2, 1.0.2)
TAGS=$(git tag -l | grep -E '(Release-|v)?[0-9]+\.[0-9]+\.[0-9]+(v[0-9]+)?' || true)

if [ -z "$TAGS" ]; then
    echo "No version tags found in repository (skipping release/* branches)"
else
    echo ""
    echo "Found the following version tags:"
    echo "$TAGS"
    echo ""

    # Process each tag
    for TAG in $TAGS; do
        # Extract version number from tag
        VERSION=$(echo "$TAG" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')

        # Create branch name
        BRANCH_NAME="release/$VERSION"

        # Create or update branch without touching the working directory
        if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
            echo "✓ Branch $BRANCH_NAME already exists, updating to $TAG"
            git branch -f "$BRANCH_NAME" "$TAG"
        else
            echo "→ Creating branch $BRANCH_NAME from tag $TAG"
            git branch "$BRANCH_NAME" "$TAG"
            echo "✓ Created branch $BRANCH_NAME"
        fi
    done
fi

# Development branch: tracks current master (Antora playbooks use this instead of master)
echo ""
echo "----------------------------------------------"
echo "Ensuring development branch from master..."
MASTER_REF=""
if git rev-parse --verify refs/remotes/origin/master >/dev/null 2>&1; then
    MASTER_REF="refs/remotes/origin/master"
elif git rev-parse --verify refs/heads/master >/dev/null 2>&1; then
    MASTER_REF="refs/heads/master"
else
    echo "⚠ No master branch (origin/master or master); skipping development branch"
fi

if [ -n "$MASTER_REF" ]; then
    if git show-ref --verify --quiet refs/heads/development; then
        echo "✓ Branch development exists, updating to $MASTER_REF"
        git branch -f development "$MASTER_REF"
    else
        echo "→ Creating branch development from $MASTER_REF"
        git branch development "$MASTER_REF"
        echo "✓ Created branch development"
    fi
fi

echo ""
echo "=============================================="
echo "Branch creation complete!"
echo ""
echo "Created/verified branches:"
git branch -l 'release/*' 2>/dev/null || true
if git show-ref --verify --quiet refs/heads/development; then
    git branch -l development
fi

echo ""
echo "To push these branches to remote, run:"
echo "  cd $REPO_PATH"
echo "  git push origin development"
echo "  git push origin 'refs/heads/release/*'"
