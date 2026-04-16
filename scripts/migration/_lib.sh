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
# normalize_semver3 <version>
#   "1.4" -> "1.4.0"
#   "v1.2.0" -> "1.2.0"
# -------------------------------------------------------------------
normalize_semver3() {
  local raw="${1:-}"
  raw="${raw#v}"
  raw="${raw//[^0-9.]/}"
  IFS='.' read -r major minor patch <<< "$raw"
  major="${major:-0}"
  minor="${minor:-0}"
  patch="${patch:-0}"
  echo "${major}.${minor}.${patch}"
}

# -------------------------------------------------------------------
# latest_manifest_release <manifest_json>
#   Returns first releases[].id in manifest.json (or empty)
# -------------------------------------------------------------------
latest_manifest_release() {
  local manifest_json="$1"
  [ -f "$manifest_json" ] || { echo ""; return; }
  jq -r '.releases[0].id // empty' "$manifest_json" 2>/dev/null || true
}

# -------------------------------------------------------------------
# manifest_has_release <manifest_json> <version>
#   Returns success if releases[].id contains version
# -------------------------------------------------------------------
manifest_has_release() {
  local manifest_json="$1"
  local version="$2"
  [ -f "$manifest_json" ] || return 1
  jq -e --arg version "$version" '.releases[]? | select(.id == $version)' "$manifest_json" >/dev/null 2>&1
}

# -------------------------------------------------------------------
# to_bmm_id <component> <version>
#   BASE + 1.3.0 -> openehr_base_1.3.0
# -------------------------------------------------------------------
to_bmm_id() {
  local component="$1"
  local version="$2"
  local lc
  lc="$(echo "$component" | tr '[:upper:]' '[:lower:]')"
  echo "openehr_${lc}_$(normalize_semver3 "$version")"
}
