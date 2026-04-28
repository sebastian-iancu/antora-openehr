#!/bin/bash
set -euo pipefail

# Step 13: Finalise landing pages
#
# Per subspec module:
#   - Creates pages/appendix.adoc (acknowledgements first, then remaining preface
#     sections after Nomenclature/Feedback, package_qualifiers ifdef, optional
#     References only when citations exist; amendment record partial is included
#     here only (not on index.adoc)
#   - Rewrites pages/index.adoc: header + title + abstract + Purpose/Related
#     Documents/Nomenclature (from partials/preface.adoc during this step only) +
#     intro body before first section + Feedback; Status section is omitted
#   - Removes partials/preface.adoc after inlining (git rm when tracked) so the
#     partial is not part of the final tree; lineage remains via the prior
#     git mv from docs/**/preface into partials/preface before this step
#   - Injects abstract from scripts/resources/abstracts/{COMPONENT}.adoc
#   - Optionally updates manifest.json "summary" for this module from the
#     matching @spec:{ModuleId} abstract block when present
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

# Extract Purpose, Related Documents, and Nomenclature from partials/preface.adoc
# for the module index. Omits Status (not carried forward). Stops before Feedback.
extract_preface_index_sections() {
  local preface="$1"
  [ -f "$preface" ] || return 0
  awk '
    function title(line,    t) {
      if (line !~ /^==/) return ""
      t = line; sub(/^==[[:space:]]+/, "", t); sub(/[[:space:]]+$/, "", t)
      return t
    }
    /^==/ {
      t = title($0)
      if (t == "Preface") { active = 0; next }
      if (t == "Purpose" || t == "Related Documents" || t == "Nomenclature") {
        active = 1
        print
        next
      }
      if (t == "Feedback") { active = 0; exit }
      active = 0
      next
    }
    active { print }
  ' "$preface"
}

# Appendix: drop Preface title, Purpose–Nomenclature, Status, and Feedback;
# keep Conformance onward (Status body is not reproduced anywhere).
extract_preface_appendix_sections() {
  local preface="$1"
  [ -f "$preface" ] || return 0
  awk '
    function title(line,    t) {
      if (line !~ /^==/) return ""
      t = line; sub(/^==[[:space:]]+/, "", t); sub(/[[:space:]]+$/, "", t)
      return t
    }
    /^==/ {
      t = title($0)
      if (t == "Preface" || t == "Purpose" || t == "Related Documents" \
          || t == "Nomenclature" || t == "Status" || t == "Feedback") {
        skip = 1
        next
      }
      skip = 0
      print
      next
    }
    skip { next }
    { print }
  ' "$preface"
}

# After inlining, drop partials/preface.adoc so it is not shipped in the final tree.
# Uses git rm when the path is tracked (records removal after the earlier git mv from docs).
remove_superseded_preface_partial() {
  local module="$1"
  local p="modules/$module/partials/preface.adoc"
  [ -f "$p" ] || return 0
  echo "  • Removing superseded partials/preface.adoc (inlined into index/appendix)"
  if git rev-parse --git-dir >/dev/null 2>&1 \
    && git ls-files --error-unmatch "$p" >/dev/null 2>&1; then
    git rm -f "$p"
  else
    rm -f "$p"
  fi
}

# True if the module uses AsciiDoc citation macros anywhere under pages/ or partials/.
module_has_citations() {
  local module="$1"
  local base="modules/$module"
  [ -d "$base/pages" ] || return 1
  if grep -RIl --include='*.adoc' -E \
    '(^|[[:space:]])(citenp|citen|cites|cite):\\[' \
    "$base/pages" "$base/partials" 2>/dev/null | grep -q .; then
    return 0
  fi
  return 1
}

