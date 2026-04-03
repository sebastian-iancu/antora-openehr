#!/bin/bash
set -euo pipefail

# Usage: step5-create-antora-yml.sh <COMPONENT_NAME> <module1> <module2> ...

COMPONENT_NAME="$1"
shift
MODULES="$@"

echo "Step 5: Creating antora.yml component descriptor..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ANTORA_YML="antora.yml"

# Define component name to title mapping
declare -A COMPONENT_MAP
COMPONENT_MAP["RM"]="Reference Model"
COMPONENT_MAP["BASE"]="Base Model"
COMPONENT_MAP["AM"]="Archetype Model"
# Set component title based on mapping
COMPONENT_TITLE="${COMPONENT_MAP[$COMPONENT_NAME]:-$COMPONENT_NAME}"

# If manifest.json exists, use the title from there
if [ -f "manifest.json" ]; then
  MANIFEST_TITLE=$(jq -r '.title // empty' manifest.json)
  if [ ! -z "$MANIFEST_TITLE" ]; then
    COMPONENT_TITLE="$MANIFEST_TITLE"
  fi
fi

cat > "$ANTORA_YML" << EOF
name: $COMPONENT_NAME
title: $COMPONENT_TITLE
start_page: ROOT:index.adoc
nav:
  - modules/ROOT/nav.adoc
EOF

# Add navigation entries for each module
if [ -f "manifest.json" ]; then
  echo "  • Ordering navigation from manifest.json"
  # Get modules from manifest in order
  MANIFEST_MODULES=$(jq -r '.specifications[] | select(.id != null) | .id' manifest.json)

  # Track which modules we've added
  ADDED_MODULES=""

  for mod_id in $MANIFEST_MODULES; do
    # Check if this module exists in our MODULES list
    if [[ " $MODULES " =~ " $mod_id " ]]; then
      echo "  - modules/$mod_id/nav.adoc" >> "$ANTORA_YML"
      ADDED_MODULES="$ADDED_MODULES $mod_id"
    fi
  done

  # Add any modules that were not in manifest.json but are in MODULES
  for module in $MODULES; do
    if [[ ! " $ADDED_MODULES " =~ " $module " ]]; then
      echo "  - modules/$module/nav.adoc" >> "$ANTORA_YML"
    fi
  done
else
  for module in $MODULES; do
    echo "  - modules/$module/nav.adoc" >> "$ANTORA_YML"
  done
fi

echo "✓ Created antora.yml"
echo ""
