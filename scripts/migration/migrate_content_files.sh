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

  # Pick per-module manifest_vars.adoc if present, else global
  local manifest=""
  if [ -f "docs/$module/manifest_vars.adoc" ]; then
    manifest="docs/$module/manifest_vars.adoc"
  elif [ -f "docs/manifest_vars.adoc" ]; then
    manifest="docs/manifest_vars.adoc"
  else
    return 0
  fi

  [ -d "$pages_dir" ] || return 0

  echo "  • Applying manifest_vars substitutions in $pages_dir/ using $manifest"

  shopt -s nullglob

  # Each line is like:
  # :spec_title: Architecture Overview
  while IFS= read -r line; do
    # Only lines that look like :name: value
    [[ "$line" =~ ^:([^:]+):[[:space:]]*(.*)$ ]] || continue

    local name="${BASH_REMATCH[1]}"   # spec_title
    local value="${BASH_REMATCH[2]}"  # Architecture Overview

    # Escape chars that sed might choke on
    local safe_value="$value"
    safe_value="${safe_value//&/\\&}"
    safe_value="${safe_value//|/\\|}"

    for f in "$pages_dir"/*.adoc; do
      [ -f "$f" ] || continue
      if is_dry_run; then
        echo "    [DRY-RUN] Would replace {$name} → $value in $f"
      else
        # Replace exact {spec_title}, {copyright_year}, etc.
        sed -i "s|{$name}|$safe_value|g" "$f"
      fi
    done
  done < "$manifest"

  shopt -u nullglob
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
  run_or_echo mkdir -p "modules/$module/pages" "modules/$module/images"

  # 1. Copy master + numbered masters
  copy_master "$module"
  copy_master_numbered "$module"

  # 2. Replace {spec_title}, {copyright_year}, etc from manifest_vars
  apply_manifest_vars "$module"

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
