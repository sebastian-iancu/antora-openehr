#!/bin/bash
set -euo pipefail

COMPONENT_NAME="$1"
shift

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
  elif [ -f "docs/$module/master.adoc" ]; then
    # Generate manifest_vars.adoc into modules/ — never touch docs/
    local generated="modules/$module/partials/manifest_vars.adoc"
    mkdir -p "modules/$module/partials"
    local spec_title copyright_year spec_status keywords description
    spec_title=$(grep -m 1 "^=" "docs/$module/master.adoc" | sed 's/^= //')
    copyright_year=$(grep -m 1 ":copyright_year:" "docs/$module/master.adoc" | cut -d' ' -f2-)
    spec_status=$(grep -m 1 ":spec_status:" "docs/$module/master.adoc" | cut -d' ' -f2-)
    keywords=$(grep -m 1 ":keywords:" "docs/$module/master.adoc" | cut -d' ' -f2-)
    description=$(grep -m 1 ":description:" "docs/$module/master.adoc" | cut -d' ' -f2-)
    {
      echo ":spec_title: $spec_title"
      echo ":copyright_year: $copyright_year"
      echo ":spec_status: $spec_status"
      echo ":keywords: $keywords"
      echo ":description: $description"
    } > "$generated"
    manifest_src="$generated"
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


install_pkg_var() {
  local module="$1"
  local module_vars="modules/$module/partials/module_vars.adoc"
  local master="docs/$module/master.adoc"

  [ -f "$module_vars" ] || return 0
  [ -f "$master" ] || return 0

  # Read :pkg: directly from master.adoc where it is authoritatively defined
  local pkg_value
  pkg_value=$(grep -m1 '^:pkg:' "$master" | sed 's/^:pkg: *//' || true)
  [ -z "$pkg_value" ] && return 0

  echo "  • Setting :pkg: ${pkg_value} in module_vars.adoc"
  echo ":pkg: ${pkg_value}" >> "$module_vars"

  # Handle multi-pkg modules: master.adoc may change :pkg: mid-document.
  # Parse include order and inject per-page :pkg: overrides for pages that
  # use a different value than the module default.
  inject_per_page_pkg_overrides "$module" "$master" "$pkg_value"
}

inject_per_page_pkg_overrides() {
  local module="$1"
  local master="$2"
  local default_pkg="$3"
  local pages_dir="modules/$module/pages"

  [ -d "$pages_dir" ] || return 0

  # Walk master.adoc tracking :pkg: changes and mapping page includes to their pkg value
  local current_pkg="$default_pkg"
  while IFS= read -r line; do
    # Detect :pkg: assignment
    if [[ "$line" =~ ^:pkg:[[:space:]]*(.+)$ ]]; then
      current_pkg="${BASH_REMATCH[1]}"
      continue
    fi
    # Detect include of a sub-page file
    if [[ "$line" =~ ^include::([^[:space:]\[]+)\.adoc ]]; then
      local src_file
      src_file=$(basename "${BASH_REMATCH[1]}.adoc")
      # Derive page name using same rename rule as step 4
      local page_name
      page_name=$(echo "$src_file" | sed -E 's/^master[0-9.]+-//; s/^masterApp[A-Z]-//')
      local page_path="$pages_dir/$page_name"

      [ -f "$page_path" ] || continue
      [ "$current_pkg" = "$default_pkg" ] && continue

      echo "  • Per-page :pkg: ${current_pkg} → ${page_name}"
      # Inject :pkg: override immediately after the module_vars include line
      local tmp="${page_path}.tmp"
      awk -v pkg=":pkg: $current_pkg" '
        /include::partial\$module_vars\.adoc\[\]/ { print; print ""; print pkg; next }
        { print }
      ' "$page_path" > "$tmp" && mv "$tmp" "$page_path"
    fi
  done < "$master"
}

# -------------------------------------------------------------------
# Front block (cover table + block diagram) — runs after module_vars exists
# -------------------------------------------------------------------

add_front_block() {
  local module="$1"
  local index_file="modules/$module/pages/index.adoc"

  [ -f "$index_file" ] || return 0

  # Only add if module_vars has spec_status (i.e. it's a real spec, not a stub)
  local module_vars="modules/$module/partials/module_vars.adoc"
  grep -q "^:spec_status:" "$module_vars" 2>/dev/null || return 0

  # Skip if already present
  grep -q "specmeta" "$index_file" 2>/dev/null && return 0

  echo "  • Adding front block to index.adoc"

  local tmp
  tmp=$(mktemp)
  awk '
    /^= / && !done {
      print
      print ""
      print "[.specmeta%autowidth,cols=\"1\",frame=all,grid=all]"
      print "|==="
      print "^h| *Status*: {spec_status}"
      print "|==="
      print ""
      print "image::ROOT:openehr_block_diagram.svg[openEHR components,60%,align=center]"
      done=1
      next
    }
    { print }
  ' "$index_file" > "$tmp"
  mv "$tmp" "$index_file"
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
  extract_amendment_vars "$module"
  include_module_vars_to_pages "$module"
  install_pkg_var "$module"
  add_front_block "$module"
}

extract_amendment_vars() {
  local module="$1"
  local module_vars="modules/$module/partials/module_vars.adoc"

  [ -f "$module_vars" ] || return 0

  # Find amendment record source
  local amend_file
  amend_file=$(find "docs/$module" -name "*amendment_record.adoc" 2>/dev/null | head -1)
  [ -n "$amend_file" ] || return 0

  local latest_issue latest_issue_date
  latest_issue=$(grep -oP '\[\[latest_issue\]\]\K[^|\n]+' "$amend_file" 2>/dev/null | head -1 | sed 's/[[:space:]]//g' || true)
  latest_issue_date=$(grep -oP '\[\[latest_issue_date\]\]\K[^|\n]+' "$amend_file" 2>/dev/null | head -1 | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//' || true)

  # Ensure file ends with a newline before appending
  printf '\n' >> "$module_vars"

  if [ -n "$latest_issue" ] && ! grep -q "^:latest_issue:" "$module_vars"; then
    echo ":latest_issue: $latest_issue" >> "$module_vars"
    echo "  • Extracted latest_issue: $latest_issue"
  elif [ -z "$latest_issue" ] && ! grep -q "^:latest_issue:" "$module_vars"; then
    echo ":latest_issue: -" >> "$module_vars"
  fi

  if [ -n "$latest_issue_date" ] && ! grep -q "^:latest_issue_date:" "$module_vars"; then
    echo ":latest_issue_date: $latest_issue_date" >> "$module_vars"
    echo "  • Extracted latest_issue_date: $latest_issue_date"
  fi
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
