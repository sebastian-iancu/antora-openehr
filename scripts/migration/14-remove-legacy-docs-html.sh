#!/usr/bin/env bash
# Step 14: Remove legacy publish/HTML artefacts and AsciiDoc tooling files under docs/
# (pre-Antora), remove obsolete docs-root sources superseded by Antora modules,
# prune empty directories under docs/<module>/, and drop repo-root
# .asciidoctorconfig when present (optional IDE/local AsciiDoctor config).
#
# Usage: run from specification repository root (same as other migration steps).
set -euo pipefail

echo "Step 14: Removing legacy docs artefacts, obsolete docs root files, and empty docs dirs..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

remove_one_tracked_or_untracked() {
  local f="$1"
  echo "  • rm $f"
  if git rev-parse --git-dir >/dev/null 2>&1 \
    && git ls-files --error-unmatch "$f" >/dev/null 2>&1; then
    git rm -f "$f"
  else
    rm -f "$f"
  fi
}

remove_html_and_tooling_files() {
  local f
  while IFS= read -r -d '' f; do
    remove_one_tracked_or_untracked "$f"
  done < <(find docs -type f \( -name '*.html' -o -name '*.htm' -o -name '.asciidoctorconfig' \) -print0 2>/dev/null || true)
}

remove_repo_root_asciidoctorconfig() {
  [ -f .asciidoctorconfig ] || return 0
  remove_one_tracked_or_untracked .asciidoctorconfig
}

remove_obsolete_docs_root_files() {
  # Superseded by modules/ROOT/pages/index.adoc
  [ -f docs/index.adoc ] && remove_one_tracked_or_untracked docs/index.adoc
  # Legacy draw.io source no longer used after migration (SVG lives in modules/ROOT/images/)
  [ -f docs/openehr_block_diagram.xml ] && remove_one_tracked_or_untracked docs/openehr_block_diagram.xml
}

prune_empty_dirs_under_docs() {
  find docs -mindepth 1 -depth -type d -empty -print -delete 2>/dev/null \
    | sed 's/^/  • rmdir /' || true
}

if [ ! -d docs ]; then
  echo "  (no docs/ directory — skipping docs tree cleanup)"
  remove_repo_root_asciidoctorconfig
  echo ""
  echo "✓ Legacy docs cleanup finished"
  exit 0
fi

remove_html_and_tooling_files
remove_obsolete_docs_root_files
prune_empty_dirs_under_docs
remove_repo_root_asciidoctorconfig

echo ""
echo "✓ Legacy docs cleanup finished"
