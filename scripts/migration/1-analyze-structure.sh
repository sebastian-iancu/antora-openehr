#!/bin/bash
set -e

# Usage: step1-analyze-structure.sh
# Run from repo root (expects docs/)

if [ ! -d "docs" ]; then
    echo "Error: docs directory not found in $(pwd)" >&2
    echo "This script expects the current structure with a docs/ directory" >&2
    exit 1
fi

echo "Step 1: Analyzing current structure..." >&2
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2

MODULES=$(find docs/* -maxdepth 0 -type d 2>/dev/null | sed 's|docs/||' || true)

if [ -z "$MODULES" ]; then
    echo "Warning: No subdirectories found in docs/" >&2
else
    echo "Found modules:" >&2
    for module in $MODULES; do
        echo "  - $module" >&2
    done
fi

echo "" >&2

# Print modules to stdout for main script to capture
echo "$MODULES"
