#!/bin/bash
set -euo pipefail

# This script expects:
#   $1       : DRY_RUN flag ("dry-run" or anything else)
#   $2..$N   : module names

DRY_RUN="$1"
shift
MODULES="$@"

# -------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------

is_dry_run() {
  [ "$DRY_RUN" = "dry-run" ]
}

run_or_echo() {
  if is_dry_run; then
    echo "[DRY-RUN] $*"
  else
    "$@"
  fi
}

# -------------------------------------------------------------------
# Copy actions
# -------------------------------------------------------------------

copy_master() {
  local module="$1"
  local src="docs/$module/master.adoc"
  local dst="modules/$module/pages/index.adoc"

  if [ -f "$src" ]; then
    echo "  • master.adoc → pages/index.adoc"
    if is_dry_run; then
      echo "    [DRY-RUN] Would copy $src to $dst and remove all include:: lines"
    else
      cp "$src" "$dst"
      # Remove ALL include:: lines from index.adoc
      sed -i '/^include::/d' "$dst"
    fi
  fi
}

copy_master_numbered() {
  local module="$1"

  if is_dry_run; then
    echo "  [DRY-RUN] Would move master##-*.adoc files to pages/"
    return
  fi

  find "docs/$module" -name "master[0-9][0-9]-*.adoc" 2>/dev/null | while read -r src; do
    local base new

    base="$(basename "$src")"                         # e.g. master01-overview.adoc
    new="$(echo "$base" | sed 's/master[0-9][0-9]-//')"  # e.g. overview.adoc

    echo "  • $base → pages/$new"
    cp "$src" "modules/$module/pages/$new"
  done
}

copy_images() {
  local module="$1"

  if [ -d "docs/$module/images" ]; then
    echo "  • Copying images/"
    run_or_echo cp -r "docs/$module/images/"* "modules/$module/images/" 2>/dev/null || true
  fi
}

copy_diagrams() {
  local module="$1"

  if [ -d "docs/$module/diagrams" ]; then
    echo "  • Copying diagrams/ to images/"
    run_or_echo mkdir -p "modules/$module/images/diagrams"
    run_or_echo cp -r "docs/$module/diagrams/"* "modules/$module/images/diagrams/" 2>/dev/null || true
  fi
}

# -------------------------------------------------------------------
# Apply manifest vars by replacing {var} with literal values
# -------------------------------------------------------------------


apply_manifest_vars() {
  local module="$1"
  local pages_dir="modules/$module/pages"
  local partials_dir="modules/$module/partials"

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

  # 1) copy manifest_vars into module partials
  if is_dry_run; then
    echo "    [DRY-RUN] Would create $partials_dir and copy $manifest_src → $partials_dir/manifest_vars.adoc"
  else
    mkdir -p "$partials_dir"
    cp "$manifest_src" "$partials_dir/manifest_vars.adoc"
  fi

  # 2) prepend include::partial$manifest_vars.adoc[] to each page if not already there
  for f in "$pages_dir"/*.adoc; do
    [ -f "$f" ] || continue

    # already contains the include? skip
    if grep -q 'include::partial\$manifest_vars.adoc\[\]' "$f"; then
      continue
    fi

    if is_dry_run; then
      echo "    [DRY-RUN] Would prepend include::partial\$manifest_vars.adoc[] to $f"
    else
      local tmp="${f}.tmp"
      {
        echo "include::partial\$manifest_vars.adoc[]"
        echo
        cat "$f"
      } > "$tmp"
      mv "$tmp" "$f"
    fi
  done
}


# -------------------------------------------------------------------
# Module processor
# -------------------------------------------------------------------
# -------------------------------------------------------------------
# Replace {diagram} with images/diagrams
# -------------------------------------------------------------------

replace_diagram_attr() {
  local module="$1"
  local pages_dir="modules/$module/pages"

  [ -d "$pages_dir" ] || return 0

  echo "  • Replacing {diagrams_uri}/ → images/diagrams in $pages_dir"

  for f in "$pages_dir"/*.adoc; do
    [ -f "$f" ] || continue
    if is_dry_run; then
      echo "    [DRY-RUN] Would replace {diagram} in $f"
    else
      sed -i "s|{diagrams_uri}|diagrams|g" "$f"
    fi
  done
}



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
  run_or_echo mkdir -p "modules/$module/pages" "modules/$module/images"

  # 1. Copy master + numbered masters
  copy_master "$module"
  copy_master_numbered "$module"

  # 2. Replace {spec_title}, {copyright_year}, etc from manifest_vars
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
