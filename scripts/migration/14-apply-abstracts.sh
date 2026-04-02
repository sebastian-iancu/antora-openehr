#!/bin/bash
set -euo pipefail

# Step 14: Apply abstracts and overview texts from scripts/resources/abstracts/
#
# Resource file format (scripts/resources/abstracts/{COMPONENT}.adoc):
#
#   // @overview
#   Paragraph injected into ROOT/pages/index.adoc between image and == Specifications.
#
#   // @spec:MODULE_ID
#   Abstract paragraph injected into modules/MODULE_ID/pages/index.adoc after the title.

COMPONENT_NAME="$1"
shift
MODULES="$@"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ABSTRACT_FILE="$SCRIPT_DIR/../resources/abstracts/${COMPONENT_NAME}.adoc"

echo "Step 14: Applying abstracts..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ! -f "$ABSTRACT_FILE" ]; then
  echo "  ⚠ No abstract file for $COMPONENT_NAME — skipping"
  echo ""
  exit 0
fi

# Extract a named section from the abstract file.
# Sections start with "// @NAME" and end at the next "// @" or EOF.
extract_section() {
  local section="$1"
  awk -v section="$section" '
    /^\/\/ @/ {
      current = substr($0, 5)
      in_section = (current == section)
      next
    }
    in_section { lines[++n] = $0 }
    END {
      while (n > 0 && lines[n] == "") n--
      start = 1
      while (start <= n && lines[start] == "") start++
      for (i = start; i <= n; i++) print lines[i]
    }
  ' "$ABSTRACT_FILE"
}

# Inject overview text into ROOT/pages/index.adoc:
# order becomes: table → overview → image (with caption) → == Specifications
apply_root_overview() {
  local overview
  overview="$(extract_section "overview")"
  [ -z "$overview" ] && return 0

  local index="modules/ROOT/pages/index.adoc"
  [ -f "$index" ] || return 0

  local tmp
  tmp=$(mktemp)
  awk -v text="$overview" '
    /^image::/ {
      imgline = $0
      next
    }
    /^== Specifications/ && !done {
      print text
      print ""
      if (imgline != "") {
        print ".Specification Component Overview"
        print imgline
        print ""
      }
      print
      done = 1
      next
    }
    { print }
  ' "$index" > "$tmp"
  mv "$tmp" "$index"
  echo "  • Overview → ROOT/pages/index.adoc"
}

# Inject abstract into a subspec index.adoc after the title line
apply_spec_abstract() {
  local module="$1"
  local abstract
  abstract="$(extract_section "spec:$module")"
  [ -z "$abstract" ] && return 0

  local index="modules/$module/pages/index.adoc"
  [ -f "$index" ] || return 0

  local tmp
  tmp=$(mktemp)
  awk -v text="$abstract" '
    /^= / && !done {
      print
      print ""
      print text
      done=1
      next
    }
    { print }
  ' "$index" > "$tmp"
  mv "$tmp" "$index"
  echo "  • Abstract → $module/pages/index.adoc"
}

apply_root_overview

for module in $MODULES; do
  apply_spec_abstract "$module"
done

echo ""
echo "✓ Abstracts applied"
