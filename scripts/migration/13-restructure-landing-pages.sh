#!/bin/bash
set -euo pipefail

# Step 13: Restructure spec landing pages
#
# New landing page layout:
#   - Metadata tables + image (header only)
#
# Creates a new standalone page pages/document_information.adoc containing:
#   = Document Information
#   == Purpose
#   == Related Documents / Nomenclature / Status / Feedback / Conformance / ...
#   == Acknowledgements
#   == References
#   == Amendment Record
#
# The page is appended as the last entry in nav.adoc.

MODULES="$@"

restructure_module() {
    local module="$1"
    local preface="modules/$module/partials/preface.adoc"
    local index="modules/$module/pages/index.adoc"
    local nav="modules/$module/nav.adoc"
    local partials_dir="modules/$module/partials"
    local pages_dir="modules/$module/pages"

    [ -f "$index" ] || return 0

    echo "  • $module"

    # ---------------------------------------------------------------
    # 1. pages/document_information.adoc  –  standalone last chapter
    # ---------------------------------------------------------------
    local doc_info="$pages_dir/document_information.adoc"
    local tmp_doc
    tmp_doc=$(mktemp)

    # Page header — title + block diagram image
    printf 'include::partial$module_vars.adoc[]\n\n= Document Information\n\nimage::ROOT:openehr_block_diagram.svg[openEHR components,60%%,align=center]\n\n' >> "$tmp_doc"

    # Full preface content (Purpose + all other sections), skipping the empty == Preface line
    if [ -f "$preface" ]; then
        awk '/^== Preface[[:space:]]*$/ { next } { print }' "$preface" >> "$tmp_doc"
    fi

    # Acknowledgements from index.adoc (keep == level, strip comment/attribute lines)
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

    # sectnums off + References + Amendment record
    printf '\n:sectnums!:\n' >> "$tmp_doc"

    if grep -q '^bibliography::\[\]' "$index" 2>/dev/null; then
        printf '\n== References\n\nbibliography::[]\n' >> "$tmp_doc"
    fi

    if grep -q 'include::partial\$amendment_record\.adoc' "$index" 2>/dev/null; then
        printf '\ninclude::partial$amendment_record.adoc[]\n' >> "$tmp_doc"
    fi

    mv "$tmp_doc" "$doc_info"

    # ---------------------------------------------------------------
    # 3. Rebuild index.adoc  –  header only
    # ---------------------------------------------------------------
    local tmp_idx
    tmp_idx=$(mktemp)

    # Header block: everything before the first == section or preface include,
    # with trailing blank lines stripped and a single trailing newline added.
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

    mv "$tmp_idx" "$index"

    # ---------------------------------------------------------------
    # 4. nav.adoc  –  append Document Information as last entry
    # ---------------------------------------------------------------
    if [ -f "$nav" ] && ! grep -q 'document_information\.adoc' "$nav"; then
        # Strip trailing blank lines, append entry, add trailing newline
        awk '
            { lines[NR] = $0 }
            END {
                end = NR
                while (end > 0 && lines[end] == "") end--
                for (i = 1; i <= end; i++) print lines[i]
                print "** xref:document_information.adoc[Document Information]"
                print ""
            }
        ' "$nav" > "$nav.tmp" && mv "$nav.tmp" "$nav"
    fi
}

echo "Step 13: Restructure spec landing pages..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for module in $MODULES; do
    restructure_module "$module"
done

echo ""
echo "✓ Landing pages restructured"
