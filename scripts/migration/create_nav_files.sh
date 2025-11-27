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

# Get the first level-0 Asciidoc header (= ...) from a page
# If none found, print empty string
get_title_from_page() {
  local page_file="$1"

  [ -f "$page_file" ] || { echo ""; return; }

  # First line starting with "= " -> strip leading "= " and return
  awk '/^= / { sub(/^= /,""); print; exit }' "$page_file"
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

# Extract chapter includes from docs/<module>/master.adoc (AFTER :sectnums:)
# and turn them into nav entries.
#
# Input:
#   $1 = module name
#
# Output:
#   writes lines like:
#     ** xref:overview.adoc[Integrating openEHR with other Systems]
#   and, if an amendment_record include exists anywhere in master.adoc:
#     ** xref:amendment_record.adoc[Amendment Record]  (as last entry)
#
generate_nav_entries_from_master() {
  local module="$1"
  local master_file="docs/$module/master.adoc"

  [ -f "$master_file" ] || return 0

  # 1) Normal chapter entries from lines after :sectnums:
  awk 'found {print} /:sectnums:/{found=1}' "$master_file" \
    | grep '^include::' 2>/dev/null \
    | sed -E 's/^include::([^[]+)\[.*/\1/' \
    | while read -r target; do
        # Skip blank
        [ -z "$target" ] && continue

        # Skip anything with a path or attribute in it
        case "$target" in
          *"/"*|*"{"* )
            continue
            ;;
        esac

        # Skip manifest_vars.adoc explicitly (no nav entry for that)
        case "$target" in
          manifest_vars.adoc)
            continue
            ;;
        esac

        # Skip amendment_record here; we'll add it explicitly at the end
        case "$target" in
          master00-amendment_record.adoc|amendment_record.adoc)
            continue
            ;;
        esac

        # target examples:
        #   "master01-overview.adoc"
        #   "amendment_record.adoc"
        local base="${target%.adoc}"

        # Strip masterNN- prefix to match your migration filenames:
        # master01-overview -> overview
        base="$(echo "$base" | sed 's/^master[0-9][0-9]-//')"

        local page_file="modules/$module/pages/${base}.adoc"
        local title

        # Prefer the first main header (= ...) from the actual page
        title="$(get_title_from_page "$page_file")"

        # Fallback: derive something readable from the filename
        if [ -z "$title" ]; then
          title="$(to_title_case "$base")"
        fi

        echo "** xref:${base}.adoc[${title}]"
      done

  # 2) Amendment record as last entry, if included anywhere in master.adoc
  if grep -q 'include::.*amendment_record\.adoc' "$master_file"; then
    echo "** xref:amendment_record.adoc[Amendment Record]"
  fi
}

create_module_nav() {
  local module="$1"

  # Skip UML modules
  case "$module" in
    UML|uml)
      echo "  Skipping nav for UML module: $module"
      return
      ;;
  esac

  if is_dry_run; then
    echo "[DRY-RUN] Would create modules/$module/nav.adoc"
    echo "[DRY-RUN] Would inspect docs/$module/master.adoc and modules/$module/pages/*.adoc for titles"
    return
  fi

  local nav_file="modules/$module/nav.adoc"
  local index_file="modules/$module/pages/index.adoc"

  mkdir -p "modules/$module"

  # Top-level title: take from the first header in index.adoc if possible
  local module_title
  module_title="$(get_title_from_page "$index_file")"
  if [ -z "$module_title" ]; then
    # fallback to module name if index.adoc has no "= ..." header
    module_title="$(to_title_case "$module")"
  fi

  {
    # Top-level entry for the module index page
    echo "* xref:index.adoc[${module_title}]"

    # Child entries derived from master.adoc (after :sectnums: + amendment last)
    generate_nav_entries_from_master "$module"
  } > "$nav_file"

  echo "✓ Created modules/$module/nav.adoc (from master + page headers)"
}

# -------------------------------------------------------------------
# Main
# -------------------------------------------------------------------

echo "→ Generating navigation files..."

create_root_nav

for module in $MODULES; do
  create_module_nav "$module"
done
