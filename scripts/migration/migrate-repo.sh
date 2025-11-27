#!/bin/bash
set -e

# Script to migrate openEHR specification repository to Antora structure
# Usage: ./migrate-repo.sh /path/to/repo

REPO_PATH="$1"
DRY_RUN="${2:-false}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -z "$REPO_PATH" ]; then
    echo "Error: Repository path not provided"
    echo "Usage: $0 /path/to/repo [dry-run]"
    echo ""
    echo "Examples:"
    echo "  $0 /path/to/specifications-BASE"
    echo "  $0 /path/to/specifications-BASE dry-run  # Test without making changes"
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
echo "Dry run:    $DRY_RUN"
echo ""

cd "$REPO_PATH"

# Check if this is a git repository
if [ ! -d ".git" ]; then
    echo "Error: $REPO_PATH is not a git repository"
    exit 1
fi

# Safety check: Create a backup branch
if [ "$DRY_RUN" != "dry-run" ]; then
    BACKUP_BRANCH="backup-pre-antora-$(date +%Y%m%d-%H%M%S)"
    echo "→ Creating backup branch: $BACKUP_BRANCH"
    git branch "$BACKUP_BRANCH" HEAD
    echo "✓ Backup created"
    echo ""
fi

# Check if docs directory exists
if [ ! -d "docs" ]; then
    echo "Error: docs directory not found in $REPO_PATH"
    echo "This script expects the current structure with a docs/ directory"
    exit 1
fi

