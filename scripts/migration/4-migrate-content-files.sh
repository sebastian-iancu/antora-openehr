#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_lib.sh"

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
  local master_file="docs/$module/master.adoc"
  [ -f "$master_file" ] || return 0

  mkdir -p "modules/$module/partials"

  declare -A root_page_for_group

  list_chapter_includes "$master_file" | while read -r target; do
    is_master_include "$target" || continue

    local src="docs/$module/$target"
    [ -f "$src" ] || continue

    local base new group root_page root_path
    base="$(basename "$target")"
    new="$(strip_master_prefix "$base")"
    group="$(chapter_group_key "$target")"

    # skip things handled as partials
    case "$new" in
      amendment_record.adoc|preface.adoc) continue ;;
    esac

    if [ -z "$group" ]; then
      echo "  • $base → pages/$new"
      cp "$src" "modules/$module/pages/$new"
      continue
    fi

    if [ -z "${root_page_for_group[$group]:-}" ]; then
      root_page_for_group[$group]="$new"
      echo "  • $base → pages/$new"
      cp "$src" "modules/$module/pages/$new"
    else
      root_page="${root_page_for_group[$group]}"
      root_path="modules/$module/pages/$root_page"

      echo "  • $base → partials/$new"
      cp "$src" "modules/$module/partials/$new"
      decrease_asciidoc_section_heading_one_level "modules/$module/partials/$new"

      if [ -f "$root_path" ]; then
        echo "" >> "$root_path"
        echo "include::partial\$$new[leveloffset=+1]" >> "$root_path"
      fi
    fi
  done
}

copy_included_non_master() {
  local module="$1"
  local master_file="docs/$module/master.adoc"

  [ -f "$master_file" ] || return 0

  list_chapter_includes "$master_file" | while read -r target; do
    # Skip master-prefixed files (handled by copy_master_numbered)
    is_master_include "$target" && continue

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

    # Append include at end of index.adoc
    if [ -f "$index_file" ]; then
      echo "  • Appending amendment_record to index.adoc"
      echo "" >> "$index_file"
      echo "include::partial\$amendment_record.adoc[]" >> "$index_file"
    fi
  fi
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
  local partials_dir="modules/$module/partials"

  [ -d "$pages_dir" ] || return 0

  echo "  • Replacing {diagrams_uri} / {images_uri} in $module pages and partials"

  for f in "$pages_dir"/*.adoc; do
    [ -f "$f" ] || continue
    sed -i "s|{diagrams_uri}|diagrams|g" "$f"
    sed -i "s|{images_uri}/||g" "$f"
  done

  if [ -d "$partials_dir" ]; then
    for f in "$partials_dir"/*.adoc; do
      [ -f "$f" ] || continue
      sed -i "s|{diagrams_uri}|diagrams|g" "$f"
      sed -i "s|{images_uri}/||g" "$f"
    done
  fi
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
