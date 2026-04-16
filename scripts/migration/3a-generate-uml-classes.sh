#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_lib.sh"

COMPONENT_NAME="${1:-}"
REPO_NAME="$(basename "$(pwd)")"
MANIFEST_PATH="manifest.json"
OUTPUT_DIR="modules/ROOT/partials/classes"
STAGING_ROOT="modules/ROOT/partials/Adoc"
# Pin default tag; override with BMM_PUBLISHER_IMAGE e.g. ghcr.io/openehr/bmm-publisher:0.4.0
DOCKER_IMAGE="${BMM_PUBLISHER_IMAGE:-ghcr.io/openehr/bmm-publisher:0.4.0}"

# Optional local BMM JSON overlays (merged on top of the image's /app/resources):
#   - Default directory next to manifest.json: ./computable/BMM/*.bmm.json
#   - Or explicit path: BMM_RESOURCES_OVERLAY=/path/to/dir
# Filenames must match publisher ids, e.g. openehr_lang_1.1.0.bmm.json
BMM_RESOURCES_MERGED_DIR=""

cleanup_bmm_resources_merged_dir() {
  if [[ -n "${BMM_RESOURCES_MERGED_DIR:-}" && -d "${BMM_RESOURCES_MERGED_DIR}" ]]; then
    rm -rf "${BMM_RESOURCES_MERGED_DIR}"
    BMM_RESOURCES_MERGED_DIR=""
  fi
}

prepare_bmm_resources_overlay() {
  local overlay=""
  if [[ -n "${BMM_RESOURCES_OVERLAY:-}" && -d "${BMM_RESOURCES_OVERLAY}" ]]; then
    overlay="${BMM_RESOURCES_OVERLAY}"
  elif [[ -d "computable/BMM" ]] && compgen -G "computable/BMM/*.bmm.json" >/dev/null; then
    overlay="$(pwd)/computable/BMM"
  fi

  if [[ -z "$overlay" ]]; then
    return 1
  fi

  echo "→ BMM resources overlay: $overlay (merged onto image /app/resources)"

  BMM_RESOURCES_MERGED_DIR="$(mktemp -d)"
  local cid
  cid="$(docker create --entrypoint /bin/true "$DOCKER_IMAGE")"
  docker cp "$cid:/app/resources/." "${BMM_RESOURCES_MERGED_DIR}/"
  docker rm "$cid" >/dev/null

  local f
  for f in "$overlay"/*.bmm.json; do
    [[ -f "$f" ]] || continue
    cp -f "$f" "${BMM_RESOURCES_MERGED_DIR}/"
    echo "  • overlay $(basename "$f")"
  done
  return 0
}

if [[ -z "$COMPONENT_NAME" ]]; then
  echo "Usage: $0 <COMPONENT_NAME>"
  exit 1
fi

pick_best_manifest_version() {
  local component="$1"
  local manifest="$2"
  shift 2
  local candidates=("$@")
  local candidate

  for candidate in "${candidates[@]}"; do
    if manifest_has_release "$manifest" "$candidate"; then
      echo "$candidate"
      return
    fi
  done

  latest_manifest_release "$manifest"
}

resolve_bmm_main() {
  local component="$1"
  local manifest="$2"

  case "$component" in
    BASE)
      pick_best_manifest_version "$component" "$manifest" "1.3.0" "1.2.0" "1.1.0"
      ;;
    AM)
      pick_best_manifest_version "$component" "$manifest" "2.4.0" "2.3.0" "2.2.0" "1.4.0"
      ;;
    RM)
      pick_best_manifest_version "$component" "$manifest" "1.2.0" "1.1.0" "1.0.4"
      ;;
    LANG)
      # LANG repo may be missing in local setup; keep a stable default.
      echo "1.1.0"
      ;;
    *)
      latest_manifest_release "$manifest"
      ;;
  esac
}

resolve_bmm_dependencies() {
  local component="$1"
  local main_version="$2"

  case "$component:$main_version" in
    AM:1.4.0) echo "openehr_base_1.1.0" ;;
    AM:2.2.0) echo "openehr_base_1.1.0" ;;
    AM:2.3.0) echo "openehr_lang_1.0.0 openehr_base_1.2.0" ;;
    AM:2.4.0) echo "openehr_lang_1.1.0 openehr_base_1.3.0" ;;
    RM:1.0.4) echo "openehr_base_1.1.0" ;;
    RM:1.1.0) echo "openehr_base_1.2.0" ;;
    RM:1.2.0) echo "openehr_base_1.3.0" ;;
    LANG:1.1.0) echo "openehr_base_1.3.0" ;;
    *) echo "" ;;
  esac
}

validate_generated_classes() {
  local output_dir="$1"
  if ! compgen -G "${output_dir}/*.adoc" >/dev/null; then
    echo "Error: bmm-publisher generated no class .adoc files in ${output_dir}"
    exit 1
  fi

  if rg -n "include::\\{uml_export_dir\\}/classes/|include::\\.\\./UML/.*/classes/" "$output_dir" >/dev/null 2>&1; then
    echo "Error: Generated class files still contain legacy UML include paths"
    exit 1
  fi
}

