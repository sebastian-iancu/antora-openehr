#!/usr/bin/env bash
# Step 14: Remove legacy rendered HTML under docs/ (pre-Antora publish artefacts)
# and prune empty directories under docs/<module>/.
#
# Usage: run from specification repository root (same as other migration steps).
set -euo pipefail

echo "Step 14: Removing legacy docs/**/*.html and empty docs directories..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

[ -d docs ] || {
  echo "  (no docs/ directory — nothing to do)"
  echo ""
  exit 0
}

remove_html_files() {
  local f
  while IFS= read -r -d '' f; do
    echo "  • rm $f"
    if git rev-parse --git-dir >/dev/null 2>&1 \
      && git ls-files --error-unmatch "$f" >/dev/null 2>&1; then
      git rm -f "$f"
    else
      rm -f "$f"
    fi
  done < <(find docs -type f \( -name '*.html' -o -name '*.htm' \) -print0 2>/dev/null || true)
}

prune_empty_dirs_under_docs() {
  find docs -mindepth 1 -depth -type d -empty -print -delete 2>/dev/null \
    | sed 's/^/  • rmdir /' || true
}

remove_html_files
prune_empty_dirs_under_docs

echo ""
echo "✓ Legacy docs HTML cleanup finished"
