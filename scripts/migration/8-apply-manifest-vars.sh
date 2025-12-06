#!/bin/bash
set -euo pipefail

# Usage: 8-apply-manifest-vars.sh <module1> <module2> ...
MODULES="$@"

# -------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------

get_manifest_src_for_module() {
  local module="$1"
  local manifest_src=""

  if [ -f "docs/$module/manifest_vars.adoc" ]; then
    manifest_src="docs/$module/manifest_vars.adoc"
  elif [ -f "docs/manifest_vars.adoc" ]; then
    manifest_src="docs/manifest_vars.adoc"
  else
    # Create manifest_vars.adoc if it doesn't exist
    mkdir -p "docs/$module"
    manifest_src="docs/$module/manifest_vars.adoc"

    # Extract variables from master.adoc
    if [ -f "docs/$module/master.adoc" ]; then
      # Get title from first heading
      spec_title=$(grep -m 1 "^=" "docs/$module/master.adoc" | sed 's/^= //')
      # Extract other variables
      copyright_year=$(grep -m 1 ":copyright_year:" "docs/$module/master.adoc" | cut -d' ' -f2-)
      spec_status=$(grep -m 1 ":spec_status:" "docs/$module/master.adoc" | cut -d' ' -f2-)
      keywords=$(grep -m 1 ":keywords:" "docs/$module/master.adoc" | cut -d' ' -f2-)
      description=$(grep -m 1 ":description:" "docs/$module/master.adoc" | cut -d' ' -f2-)

      # Write manifest file
      {
        echo ":spec_title: $spec_title"
        echo ":copyright_year: $copyright_year"
        echo ":spec_status: $spec_status"
        echo ":keywords: $keywords"
        echo ":description: $description"
      } > "$manifest_src"
    else
      manifest_src=""
    fi
  fi

  echo "$manifest_src"
}

install_component_vars() {
  local root_partials_dir="modules/ROOT/partials"
  local component_vars_src="../../resources/component_vars.adoc"

  if [ ! -f "$component_vars_src" ]; then
    return 0
  fi

  echo "    • Ensuring component_vars.adoc is installed in modules/ROOT/partials"
  mkdir -p "$root_partials_dir"
  cp "$component_vars_src" "$root_partials_dir/component_vars.adoc"
}

install_module_vars() {
  local module="$1"
  local file_src="$2"
  local partials_dir="modules/$module/partials"
  local file_dest="$partials_dir/module_vars.adoc"

  mkdir -p "$partials_dir"

  if grep -q 'include::ROOT:partial\$component_vars.adoc\[\]' "$file_src"; then
    # Source already includes the ROOT global include; just copy it
    cp "$file_src" "$file_dest"
  else
    # Prepend include of ROOT component_vars.adoc
    local tmp_file="${file_dest}.tmp"
    {
      echo "include::ROOT:partial\$component_vars.adoc[]"
      echo
      cat "$file_src"
    } > "$tmp_file"
    mv "$tmp_file" "$file_dest"
  fi
}

include_module_vars_to_pages() {
  local module="$1"
  local pages_dir="modules/$module/pages"

  [ -d "$pages_dir" ] || return 0

  # Prepend include::partial$module_vars.adoc[] to each page if not already there
  for f in "$pages_dir"/*.adoc; do
    [ -f "$f" ] || continue

    if grep -q 'include::partial\$module_vars.adoc\[\]' "$f"; then
      continue
    fi

    local tmp="${f}.tmp"
    {
      echo "include::partial\$module_vars.adoc[]"
      echo
      cat "$f"
    } > "$tmp"
    mv "$tmp" "$f"
  done
}

# -------------------------------------------------------------------
# Orchestrator for a single module
# -------------------------------------------------------------------

apply_manifest_vars() {
  local module="$1"
  local pages_dir="modules/$module/pages"

  [ -d "$pages_dir" ] || return 0

  local manifest_src
  manifest_src="$(get_manifest_src_for_module "$module")"
  echo "  • $manifest_src in $pages_dir/"

  if [ -z "$manifest_src" ]; then
    # nothing to do for this module
    return 0
  fi

  echo "  • Installing module_vars partial and include in $pages_dir/"

  install_component_vars
  install_module_vars "$module" "$manifest_src"
  include_module_vars_to_pages "$module"
}

# -------------------------------------------------------------------
# Main
# -------------------------------------------------------------------

echo "Step 8: Applying manifest vars ..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for module in $MODULES; do
  apply_manifest_vars "$module"
done

echo ""
