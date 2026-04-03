#!/bin/bash
# Shared helper functions for migration scripts.
# Source this file — do not execute directly.
#   source "$(dirname "$0")/_lib.sh"

# -------------------------------------------------------------------
# strip_master_prefix <filename>
#   masterNN-something.adoc     → something.adoc
#   masterNN.NN-something.adoc  → something.adoc
#   masterAppA-something.adoc   → something.adoc
#   anything_else.adoc          → anything_else.adoc
# -------------------------------------------------------------------
strip_master_prefix() {
  echo "$1" | sed -E 's/^master[0-9.]+-//; s/^masterApp[A-Z]-//'
}

# -------------------------------------------------------------------
# to_title_case <string>
#   "foo_bar" → "Foo Bar"
# -------------------------------------------------------------------
to_title_case() {
  echo "$1" \
    | sed 's/_/ /g' \
    | sed 's/\b\(.\)/\u\1/g'
}

# -------------------------------------------------------------------
# get_title_from_page <page_file>
#   Returns the first = heading from an .adoc file (empty if none).
# -------------------------------------------------------------------
get_title_from_page() {
  local page_file="$1"
  [ -f "$page_file" ] || { echo ""; return; }
  awk '/^[[:space:]]*= / { sub(/^[[:space:]]*= /,""); print; exit }' "$page_file"
}

# -------------------------------------------------------------------
# list_chapter_includes <master_file>
#   Prints the ordered list of chapter include targets from a
#   master.adoc file. Each line is the raw include target filename
#   (e.g. "master04-data_types.adoc"). Filters out:
#     - paths containing / or { (cross-directory / attribute-based)
#     - manifest_vars.adoc
#     - master-prefixed files (use strip_master_prefix on the result)
#     - amendment_record / preface files
# -------------------------------------------------------------------
list_chapter_includes() {
  local master_file="$1"
  [ -f "$master_file" ] || return 0

  awk 'found {print} /:sectnums:|:sectanchors:|-- CHAPTERS --/{found=1}' "$master_file" \
    | grep '^include::' 2>/dev/null \
    | sed -E 's/^include::([^[]+)\[.*/\1/' \
    | while read -r target; do
        [ -z "$target" ] && continue
        case "$target" in
          *"/"*|*"{"* )                          continue ;;
          manifest_vars.adoc)                     continue ;;
          *-amendment_record.adoc|amendment_record.adoc) continue ;;
          *-preface.adoc|preface.adoc)            continue ;;
        esac
        echo "$target"
      done
}

# -------------------------------------------------------------------
# get_uml_prefix <component_name> <module_name>
#   Returns the filename prefix used for UML class partials.
#   AM component uses aom14. / aom2. depending on module; all others
#   return empty string.
# -------------------------------------------------------------------
get_uml_prefix() {
  local component="$1"
  local module="$2"

  if [[ "$component" == "AM" ]]; then
    case "$module" in
      AOM2|OPT2|ADL2) echo "aom2." ;;
      *)              echo "aom14." ;;
    esac
  fi
  # non-AM components: no prefix (empty string)
}
