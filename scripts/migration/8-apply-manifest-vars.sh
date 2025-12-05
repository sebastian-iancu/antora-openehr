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
    manifest_src=""
  fi

  echo "$manifest_src"
}

ensure_root_global_vars() {
  local root_partials_dir="modules/ROOT/partials"
  local global_vars_src="../../resources/global_vars.adoc"

  if [ ! -f "$global_vars_src" ]; then
    return 0
  fi

  echo "    • Ensuring global_vars.adoc is installed in modules/ROOT/partials"
  mkdir -p "$root_partials_dir"
  cp "$global_vars_src" "$root_partials_dir/global_vars.adoc"
}

install_manifest_partial() {
  local module="$1"
  local manifest_src="$2"
  local partials_dir="modules/$module/partials"
  local manifest_dest="$partials_dir/manifest_vars.adoc"

  mkdir -p "$partials_dir"

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
}

prepend_manifest_include_to_pages() {
  local module="$1"
  local pages_dir="modules/$module/pages"

  [ -d "$pages_dir" ] || return 0

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
# Orchestrator for a single module
# -------------------------------------------------------------------

apply_manifest_vars() {
  local module="$1"
  local pages_dir="modules/$module/pages"

  [ -d "$pages_dir" ] || return 0

  local manifest_src
  manifest_src="$(get_manifest_src_for_module "$module")"

  if [ -z "$manifest_src" ]; then
    # nothing to do for this module
    return 0
  fi

  echo "  • Installing manifest_vars partial and include in $pages_dir/"

  ensure_root_global_vars
  install_manifest_partial "$module" "$manifest_src"
  prepend_manifest_include_to_pages "$module"
}

# -------------------------------------------------------------------
# Main
# -------------------------------------------------------------------

echo "Step 8: Applying manifest vars..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for module in $MODULES; do
  apply_manifest_vars "$module"
done

echo ""
