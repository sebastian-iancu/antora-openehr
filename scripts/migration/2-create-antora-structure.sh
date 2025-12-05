#!/bin/bash
set -e

# Usage: step2-create-antora-structure.sh <module1> <module2> ...

MODULES="$@"

echo "Step 2: Creating Antora directory structure..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create ROOT module directories
mkdir -p modules/ROOT/pages
mkdir -p modules/ROOT/images

# Only create ROOT/partials if it does not already exist
if [ ! -d "modules/ROOT/partials" ]; then
    mkdir -p modules/ROOT/partials
    echo "✓ Created ROOT partials directory"
else
    echo "✓ ROOT partials directory already exists, leaving it untouched"
fi

echo "✓ Created ROOT module structure"

# Process each module (subdirectory in docs/)
for module in $MODULES; do
    echo "→ Processing module: $module"

    mkdir -p "modules/$module/pages"
    mkdir -p "modules/$module/partials"
    mkdir -p "modules/$module/images"
    mkdir -p "modules/$module/examples"

    echo "✓ Created module: $module"
done

echo ""
