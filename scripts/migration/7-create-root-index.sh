#!/bin/bash
set -e

# Usage: step7-create-root-index.sh <COMPONENT_NAME> <module1> <module2> ...

COMPONENT_NAME="$1"
shift
MODULES="$@"

echo "Step 7: Creating ROOT index page..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

mkdir -p "modules/ROOT/pages"

cat > "modules/ROOT/pages/index.adoc" << EOF
= $COMPONENT_NAME Component

Welcome to the $COMPONENT_NAME component of the openEHR specifications.

== Modules

EOF

# Add links to each module
if [ -f "manifest.json" ]; then
  echo "  • Reading module order and titles from manifest.json"
  
  # Get component info from manifest
  MANIFEST_TITLE=$(jq -r '.title // empty' manifest.json)
  MANIFEST_DESC=$(jq -r '.description // empty' manifest.json)
  
  if [ ! -z "$MANIFEST_TITLE" ]; then
     # Rewrite index.adoc with manifest info
     cat > "modules/ROOT/pages/index.adoc" << EOF
= $MANIFEST_TITLE
EOF
     if [ ! -z "$MANIFEST_DESC" ]; then
       echo "" >> "modules/ROOT/pages/index.adoc"
       echo "$MANIFEST_DESC" >> "modules/ROOT/pages/index.adoc"
     fi
     echo "" >> "modules/ROOT/pages/index.adoc"
     echo "== Specifications" >> "modules/ROOT/pages/index.adoc"
     echo "" >> "modules/ROOT/pages/index.adoc"
  fi

  # Get modules from manifest in order
  MANIFEST_MODULES=$(jq -r '.specifications[] | select(.id != null) | .id' manifest.json)
  
  # Track which modules we've added
  ADDED_MODULES=""

  for mod_id in $MANIFEST_MODULES; do
    # Check if this module exists in our MODULES list
    if [[ " $MODULES " =~ " $mod_id " ]]; then
      MODULE_TITLE=$(jq -r ".specifications[] | select(.id == \"$mod_id\") | .title" manifest.json)
      echo "* xref:$mod_id:index.adoc[$MODULE_TITLE]" >> "modules/ROOT/pages/index.adoc"
      ADDED_MODULES="$ADDED_MODULES $mod_id"
    fi
  done

  # Add any modules that were not in manifest.json but are in MODULES
  for module in $MODULES; do
    if [[ ! " $ADDED_MODULES " =~ " $module " ]]; then
      MODULE_TITLE=$(echo "$module" | sed 's/_/ /g' | sed 's/\b\(.\)/\u\1/g')
      echo "* xref:$module:index.adoc[$MODULE_TITLE]" >> "modules/ROOT/pages/index.adoc"
    fi
  done
else
  for module in $MODULES; do
    MODULE_TITLE=$(echo "$module" | sed 's/_/ /g' | sed 's/\b\(.\)/\u\1/g')
    echo "* xref:$module:index.adoc[$MODULE_TITLE]" >> "modules/ROOT/pages/index.adoc"
  done
fi

echo "✓ Created ROOT index page"
echo ""
