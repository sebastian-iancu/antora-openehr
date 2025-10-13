#!/bin/bash
set -e

# Script to create release branches from git tags
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

# Fetch all tags
echo "Fetching tags..."
git fetch --tags

# Get all tags that look like version numbers (e.g., Release-1.0.2, v1.0.2, 1.0.2)
TAGS=$(git tag -l | grep -E '(Release-|v)?[0-9]+\.[0-9]+\.[0-9]+(v[0-9]+)?' || true)

if [ -z "$TAGS" ]; then
    echo "No version tags found in repository"
    exit 0
fi

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
    
    # Check if branch already exists
    if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
        echo "✓ Branch $BRANCH_NAME from tag $TAG already exists locally"
        git checkout -f -B "$BRANCH_NAME" "$TAG"
        echo "✓ Bound branch $BRANCH_NAME to $TAG tag"
    else
        echo "→ Creating branch $BRANCH_NAME from tag $TAG"
        git branch "$BRANCH_NAME" "$TAG"
        echo "✓ Created branch $BRANCH_NAME"
    fi
done

echo ""
echo "=============================================="
echo "Branch creation complete!"
echo ""
echo "Created/verified branches:"
git branch -l 'release/*'

echo ""
echo "To push these branches to remote, run:"
echo "  cd $REPO_PATH"
echo "  git push origin 'refs/heads/release/*'"
