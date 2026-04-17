#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/scripts/financial_policy_gate.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

create_repo() {
  local repo_root="$1"
  local include_gap_doc="${2:-true}"

  mkdir -p "$repo_root/.git" "$repo_root/docs"
  cat > "$repo_root/docs/discovered-system-architecture-map.md" <<'MAP'
# map
MAP

  if [[ "$include_gap_doc" == "true" ]]; then
    cat > "$repo_root/docs/production-readiness-gap-analysis.md" <<'GAP'
ledger double-entry append-only
event trace audit
sandbox external integration adapter
GAP
  fi
}

assert_contains() {
  local needle="$1"
  local haystack_file="$2"
  if ! rg -F "$needle" "$haystack_file" >/dev/null; then
    echo "Expected to find: $needle"
    echo "In file: $haystack_file"
    cat "$haystack_file"
    exit 1
  fi
}

# Test 1: current mode should pass for valid repo
REPO_OK="$TMP_DIR/repo-ok"
create_repo "$REPO_OK" true
(
  cd "$REPO_OK"
  STRICT_MODE=true REPORT_FILE="$TMP_DIR/report-current.txt" "$SCRIPT"
)
assert_contains "Total failures: 0" "$TMP_DIR/report-current.txt"

# Test 2: paths mode should evaluate multiple repos and fail when one is missing required doc
REPO_BAD="$TMP_DIR/repo-bad"
create_repo "$REPO_BAD" false
set +e
SCAN_MODE=paths REPO_PATHS="$REPO_OK,$REPO_BAD" STRICT_MODE=true REPORT_FILE="$TMP_DIR/report-paths.txt" "$SCRIPT"
exit_code=$?
set -e
if [[ "$exit_code" -eq 0 ]]; then
  echo "Expected strict mode to fail when repo-bad is missing required docs"
  exit 1
fi
assert_contains "Repositories evaluated: 2" "$TMP_DIR/report-paths.txt"
assert_contains "FAIL [repo-bad]: SECURITY_PASSED baseline governance documentation present" "$TMP_DIR/report-paths.txt"

# Test 3: workspace mode should discover nested repos under workspace root
SCAN_MODE=workspace WORKSPACE_ROOT="$TMP_DIR" STRICT_MODE=false REPORT_FILE="$TMP_DIR/report-workspace.txt" "$SCRIPT"
assert_contains "Repositories evaluated: 2" "$TMP_DIR/report-workspace.txt"

echo "All financial_policy_gate tests passed"
