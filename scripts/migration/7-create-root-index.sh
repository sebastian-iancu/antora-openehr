#!/bin/bash
set -e

# Usage: 7-create-root-index.sh <COMPONENT_NAME> <module1> <module2> ...

COMPONENT_NAME="$1"
shift
MODULES="$@"

echo "Step 7: Creating ROOT index page..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

mkdir -p "modules/ROOT/pages"
mkdir -p "modules/ROOT/images"

# Copy block diagram if available
if [ -f "docs/openehr_block_diagram.svg" ]; then
  cp "docs/openehr_block_diagram.svg" "modules/ROOT/images/"
  echo "  • Copied openehr_block_diagram.svg to ROOT/images/"
fi

# Component descriptions — written per component, not derived from manifest
declare -A COMPONENT_DESC
COMPONENT_DESC["AM"]="Defines the formalism for building clinical content models. Specifies the Archetype Definition Language (ADL), Archetype Object Model (AOM), archetype identification and versioning, and operational templates. AOM 2 is adopted as ISO 13606-2:2019."
COMPONENT_DESC["BASE"]="Foundation of the openEHR specification stack. Covers the global Architecture Overview, primitive and structured types (Boolean, Interval, Date/Time), identifiers (UUIDs, object references, version IDs), and the Resource model for authored, translatable documents."
COMPONENT_DESC["RM"]="Core information model of openEHR: EHR structure, demographic model, data types (quantities, coded text, date/times), data structures (lists, tables, trees), and the EHR Extract model. Archetypes constrain RM instances to express domain content."
COMPONENT_DESC["LANG"]="Formal language specifications shared across openEHR: ODIN (Object Data Instance Notation for serialisation), BMM (Basic Meta-Model for defining information models), BMM persistence format, and expression languages BEL and EL."
COMPONENT_DESC["QUERY"]="Archetype Query Language (AQL) — an SQL-like language for retrieving openEHR data using archetype paths as the addressing mechanism. Includes the formal specification and annotated query examples."
COMPONENT_DESC["PROC"]="Task Planning model for encoding adaptive, executable, team-based clinical workflows. Includes the TP-VML visual notation for designing care plans, a decision rule language, and real-world clinical process examples."
COMPONENT_DESC["CDS"]="Guideline Definition Language v2 (GDL2) for encoding computable clinical guidelines and decision rules. GDL2 rules operate on openEHR archetypes and can be evaluated at the point of care to drive clinical decision support."
COMPONENT_DESC["CNF"]="Framework for certifying openEHR platform implementations. Defines conformance profiles, test cases per REST API endpoint, and a certificate scheme for verifying vendor compliance against the openEHR specifications."
COMPONENT_DESC["SM"]="Abstract service interfaces for a complete openEHR platform, covering EHR, Query, Definitions, Demographics, Admin, and Terminology services. Includes the Simplified Information Model (SIM-B) and serial data formats for REST contexts."
COMPONENT_DESC["ITS-REST"]="OpenAPI specifications for the openEHR REST APIs: EHR, Query, Definition, System, Demographic, Admin, and SMART on openEHR. The core APIs (EHR, Query, Definition) are stable and in production use across implementations."
COMPONENT_DESC["ITS-XML"]="XSD schemas for validating XML-encoded openEHR data, covering the Reference Model, Archetype Model (AM 1.4 and AM 2), BASE types, and AQL query structures."
COMPONENT_DESC["ITS-JSON"]="JSON Schema definitions for validating JSON-encoded openEHR data across all information models. Used by implementations to verify request and response payloads against the REST APIs."
COMPONENT_DESC["ITS-BMM"]="Machine-readable BMM schemas for openEHR information models. Used by modelling tools and validators to load, introspect, and validate the structure of openEHR model definitions."

# Read manifest
if [ ! -f "manifest.json" ]; then
  echo "  ⚠ No manifest.json found, creating minimal index"
  cat > "modules/ROOT/pages/index.adoc" << EOF
= $COMPONENT_NAME Component

EOF
  for module in $MODULES; do
    MODULE_TITLE=$(echo "$module" | sed 's/_/ /g' | sed 's/\b\(.\)/\u\1/g')
    echo "* xref:$module:index.adoc[$MODULE_TITLE]" >> "modules/ROOT/pages/index.adoc"
  done
  echo "✓ Created ROOT index page"
  echo ""
  exit 0
fi

MANIFEST_TITLE=$(jq -r '.title // empty' manifest.json)
DESC="${COMPONENT_DESC[$COMPONENT_NAME]}"
COMPONENT_STATUS=$(jq -r '.status // "STABLE"' manifest.json | tr '[:lower:]' '[:upper:]')
COMPONENT_STATUS_CLASS=$(echo "$COMPONENT_STATUS" | tr '[:upper:]' '[:lower:]')
COMPONENT_STATUS_BADGE="[.spec-status.spec-status-${COMPONENT_STATUS_CLASS}]#${COMPONENT_STATUS}#"

# Build index.adoc
{
  echo "= $MANIFEST_TITLE"
  echo ""
  echo "[.specmeta%autowidth,cols=\"1,1\",frame=all,grid=all]"
  echo "|==="
  echo "| *Release*: {page-component-version} | *Status*: $COMPONENT_STATUS_BADGE"
  echo "|==="
  echo ""

  if [ -f "modules/ROOT/images/openehr_block_diagram.svg" ]; then
    echo "image::openehr_block_diagram.svg[openEHR $MANIFEST_TITLE block diagram,role=block-diagram]"
    echo ""
  fi

  if [ -n "$DESC" ]; then
    echo "$DESC"
    echo ""
  fi

  echo "== Specifications"
  echo ""

  # Specs in manifest order, filtered to modules that exist
  MANIFEST_MODULES=$(jq -r '.specifications[] | select(.id != null) | .id' manifest.json)
  ADDED_MODULES=""

  for mod_id in $MANIFEST_MODULES; do
    if [[ " $MODULES " =~ " $mod_id " ]]; then
      MODULE_TITLE=$(jq -r ".specifications[] | select(.id == \"$mod_id\") | .title" manifest.json)
      SPEC_STATUS=$(jq -r ".specifications[] | select(.id == \"$mod_id\") | .spec_status" manifest.json)
      MICRO=$(jq -r ".specifications[] | select(.id == \"$mod_id\") | .micro_summary // empty" manifest.json)
      STATUS_LABEL=""
      case "$SPEC_STATUS" in
        DEVELOPMENT) STATUS_LABEL=" _(development)_" ;;
        TRIAL)       STATUS_LABEL=" _(trial)_" ;;
        RETIRED)     STATUS_LABEL=" _(retired)_" ;;
        PAUSED)      STATUS_LABEL=" _(paused)_" ;;
      esac
      if [ -n "$MICRO" ]; then
        echo "* xref:$mod_id:index.adoc[$MODULE_TITLE]$STATUS_LABEL — $MICRO"
      else
        echo "* xref:$mod_id:index.adoc[$MODULE_TITLE]$STATUS_LABEL"
      fi
      ADDED_MODULES="$ADDED_MODULES $mod_id"
    fi
  done

  # Modules not in manifest
  for module in $MODULES; do
    if [[ ! " $ADDED_MODULES " =~ " $module " ]]; then
      MODULE_TITLE=$(echo "$module" | sed 's/_/ /g' | sed 's/\b\(.\)/\u\1/g')
      echo "* xref:$module:index.adoc[$MODULE_TITLE]"
    fi
  done

} > "modules/ROOT/pages/index.adoc"

echo "✓ Created ROOT index page"
echo ""
