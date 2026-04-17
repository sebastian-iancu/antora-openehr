#!/bin/bash
set -euo pipefail

# Step 12: Escape literal curly-brace expressions that Asciidoctor
# misparses as attribute references in ADL/grammar prose.
# Targets patterns like {0}, {1}, {0..1}, {m..n}, {*} in module pages
# and module partials (but not generated bmm-publisher class partials).
#
# Only runs for AM and LANG components; a no-op for all others.

COMPONENT_NAME="$1"
shift
MODULES="$@"

case "$COMPONENT_NAME" in
  AM|LANG) ;;
  *) exit 0 ;;
esac

echo "Step 12: Escaping literal brace expressions..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

COUNT=0
for module in $MODULES; do
  pages_dir="modules/$module/pages"
  partials_dir="modules/$module/partials"

  for f in "$pages_dir"/*.adoc "$partials_dir"/*.adoc; do
    [ -f "$f" ] || continue
    case "$f" in
      */ROOT/partials/classes/*) continue ;;
    esac

    # Only process files that actually contain unescaped brace patterns
    if grep -qE '\{[0-9*mn](\.\.[0-9*n])?\}' "$f" 2>/dev/null; then
      sed -i \
        -e 's/{\([0-9]\)}/\\{\1}/g' \
        -e 's/{\([0-9]\)\.\.\([0-9*n]\)}/\\{\1..\2}/g' \
        -e 's/{\([mn]\)\.\.\([0-9*n]\)}/\\{\1..\2}/g' \
        -e 's/{\([mn]\)}/\\{\1}/g' \
        -e 's/{\*}/\\{*}/g' \
        "$f"
      echo "  ✓ $f"
      COUNT=$((COUNT + 1))
    fi
  done
done

echo ""
if [ "$COUNT" -gt 0 ]; then
  echo "✓ Escaped literal brace expressions in $COUNT file(s)"
else
  echo "✓ No files needed brace escaping"
fi
