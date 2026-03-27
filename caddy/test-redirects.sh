#!/usr/bin/env bash
# Test legacy URL redirects against the local Caddy container.
# Run after: docker compose --profile test up caddy

BASE="http://localhost:8081"
PASS=0
FAIL=0
SKIP=0
SKIPPED=()

LIVE="https://specifications.openehr.org"

check() {
  local description="$1"
  local url="$2"
  local expected="$3"

  local old_path="${url#$BASE}"
  local live_status=$(curl -s -o /dev/null -w "%{http_code}" "$LIVE$old_path")

  if [ "$live_status" != "200" ]; then
    ((SKIP++))
    SKIPPED+=("SKIP  $description ($LIVE$old_path → $live_status)")
    return
  fi

  local location=$(curl -s -o /dev/null -w "%{redirect_url}" "$url")
  local status=$(curl -s -o /dev/null -w "%{http_code}" "$url")
  local location_path=$(echo "$location" | sed 's|https\?://[^/]*||')

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

# --- AM latest ---
echo ""
echo "AM (latest):"
check "Overview"       "$BASE/releases/AM/latest/Overview.html"      "/AM/latest/Overview/"
check "ADL1.4"         "$BASE/releases/AM/latest/ADL1.4.html"        "/AM/latest/ADL1.4/"
check "AOM1.4"         "$BASE/releases/AM/latest/AOM1.4.html"        "/AM/latest/AOM1.4/"
check "ADL2"           "$BASE/releases/AM/latest/ADL2.html"          "/AM/latest/ADL2/"
check "AOM2"           "$BASE/releases/AM/latest/AOM2.html"          "/AM/latest/AOM2/"
check "OPT2"           "$BASE/releases/AM/latest/OPT2.html"          "/AM/latest/OPT2/"
check "Identification" "$BASE/releases/AM/latest/Identification.html" "/AM/latest/Identification/"

# --- BASE latest ---
echo ""
echo "BASE (latest):"
check "architecture_overview" "$BASE/releases/BASE/latest/architecture_overview.html" "/BASE/latest/architecture_overview/"
check "base_types"             "$BASE/releases/BASE/latest/base_types.html"            "/BASE/latest/base_types/"
check "foundation_types"       "$BASE/releases/BASE/latest/foundation_types.html"      "/BASE/latest/foundation_types/"
check "resource"               "$BASE/releases/BASE/latest/resource.html"              "/BASE/latest/resource/"

# --- RM latest ---
echo ""
echo "RM (latest):"
check "common"          "$BASE/releases/RM/latest/common.html"          "/RM/latest/common/"
check "data_structures" "$BASE/releases/RM/latest/data_structures.html" "/RM/latest/data_structures/"
check "data_types"      "$BASE/releases/RM/latest/data_types.html"      "/RM/latest/data_types/"
check "demographic"     "$BASE/releases/RM/latest/demographic.html"     "/RM/latest/demographic/"
check "ehr"             "$BASE/releases/RM/latest/ehr.html"             "/RM/latest/ehr/"
check "ehr_extract"     "$BASE/releases/RM/latest/ehr_extract.html"     "/RM/latest/ehr_extract/"
check "integration"     "$BASE/releases/RM/latest/integration.html"     "/RM/latest/integration/"
check "support"         "$BASE/releases/RM/latest/support.html"         "/RM/latest/support/"

# --- LANG latest ---
echo ""
echo "LANG (latest):"
check "bmm"                 "$BASE/releases/LANG/latest/bmm.html"                 "/LANG/latest/bmm/"
check "bmm_persistence"     "$BASE/releases/LANG/latest/bmm_persistence.html"     "/LANG/latest/bmm_persistence/"
check "expression_language" "$BASE/releases/LANG/latest/expression_language.html" "/LANG/latest/expression_language/"
check "odin"                "$BASE/releases/LANG/latest/odin.html"                "/LANG/latest/odin/"

# --- SM latest ---
echo ""
echo "SM (latest):"
check "openehr_platform"     "$BASE/releases/SM/latest/openehr_platform.html"     "/SM/latest/openehr_platform/"
check "simplified_im_b"      "$BASE/releases/SM/latest/simplified_im_b.html"      "/SM/latest/simplified_im_b/"
check "serial_data_formats"  "$BASE/releases/SM/latest/serial_data_formats.html"  "/SM/latest/serial_data_formats/"

# --- QUERY latest ---
echo ""
echo "QUERY (latest):"
check "AQL"          "$BASE/releases/QUERY/latest/AQL.html"          "/QUERY/latest/AQL/"
check "AQL_examples" "$BASE/releases/QUERY/latest/AQL_examples.html" "/QUERY/latest/AQL_examples/"

# --- PROC latest ---
echo ""
echo "PROC (latest):"
check "overview"           "$BASE/releases/PROC/latest/overview.html"           "/PROC/latest/overview/"
check "task_planning"      "$BASE/releases/PROC/latest/task_planning.html"      "/PROC/latest/task_planning/"
check "tp_vml"             "$BASE/releases/PROC/latest/tp_vml.html"             "/PROC/latest/tp_vml/"
check "process_examples"   "$BASE/releases/PROC/latest/process_examples.html"   "/PROC/latest/process_examples/"
check "decision_language"  "$BASE/releases/PROC/latest/decision_language.html"  "/PROC/latest/decision_language/"

# --- CDS latest ---
echo ""
echo "CDS (latest):"
check "GDL"  "$BASE/releases/CDS/latest/GDL.html"  "/CDS/latest/GDL/"
check "GDL2" "$BASE/releases/CDS/latest/GDL2.html" "/CDS/latest/GDL2/"

# --- CNF latest ---
echo ""
echo "CNF (latest):"
check "guide"                   "$BASE/releases/CNF/latest/guide.html"                   "/CNF/latest/guide/"
check "platform_test_schedule"  "$BASE/releases/CNF/latest/platform_test_schedule.html"  "/CNF/latest/platform_test_schedule/"
check "certificate"             "$BASE/releases/CNF/latest/certificate.html"             "/CNF/latest/certificate/"
check "profiles"                "$BASE/releases/CNF/latest/profiles.html"                "/CNF/latest/profiles/"

# --- TERM latest ---
echo ""
echo "TERM (latest):"
check "SupportTerminology" "$BASE/releases/TERM/latest/SupportTerminology.html" "/TERM/latest/SupportTerminology/"

# --- ITS-REST development ---
echo ""
echo "ITS-REST (development):"
check "ehr"                  "$BASE/releases/ITS-REST/development/ehr.html"                  "/ITS-REST/development/ehr/"
check "query"                "$BASE/releases/ITS-REST/development/query.html"                "/ITS-REST/development/query/"
check "definitions"          "$BASE/releases/ITS-REST/development/definitions.html"          "/ITS-REST/development/definitions/"
check "demographic"          "$BASE/releases/ITS-REST/development/demographic.html"          "/ITS-REST/development/demographic/"
check "simplified_formats"   "$BASE/releases/ITS-REST/development/simplified_formats.html"   "/ITS-REST/development/simplified_formats/"
check "smart_app_launch"     "$BASE/releases/ITS-REST/development/smart_app_launch.html"     "/ITS-REST/development/smart_app_launch/"

# ===================================================================
# Release version tests
# ===================================================================

# --- AM releases ---
echo ""
echo "AM releases:"
for version in 2.0.6 2.1.0 2.2.0 2.3.0; do
  for page in Overview ADL1.4 AOM1.4 ADL2 AOM2 OPT2 Identification; do
    check "AM $version $page" "$BASE/releases/AM/$version/$page.html" "/AM/Release-$version/$page/"
  done
done

# --- BASE releases ---
echo ""
echo "BASE releases:"
# 1.0.2 and 1.0.3: only architecture_overview and odin
for version in 1.0.2 1.0.3; do
  for page in architecture_overview odin; do
    check "BASE $version $page" "$BASE/releases/BASE/$version/$page.html" "/BASE/Release-$version/$page/"
  done
done
# 1.0.4: added bmm, bmm_persistence, expression, foundation_types, base_types, resource
for page in architecture_overview base_types bmm bmm_persistence expression foundation_types odin resource; do
  check "BASE 1.0.4 $page" "$BASE/releases/BASE/1.0.4/$page.html" "/BASE/Release-1.0.4/$page/"
done
# 1.1.0 and 1.2.0
for version in 1.1.0 1.2.0; do
  for page in architecture_overview base_types foundation_types resource; do
    check "BASE $version $page" "$BASE/releases/BASE/$version/$page.html" "/BASE/Release-$version/$page/"
  done
done

# --- RM releases ---
echo ""
echo "RM releases:"
for version in 1.0.2 1.0.3 1.0.4 1.1.0; do
  for page in common data_structures data_types demographic ehr ehr_extract integration support; do
    check "RM $version $page" "$BASE/releases/RM/$version/$page.html" "/RM/Release-$version/$page/"
  done
done

# --- LANG releases ---
echo ""
echo "LANG releases:"
for page in bmm bmm_persistence expression_language odin; do
  check "LANG 1.0.0 $page" "$BASE/releases/LANG/1.0.0/$page.html" "/LANG/Release-1.0.0/$page/"
done

# --- QUERY releases ---
echo ""
echo "QUERY releases:"
for version in 1.0.0 1.0.1; do
  check "QUERY $version AQL" "$BASE/releases/QUERY/$version/AQL.html" "/QUERY/Release-$version/AQL/"
done
for page in AQL AQL_examples; do
  check "QUERY 1.1.0 $page" "$BASE/releases/QUERY/1.1.0/$page.html" "/QUERY/Release-1.1.0/$page/"
done

# --- PROC releases ---
echo ""
echo "PROC releases:"
for page in task_planning tp_vml; do
  check "PROC 1.0.0 $page" "$BASE/releases/PROC/1.0.0/$page.html" "/PROC/Release-1.0.0/$page/"
done
for page in decision_language task_planning tp_examples tp_vml; do
  check "PROC 1.5.0 $page" "$BASE/releases/PROC/1.5.0/$page.html" "/PROC/Release-1.5.0/$page/"
done
for version in 1.6.0 1.7.0; do
  for page in decision_language overview process_examples task_planning tp_vml; do
    check "PROC $version $page" "$BASE/releases/PROC/$version/$page.html" "/PROC/Release-$version/$page/"
  done
done

# --- CDS releases ---
echo ""
echo "CDS releases:"
for version in 2.0.0 2.0.1; do
  for page in GDL GDL2; do
    check "CDS $version $page" "$BASE/releases/CDS/$version/$page.html" "/CDS/Release-$version/$page/"
  done
done

# --- ITS-REST releases ---
echo ""
echo "ITS-REST releases:"
for page in definitions ehr query; do
  check "ITS-REST 1.0.0 $page" "$BASE/releases/ITS-REST/1.0.0/$page.html" "/ITS-REST/Release-1.0.0/$page/"
done
for page in definitions ehr query; do
  check "ITS-REST 1.0.1 $page" "$BASE/releases/ITS-REST/1.0.1/$page.html" "/ITS-REST/Release-1.0.1/$page/"
done
for page in definitions ehr overview query simplified_data_template; do
  check "ITS-REST 1.0.2 $page" "$BASE/releases/ITS-REST/1.0.2/$page.html" "/ITS-REST/Release-1.0.2/$page/"
done
for page in definition definitions ehr overview query simplified_data_template; do
  check "ITS-REST 1.0.3 $page" "$BASE/releases/ITS-REST/1.0.3/$page.html" "/ITS-REST/Release-1.0.3/$page/"
done

# ===================================================================
# Results
# ===================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Results: $PASS passed, $FAIL failed, $SKIP skipped"

if [ ${#SKIPPED[@]} -gt 0 ]; then
  echo ""
  echo "Skipped (old URL not found on live site):"
  for s in "${SKIPPED[@]}"; do
    echo "  $s"
  done
fi
echo ""
