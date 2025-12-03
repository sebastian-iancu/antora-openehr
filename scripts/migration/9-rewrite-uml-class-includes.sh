#!/bin/bash
set -euo pipefail

MODULES="$@"

rewrite_uml_class_includes_for_module() {
  local module="$1"
  local pages_dir="modules/$module/pages"

  [ -d "$pages_dir" ] || return 0

  echo "→ Rewriting UML class includes to ROOT UML partials in $pages_dir"

  for f in "$pages_dir"/*.adoc; do
    [ -f "$f" ] || continue

    # include::{uml_export_dir}/classes/X.adoc[]
    #   → include::ROOT:partial$uml/X.adoc[]
    sed -i 's|{uml_export_dir}/classes/|ROOT:partial$uml/|g' "$f"
  done
}

echo "Step 9: Rewriting UML class includes..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for module in $MODULES; do
  case "$module" in
    UML|uml)
      echo "  Skipping UML module for UML include rewrite: $module"
      continue
      ;;
  esac
  rewrite_uml_class_includes_for_module "$module"
done

echo ""
