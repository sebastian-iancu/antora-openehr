#!/bin/bash
set -e

# Usage: step3-move-uml.sh
# Run from repo root

echo "Step 3: Moving UML content..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Handle UML directory if it exists
if [ -d "docs/UML" ] || [ -d "docs/uml" ]; then
    UML_DIR=$(find docs -iname "UML" -type d | head -n 1)

    # Move UML classes to ROOT partials
    if [ -d "$UML_DIR/classes" ]; then
#        echo "→ Moving UML classes to ROOT/partials/classes"
        echo "→ Creating classes-tabs directory in ROOT/partials/classes"
        mkdir -p modules/ROOT/partials/classes/
#        find "$UML_DIR/classes" -name "*.adoc" -exec cp {} modules/ROOT/partials/classes/ \;
#        echo "✓ Moved UML classes"
        echo "✓ Created classes-tabs directory "
    fi

    # Move UML diagrams to ROOT images
    if [ -d "$UML_DIR/diagrams" ]; then
        echo "→ Moving UML diagrams to ROOT/images/uml/"
        mkdir -p modules/ROOT/images/uml
        find "$UML_DIR/diagrams" \( -name "*.svg" -o -name "*.png" -o -name "*.jpg" \) \
            -exec cp {} modules/ROOT/images/uml/ \;
        echo "✓ Moved UML diagrams"
    fi
else
    echo "No UML directory found, skipping UML move."
fi

echo ""
