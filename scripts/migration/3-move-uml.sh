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
        echo "→ Moving UML classes to ROOT/partials/uml"
        mkdir -p modules/ROOT/partials/uml/
        find "$UML_DIR/classes" -name "*.adoc" -exec cp {} modules/ROOT/partials/uml/ \;
        echo "✓ Moved UML classes"
    fi

    # Move UML diagrams to ROOT images
    if [ -d "$UML_DIR/diagrams" ]; then
        echo "→ Moving UML diagrams to ROOT/images/uml/diagrams/"
        mkdir -p modules/ROOT/images/uml/diagrams
        find "$UML_DIR/diagrams" \( -name "*.svg" -o -name "*.png" -o -name "*.jpg" \) \
            -exec cp {} modules/ROOT/images/uml/diagrams/ \;
        echo "✓ Moved UML diagrams"
    fi
else
    echo "No UML directory found, skipping UML move."
fi

echo ""
