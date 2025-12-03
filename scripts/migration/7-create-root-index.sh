#!/bin/bash
set -e

# Usage: step7-create-root-index.sh <COMPONENT_NAME> <module1> <module2> ...

COMPONENT_NAME="$1"
shift
MODULES="$@"

echo "Step 7: Creating ROOT index page..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

mkdir -p "modules/ROOT/pages"

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
echo ""
