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
    # Remove :sectnums:
    sed -i '/^:sectnums:/d' "$dst"
  fi
}

copy_master_numbered() {
  local module="$1"

  # Copy all masterNN-* and masterAppA-* files, stripping the prefix
  find "docs/$module" \( -name "master[0-9][0-9]-*.adoc" -o -name "master[0-9][0-9].[0-9]-*.adoc" -o -name "master[0-9][0-9].[0-9][0-9]-*.adoc" -o -name "masterApp[A-Z]-*.adoc" \) 2>/dev/null \
    | while read -r src; do
        local base new

        base="$(basename "$src")"
        # Strip prefixes:
        #   masterNN-something.adoc   -> something.adoc
        #   masterNN.NN-something.adoc   -> something.adoc
        #   masterAppA-something.adoc -> something.adoc
        new="$(echo "$base" | sed -E 's/^master[0-9.]+-//; s/^masterApp[A-Z]-//')"

        # skip things handled as partials
        case "$new" in
          amendment_record.adoc|preface.adoc) continue ;;
        esac

        echo "  • $base → pages/$new"
        cp "$src" "modules/$module/pages/$new"
      done
}

copy_included_non_master() {
  local module="$1"
  local master_file="docs/$module/master.adoc"

  [ -f "$master_file" ] || return 0
  # find all 'include::' lines after ':sectnums:' or ':sectanchors:' or '-- CHAPTERS --'
  awk 'found {print} /:sectnums:|:sectanchors:|-- CHAPTERS --/{found=1}' "$master_file" \
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
          master[0-9][0-9].[0-9]-*.adoc) continue ;;
          master[0-9][0-9].[0-9][0-9]-*.adoc) continue ;;
          masterApp[A-Z]-*.adoc) continue ;;
          *-amendment_record.adoc|amendment_record.adoc) continue ;;
          *-preface.adoc|preface.adoc) continue ;;
        esac

        local src="docs/$module/$target"
        local dst="modules/$module/pages/$target"

        if [ -f "$src" ]; then
          echo "  • $target → pages/$target"
          cp "$src" "$dst"
        fi
      done
}

migrate_preface() {
  local module="$1"
  local master_file="docs/$module/master.adoc"
  local partials_dir="modules/$module/partials"
  local index_file="modules/$module/pages/index.adoc"

  [ -f "$master_file" ] || return 0
  mkdir -p "$partials_dir"

  # Find preface in master.adoc
  local preface_file=$(grep -E 'include::.*preface\.adoc' "$master_file" | sed -E 's/^include::([^[]+)\[.*/\1/' | head -n 1)

  if [ -z "$preface_file" ]; then
     # Try standard names if not found in master
     if [ -f "docs/$module/preface.adoc" ]; then
        preface_file="preface.adoc"
     else
        preface_file=$(find "docs/$module" -name "*preface.adoc" | head -n 1 | xargs basename 2>/dev/null || true)
     fi
  fi

  if [ ! -z "$preface_file" ] && [ -f "docs/$module/$preface_file" ]; then
    echo "  • $preface_file → partials/preface.adoc"
    
    # Change heading to level 2
    sed -E 's/^= (Preface|Purpose)/== \1/' "docs/$module/$preface_file" > "$partials_dir/preface.adoc"

    # Insert include in index.adoc after :sectnums:
    if [ -f "$index_file" ]; then
      # We insert it after CHAPTERS comment block
      echo "  • Including preface in index.adoc"
      if grep -q "\-\- CHAPTERS \-\-" "$index_file"; then
         sed -i '/-- CHAPTERS --/a \\ninclude::partial$preface.adoc[]' "$index_file"
      else
         echo "include::partial$preface.adoc[]" >> "$index_file"
      fi
    fi
  fi
}

migrate_amendment_record() {
  local module="$1"
  local master_file="docs/$module/master.adoc"
  local partials_dir="modules/$module/partials"
  local index_file="modules/$module/pages/index.adoc"

  [ -f "$master_file" ] || return 0
  mkdir -p "$partials_dir"

  # Find amendment record in master.adoc
  local amendment_file=$(grep -E 'include::.*amendment_record\.adoc' "$master_file" | sed -E 's/^include::([^[]+)\[.*/\1/' | head -n 1)

  if [ -z "$amendment_file" ]; then
     # Try standard name if not found in master
     if [ -f "docs/$module/amendment_record.adoc" ]; then
        amendment_file="amendment_record.adoc"
     fi
  fi

  if [ ! -z "$amendment_file" ] && [ -f "docs/$module/$amendment_file" ]; then
    echo "  • $amendment_file → partials/amendment_record.adoc"
    
    # Copy and change heading to level 2
    sed 's/^= Amendment Record/\n== Amendment Record/' "docs/$module/$amendment_file" > "$partials_dir/amendment_record.adoc"

    # Insert include in index.adoc after :sectnums:
    if [ -f "$index_file" ]; then
      echo "  • Including amendment_record in index.adoc"
      # Insert amendment record after preface if preface exists, or after CHAPTERS.
      if grep -q "include::partial\$preface.adoc\[\]" "$index_file"; then
         sed -i '/include::partial\$preface.adoc\[\]/a include::partial$amendment_record.adoc[]' "$index_file"
      else
         # Try to find CHAPTERS block, else append at end (though copy_master should have it)
         if grep -q "\-\- CHAPTERS \-\-" "$index_file"; then
            sed -i '/-- CHAPTERS --/a \\ninclude::partial$amendment_record.adoc[]' "$index_file"
         else
            echo "include::partial$amendment_record.adoc[]" >> "$index_file"
         fi
      fi
    fi
  fi
}

