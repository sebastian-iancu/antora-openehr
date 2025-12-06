#!/bin/bash
set -e

# Script to validate Antora structure in a repository
# Usage: ./validate-structure.sh /path/to/repo

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

REPO_NAME=$(basename "$REPO_PATH")
ERRORS=0
WARNINGS=0

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Antora Structure Validator                               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Validating: $REPO_NAME"
echo "Path:       $REPO_PATH"
echo ""

cd "$REPO_PATH"

# Check 1: antora.yml exists
echo "→ Checking for antora.yml..."
if [ -f "antora.yml" ]; then
    echo "✓ antora.yml found"
    
    # Validate antora.yml content
    if grep -q "^name:" antora.yml; then
        echo "  ✓ 'name' attribute present"
    else
        echo "  ✗ 'name' attribute missing"
        ERRORS=$((ERRORS + 1))
    fi
    
    if grep -q "^version:" antora.yml; then
        echo "  ✓ 'version' attribute present"
    else
        echo "  ⚠ 'version' attribute missing"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    if grep -q "^start_page:" antora.yml; then
        echo "  ✓ 'start_page' attribute present"
    else
        echo "  ✗ 'start_page' attribute missing"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "✗ antora.yml not found"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 2: modules directory exists
echo "→ Checking for modules directory..."
if [ -d "modules" ]; then
    echo "✓ modules/ directory found"
    
    # Count modules
    MODULE_COUNT=$(find modules/* -maxdepth 0 -type d 2>/dev/null | wc -l)
    echo "  Found $MODULE_COUNT module(s)"
    
    # Check for ROOT module
    if [ -d "modules/ROOT" ]; then
        echo "  ✓ ROOT module exists"
    else
        echo "  ✗ ROOT module missing"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "✗ modules/ directory not found"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 3: Validate each module structure
echo "→ Validating module structures..."
if [ -d "modules" ]; then
    for MODULE_DIR in modules/*/; do
        MODULE=$(basename "$MODULE_DIR")
        echo ""
        echo "  Module: $MODULE"
        echo "  ────────────────────────────────"
        
        # Check for pages directory
        if [ -d "$MODULE_DIR/pages" ]; then
            PAGE_COUNT=$(find "$MODULE_DIR/pages" -name "*.adoc" 2>/dev/null | wc -l)
            echo "    ✓ pages/ directory ($PAGE_COUNT files)"
            
            # Check for index.adoc in pages
            if [ -f "$MODULE_DIR/pages/index.adoc" ]; then
                echo "      ✓ index.adoc exists"
            else
                echo "      ⚠ index.adoc missing (recommended)"
                WARNINGS=$((WARNINGS + 1))
            fi
        else
            echo "    ✗ pages/ directory missing"
            ERRORS=$((ERRORS + 1))
        fi
        
        # Check for partials directory
        if [ -d "$MODULE_DIR/partials" ]; then
            PARTIAL_COUNT=$(find "$MODULE_DIR/partials" -name "*.adoc" 2>/dev/null | wc -l)
            echo "    ✓ partials/ directory ($PARTIAL_COUNT files)"

            # Check for vars in partials
            if [ "$MODULE" = "ROOT" ]; then
                if [ -f "$MODULE_DIR/partials/component_vars.adoc" ]; then
                    echo "      ✓ partials/component_vars.adoc exists"
                else
                    echo "      ⚠ partials/component_vars.adoc missing (required)"
                    ERRORS=$((ERRORS + 1))
                fi
            else
                if [ -f "$MODULE_DIR/partials/module_vars.adoc" ]; then
                    echo "      ✓ partials/module_vars.adoc exists"
                else
                    echo "      ⚠ partials/module_vars.adoc missing (required)"
                    ERRORS=$((ERRORS + 1))
                fi
            fi
        else
            echo "    ✗ partials/ directory not present (required)"
            ERRORS=$((ERRORS + 1))
        fi
        
        # Check for images directory
        if [ -d "$MODULE_DIR/images" ]; then
            IMAGE_COUNT=$(find "$MODULE_DIR/images" \( -name "*.png" -o -name "*.jpg" -o -name "*.svg" \) 2>/dev/null | wc -l)
            echo "    ✓ images/ directory ($IMAGE_COUNT files)"
        else
            echo "    ℹ images/ directory not present (optional)"
        fi
        
        # Check for nav.adoc
        if [ -f "$MODULE_DIR/nav.adoc" ]; then
            echo "    ✓ nav.adoc exists"
        else
            echo "    ⚠ nav.adoc missing (recommended)"
            WARNINGS=$((WARNINGS + 1))
        fi
    done
fi
echo ""

# Check 4: Look for old structure remnants
echo "→ Checking for old structure remnants..."
if [ -d "docs" ]; then
    echo "⚠ docs/ directory still exists"
    echo "  Consider archiving or removing after migration is complete"
    WARNINGS=$((WARNINGS + 1))
else
    echo "✓ No old docs/ directory found"
fi
echo ""

# Check 5: Validate common AsciiDoc issues
echo "→ Scanning for common migration issues..."
INCLUDE_ISSUES=0

# Look for old-style includes in pages
if [ -d "modules" ]; then
    # Check for includes without partial$
    while IFS= read -r line; do
        if echo "$line" | grep -q "include::" && ! echo "$line" | grep -q "partial\\$" && ! echo "$line" | grep -q "example\\$"; then
            if [ $INCLUDE_ISSUES -eq 0 ]; then
                echo "⚠ Found potential include directive issues:"
            fi
            echo "  $line"
            INCLUDE_ISSUES=$((INCLUDE_ISSUES + 1))
        fi
    done < <(find modules/*/pages -name "*.adoc" -exec grep -H "include::" {} \; 2>/dev/null)
    
    if [ $INCLUDE_ISSUES -gt 0 ]; then
        echo ""
        echo "  Found $INCLUDE_ISSUES potential include issues"
        echo "  Include directives should use: include::partial\$filename.adoc[]"
        WARNINGS=$((WARNINGS + 1))
    else
        echo "✓ No obvious include directive issues found"
    fi
fi
echo ""

# Summary
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Validation Summary                                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Repository: $REPO_NAME"
echo "Errors:     $ERRORS"
echo "Warnings:   $WARNINGS"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✓ Structure validation passed with no issues!"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "✓ Structure validation passed with $WARNINGS warning(s)"
    echo "  Review warnings above and address if needed"
    exit 0
else
    echo "✗ Structure validation failed with $ERRORS error(s) and $WARNINGS warning(s)"
    echo "  Please fix errors before building with Antora"
    exit 1
fi
