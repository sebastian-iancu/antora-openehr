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
    # CLASS DEFINITIONS — flat layout: {uml_export_dir}/classes/X.adoc
    #
    prefix=""
    if [[ "$COMPONENT_NAME" == "AM" ]]; then
      case "$module" in
        AOM2|OPT2|ADL2) prefix="aom2." ;;
        *)              prefix="aom14." ;;
      esac
    fi
    sed -i "s|include::{uml_export_dir}/classes/|include::ROOT:partial\$classes/${prefix}|g" "$f"

    #
    # CLASS DEFINITIONS — nested layout: {uml_export_dir}/SUBDIR/classes/X.adoc
    # Strip the subdir and apply prefix derived from it.
    # Handles any {uml_export_dir}/<word><dot><word>/classes/ or {uml_export_dir}/<word>/classes/
    #
    perl -i -pe '
      s|include::\{uml_export_dir\}/([^/]+)/classes/|
        my $sub = lc($1); $sub =~ s/\.//g;
        "include::ROOT:partial\$classes/$sub."|ge
    ' "$f"

    #
    # UML DIAGRAMS — all known diagram URI attributes → ROOT:uml/
    #
    sed -i 's|image::{uml_diagrams_uri}/|image::ROOT:uml/|g' "$f"
    sed -i 's|image::{uml_aom14_diagrams_uri}/|image::ROOT:uml/|g' "$f"
    sed -i 's|image::{uml_aom2_diagrams_uri}/|image::ROOT:uml/|g' "$f"
  done
}

echo "Step 9: Rewriting UML class includes & diagram references..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for module in $MODULES; do
  rewrite_uml_class_includes_for_module "$module"
done

echo ""
