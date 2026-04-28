#!/usr/bin/env bash
# Step 12b: Fix AsciiDoc heading ladder for *class_definitions partials that embed
# ROOT partial$classes includes (e.g. constraint_model-class_definitions.adoc).
#
# Problem: partial opens with "= Class Definitions" and is included from an *overview
# page with [leveloffset=+1], while nested class fragments use "=== …". AsciiDoctor then
# warns "section title out of sequence: expected level 2, got level 3".
#
# Fix: promote the partial top heading to "== Class Definitions" and include it without
# leveloffset so "===" class sections nest under "= Constraint Model Package" correctly.
#
# Usage: 12b-fix-class-definitions-heading-ladder.sh <COMPONENT_NAME> <module> ...
set -euo pipefail

COMPONENT_NAME="$1"
shift
MODULES="$@"

echo "Step 12b: Fixing class_definitions partial / overview include heading ladder..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

fix_module() {
  local module="$1"
  local partials_dir="modules/$module/partials"
  local pages_dir="modules/$module/pages"

  [ -d "$partials_dir" ] || return 0

  local p base f
  shopt -s nullglob
  for p in "$partials_dir"/*class_definitions.adoc; do
    [ -f "$p" ] || continue
    grep -q 'include::ROOT:partial\$classes/' "$p" 2>/dev/null || continue
    if ! grep -q '^= Class Definitions[[:space:]]*$' "$p"; then
      continue
    fi

    echo "  • $module: $(basename "$p") — promote '= Class Definitions' to '=='"
    sed -i 's/^= Class Definitions$/== Class Definitions/' "$p"

    base=$(basename "$p" .adoc)
    [ -d "$pages_dir" ] || continue
    for f in "$pages_dir"/*.adoc; do
      [ -f "$f" ] || continue
      if grep -qF "include::partial\$${base}.adoc[leveloffset=+1]" "$f"; then
        echo "  • $module: $(basename "$f") — strip [leveloffset=+1] for ${base} include"
        sed -i 's|include::partial\$'"${base}"'\.adoc\[leveloffset=+1\]|include::partial\$'"${base}"'.adoc[]|g' "$f"
      fi
    done
  done
  shopt -u nullglob
}

for module in $MODULES; do
  fix_module "$module"
done

echo ""
echo "✓ Class definitions heading ladder step finished"
