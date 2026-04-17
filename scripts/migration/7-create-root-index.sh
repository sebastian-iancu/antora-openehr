#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_lib.sh"

# Usage: 7-create-root-index.sh <COMPONENT_NAME> <module1> <module2> ...

COMPONENT_NAME="$1"
shift
MODULES="$@"

echo "Step 7: Creating ROOT index page..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

mkdir -p "modules/ROOT/pages"
mkdir -p "modules/ROOT/images"

# Move block diagram if available (git mv when tracked)
if [ -f "docs/openehr_block_diagram.svg" ]; then
  git_move_preserve_history "docs/openehr_block_diagram.svg" "modules/ROOT/images/openehr_block_diagram.svg"
  echo "  • Moved openehr_block_diagram.svg to ROOT/images/"
fi

# Read manifest
if [ ! -f "manifest.json" ]; then
  echo "  ⚠ No manifest.json found, creating minimal index"
  cat > "modules/ROOT/pages/index.adoc" << EOF
= $COMPONENT_NAME Component

EOF
  for module in $MODULES; do
    MODULE_TITLE=$(echo "$module" | sed 's/_/ /g' | sed 's/\b\(.\)/\u\1/g')
    echo "* xref:$module:index.adoc[$MODULE_TITLE]" >> "modules/ROOT/pages/index.adoc"
  done
  echo "✓ Created ROOT index page"
  echo ""
  exit 0
fi

MANIFEST_TITLE=$(jq -r '.title // empty' manifest.json)
COMPONENT_STATUS=$(jq -r '.status // "STABLE"' manifest.json | tr '[:lower:]' '[:upper:]')
COMPONENT_STATUS_CLASS=$(echo "$COMPONENT_STATUS" | tr '[:upper:]' '[:lower:]')
COMPONENT_STATUS_BADGE="[.spec-status.spec-status-${COMPONENT_STATUS_CLASS}]#${COMPONENT_STATUS}#"

VERSION_DISPLAY="{page-component-version}"

# Build index.adoc
{
  echo "= $MANIFEST_TITLE"
  echo ""
  echo "[.spec-meta-line]"
  echo "Status: $COMPONENT_STATUS_BADGE  Release: [.release-tag]#${VERSION_DISPLAY}#"
  echo ""

  if [ -f "modules/ROOT/images/openehr_block_diagram.svg" ]; then
    echo "image::openehr_block_diagram.svg[openEHR $MANIFEST_TITLE block diagram,role=block-diagram]"
    echo ""
  fi

  echo "== Specifications"
  echo ""

  # Specs in manifest order, filtered to modules that exist
  MANIFEST_MODULES=$(jq -r '.specifications[] | select(.id != null) | .id' manifest.json)
  ADDED_MODULES=""

  for mod_id in $MANIFEST_MODULES; do
    if [[ " $MODULES " =~ " $mod_id " ]]; then
      MODULE_TITLE=$(jq -r ".specifications[] | select(.id == \"$mod_id\") | .title" manifest.json)
      SPEC_STATUS=$(jq -r ".specifications[] | select(.id == \"$mod_id\") | .spec_status" manifest.json)
      MICRO=$(jq -r ".specifications[] | select(.id == \"$mod_id\") | .micro_summary // empty" manifest.json)
      SPEC_STATUS_CLASS=$(echo "$SPEC_STATUS" | tr '[:upper:]' '[:lower:]')
      STATUS_BADGE=" [.spec-status.spec-status-${SPEC_STATUS_CLASS}]#${SPEC_STATUS}#"
      if [ -n "$MICRO" ]; then
        echo "* xref:$mod_id:index.adoc[$MODULE_TITLE]${STATUS_BADGE} — $MICRO"
      else
        echo "* xref:$mod_id:index.adoc[$MODULE_TITLE]${STATUS_BADGE}"
      fi
      ADDED_MODULES="$ADDED_MODULES $mod_id"
    fi
  done

  # Modules not in manifest
  for module in $MODULES; do
    if [[ ! " $ADDED_MODULES " =~ " $module " ]]; then
      MODULE_TITLE=$(echo "$module" | sed 's/_/ /g' | sed 's/\b\(.\)/\u\1/g')
      echo "* xref:$module:index.adoc[$MODULE_TITLE]"
    fi
  done

} > "modules/ROOT/pages/index.adoc"

echo "✓ Created ROOT index page"
echo ""
