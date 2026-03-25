#!/usr/bin/env bash
# Test legacy URL redirects against the local nginx container.
# Run after: docker compose --profile test up nginx

BASE="http://localhost:8081"
PASS=0
FAIL=0

LIVE="https://specifications.openehr.org"

check() {
  local description="$1"
  local url="$2"
  local expected="$3"

  # Derive the old path from the local test URL and check it on the live site
  local old_path="${url#$BASE}"
  local live_status=$(curl -s -o /dev/null -w "%{http_code}" "$LIVE$old_path")

  if [ "$live_status" != "200" ]; then
    echo "  SKIP  $description (old URL returned $live_status on live site)"
    return
  fi

  # Old URL exists — now check our local nginx redirect
  location=$(curl -s -o /dev/null -w "%{redirect_url}" "$url")
  status=$(curl -s -o /dev/null -w "%{http_code}" "$url")

  # Compare only the path — nginx returns its internal host/port (80), not the mapped one (8081)
  location_path=$(echo "$location" | sed 's|https\?://[^/]*||')

  if [ "$status" = "301" ] && [ "$location_path" = "$expected" ]; then
    echo "  PASS  $description"
    ((PASS++))
  else
    echo "  FAIL  $description"
    echo "        expected 301 -> $expected"
    echo "        got      $status -> $location_path"
    ((FAIL++))
  fi
}

echo ""
echo "Testing legacy URL redirects..."
echo ""

# --- Version format types ---
echo "Version formats:"
check "bare numeric version"         "$BASE/releases/AM/2.2.0/AOM2.html"                  "/AM/Release-2.2.0/AOM2/"
check "Release- prefixed version"    "$BASE/releases/RM/Release-1.0.3/support.html"        "/RM/Release-1.0.3/support/"
check "latest"                       "$BASE/releases/AM/latest/AOM2.html"                  "/AM/latest/AOM2/"
check "development"                  "$BASE/releases/AM/development/AOM2.html"             "/AM/development/AOM2/"

# --- AM ---
echo ""
echo "AM:"
check "Overview"                     "$BASE/releases/AM/latest/Overview.html"              "/AM/latest/Overview/"
check "ADL1.4"                       "$BASE/releases/AM/latest/ADL1.4.html"                "/AM/latest/ADL1.4/"
check "AOM1.4"                       "$BASE/releases/AM/latest/AOM1.4.html"                "/AM/latest/AOM1.4/"
check "ADL2"                         "$BASE/releases/AM/latest/ADL2.html"                  "/AM/latest/ADL2/"
check "AOM2"                         "$BASE/releases/AM/latest/AOM2.html"                  "/AM/latest/AOM2/"
check "OPT2"                         "$BASE/releases/AM/latest/OPT2.html"                  "/AM/latest/OPT2/"
check "Identification"               "$BASE/releases/AM/latest/Identification.html"        "/AM/latest/Identification/"

# --- BASE ---
echo ""
echo "BASE:"
check "base_types"                   "$BASE/releases/BASE/latest/base_types.html"          "/BASE/latest/base_types/"
check "foundation_types"             "$BASE/releases/BASE/latest/foundation_types.html"    "/BASE/latest/foundation_types/"
check "resource"                     "$BASE/releases/BASE/latest/resource.html"            "/BASE/latest/resource/"
check "architecture_overview"        "$BASE/releases/BASE/latest/architecture_overview.html" "/BASE/latest/architecture_overview/"
check "expression (Release-1.0.4)"  "$BASE/releases/BASE/Release-1.0.4/expression.html"  "/BASE/Release-1.0.4/expression/"

