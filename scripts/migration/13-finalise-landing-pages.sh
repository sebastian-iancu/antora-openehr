#!/bin/bash
set -euo pipefail

# Step 13: Finalise landing pages
#
# Per subspec module:
#   - Creates pages/appendix.adoc (image, preface sections, acknowledgements,
#     references, amendment record) — Feedback section excluded
#   - Trims pages/index.adoc to header only, appends Feedback section
#   - Injects abstract from scripts/resources/abstracts/{COMPONENT}.adoc
#   - Appends appendix to nav.adoc
#
# For ROOT:
#   - Injects @overview text before == Specifications, with figure caption

COMPONENT_NAME="$1"
shift
MODULES="$@"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ABSTRACT_FILE="$SCRIPT_DIR/../resources/abstracts/${COMPONENT_NAME}.adoc"

echo "Step 13: Finalising landing pages..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# -------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------

# Extract a named section from the abstract file.
# Sections start with "// @NAME" and end at the next "// @" or EOF.
extract_section() {
  local section="$1"
  [ -f "$ABSTRACT_FILE" ] || return 0
  awk -v section="$section" '
    /^\/\/ @/ {
      current = substr($0, 5)
      in_section = (current == section)
      next
    }
    in_section { lines[++n] = $0 }
    END {
      while (n > 0 && lines[n] == "") n--
      start = 1
      while (start <= n && lines[start] == "") start++
      for (i = start; i <= n; i++) print lines[i]
    }
  ' "$ABSTRACT_FILE"
}

# -------------------------------------------------------------------
# ROOT: inject micro summaries into spec listing
# -------------------------------------------------------------------
apply_root_micros() {
  local index="modules/ROOT/pages/index.adoc"
  [ -f "$index" ] || return 0
  [ -f "$ABSTRACT_FILE" ] || return 0

  local tmp
  tmp=$(mktemp)

  # Two-pass awk: first file = abstract resource (builds micro map),
  # second file = ROOT index (applies overrides to xref bullet lines)
  awk '
    NR == FNR {
      if (/^\/\/ @micro:/) {
        current = substr($0, 11)
        in_micro = 1
      } else if (/^\/\/ @/) {
        in_micro = 0; current = ""
      } else if (in_micro && /[^[:space:]]/) {
        micros[current] = $0
        in_micro = 0
      }
      next
    }
    /^\* xref:/ {
      s = $0
      sub(/^\* xref:/, "", s)
      n = index(s, ":index.adoc")
      if (n > 0) {
        mod = substr(s, 1, n - 1)
        if (mod in micros) {
          sub(/ -- .*$/, "")
          sub(/[[:space:]]+$/, "")
          print $0 " -- " micros[mod]
          next
        }
      }
    }
    { print }
  ' "$ABSTRACT_FILE" "$index" > "$tmp"

  mv "$tmp" "$index"
  echo "  • Micro summaries → ROOT/pages/index.adoc"
}

# -------------------------------------------------------------------
# ROOT: inject overview text and image caption
# -------------------------------------------------------------------
apply_root_overview() {
  local overview
  overview="$(extract_section "overview")"
  [ -z "$overview" ] && return 0

  local index="modules/ROOT/pages/index.adoc"
  [ -f "$index" ] || return 0

  local tmp
  tmp=$(mktemp)
  awk -v text="$overview" '
    /^image::/ {
      imgline = $0
      next
    }
    /^== Specifications/ && !done {
      print text
      print ""
      if (imgline != "") {
        print ".Specification Component Overview"
        print imgline
        print ""
      }
      print
      done = 1
      next
    }
    { print }
  ' "$index" > "$tmp"
  mv "$tmp" "$index"
  echo "  • Overview → ROOT/pages/index.adoc"
}

