#!/bin/bash
set -euo pipefail

# This script expects:
#   $1..$N   : module names

MODULES="$@"

# -------------------------------------------------------------------
# Copy actions
# -------------------------------------------------------------------

copy_master() {
  local module="$1"
  local src="docs/$module/master.adoc"
  local dst="modules/$module/pages/index.adoc"

  if [ -f "$src" ]; then
    echo "  • master.adoc → pages/index.adoc"
    cp "$src" "$dst"
    # Remove ALL include:: lines from index.adoc
    sed -i '/^include::/d' "$dst"
  fi
}

copy_master_numbered() {
  local module="$1"

  find "docs/$module" -name "master[0-9][0-9]-*.adoc" 2>/dev/null | while read -r src; do
    local base new

    base="$(basename "$src")"                          # e.g. master01-overview.adoc
    new="$(echo "$base" | sed 's/master[0-9][0-9]-//')"  # e.g. overview.adoc

    echo "  • $base → pages/$new"
    cp "$src" "modules/$module/pages/$new"
  done
}

copy_images() {
  local module="$1"

  if [ -d "docs/$module/images" ]; then
    echo "  • Copying images/"
    cp -r "docs/$module/images/"* "modules/$module/images/" 2>/dev/null || true
  fi
}

copy_diagrams() {
  local module="$1"

  if [ -d "docs/$module/diagrams" ]; then
    echo "  • Copying diagrams/ to images/"
    mkdir -p "modules/$module/images/diagrams"
    cp -r "docs/$module/diagrams/"* "modules/$module/images/diagrams/" 2>/dev/null || true
  fi
}


# -------------------------------------------------------------------
# Replace {diagrams_uri} with diagrams
# -------------------------------------------------------------------

replace_diagram_attr() {
  local module="$1"
  local pages_dir="modules/$module/pages"

  [ -d "$pages_dir" ] || return 0

  echo "  • Replacing {diagrams_uri} → diagrams in $pages_dir"

  for f in "$pages_dir"/*.adoc; do
    [ -f "$f" ] || continue
    sed -i "s|{diagrams_uri}|diagrams|g" "$f"
  done
}

# -------------------------------------------------------------------
# Rewrite UML class includes using {uml_export_dir}
# -------------------------------------------------------------------

replace_uml_class_includes() {
  local module="$1"
  local pages_dir="modules/$module/pages"

  [ -d "$pages_dir" ] || return 0

  echo "  • Rewriting UML class includes to ROOT UML partials in $pages_dir"

  for f in "$pages_dir"/*.adoc; do
    [ -f "$f" ] || continue

    # include::{uml_export_dir}/classes/X.adoc[]
    #   → include::ROOT:partial$uml/X.adoc[]
    sed -i 's|include::[{]uml_export_dir[}]/classes/\([^[]]*\)\[\]|include::ROOT:partial$uml/\1[]|g' "$f"
  done
}

# -------------------------------------------------------------------
# Module processor
# -------------------------------------------------------------------

process_module() {
  local module="$1"

  case "$module" in
    UML|uml)
      echo "→ Skipping UML module: $module"
      return
      ;;
  esac

  echo "→ Processing module: $module"

  # Ensure directories
  mkdir -p "modules/$module/pages" "modules/$module/images"

  # 1. Copy master + numbered masters
  copy_master "$module"
  copy_master_numbered "$module"

  # 2. Apply manifest vars and replace diagram attr
  replace_diagram_attr "$module"

  # 3. Rewrite UML class includes to ROOT partials
  replace_uml_class_includes "$module"

  # 4. Assets
  copy_images "$module"
  copy_diagrams "$module"

  echo "✓ Processed: $module"
}

# -------------------------------------------------------------------
# Main
# -------------------------------------------------------------------

for module in $MODULES; do
  process_module "$module"
done