# --- RM ---
echo ""
echo "RM:"
check "data_types"                   "$BASE/releases/RM/latest/data_types.html"            "/RM/latest/data_types/"
check "data_structures"              "$BASE/releases/RM/latest/data_structures.html"       "/RM/latest/data_structures/"
check "common"                       "$BASE/releases/RM/latest/common.html"                "/RM/latest/common/"
check "demographic"                  "$BASE/releases/RM/latest/demographic.html"           "/RM/latest/demographic/"
check "ehr"                          "$BASE/releases/RM/latest/ehr.html"                   "/RM/latest/ehr/"
check "ehr_extract"                  "$BASE/releases/RM/latest/ehr_extract.html"           "/RM/latest/ehr_extract/"
check "integration"                  "$BASE/releases/RM/latest/integration.html"           "/RM/latest/integration/"
check "support"                      "$BASE/releases/RM/latest/support.html"               "/RM/latest/support/"
check "entity"                       "$BASE/releases/RM/development/entity.html"           "/RM/development/entity/"
check "support (Release-1.0.3)"     "$BASE/releases/RM/Release-1.0.3/support.html"        "/RM/Release-1.0.3/support/"
check "common (Release-1.0.3)"      "$BASE/releases/RM/Release-1.0.3/common.html"         "/RM/Release-1.0.3/common/"
check "data_types (Release-1.0.3)"  "$BASE/releases/RM/Release-1.0.3/data_types.html"     "/RM/Release-1.0.3/data_types/"

# --- LANG ---
echo ""
echo "LANG:"
check "odin"                         "$BASE/releases/LANG/latest/odin.html"                "/LANG/latest/odin/"
check "bmm"                          "$BASE/releases/LANG/latest/bmm.html"                 "/LANG/latest/bmm/"
check "bmm_persistence"              "$BASE/releases/LANG/latest/bmm_persistence.html"     "/LANG/latest/bmm_persistence/"
check "BEL"                          "$BASE/releases/LANG/development/BEL.html"                 "/LANG/development/BEL/"
check "EL"                           "$BASE/releases/LANG/development/EL.html"                  "/LANG/development/EL/"

# --- SM ---
echo ""
echo "SM:"
check "openehr_platform"             "$BASE/releases/SM/latest/openehr_platform.html"      "/SM/latest/openehr_platform/"
check "simplified_im_b"             "$BASE/releases/SM/latest/simplified_im_b.html"       "/SM/latest/simplified_im_b/"
check "serial_data_formats"         "$BASE/releases/SM/latest/serial_data_formats.html"   "/SM/latest/serial_data_formats/"

# --- QUERY ---
echo ""
echo "QUERY:"
check "AQL"                          "$BASE/releases/QUERY/latest/AQL.html"                "/QUERY/latest/AQL/"
check "AQL_examples"                 "$BASE/releases/QUERY/latest/AQL_examples.html"       "/QUERY/latest/AQL_examples/"

# --- PROC ---
echo ""
echo "PROC:"
check "overview"                     "$BASE/releases/PROC/latest/overview.html"            "/PROC/latest/overview/"
check "task_planning"                "$BASE/releases/PROC/latest/task_planning.html"       "/PROC/latest/task_planning/"
check "tp_vml"                       "$BASE/releases/PROC/latest/tp_vml.html"              "/PROC/latest/tp_vml/"
check "process_examples"             "$BASE/releases/PROC/latest/process_examples.html"    "/PROC/latest/process_examples/"
check "decision_language"            "$BASE/releases/PROC/latest/decision_language.html"   "/PROC/latest/decision_language/"

# --- CDS ---
echo ""
echo "CDS:"
check "GDL"                          "$BASE/releases/CDS/latest/GDL.html"                  "/CDS/latest/GDL/"
check "GDL2"                         "$BASE/releases/CDS/latest/GDL2.html"                 "/CDS/latest/GDL2/"

# --- CNF ---
echo ""
echo "CNF:"
check "guide"                        "$BASE/releases/CNF/latest/guide.html"                "/CNF/latest/guide/"
check "platform_test_schedule"       "$BASE/releases/CNF/latest/platform_test_schedule.html" "/CNF/latest/platform_test_schedule/"
check "certificate"                  "$BASE/releases/CNF/latest/certificate.html"          "/CNF/latest/certificate/"
check "profiles"                     "$BASE/releases/CNF/latest/profiles.html"             "/CNF/latest/profiles/"

# --- TERM ---
echo ""
echo "TERM:"
check "SupportTerminology"           "$BASE/releases/TERM/latest/SupportTerminology.html"  "/TERM/latest/SupportTerminology/"