add_child_nav_to_index() {
  local module="$1"
  local index_file="modules/$module/pages/index.adoc"
  local master_file="docs/$module/master.adoc"

  [ -f "$index_file" ] || return 0
  [ -f "$master_file" ] || return 0

  echo "  • Adding child navigation to index.adoc"

  # Create a temporary file for the navigation section
  local nav_tmp=$(mktemp)
  echo "" > "$nav_tmp"
  echo "== Sections" >> "$nav_tmp"
  echo "" >> "$nav_tmp"

  # Extract includes from master.adoc (same logic as nav generation)
  awk 'found {print} /:sectnums:|:sectanchors:|-- CHAPTERS --/{found=1}' "$master_file" \
    | grep '^include::' 2>/dev/null \
    | sed -E 's/^include::([^[]+)\[.*/\1/' \
    | while read -r target; do
        [ -z "$target" ] && continue
        case "$target" in
          *"/"*|*"{"* ) continue ;;
          manifest_vars.adoc) continue ;;
          *-amendment_record.adoc|amendment_record.adoc) continue ;;
          *-preface.adoc|preface.adoc) continue ;;
        esac

        local base="${target%.adoc}"
        base="$(echo "$base" | sed -E 's/^master[0-9.]+-//; s/^masterApp[A-Z]-//')"
        
        # We need the title of the page. 
        # Since this script runs after master files are copied, we can try to get it from the page
        local page_file="modules/$module/pages/${base}.adoc"
        local title=""
        if [ -f "$page_file" ]; then
           title=$(awk '/^[[:space:]]*= / { sub(/^[[:space:]]*= /,""); print; exit }' "$page_file")
        fi
        [ -z "$title" ] && title=$(echo "$base" | sed 's/_/ /g' | sed 's/\b\(.\)/\u\1/g')

        echo "* xref:${base}.adoc[${title}]" >> "$nav_tmp"
      done
  echo " " >> "$nav_tmp"
  echo " " >> "$nav_tmp"

  # Append navigation to index.adoc before References or at the end
  # First, remove existing References and bibliography if they exist in index.adoc
  if [ -f "$index_file" ]; then
    # Use a temporary file to safely remove sections
    local tmp_idx=$(mktemp)
    # Remove lines from == References to the end of file, and also any bibliography::[]
    # This is a bit aggressive, but we want to clean it up.
    # Actually, simpler: just delete any line starting with == References or bibliography::[]
    sed '/^== References/d' "$index_file" | sed '/^bibliography::\[\]/d' > "$tmp_idx"
    mv "$tmp_idx" "$index_file"
  fi

  cat "$nav_tmp" >> "$index_file"
  rm "$nav_tmp"
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
# Replace {diagrams_uri} with diagrams and also removing {images_uri}/
# -------------------------------------------------------------------

replace_diagram_and_images_uri_attr() {
  local module="$1"
  local pages_dir="modules/$module/pages"

  [ -d "$pages_dir" ] || return 0

  echo "  • Replacing {diagrams_uri} → diagrams in $pages_dir"

  for f in "$pages_dir"/*.adoc; do
    [ -f "$f" ] || continue
    sed -i "s|{diagrams_uri}|diagrams|g" "$f"
    sed -i "s|{images_uri}/||g" "$f"
  done
}

function add_bibliography() {
  local module="$1"
  local pages_dir="modules/$module/pages"

  [ -d "$pages_dir" ] || return 0

  for f in "$pages_dir"/*.adoc; do
    [ -f "$f" ] || continue
    if grep -q 'cite:\[[^]]\+\]' "$f"; then
      # Check if bibliography already exists
      if ! grep -q '^bibliography::\[\]' "$f"; then
        echo "  • Adding bibliography to $f"
        # Append the references section
        echo "" >> "$f"
        echo "== References" >> "$f"
        echo "bibliography::[]" >> "$f"
      fi
    fi
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
  migrate_preface "$module"
  migrate_amendment_record "$module"
  add_child_nav_to_index "$module"

  replace_diagram_and_images_uri_attr "$module"
  add_bibliography "$module"

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
