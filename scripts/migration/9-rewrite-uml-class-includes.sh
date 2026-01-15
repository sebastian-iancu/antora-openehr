#!/bin/bash
set -euo pipefail

COMPONENT_NAME="$1"
shift

MODULES="$@"

rewrite_uml_class_includes_for_module() {
  local module="$1"
  local pages_dir="modules/$module/pages"

  [ -d "$pages_dir" ] || return 0

  echo "→ Rewriting UML includes + diagrams in $pages_dir"

  for f in "$pages_dir"/*.adoc; do
    [ -f "$f" ] || continue

    #
    # CLASS DEFINITIONS
    # include::{uml_export_dir}/classes/X.adoc[]
    #     → partial::ROOT:classes/NAME.svg[]
    #
    prefix=""
    if [[ "$COMPONENT_NAME" == "AM" ]]; then
      case "$module" in
        AOM2|OPT2|ADL2) prefix="aom2." ;;
        *)              prefix="aom14." ;;
      esac
    fi
    sed -i "s|{uml_export_dir}/classes/{pkg}|ROOT:partial\$classes/${prefix}|g" "$f"

    #
    # UML DIAGRAMS
    # image::{uml_diagrams_uri}/NAME.svg[]
    #      → image::ROOT:uml/diagrams/NAME.svg[]
    #
    sed -i 's|image::{uml_diagrams_uri}/|image::ROOT:uml/|g' "$f"
  done
}

echo "Step 9: Rewriting UML class includes & diagram references..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for module in $MODULES; do
  rewrite_uml_class_includes_for_module "$module"
done

echo ""