# Set manifest.specifications[].summary for this module id from abstract text (first paragraph).
update_manifest_summary_from_abstract() {
  local module="$1"
  local manifest="manifest.json"
  [ -f "$manifest" ] || return 0
  command -v jq >/dev/null 2>&1 || return 0
  local abstract_text
  abstract_text="$(extract_section "spec:$module")"
  [ -n "$abstract_text" ] || return 0
  local summary
  summary="$(printf '%s\n' "$abstract_text" | awk '
    NF { buf = buf (buf ? " " : "") $0 }
    /^$/ && buf { print buf; exit }
    END { if (buf) print buf }
  ')"
  [ -n "$summary" ] || return 0
  local tmp
  tmp=$(mktemp)
  if jq --arg id "$module" --arg s "$summary" '
    (.specifications |= map(if .id == $id then .summary = $s else . end))
  ' "$manifest" > "$tmp" 2>/dev/null; then
    mv "$tmp" "$manifest"
  else
    rm -f "$tmp"
  fi
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
  # 1. pages/appendix.adoc (read original index before it is rewritten)
  # -----------------------------------------------------------------
  local appendix="$pages_dir/appendix.adoc"
  local tmp_doc
  tmp_doc=$(mktemp)

  printf 'include::partial$module_vars.adoc[]\n\n= Appendix\n\n' >> "$tmp_doc"

  # Acknowledgements first (scraped from index before trim)
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

  # Remaining preface (Conformance, Tools, change log, etc.) — not Purpose–Status or Feedback
  if [ -f "$preface" ]; then
    extract_preface_appendix_sections "$preface" >> "$tmp_doc"
  fi

  # Package-qualifier ifdef block (AOM-style specs only)
  if grep -q '^ifdef::package_qualifiers' "$index" 2>/dev/null; then
    printf '\n' >> "$tmp_doc"
    awk '/^ifdef::package_qualifiers/{p=1} p{print} /^endif::\[\]/{p=0}' "$index" >> "$tmp_doc"
  fi

  printf '\n:sectnums!:\n' >> "$tmp_doc"

  # References only when the module actually cites something (avoids empty bibliography)
  if module_has_citations "$module"; then
    printf '\n== References\n\nbibliography::[]\n' >> "$tmp_doc"
  fi

  # Amendment record: single include on appendix only (partial must exist). Skip if a
  # legacy line was already copied into tmp_doc from extracted preface material.
  local amend_partial="modules/$module/partials/amendment_record.adoc"
  if [ -f "$amend_partial" ] \
    && ! grep -q 'include::partial\$amendment_record\.adoc' "$tmp_doc" 2>/dev/null; then
    printf '\ninclude::partial$amendment_record.adoc[]\n' >> "$tmp_doc"
  fi

  mv "$tmp_doc" "$appendix"

  # -----------------------------------------------------------------
  # 2. Trim index body (before first section or preface include)
  # -----------------------------------------------------------------
  local tmp_trim
  tmp_trim=$(mktemp)

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
    }
  ' "$index" > "$tmp_trim"

  # Drop amendment includes from index trim (appendix-only; legacy migrations appended them)
  awk '$0 !~ /^include::partial\$amendment_record\.adoc\[\][[:space:]]*$/' "$tmp_trim" > "${tmp_trim}.noamend" \
    && mv "${tmp_trim}.noamend" "$tmp_trim"

  local pidx_tmp feed_tmp abst_tmp
  pidx_tmp=$(mktemp)
  feed_tmp=$(mktemp)
  abst_tmp=$(mktemp)
  if [ -f "$preface" ]; then
    extract_preface_index_sections "$preface" > "$pidx_tmp"
    awk '
      /^== Feedback[[:space:]]*$/ { in_feedback = 1; print; next }
      in_feedback && /^== /       { exit }
      in_feedback                 { print }
    ' "$preface" > "$feed_tmp"
  else
    : > "$pidx_tmp"
    : > "$feed_tmp"
  fi
  extract_section "spec:$module" > "$abst_tmp" || true

  # -----------------------------------------------------------------
  # 3. Assemble index: header… title, abstract, preface core, intro, Feedback
  # -----------------------------------------------------------------
  local title_line total_lines
  title_line=$(awk '/^= /{print NR; exit}' "$tmp_trim" || true)
  total_lines=$(wc -l < "$tmp_trim" | tr -d ' ')

  {
    if [ -n "${title_line:-}" ] && [ "$title_line" -gt 0 ]; then
      if [ "$title_line" -gt 1 ]; then
        head -n $((title_line - 1)) "$tmp_trim"
      fi
      sed -n "${title_line}p" "$tmp_trim"
      echo ""
      if [ -s "$abst_tmp" ]; then
        cat "$abst_tmp"
        echo ""
      fi
      if [ -s "$pidx_tmp" ]; then
        cat "$pidx_tmp"
        echo ""
      fi
      if [ -n "$total_lines" ] && [ "$title_line" -lt "$total_lines" ]; then
        tail -n +$((title_line + 1)) "$tmp_trim"
      fi
    else
      cat "$tmp_trim"
      echo ""
      if [ -s "$abst_tmp" ]; then
        cat "$abst_tmp"
        echo ""
      fi
      if [ -s "$pidx_tmp" ]; then
        cat "$pidx_tmp"
        echo ""
      fi
    fi
    if [ -s "$feed_tmp" ]; then
      echo ""
      cat "$feed_tmp"
    fi
    echo ""
  } > "$index"

  rm -f "$tmp_trim" "$pidx_tmp" "$feed_tmp" "$abst_tmp"

  remove_superseded_preface_partial "$module"

  update_manifest_summary_from_abstract "$module"

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