# -------------------------------------------------------------------
# Per subspec: restructure index + create appendix + inject abstract
# -------------------------------------------------------------------
restructure_module() {
  local module="$1"
  local preface="modules/$module/partials/preface.adoc"
  local index="modules/$module/pages/index.adoc"
  local nav="modules/$module/nav.adoc"
  local pages_dir="modules/$module/pages"

  [ -f "$index" ] || return 0

  echo "  • $module"

  # -----------------------------------------------------------------
  # 1. pages/appendix.adoc
  # -----------------------------------------------------------------
  local appendix="$pages_dir/appendix.adoc"
  local tmp_doc
  tmp_doc=$(mktemp)

  printf 'include::partial$module_vars.adoc[]\n\n= Appendix\n\nimage::ROOT:openehr_block_diagram.svg[openEHR components,60%%,align=center]\n\n' >> "$tmp_doc"

  # Preface content — skip == Preface title and == Feedback section
  if [ -f "$preface" ]; then
    awk '
      /^== Preface[[:space:]]*$/  { next }
      /^== Feedback[[:space:]]*$/ { in_feedback = 1; next }
      in_feedback && /^== /       { in_feedback = 0 }
      !in_feedback                { print }
    ' "$preface" >> "$tmp_doc"
  fi

  # Acknowledgements from index.adoc
  awk '
    /^== Acknowledgements[[:space:]]*$/ { in_ack = 1; print "\n== Acknowledgements"; next }
    in_ack && /^include::partial\$preface\.adoc/ { exit }
    in_ack && /^== /      { exit }
    in_ack && /^\/\//     { next }
    in_ack && /^:[[:alpha:]]/ { next }
    in_ack                { print }
  ' "$index" | awk '
    { lines[NR] = $0 }
    END {
      end = NR
      while (end > 0 && lines[end] == "") end--
      for (i = 1; i <= end; i++) print lines[i]
    }
  ' >> "$tmp_doc"

  # Package-qualifier ifdef block (AOM-style specs only)
  if grep -q '^ifdef::package_qualifiers' "$index" 2>/dev/null; then
    printf '\n' >> "$tmp_doc"
    awk '/^ifdef::package_qualifiers/{p=1} p{print} /^endif::\[\]/{p=0}' "$index" >> "$tmp_doc"
  fi

  printf '\n:sectnums!:\n' >> "$tmp_doc"

  if grep -q '^bibliography::\[\]' "$index" 2>/dev/null; then
    printf '\n== References\n\nbibliography::[]\n' >> "$tmp_doc"
  fi

  if grep -q 'include::partial\$amendment_record\.adoc' "$index" 2>/dev/null; then
    printf '\ninclude::partial$amendment_record.adoc[]\n' >> "$tmp_doc"
  fi

  mv "$tmp_doc" "$appendix"

  # -----------------------------------------------------------------
  # 2. Trim index.adoc to header + Feedback
  # -----------------------------------------------------------------
  local tmp_idx
  tmp_idx=$(mktemp)

  awk '
    {
      lines[NR] = $0
      if (!stop && (/^== / || /^include::partial\$preface\.adoc/)) {
        stop = NR - 1
      }
    }
    END {
      end = (stop > 0) ? stop : NR
      while (end > 0 && lines[end] == "") end--
      for (i = 1; i <= end; i++) print lines[i]
      print ""
    }
  ' "$index" >> "$tmp_idx"

  # Append Feedback section from preface
  if [ -f "$preface" ]; then
    local feedback
    feedback=$(awk '
      /^== Feedback[[:space:]]*$/ { in_feedback = 1; print; next }
      in_feedback && /^== /       { exit }
      in_feedback                 { print }
    ' "$preface")
    if [ -n "$feedback" ]; then
      printf '\n%s\n' "$feedback" >> "$tmp_idx"
    fi
  fi

  # -----------------------------------------------------------------
  # 3. Inject abstract after title
  # -----------------------------------------------------------------
  local abstract
  abstract="$(extract_section "spec:$module")"
  if [ -n "$abstract" ]; then
    local tmp_abs
    tmp_abs=$(mktemp)
    awk -v text="$abstract" '
      /^= / && !done {
        print
        print ""
        print text
        done=1
        next
      }
      { print }
    ' "$tmp_idx" > "$tmp_abs"
    mv "$tmp_abs" "$tmp_idx"
  fi

  mv "$tmp_idx" "$index"

  # -----------------------------------------------------------------
  # 4. nav.adoc — append Appendix as last entry
  # -----------------------------------------------------------------
  if [ -f "$nav" ] && ! grep -q 'appendix\.adoc' "$nav"; then
    awk '
      { lines[NR] = $0 }
      END {
        end = NR
        while (end > 0 && lines[end] == "") end--
        for (i = 1; i <= end; i++) print lines[i]
        print "** xref:appendix.adoc[Appendix]"
        print ""
      }
    ' "$nav" > "$nav.tmp" && mv "$nav.tmp" "$nav"
  fi
}

# -------------------------------------------------------------------
# Main
# -------------------------------------------------------------------

apply_root_micros
apply_root_overview

for module in $MODULES; do
  restructure_module "$module"
done

echo ""
echo "✓ Landing pages finalised"
