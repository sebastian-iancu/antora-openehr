#!/bin/bash
set -euo pipefail

# Rewrites class cross-references in ROOT/partials/classes/ to Antora xref macros
# using class_* attributes from global-vars.yml.
#
# Handles two patterns:
#
#   1. AsciiDoc internal refs:
#      <<_string_class,String>>  →  xref:{class_string}[String]
#
#   2. Hardcoded release URL links:
#      link:/releases/BASE/{base_release}/foundation_types.html#_string_class[String^]
#        →  xref:{class_string}[String]
#
# Run from repo root (inside the target specification repo)

CLASSES_DIR="modules/ROOT/partials/classes"

[ -d "$CLASSES_DIR" ] || { echo "No classes dir found, skipping."; exit 0; }

echo "Step 10: Rewriting class cross-references in $CLASSES_DIR..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for f in "$CLASSES_DIR"/*.adoc; do
  [ -f "$f" ] || continue

  # Pattern 1a: <<_foo_bar_class,Some Text>>  →  xref:{class_foo_bar}[Some Text]
  sed -i 's/<<_\([a-z0-9_]*\)_class,\([^>]*\)>>/xref:{class_\1}[\2]/g' "$f"

  # Pattern 1b: <<_foo_bar_class>>  →  xref:{class_foo_bar}[foo_bar]
  sed -i 's/<<_\([a-z0-9_]*\)_class>>/xref:{class_\1}[\1]/g' "$f"

  # Pattern 2: link:/releases/.../spec.html#_foo_bar_class[Text^]  →  xref:{class_foo_bar}[Text]
  # Strips the ^ (external link marker) from the display text
  sed -i 's|link:/releases/[^#]*#_\([a-z0-9_]*\)_class\[\([^\^]*\)\^\]|xref:{class_\1}[\2]|g' "$f"

  # Pattern 2b: same but without the ^ marker
  sed -i 's|link:/releases/[^#]*#_\([a-z0-9_]*\)_class\[\([^]]*\)\]|xref:{class_\1}[\2]|g' "$f"
done

echo "✓ Rewrote class cross-references"
echo ""
