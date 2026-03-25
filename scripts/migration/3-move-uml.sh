#!/bin/bash
set -e

# Usage: step3-move-uml.sh <COMPONENT_NAME>
# Run from repo root

COMPONENT_NAME="${1:-}"

echo "Step 3: Moving UML content..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Handle UML directory if it exists
if [ -d "docs/UML" ] || [ -d "docs/uml" ]; then
    UML_DIR=$(find docs -iname "UML" -type d | head -n 1)

    mkdir -p modules/ROOT/partials/classes/ modules/ROOT/images/uml

    # Flat layout: UML/classes/ and UML/diagrams/
    # For AM, flat classes are AOM2 — copy with aom2. prefix since AOM1.4 has overlapping names.
    # For all other components, copy flat (no prefix needed).
    if [ -d "$UML_DIR/classes" ]; then
        if [[ "$COMPONENT_NAME" == "AM" ]]; then
            echo "→ Moving UML classes (flat/AM) to ROOT/partials/classes with aom2. prefix"
            for f in "$UML_DIR/classes/"*.adoc; do
                [ -f "$f" ] || continue
                cp "$f" "modules/ROOT/partials/classes/aom2.$(basename "$f")"
            done
        else
            echo "→ Moving UML classes (flat) to ROOT/partials/classes"
            find "$UML_DIR/classes" -name "*.adoc" -exec cp {} modules/ROOT/partials/classes/ \;
        fi
        echo "✓ Moved UML classes"
    fi
    if [ -d "$UML_DIR/diagrams" ]; then
        echo "→ Moving UML diagrams (flat) to ROOT/images/uml/"
        find "$UML_DIR/diagrams" \( -name "*.svg" -o -name "*.png" -o -name "*.jpg" \) \
            -exec cp {} modules/ROOT/images/uml/ \;
        echo "✓ Moved UML diagrams"
    fi

    # Nested layout: UML/<SUBDIR>/classes/ and UML/<SUBDIR>/diagrams/
    for subdir in "$UML_DIR"/*/; do
        [ -d "$subdir" ] || continue
        subname=$(basename "$subdir")
        # Derive short prefix: AOM1.4 → aom14, AOM2 → aom2
        prefix=$(echo "$subname" | tr '[:upper:]' '[:lower:]' | tr -d '.')

        if [ -d "$subdir/classes" ]; then
            echo "→ Moving UML classes from $subname (prefix: $prefix.) to ROOT/partials/classes"
            for f in "$subdir/classes/"*.adoc; do
                [ -f "$f" ] || continue
                cp "$f" "modules/ROOT/partials/classes/${prefix}.$(basename "$f")"
            done
        fi
        if [ -d "$subdir/diagrams" ]; then
            echo "→ Moving UML diagrams from $subname to ROOT/images/uml/"
            find "$subdir/diagrams" \( -name "*.svg" -o -name "*.png" -o -name "*.jpg" \) \
                -exec cp {} modules/ROOT/images/uml/ \;
        fi
    done
else
    echo "No UML directory found, skipping UML move."
fi

echo ""
