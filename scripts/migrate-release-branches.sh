#!/bin/bash
set -euo pipefail

# Migrate all release branches of a spec repo to Antora structure.
# Runs the full migration pipeline on each release/* branch, commits the
# result, then restores the original branch.
#
# Usage: ./scripts/migrate-release-branches.sh repos/specifications-AM
#   or:  ./scripts/migrate-release-branches.sh  (migrates all repos)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MIGRATION_DIR="$SCRIPT_DIR/migration"
REPOS_DIR="$(cd "$SCRIPT_DIR/../repos" && pwd)"

# Grammar source dirs (populated by make update-grammars)
ADL_ANTLR_SRC="$REPOS_DIR/adl-antlr/src/main/antlr/adl"
OPENEHR_ANTLR4_SRC="$REPOS_DIR/openEHR-antlr4/reader_common/src/main/antlr"

migrate_repo_branch() {
  local repo_path="$1"
  local branch="$2"
  local repo_name component_name

  repo_name=$(basename "$repo_path")
  component_name="${repo_name#specifications-}"

  echo ""
  echo "  ── Branch: $branch"

  git -C "$repo_path" checkout "$branch" --quiet

  # Remove previous migration output
  rm -rf "$repo_path/modules"
  rm -f  "$repo_path/antora.yml"

  # Run migration (suppress backup — release branch IS the original)
  local orig_dir="$PWD"
  cd "$repo_path"

  MODULES="$("$MIGRATION_DIR/1-analyze-structure.sh")"
  "$MIGRATION_DIR/2-create-antora-structure.sh" $MODULES
  "$MIGRATION_DIR/3-move-uml.sh" "$component_name"
  "$MIGRATION_DIR/4-migrate_content_files.sh" $MODULES
  "$MIGRATION_DIR/4a-fetch-external-grammars.sh" "$component_name" $MODULES
  "$MIGRATION_DIR/5-create-antora-yml.sh" "$component_name" $MODULES
  "$MIGRATION_DIR/6-create_nav_files.sh" $MODULES
  "$MIGRATION_DIR/7-create-root-index.sh" "$component_name" $MODULES
  "$MIGRATION_DIR/8-apply-manifest-vars.sh" "$component_name" $MODULES
  "$MIGRATION_DIR/9-rewrite-uml-class-includes.sh" "$component_name" $MODULES
  "$MIGRATION_DIR/10-rewrite-class-xrefs.sh"
  "$MIGRATION_DIR/11-tag-query-source-blocks.sh" "$component_name"
  "$MIGRATION_DIR/12-escape-literal-braces.sh"

  cd "$orig_dir"

  # Copy grammar files into partials (mirrors make update-grammars)
  if [ -d "$ADL_ANTLR_SRC" ]; then
    for module in ADL1.4 ADL2 OPT2; do
      local pdir="$repo_path/modules/$module/partials"
      [ -d "$pdir" ] && cp "$ADL_ANTLR_SRC"/*.g4 "$pdir/" 2>/dev/null || true
    done
    for module in odin BEL decision_language; do
      local pdir="$repo_path/modules/$module/partials"
      [ -d "$pdir" ] && cp "$ADL_ANTLR_SRC"/*.g4 "$pdir/" 2>/dev/null || true
    done
  fi
  if [ -d "$OPENEHR_ANTLR4_SRC" ]; then
    for module in EL; do
      local pdir="$repo_path/modules/$module/partials"
      [ -d "$pdir" ] && cp "$OPENEHR_ANTLR4_SRC"/El*.g4 "$pdir/" 2>/dev/null || true
    done
  fi

  # Commit migrated content
  git -C "$repo_path" add modules/ antora.yml 2>/dev/null || true
  if ! git -C "$repo_path" diff --cached --quiet; then
    git -C "$repo_path" commit -m "Apply Antora migration to $branch" --quiet
    echo "  ✓ Committed migration for $branch"
  else
    echo "  ✓ No changes to commit for $branch"
  fi
}

migrate_repo() {
  local repo_path="$1"
  local repo_name
  repo_name=$(basename "$repo_path")

  echo ""
  echo "═══════════════════════════════════════════"
  echo "  Repository: $repo_name"
  echo "═══════════════════════════════════════════"

  # Save current branch
  local original_branch
  original_branch=$(git -C "$repo_path" symbolic-ref --short HEAD 2>/dev/null || echo "master")

  # Get all local release branches
  local branches
  branches=$(git -C "$repo_path" branch | grep 'release/' | sed 's/[* ]*//' || true)

  if [ -z "$branches" ]; then
    echo "  No release branches found — skipping"
    git -C "$repo_path" checkout "$original_branch" --quiet
    return
  fi

  for branch in $branches; do
    migrate_repo_branch "$repo_path" "$branch"
  done

  # Restore original branch
  git -C "$repo_path" checkout "$original_branch" --quiet
  echo ""
  echo "  ✓ Restored branch: $original_branch"
}

# Main
if [ $# -eq 1 ]; then
  migrate_repo "$1"
else
  echo "Migrating all release branches for all repositories..."
  for repo in "$REPOS_DIR"/specifications-*/; do
    migrate_repo "$repo"
  done
fi

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  Release branch migration complete       ║"
echo "╚══════════════════════════════════════════╝"
