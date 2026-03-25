#!/bin/bash
set -euo pipefail

# Step 4c: Download external grammar files and rewrite remote include directives
#
# Problem: Several pages include ANTLR g4 grammar files via remote URLs:
#   include::{openehr_adl_antlr_include}/adl/adl14.g4[]
# Antora locks safe mode to 'safe' which blocks all URI includes.
#
# Solution:
#   1. Download the g4 files from adl-antlr into module partials
#   2. Rewrite include directives from remote URL pattern to local partial$

COMPONENT_NAME="$1"
shift
MODULES="$@"

ANTLR_BASE="https://raw.githubusercontent.com/openEHR/adl-antlr/master/src/main/antlr/adl"

# Files used by ADL1.4 syntax_spec
ADL14_FILES="adl14.g4 cadl14.g4 cadl14_primitives.g4 adl_keywords.g4 base_expressions.g4 base_lexer.g4"

# Files used by ADL2 syntax_spec
ADL2_FILES="adl2.g4 cadl2.g4 cadl2_primitives.g4 adl_keywords.g4 base_expressions.g4 base_lexer.g4"

echo "Step 4c: Fetching external grammar files..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

fetch_to_partials() {
  local module="$1"
  shift
  local files="$@"
  local partials_dir="modules/$module/partials"

  mkdir -p "$partials_dir"

  for file in $files; do
    local url="$ANTLR_BASE/$file"
    echo "  ↓ $file → $module/partials/"
    if curl -sf -o "$partials_dir/$file" "$url"; then
      : # success
    else
      echo "  ✗ Failed to download $url — skipping"
    fi
  done
}

rewrite_includes() {
  local module="$1"
  local pages_dir="modules/$module/pages"
  [ -d "$pages_dir" ] || return 0

  echo "  ↻ Rewriting remote includes in $module/pages/"
  for page in "$pages_dir"/*.adoc; do
    [ -f "$page" ] || continue
    # Rewrite: include::{openehr_adl_antlr_include}/adl/X.g4[] → include::partial$X.g4[]
    sed -i 's|include::{openehr_adl_antlr_include}/adl/\([^]]*\)\[\]|include::partial$\1[]|g' "$page"
  done
}

if [[ "$COMPONENT_NAME" != "AM" ]]; then
  echo "  (no external grammars for $COMPONENT_NAME, skipping)"
  echo ""
  exit 0
fi

for module in $MODULES; do
  case "$module" in
    ADL1.4)
      fetch_to_partials "$module" $ADL14_FILES
      rewrite_includes "$module"
      ;;
    ADL2|OPT2)
      fetch_to_partials "$module" $ADL2_FILES
      rewrite_includes "$module"
      ;;
  esac
done

echo ""
echo "✓ External grammar files fetched and includes rewritten"
echo ""