collect_generated_artifacts() {
  local main_id="$1"
  local target_root="$2"
  local generated_root="${STAGING_ROOT}/${main_id}"

  # bmm-publisher writes under partials/Adoc/<main_id>/*.
  # Promote all generated sibling directories (classes + related artifacts)
  # into ROOT partials for migration-time consumption.
  if [ -d "$generated_root" ]; then
    local item
    for item in "$generated_root"/*; do
      [ -e "$item" ] || continue
      local name
      name="$(basename "$item")"
      mkdir -p "${target_root}/${name}"
      cp -r "$item"/. "${target_root}/${name}/"
    done
  fi
}

cleanup_staging_output() {
  # Keep migration output stable: only ROOT/partials/classes is needed downstream.
  if [ -d "$STAGING_ROOT" ]; then
    rm -rf "$STAGING_ROOT"
  fi
}

echo "Step 3a: Generating UML class partials via bmm-publisher..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ! -f "$MANIFEST_PATH" ]; then
  echo "No manifest.json found in $(pwd); skipping bmm-publisher generation."
  echo ""
  exit 0
fi

mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR"/*.adoc

if [ -n "${BMM_MAIN_FILE:-}" ]; then
  MAIN_IDS=("$BMM_MAIN_FILE")
  RESOLUTION_MODE="external override"
else
  MAIN_VERSION="$(resolve_bmm_main "$COMPONENT_NAME" "$MANIFEST_PATH")"
  if [ -z "$MAIN_VERSION" ]; then
    echo "Error: Could not resolve BMM version for component $COMPONENT_NAME from $MANIFEST_PATH"
    exit 1
  fi
  MAIN_ID="$(to_bmm_id "$COMPONENT_NAME" "$MAIN_VERSION")"
  MAIN_IDS=("$MAIN_ID")
  # AM content references both aom14.* and aom2.* class partial series.
  if [[ "$COMPONENT_NAME" == "AM" ]]; then
    MAIN_IDS=("openehr_am_1.4.0" "$MAIN_ID")
  fi
  RESOLUTION_MODE="manifest-driven"
fi

echo "→ Repo: $REPO_NAME"
echo "→ Component: $COMPONENT_NAME"
echo "→ Output dir: $OUTPUT_DIR"

trap cleanup_bmm_resources_merged_dir EXIT
if prepare_bmm_resources_overlay; then
  :
fi

for MAIN_ID in "${MAIN_IDS[@]}"; do
  if [ -n "${BMM_DEP_FILES:-}" ]; then
    DEP_IDS="${BMM_DEP_FILES}"
    DEP_MODE="external override"
  else
    MAIN_VERSION_NORMALIZED="$(echo "$MAIN_ID" | sed -E 's/^openehr_[a-z]+_//')"
    DEP_IDS="$(resolve_bmm_dependencies "$COMPONENT_NAME" "$MAIN_VERSION_NORMALIZED")"
    DEP_MODE="fallback map"
  fi

  echo "→ Main BMM id ($RESOLUTION_MODE): $MAIN_ID"
  if [ -n "$DEP_IDS" ]; then
    echo "  Dependency ids ($DEP_MODE): $DEP_IDS"
  else
    echo "  Dependency ids: none"
  fi

  docker_run=(docker run --rm -v "$(pwd)/modules/ROOT/partials:/app/output")
  if [[ -n "${BMM_RESOURCES_MERGED_DIR:-}" ]]; then
    docker_run+=(-v "${BMM_RESOURCES_MERGED_DIR}:/app/resources")
  fi
  docker_run+=("$DOCKER_IMAGE" asciidoc "$MAIN_ID" $DEP_IDS)
  "${docker_run[@]}"

  collect_generated_artifacts "$MAIN_ID" "modules/ROOT/partials"
done

validate_generated_classes "$OUTPUT_DIR"
cleanup_staging_output
cleanup_bmm_resources_merged_dir
trap - EXIT
echo "✓ Generated UML class partials in $OUTPUT_DIR"
echo ""