echo "Step 1: Analyzing current structure..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Find all subdirectories in docs/ (these will become modules)
MODULES=$(find docs/* -maxdepth 0 -type d 2>/dev/null | sed 's|docs/||' || true)

if [ -z "$MODULES" ]; then
    echo "Warning: No subdirectories found in docs/"
    MODULES=""
fi

echo "Found modules:"
for module in $MODULES; do
    echo "  - $module"
done
echo ""

# Function to execute or print command based on dry-run mode
execute() {
    if [ "$DRY_RUN" = "dry-run" ]; then
        echo "[DRY-RUN] $*"
    else
        "$@"
    fi
}

echo "Step 2: Creating Antora directory structure..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create modules directory
execute mkdir -p modules/ROOT/pages
execute mkdir -p modules/ROOT/partials
execute mkdir -p modules/ROOT/images

echo "✓ Created ROOT module structure"

# Process each module (subdirectory in docs/)
for module in $MODULES; do
    # Skip UML directory - it will be handled specially
    if [ "$module" = "UML" ] || [ "$module" = "uml" ]; then
        echo "  Skipping $module (will be processed separately)"
        continue
    fi
    
    echo "→ Processing module: $module"
    
    execute mkdir -p "modules/$module/pages"
    execute mkdir -p "modules/$module/partials"
    execute mkdir -p "modules/$module/images"
    execute mkdir -p "modules/$module/examples"
    
    echo "✓ Created module: $module"
done

echo ""
echo "Step 3: Moving UML content..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Handle UML directory if it exists
if [ -d "docs/UML" ] || [ -d "docs/uml" ]; then
    UML_DIR=$(find docs -iname "UML" -type d | head -n 1)
    
    # Move UML classes to ROOT partials
    if [ -d "$UML_DIR/classes" ]; then
        echo "→ Moving UML classes to ROOT/partials/uml/classes/"
        execute mkdir -p modules/ROOT/partials/uml/classes
        if [ "$DRY_RUN" != "dry-run" ]; then
            find "$UML_DIR/classes" -name "*.adoc" -exec cp {} modules/ROOT/partials/uml/classes/ \;
        else
            echo "[DRY-RUN] cp $UML_DIR/classes/*.adoc modules/ROOT/partials/uml/classes/"
        fi
        echo "✓ Moved UML classes"
    fi
    
    # Move UML diagrams to ROOT images
    if [ -d "$UML_DIR/diagrams" ]; then
        echo "→ Moving UML diagrams to ROOT/images/uml/diagrams/"
        execute mkdir -p modules/ROOT/images/uml/diagrams
        if [ "$DRY_RUN" != "dry-run" ]; then
            find "$UML_DIR/diagrams" \( -name "*.svg" -o -name "*.png" -o -name "*.jpg" \) \
                -exec cp {} modules/ROOT/images/uml/diagrams/ \;
        else
            echo "[DRY-RUN] cp $UML_DIR/diagrams/* modules/ROOT/images/uml/diagrams/"
        fi
        echo "✓ Moved UML diagrams"
    fi
fi

echo ""
echo "Step 4: Migrating content files..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Process each module's content
for module in $MODULES; do
    if [ "$module" = "UML" ] || [ "$module" = "uml" ]; then
        continue
    fi
    
    echo "→ Processing content in: $module"
    
    # Find master.adoc (main page file)
    if [ -f "docs/$module/master.adoc" ]; then
        echo "  • master.adoc → pages/index.adoc"
        if [ "$DRY_RUN" != "dry-run" ]; then
            TARGET_FILE="modules/$module/pages/index.adoc"
            cp "docs/$module/master.adoc" "$TARGET_FILE"
            "$SCRIPT_DIR/alter_master_adoc.sh" "$TARGET_FILE"
        fi
    fi
    
    # Move all master##-*.adoc files to pages with renamed names
    if [ "$DRY_RUN" != "dry-run" ]; then
        find "docs/$module" -name "master[0-9][0-9]-*.adoc" 2>/dev/null | while read -r file; do
            basename_file=$(basename "$file")
            # Extract the part after "master##-"
            new_name=$(echo "$basename_file" | sed 's/master[0-9][0-9]-//')
            echo "  • $basename_file → pages/$new_name"
            cp "$file" "modules/$module/pages/$new_name"
        done
    else
        echo "  [DRY-RUN] Would move master##-*.adoc files to pages/"
    fi
    
    # Move images if they exist
    if [ -d "docs/$module/images" ]; then
        echo "  • Copying images/"
        if [ "$DRY_RUN" != "dry-run" ]; then
            cp -r "docs/$module/images/"* "modules/$module/images/" 2>/dev/null || true
        fi
    fi
    
    # Move diagrams if they exist
    if [ -d "docs/$module/diagrams" ]; then
        echo "  • Copying diagrams/ to images/"
        execute mkdir -p "modules/$module/images/diagrams"
        if [ "$DRY_RUN" != "dry-run" ]; then
            cp -r "docs/$module/diagrams/"* "modules/$module/images/diagrams/" 2>/dev/null || true
        fi
    fi
    
    echo "✓ Processed: $module"
done

echo ""
echo "Step 5: Creating antora.yml component descriptor..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create antora.yml
ANTORA_YML="antora.yml"

if [ "$DRY_RUN" != "dry-run" ]; then
    cat > "$ANTORA_YML" << EOF
name: $COMPONENT_NAME
title: $COMPONENT_NAME Component
version: ~
display_version: Development
start_page: ROOT:index.adoc
nav:
  - modules/ROOT/nav.adoc
EOF

    # Add navigation entries for each module
    for module in $MODULES; do
        if [ "$module" != "UML" ] && [ "$module" != "uml" ]; then
            echo "  - modules/$module/nav.adoc" >> "$ANTORA_YML"
        fi
    done
    
    echo "✓ Created antora.yml"
else
    echo "[DRY-RUN] Would create antora.yml with:"
    echo "  name: $COMPONENT_NAME"
    echo "  version: ~"
    echo "  start_page: ROOT:index.adoc"
fi

echo ""
echo "Step 6: Creating navigation files..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Delegate nav.adoc creation to separate script
"$SCRIPT_DIR/create_nav_files.sh" "$DRY_RUN" $MODULES

echo ""
echo "Step 7: Creating ROOT index page..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$DRY_RUN" != "dry-run" ]; then
    cat > "modules/ROOT/pages/index.adoc" << EOF
= $COMPONENT_NAME Component

Welcome to the $COMPONENT_NAME component of the openEHR specifications.

== Modules

EOF

    # Add links to each module
    for module in $MODULES; do
        if [ "$module" != "UML" ] && [ "$module" != "uml" ]; then
            MODULE_TITLE=$(echo "$module" | sed 's/_/ /g' | sed 's/\b\(.\)/\u\1/g')
            echo "* xref:$module:index.adoc[$MODULE_TITLE]" >> "modules/ROOT/pages/index.adoc"
        fi
    done
    
    echo "✓ Created ROOT index page"
else
    echo "[DRY-RUN] Would create modules/ROOT/pages/index.adoc"
fi

echo ""
echo "Step 8: Updating include directives..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️  MANUAL STEP REQUIRED:"
echo ""
echo "You need to update include directives in the migrated .adoc files:"
echo ""
echo "In modules/*/pages/index.adoc files, change:"
echo "  include::master01-preface.adoc[]"
echo "To:"
echo "  include::xref:preface.adoc[]"
echo ""
echo "For UML class includes, change:"
echo "  include::../../UML/classes/LOCATABLE.adoc[]"
echo "To:"
echo "  include::ROOT:partial\$uml/classes/LOCATABLE.adoc[]"
echo ""
echo "For UML diagram images, change:"
echo "  image::../UML/diagrams/diagram.svg[]"
echo "To:"
echo "  image::ROOT:uml/diagrams/diagram.svg[]"
echo ""

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Migration Summary                                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "✓ Repository: $REPO_NAME"
echo "✓ Component:  $COMPONENT_NAME"
echo "✓ Modules:    $(echo $MODULES | wc -w)"
echo ""

if [ "$DRY_RUN" != "dry-run" ]; then
    echo "✓ Backup branch: $BACKUP_BRANCH"
    echo ""
    echo "Next steps:"
    echo "  1. Review the migrated structure in modules/"
    echo "  2. Update include directives manually (see Step 8 above)"
    echo "  3. Test build: make validate-structure REPO=$REPO_NAME"
    echo "  4. Commit changes: git add . && git commit -m 'Migrate to Antora structure'"
    echo ""
    echo "To rollback: git checkout $BACKUP_BRANCH"
else
    echo "This was a DRY RUN - no changes were made."
    echo "Run without 'dry-run' parameter to perform actual migration."
fi

echo ""
