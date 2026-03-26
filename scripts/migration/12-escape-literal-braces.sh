#!/bin/bash
set -euo pipefail

# Step 12: Escape literal curly-brace expressions that Asciidoctor
# misparses as attribute references in ADL/grammar prose.
# Targets patterns like {0}, {1}, {0..1}, {m..n}, {*} in AM pages.

echo "Step 12: Escaping literal brace expressions..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

FILES=(
  "modules/ADL1.4/pages/cadl.adoc"
  "modules/ADL2/pages/cadl_complex_types.adoc"
  "modules/ADL2/pages/cadl_primitive_types.adoc"
  "modules/ADL2/pages/spec_attrib_redef.adoc"
  "modules/ADL2/pages/spec_object_redef.adoc"
  "modules/ADL2/pages/templates.adoc"
  "modules/AOM2/pages/constraint_model-class_definitions.adoc"
  "modules/AOM2/pages/validation.adoc"
  "modules/OPT2/pages/opt_raw.adoc"
  "modules/OPT2/pages/overview.adoc"
)

for f in "${FILES[@]}"; do
  [ -f "$f" ] || continue
  # Escape single digits/letters in braces: {0} {1} {2} {3} {m} {*} {n}
  # and ranges: {0..1} {0..n} {m..n} {0..*} etc.
  sed -i \
    -e 's/{\([0-9]\)}/\\{\1}/g' \
    -e 's/{\([0-9]\)\.\.\([0-9*n]\)}/\\{\1..\2}/g' \
    -e 's/{\([mn]\)\.\.\([0-9*n]\)}/\\{\1..\2}/g' \
    -e 's/{\([mn]\)}/\\{\1}/g' \
    -e 's/{\*}/\\{*}/g' \
    "$f"
  echo "  ✓ $f"
done

echo ""
echo "✓ Literal brace expressions escaped"
