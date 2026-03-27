#!/bin/bash
set -euo pipefail

# Step 4a: Fetch external grammar files and copy local ones to partials
#
# Handles two cases:
#   1. Remote: pages include ANTLR g4 files via URL (openehr_adl_antlr_include)
#      → download from adl-antlr into module partials, rewrite to partial$
#   2. Local: pages include grammar files (.g, .g4, .jj) via relative paths
#      → locate in docs/, copy to module partials, rewrite to partial$

COMPONENT_NAME="$1"
shift
MODULES="$@"

echo "Step 4a: Handling grammar file includes..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Rewrite remote adl-antlr includes to partial$ (files are provided by make update-grammars)
if [[ "$COMPONENT_NAME" == "AM" ]]; then
  for module in $MODULES; do
    case "$module" in
      ADL1.4|ADL2|OPT2)
        pages_dir="modules/$module/pages"
        [ -d "$pages_dir" ] || continue
        echo "  ↻ Rewriting adl-antlr remote includes in $module/pages/"
        for page in "$pages_dir"/*.adoc; do
          [ -f "$page" ] || continue
          sed -i 's|include::{openehr_adl_antlr_include}/adl/\([^]]*\)\[\]|include::partial$\1[]|g' "$page"
        done
        ;;
    esac
  done
fi

# Local grammars: find relative includes of .g/.g4/.jj files in any module,
# locate the file in docs/, copy to partials, rewrite the include
for module in $MODULES; do
  pages_dir="modules/$module/pages"
  [ -d "$pages_dir" ] || continue

  for page in "$pages_dir"/*.adoc; do
    [ -f "$page" ] || continue

    # Find all relative grammar includes (not starting with http or {)
    { grep -oP 'include::(?!http|\{)[^\[]+\.(g4?|jj)\[\]' "$page" 2>/dev/null || true; } | \
    sed 's/include:://;s/\[\]//' | while read -r rel_path; do
      filename=$(basename "$rel_path")
      partials_dir="modules/$module/partials"

      # Search for the file in docs/ (case-insensitive)
      src=$(find docs -iname "$filename" 2>/dev/null | head -1)
      if [ -z "$src" ]; then
        echo "  ✗ Could not find $filename in docs/ — skipping"
        continue
      fi

      # Preserve subdirectory structure from the relative include path
      subdir=$(dirname "$rel_path")
      if [ "$subdir" = "." ]; then
        dest_dir="$partials_dir"
      else
        dest_dir="$partials_dir/$subdir"
      fi

      mkdir -p "$dest_dir"
      # Copy with lowercase filename to match the include directive
      cp "$src" "$dest_dir/$(echo "$filename" | tr '[:upper:]' '[:lower:]')"
      echo "  ↳ $src → $module/partials/$rel_path"

      # Rewrite include directive to use partial$
      sed -i "s|include::${rel_path}\[\]|include::partial\$${rel_path}[]|g" "$page"
    done
  done
done

echo ""
echo "✓ Grammar files fetched/copied and includes rewritten"
echo ""