# --- ITS-REST ---
echo ""
echo "ITS-REST:"
check "ehr"                          "$BASE/releases/ITS-REST/development/ehr.html"        "/ITS-REST/development/ehr/"
check "query"                        "$BASE/releases/ITS-REST/development/query.html"      "/ITS-REST/development/query/"
check "definitions"                  "$BASE/releases/ITS-REST/development/definitions.html" "/ITS-REST/development/definitions/"
check "demographic"                  "$BASE/releases/ITS-REST/development/demographic.html" "/ITS-REST/development/demographic/"
check "simplified_formats"           "$BASE/releases/ITS-REST/development/simplified_formats.html" "/ITS-REST/development/simplified_formats/"
check "smart_app_launch"             "$BASE/releases/ITS-REST/development/smart_app_launch.html" "/ITS-REST/development/smart_app_launch/"

# -------------------------------------------------------------------
# Version-specific tests (derived from release branches in the repos)
# -------------------------------------------------------------------

echo ""
echo "AM versions:"
check "AM 2.0.6 AOM2"          "$BASE/releases/AM/2.0.6/AOM2.html"           "/AM/Release-2.0.6/AOM2/"
check "AM 2.1.0 AOM2"          "$BASE/releases/AM/2.1.0/AOM2.html"           "/AM/Release-2.1.0/AOM2/"
check "AM 2.2.0 AOM2"          "$BASE/releases/AM/2.2.0/AOM2.html"           "/AM/Release-2.2.0/AOM2/"
check "AM 2.3.0 AOM2"          "$BASE/releases/AM/2.3.0/AOM2.html"           "/AM/Release-2.3.0/AOM2/"

echo ""
echo "BASE versions:"
check "BASE 1.0.2 architecture_overview"  "$BASE/releases/BASE/1.0.2/architecture_overview.html"  "/BASE/Release-1.0.2/architecture_overview/"
check "BASE 1.0.3 architecture_overview"  "$BASE/releases/BASE/1.0.3/architecture_overview.html"  "/BASE/Release-1.0.3/architecture_overview/"
check "BASE 1.0.4 foundation_types"  "$BASE/releases/BASE/1.0.4/foundation_types.html"  "/BASE/Release-1.0.4/foundation_types/"
check "BASE 1.1.0 foundation_types"  "$BASE/releases/BASE/1.1.0/foundation_types.html"  "/BASE/Release-1.1.0/foundation_types/"
check "BASE 1.2.0 foundation_types"  "$BASE/releases/BASE/1.2.0/foundation_types.html"  "/BASE/Release-1.2.0/foundation_types/"

echo ""
echo "RM versions:"
check "RM 1.0.2 data_types"    "$BASE/releases/RM/1.0.2/data_types.html"     "/RM/Release-1.0.2/data_types/"
check "RM 1.0.3 data_types"    "$BASE/releases/RM/1.0.3/data_types.html"     "/RM/Release-1.0.3/data_types/"
check "RM 1.0.4 data_types"    "$BASE/releases/RM/1.0.4/data_types.html"     "/RM/Release-1.0.4/data_types/"
check "RM 1.1.0 data_types"    "$BASE/releases/RM/1.1.0/data_types.html"     "/RM/Release-1.1.0/data_types/"

echo ""
echo "LANG versions:"
check "LANG 1.0.0 bmm"         "$BASE/releases/LANG/1.0.0/bmm.html"          "/LANG/Release-1.0.0/bmm/"

echo ""
echo "PROC versions:"
check "PROC 1.0.0 task_planning"  "$BASE/releases/PROC/1.0.0/task_planning.html"  "/PROC/Release-1.0.0/task_planning/"
check "PROC 1.5.0 task_planning"  "$BASE/releases/PROC/1.5.0/task_planning.html"  "/PROC/Release-1.5.0/task_planning/"
check "PROC 1.6.0 task_planning"  "$BASE/releases/PROC/1.6.0/task_planning.html"  "/PROC/Release-1.6.0/task_planning/"

echo ""
echo "QUERY versions:"
check "QUERY 1.0.0 AQL"        "$BASE/releases/QUERY/1.0.0/AQL.html"         "/QUERY/Release-1.0.0/AQL/"
check "QUERY 1.1.0 AQL"        "$BASE/releases/QUERY/1.1.0/AQL.html"         "/QUERY/Release-1.1.0/AQL/"

echo ""
echo "ITS-REST versions:"
check "ITS-REST 1.0.x ehr"     "$BASE/releases/ITS-REST/1.0.x/ehr.html"      "/ITS-REST/Release-1.0.x/ehr/"

echo ""
echo "Results: $PASS passed, $FAIL failed"
echo ""
