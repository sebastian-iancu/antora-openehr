#!/bin/bash
set -e

DRY_RUN="$1"
shift
MODULES="$@"

# -------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------

is_dry_run() {
  [ "$DRY_RUN" = "dry-run" ]
}

# Turn "foo_bar" into "Foo Bar"
to_title_case() {
  echo "$1" \
    | sed 's/_/ /g' \
    | sed 's/\b\(.\)/\u\1/g'
}

# Get the first = header from a page
get_title_from_page() {
  local page_file="$1"
  [ -f "$page_file" ] || { echo ""; return; }

  awk '/^[[:space:]]*= / { sub(/^[[:space:]]*= /,""); print; exit }' "$page_file"
}

# -------------------------------------------------------------------
# NEW: Extract :spec_title: from manifest_vars.adoc
# -------------------------------------------------------------------

get_spec_title_from_manifest() {
  local module="$1"
  local manifest=""

  # Prefer per-module manifest_vars
  if [ -f "docs/$module/manifest_vars.adoc" ]; then
    manifest="docs/$module/manifest_vars.adoc"
  elif [ -f "docs/manifest_vars.adoc" ]; then
    manifest="docs/manifest_vars.adoc"
  else
    echo ""
    return
  fi

  # Find line beginning with :spec_title:
  local line
  line="$(grep '^:spec_title:' "$manifest" | head -n1 || true)"

  [ -z "$line" ] && { echo ""; return; }

  # Remove prefix ":spec_title: "
  echo "${line#*:spec_title: }"
}

# -------------------------------------------------------------------
# ROOT nav
# -------------------------------------------------------------------

create_root_nav() {
  if is_dry_run; then
    echo "[DRY-RUN] Would create modules/ROOT/nav.adoc"
    return
  fi

  mkdir -p "modules/ROOT"

  cat > "modules/ROOT/nav.adoc" << EOF
* xref:index.adoc[Overview]
EOF

  echo "✓ Created modules/ROOT/nav.adoc"
}

# -------------------------------------------------------------------
# Module nav generation
# -------------------------------------------------------------------

generate_nav_entries_from_master() {
  local module="$1"
  local master_file="docs/$module/master.adoc"

  [ -f "$master_file" ] || return 0

  awk 'found {print} /:sectnums:/{found=1}' "$master_file" \
    | grep '^include::' 2>/dev/null \
    | sed -E 's/^include::([^[]+)\[.*/\1/' \
    | while read -r target; do
        [ -z "$target" ] && continue

        case "$target" in
          *"/"*|*"{"* ) continue ;;
        esac

        case "$target" in
          manifest_vars.adoc) continue ;;
        esac

        case "$target" in
          master00-amendment_record.adoc|amendment_record.adoc) continue ;;
        esac

        local base="${target%.adoc}"
        base="$(echo "$base" | sed 's/^master[0-9][0-9]-//')"

        local page_file="modules/$module/pages/${base}.adoc"
        local title

        title="$(get_title_from_page "$page_file")"
        if [ -z "$title" ]; then
          title="$(to_title_case "$base")"
        fi

        echo "** xref:${base}.adoc[${title}]"
      done

  if grep -q 'include::.*amendment_record\.adoc' "$master_file"; then
    echo "** xref:amendment_record.adoc[Amendment Record]"
  fi
}

create_module_nav() {
  local module="$1"

  case "$module" in
    UML|uml)
      echo "  Skipping nav for UML module: $module"
      return
      ;;
  esac

  if is_dry_run; then
    echo "[DRY-RUN] Would create modules/$module/nav.adoc"
    echo "[DRY-RUN] Would extract module title from manifest_vars or index.adoc"
    return
  fi

  local nav_file="modules/$module/nav.adoc"
  local index_file="modules/$module/pages/index.adoc"

  mkdir -p "modules/$module"

  # ------------------------------------------------------------------
  # TITLE RESOLUTION PRIORITY:
  # 1) :spec_title: from manifest_vars.adoc
  # 2) First "= Heading" in index.adoc
  # 3) Prettified module name
  # ------------------------------------------------------------------
  local module_title

  module_title="$(get_spec_title_from_manifest "$module")"

  if [ -z "$module_title" ]; then
    module_title="$(get_title_from_page "$index_file")"
  fi

  if [ -z "$module_title" ]; then
    module_title="$(to_title_case "$module")"
  fi

  {
    echo "* xref:index.adoc[${module_title}]"
    generate_nav_entries_from_master "$module"
  } > "$nav_file"

  echo "✓ Created modules/$module/nav.adoc"
}

# -------------------------------------------------------------------
# Main
# -------------------------------------------------------------------

echo "→ Generating navigation files..."
create_root_nav

for module in $MODULES; do
  create_module_nav "$module"
done
