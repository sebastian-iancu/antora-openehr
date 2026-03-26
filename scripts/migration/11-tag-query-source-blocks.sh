#!/bin/bash
set -euo pipefail

# Step 11: Tag untagged listing blocks in QUERY/AQL pages with [source, sql]
#
# Blocks in AQL pages have no [source, ...] tag so get no highlighting.
# This step adds [source, sql] before the OPENING delimiter of any listing
# block that is not already preceded by a [source, ...] line.
#
# Tracks block open/close state so closing delimiters are never tagged.
#
# Only runs for the QUERY component; a no-op for all others.
#
# Usage: ./11-tag-query-source-blocks.sh <COMPONENT_NAME>

COMPONENT_NAME="$1"

if [ "$COMPONENT_NAME" != "QUERY" ]; then
  exit 0
fi

echo "Step 11: Tagging AQL listing blocks with [source, sql]..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

tag_source_blocks() {
  local f="$1"

  perl -i -pe '
    BEGIN { our $prev = ""; our $in_block = 0; our $block_delim = "" }
    if (/^(-{4,})\s*$/) {
      my $delim = $1;
      if (!$in_block) {
        # Opening a new block: tag it if not already tagged
        if ($prev !~ /^\[source/) {
          print "[source, sql]\n";
        }
        $in_block = 1;
        $block_delim = $delim;
      } elsif ($delim eq $block_delim) {
        # Closing delimiter: matches the opening one
        $in_block = 0;
        $block_delim = "";
      }
      # Mismatched inner delimiters (content) are left alone
    }
    $prev = $_;
  ' "$f"
}

for pages_dir in modules/*/pages; do
  [ -d "$pages_dir" ] || continue
  for f in "$pages_dir"/*.adoc; do
    [ -f "$f" ] || continue
    tag_source_blocks "$f"
  done
  echo "→ Tagged source blocks in $pages_dir"
done

echo ""
