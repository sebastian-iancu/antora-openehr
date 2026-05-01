#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_lib.sh"

COMPONENT_NAME="${1:-}"
REPO_NAME="$(basename "$(pwd)")"
MANIFEST_PATH="manifest.json"
OUTPUT_DIR="modules/ROOT/partials/classes"
STAGING_ROOT="modules/ROOT/partials/Adoc"
#
# Docker + host layout
# ---------------------
# Run bmm-publisher as **host UID:GID** (`docker run --user …`) so bind-mounted output is owned by you, not root.
# Mount **modules/ROOT/partials** → **/app/output**. The publisher writes Adoc/<BMM_ID>/{classes,definitions,…,images,plantUML,…}.
#
# Why not bind-mount each subtree straight onto modules/ROOT/partials/<dir> and modules/ROOT/images?
# Any nested Docker bind mount under /app/output/Adoc/… causes bmm-publisher (tested through 0.7.x) to abort with
# `Directory "/app/output/Adoc/" is not writable` (Java writability check). Only a single mount on /app/output works.
#
# So we **promote** output after each run: classes/definitions/effective/BMMs → modules/ROOT/partials/*;
# SVG tree → modules/ROOT/images/*. **plantUML/** and **images/** under Adoc are not copied into partials/plantUML
# (images/ is handled separately; plantUML/ is staging-only and removed with Adoc/).
#
# Pin default tag; override with BMM_PUBLISHER_IMAGE e.g. ghcr.io/openehr/bmm-publisher:0.7.0
# Set BMM_PUBLISHER_AS_ROOT=1 to omit --user (not recommended; leaves root-owned files on mounts).
DOCKER_IMAGE="${BMM_PUBLISHER_IMAGE:-ghcr.io/openehr/bmm-publisher:0.7.0}"
ROOT_IMAGES_DIR="modules/ROOT/images"

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
  # docker cp often leaves root-owned files; publisher runs as host UID and must read /app/resources.
  chmod -R a+rX "${BMM_RESOURCES_MERGED_DIR}" 2>/dev/null || true

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

  # Promote Adoc/<id>/* into ROOT partials (except images/ → ROOT images; plantUML/ not kept under partials/).
  if [ -d "$generated_root" ]; then
    local item name rel dest
    for item in "$generated_root"/*; do
      [ -e "$item" ] || continue
      name="$(basename "$item")"
      if [[ "$name" == "images" || "$name" == "plantUML" ]]; then
        continue
      fi
      dest="${target_root}/${name}"
      mkdir -p "$dest"

      while IFS= read -r -d '' rel; do
        [[ "$rel" == *.puml ]] && continue
        if [ -d "$item/$rel" ]; then
          mkdir -p "$dest/$rel"
        else
          mkdir -p "$(dirname "$dest/$rel")"
          cp -f -- "$item/$rel" "$dest/$rel"
        fi
      done < <(cd "$item" && find . -mindepth 1 -print0)

      find "$dest" -type f -name '*.puml' -delete 2>/dev/null || true
    done
  fi
}

collect_generated_publisher_images() {
  local main_id="$1"
  local dest_images_root="$2"
  local src="${STAGING_ROOT}/${main_id}/images"

  [ -d "$src" ] || return 0

  local f rel copied=0
  while IFS= read -r -d '' f; do
    rel="${f#"${src}/"}"
    mkdir -p "$(dirname "${dest_images_root}/${rel}")"
    cp -f -- "$f" "${dest_images_root}/${rel}"
    copied=$((copied + 1))
  done < <(find "$src" -type f \( -name '*.svg' -o -name '*.SVG' \) -print0 2>/dev/null)

  if [ "$copied" -gt 0 ]; then
    echo "  • publisher SVGs ($copied files) → ${dest_images_root}/ (from Adoc/${main_id}/images/)"
  fi
}

cleanup_staging_output() {
  rm_rf_repo_path "modules/ROOT/partials/.bmm-output-scratch"
  rm_rf_repo_path "$STAGING_ROOT"
}

is_tracked_path() {
  local path="$1"
  git ls-files --error-unmatch "$path" >/dev/null 2>&1
}

remove_legacy_class_file() {
  local path="$1"
  [ -f "$path" ] || return 0
  if is_tracked_path "$path"; then
    git rm -f -- "$path" >/dev/null
  else
    rm -f -- "$path"
  fi
}

cleanup_empty_parent_dirs() {
  local dir="$1"
  while [ -n "$dir" ] && [ "$dir" != "." ] && [ "$dir" != "/" ]; do
    rmdir "$dir" 2>/dev/null || break
    dir="$(dirname "$dir")"
  done
}

reconcile_legacy_class_files() {
  local output_dir="$1"
  local mapped=0
  local removed=0

  # Legacy class files historically lived under docs/**/UML/classes/*.adoc.
  local -a legacy_files=()
  while IFS= read -r f; do
    legacy_files+=("$f")
  done < <(find docs -type f -path "*/[Uu][Mm][Ll]/classes/*.adoc" 2>/dev/null | sort)

  [ "${#legacy_files[@]}" -gt 0 ] || return 0

  declare -A legacy_for_name
  local lf base
  for lf in "${legacy_files[@]}"; do
    base="$(basename "$lf")"
    # Keep first match deterministically (sorted order).
    if [ -z "${legacy_for_name[$base]:-}" ]; then
      legacy_for_name[$base]="$lf"
    fi
  done

  local generated generated_tmp legacy
  for generated in "$output_dir"/*.adoc; do
    [ -f "$generated" ] || continue
    base="$(basename "$generated")"
    legacy="${legacy_for_name[$base]:-}"
    [ -n "$legacy" ] || continue
    [ -f "$legacy" ] || continue

    generated_tmp="${generated}.generated-tmp"
    mv -f -- "$generated" "$generated_tmp"
    git_move_preserve_history "$legacy" "$generated"
    mv -f -- "$generated_tmp" "$generated"
    cleanup_empty_parent_dirs "$(dirname "$legacy")"
    unset 'legacy_for_name[$base]'
    mapped=$((mapped + 1))
    echo "  • legacy class mapped via git mv: $legacy → $generated"
  done

  # Remove remaining legacy class files that do not map 1:1 to new outputs.
  for lf in "${legacy_files[@]}"; do
    [ -f "$lf" ] || continue
    remove_legacy_class_file "$lf"
    cleanup_empty_parent_dirs "$(dirname "$lf")"
    removed=$((removed + 1))
  done

  if [ "$mapped" -gt 0 ] || [ "$removed" -gt 0 ]; then
    echo "→ Legacy UML class cleanup: mapped=$mapped, removed=$removed"
  fi
}

echo "Step 3a: Generating UML class partials via bmm-publisher..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ! -f "$MANIFEST_PATH" ]; then
  echo "No manifest.json found in $(pwd); skipping bmm-publisher generation."
  echo ""
  exit 0
fi

mkdir -p "$OUTPUT_DIR" \
  modules/ROOT/partials/definitions \
  modules/ROOT/partials/effective \
  modules/ROOT/partials/BMMs \
  "$ROOT_IMAGES_DIR"
rm -f "$OUTPUT_DIR"/*.adoc
# Regenerated publisher SVG outputs only (do not remove other ROOT/images assets).
rm -rf "${ROOT_IMAGES_DIR}/uml/classes" "${ROOT_IMAGES_DIR}/uml/diagrams" 2>/dev/null || true

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

  docker_run=(docker run --rm)
  if [[ -z "${BMM_PUBLISHER_AS_ROOT:-}" ]]; then
    docker_run+=(--user "$(id -u):$(id -g)" -e HOME=/tmp)
  fi
  docker_run+=(-v "$(pwd)/modules/ROOT/partials:/app/output")
  if [[ -n "${BMM_RESOURCES_MERGED_DIR:-}" ]]; then
    docker_run+=(-v "${BMM_RESOURCES_MERGED_DIR}:/app/resources")
  fi
  docker_run+=("$DOCKER_IMAGE" asciidoc "$MAIN_ID" $DEP_IDS)
  "${docker_run[@]}"

  collect_generated_artifacts "$MAIN_ID" "modules/ROOT/partials"
  collect_generated_publisher_images "$MAIN_ID" "$ROOT_IMAGES_DIR"
done

validate_generated_classes "$OUTPUT_DIR"
reconcile_legacy_class_files "$OUTPUT_DIR"
cleanup_staging_output
cleanup_bmm_resources_merged_dir
trap - EXIT
echo "✓ Generated UML class partials in $OUTPUT_DIR"
if find "${ROOT_IMAGES_DIR}/uml" -type f -name '*.svg' 2>/dev/null | read -r _; then
  echo "✓ Publisher SVG assets under ${ROOT_IMAGES_DIR}/uml/"
fi
echo ""
