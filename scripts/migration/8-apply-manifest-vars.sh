#!/bin/bash
set -euo pipefail

# Usage: 8-apply-manifest-vars.sh <module1> <module2> ...
MODULES="$@"

apply_manifest_vars() {
  local module="$1"
  local pages_dir="modules/$module/pages"
  local partials_dir="modules/$module/partials"
  local root_partials_dir="modules/ROOT/partials"
  # adjust if needed; from repo root this would usually be "resources/global_vars.adoc"
  local global_vars_src="resources/global_vars.adoc"

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

echo "Step 8: Applying manifest vars..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for module in $MODULES; do
  case "$module" in
    UML|uml)
      echo "→ Skipping UML module for manifest vars: $module"
      continue
      ;;
  esac
  apply_manifest_vars "$module"
done

echo ""
