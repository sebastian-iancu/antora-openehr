#!/bin/bash
set -euo pipefail

# Usage: step3-move-uml.sh
# Run from repo root

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_lib.sh"

echo "Step 3: Moving UML content..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

move_diagram_to_root() {
  local src="$1"
  local base
  base="$(basename "$src")"
  git_move_preserve_history "$src" "modules/ROOT/images/uml/$base"
}

# Handle UML directory if it exists
if [ -d "docs/UML" ] || [ -d "docs/uml" ]; then
  UML_DIR=$(find docs -iname "UML" -type d | head -n 1)

  mkdir -p modules/ROOT/images/uml

  # Flat layout: UML/diagrams/
  if [ -d "$UML_DIR/diagrams" ]; then
    echo "→ Moving UML diagrams (flat) to ROOT/images/uml/"
    find "$UML_DIR/diagrams" \( -name "*.svg" -o -name "*.png" -o -name "*.jpg" \) -type f | while read -r f; do
      move_diagram_to_root "$f"
    done
    echo "✓ Moved UML diagrams"
  fi

  # Nested layout: UML/<SUBDIR>/diagrams/
  for subdir in "$UML_DIR"/*/; do
    [ -d "$subdir" ] || continue
    subname=$(basename "$subdir")
    if [ -d "$subdir/diagrams" ]; then
      echo "→ Moving UML diagrams from $subname to ROOT/images/uml/"
      find "$subdir/diagrams" \( -name "*.svg" -o -name "*.png" -o -name "*.jpg" \) -type f | while read -r f; do
        move_diagram_to_root "$f"
      done
    fi
  done
else
  echo "No UML directory found, skipping UML move."
fi

echo ""
