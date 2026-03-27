#!/bin/bash
set -euo pipefail

COMPONENT_NAME="$1"
shift

MODULES="$@"

rewrite_uml_class_includes_for_module() {
  local module="$1"
  local pages_dir="modules/$module/pages"
  local partials_dir="modules/$module/partials"

  [ -d "$pages_dir" ] && echo "→ Rewriting UML includes + diagrams in $pages_dir"
  [ -d "$partials_dir" ] && echo "→ Rewriting UML includes + diagrams in $partials_dir"

  # Process both pages and partials
  for f in "$pages_dir"/*.adoc "$partials_dir"/*.adoc; do
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
    # and bare path variant: ../UML/SUBDIR/classes/X.adoc
    #
    perl -i -pe '
      s!include::(?:\{uml_export_dir\}|\.\./UML)/([^/]+)/classes/!
        my $sub = lc($1); $sub =~ s/\.//g;
        "include::ROOT:partial\$classes/$sub."!ge
    ' "$f"

    #
    # CLASS DEFINITIONS — bare flat path: ../UML/classes/X.adoc
    #
    sed -i "s|include::../UML/classes/|include::ROOT:partial\$classes/${prefix}|g" "$f"

    #
    # UML DIAGRAMS — all known diagram URI attributes → ROOT:uml/
    #
    sed -i 's|image::{uml_diagrams_uri}/|image::ROOT:uml/|g' "$f"
    sed -i 's|image::{uml_aom14_diagrams_uri}/|image::ROOT:uml/|g' "$f"
    sed -i 's|image::{uml_aom2_diagrams_uri}/|image::ROOT:uml/|g' "$f"

    #
    # UML DIAGRAMS — bare paths: UML/diagrams/X.svg and UML/AOM*/diagrams/X.svg → ROOT:uml/
    #
    sed -i 's|image::UML/diagrams/|image::ROOT:uml/|g' "$f"
    perl -i -pe 's|image::UML/([^/]+)/diagrams/|image::ROOT:uml/|g' "$f"

    #
    # LEGACY diagrams_uri — image::{diagrams_uri}/X.png → image::diagrams/X.png
    # Files are copied to modules/<module>/images/diagrams/ by migration step 4
    #
    sed -i 's|image::{diagrams_uri}/|image::diagrams/|g' "$f"

    #
    # FIX wrong image extension: image::ROOT:uml/X.png → image::ROOT:uml/X.svg
    # when X.svg exists in ROOT/images/uml/ but X.png does not
    #
    while IFS= read -r line; do
      if [[ "$line" =~ image::ROOT:uml/([^[]+)\.png ]]; then
        base="${BASH_REMATCH[1]}"
        if [ -f "modules/ROOT/images/uml/${base}.svg" ] && [ ! -f "modules/ROOT/images/uml/${base}.png" ]; then
          sed -i "s|image::ROOT:uml/${base}\.png|image::ROOT:uml/${base}.svg|g" "$f"
        fi
      fi
    done < "$f"
  done
}

echo "Step 9: Rewriting UML class includes & diagram references..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for module in $MODULES; do
  rewrite_uml_class_includes_for_module "$module"
done

echo ""
