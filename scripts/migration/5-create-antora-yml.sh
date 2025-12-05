#!/bin/bash
set -e

# Usage: step5-create-antora-yml.sh <COMPONENT_NAME> <module1> <module2> ...

COMPONENT_NAME="$1"
shift
MODULES="$@"

echo "Step 5: Creating antora.yml component descriptor..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ANTORA_YML="antora.yml"

cat > "$ANTORA_YML" << EOF
name: $COMPONENT_NAME
title: $COMPONENT_NAME Component
version: ~
display_version: Development
start_page: ROOT:index.adoc
nav:
  - modules/ROOT/nav.adoc
EOF

# Add navigation entries for each module
for module in $MODULES; do
  echo "  - modules/$module/nav.adoc" >> "$ANTORA_YML"
done

echo "✓ Created antora.yml"
echo ""
