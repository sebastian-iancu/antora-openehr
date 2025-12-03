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
# Apply manifest vars
# -------------------------------------------------------------------

apply_manifest_vars() {
  local module="$1"
  local pages_dir="modules/$module/pages"
  local partials_dir="modules/$module/partials"
  local root_partials_dir="modules/ROOT/partials"
  local global_vars_src="../../resources/global_vars.adoc"

  # Pick per-module manifest_vars.adoc if present, else global
  local manifest_src=""
  if [ -f "docs/$module/manifest_vars.adoc" ]; then
    manifest_src="docs/$module/manifest_vars.adoc"
  elif [ -f "docs/manifest_vars.adoc" ]; then
    manifest_src="docs/manifest_vars.adoc"
  else
    # nothing to do
    return 0
  fi

  [ -d "$pages_dir" ] || return 0

  echo "  • Installing manifest_vars partial and include in $pages_dir/"

  # Ensure global_vars.adoc is in ROOT partials
  if [ -f "$global_vars_src" ]; then
    echo "    • Ensuring global_vars.adoc is installed in modules/ROOT/partials"
    mkdir -p "$root_partials_dir"
    cp "$global_vars_src" "$root_partials_dir/global_vars.adoc"
  fi

  # Create module partials and install manifest_vars.adoc (including global_vars)
  mkdir -p "$partials_dir"
  local manifest_dest="$partials_dir/manifest_vars.adoc"


  if grep -q 'include::ROOT:partial\$global_vars.adoc\[\]' "$manifest_src"; then
    # Source already includes the ROOT global include; just copy it
    cp "$manifest_src" "$manifest_dest"
  else
    # Prepend include of ROOT global_vars.adoc
    local tmp_manifest="${manifest_dest}.tmp"
    {
      echo "include::ROOT:partial\$global_vars.adoc[]"
      echo
      cat "$manifest_src"
    } > "$tmp_manifest"
    mv "$tmp_manifest" "$manifest_dest"
  fi

  # Prepend include::partial$manifest_vars.adoc[] to each page if not already there
  for f in "$pages_dir"/*.adoc; do
    [ -f "$f" ] || continue

    if grep -q 'include::partial\$manifest_vars.adoc\[\]' "$f"; then
      continue
    fi

    local tmp="${f}.tmp"
    {
      echo "include::partial\$manifest_vars.adoc[]"
      echo
      cat "$f"
    } > "$tmp"
    mv "$tmp" "$f"
  done
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
  apply_manifest_vars "$module"
  replace_diagram_attr "$module"

  # 3. Assets
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
