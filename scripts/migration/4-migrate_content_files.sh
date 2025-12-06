#!/bin/bash
set -euo pipefail

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
    # Remove ALL include:: lines and the openehr logo image line
    sed -i '/^include::/d;/^image::{openehr_logo}/d' "$dst"
  fi
}

copy_master_numbered() {
  local module="$1"

  # Copy all masterNN-* and masterAppA-* files, stripping the prefix
  find "docs/$module" \( -name "master[0-9][0-9]-*.adoc" -o -name "masterAppA-*.adoc" \) 2>/dev/null \
    | while read -r src; do
        local base new

        base="$(basename "$src")"
        # Strip prefixes:
        #   masterNN-something.adoc   -> something.adoc
        #   masterAppA-something.adoc -> something.adoc
        new="$(echo "$base" | sed -E 's/^master[0-9][0-9]-//; s/^masterAppA-//')"

        echo "  • $base → pages/$new"
        cp "$src" "modules/$module/pages/$new"
      done
}

copy_included_non_master() {
  local module="$1"
  local master_file="docs/$module/master.adoc"

  [ -f "$master_file" ] || return 0

  awk 'found {print} /:sectnums|sectanchors:/{found=1}' "$master_file" \
    | grep '^include::' 2>/dev/null \
    | sed -E 's/^include::([^[]+)\[.*/\1/' \
    | while read -r target; do
        [ -z "$target" ] && continue

        # skip paths and attribute-based includes
        case "$target" in
          *"/"*|*"{"* ) continue ;;
        esac

        # skip things handled elsewhere (master files)
        case "$target" in
          manifest_vars.adoc) continue ;;
          master[0-9][0-9]-*.adoc) continue ;;
          masterAppA-*.adoc) continue ;;
          *-amendment_record.adoc|amendment_record.adoc) continue ;;
        esac

        local src="docs/$module/$target"
        local dst="modules/$module/pages/$target"

        if [ -f "$src" ]; then
          echo "  • $target → pages/$target"
          cp "$src" "$dst"
        fi
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
# Module processor
# -------------------------------------------------------------------

process_module() {
  local module="$1"

  echo "→ Processing module: $module"

  mkdir -p "modules/$module/pages" "modules/$module/images"

  copy_master "$module"
  copy_master_numbered "$module"
  copy_included_non_master "$module"

  replace_diagram_attr "$module"

  copy_images "$module"
  copy_diagrams "$module"

  echo "✓ Processed: $module"
}

# -------------------------------------------------------------------
# Main
# -------------------------------------------------------------------

echo "Step 4: Migrate content files..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for module in $MODULES; do
  process_module "$module"
done
