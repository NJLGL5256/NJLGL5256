#!/usr/bin/env bash
set -euo pipefail

REPORT_FILE="${REPORT_FILE:-financial-readiness-report.txt}"
STRICT_MODE="${STRICT_MODE:-true}"
SCAN_MODE="${SCAN_MODE:-current}" # current | workspace | paths
WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(pwd)}"
REPO_PATHS="${REPO_PATHS:-}"
CREDENTIAL_ENFORCEMENT="${CREDENTIAL_ENFORCEMENT:-false}"
REQUIRED_CREDENTIAL_ENVS="${REQUIRED_CREDENTIAL_ENVS:-OPENAI_API_KEY}"

fail_count=0
repo_count=0

pass() {
  local repo_label="$1"
  local message="$2"
  printf "PASS [%s]: %s\n" "$repo_label" "$message" | tee -a "$REPORT_FILE"
}

fail() {
  local repo_label="$1"
  local message="$2"
  printf "FAIL [%s]: %s\n" "$repo_label" "$message" | tee -a "$REPORT_FILE"
  fail_count=$((fail_count + 1))
}

check_file_exists() {
  local repo_root="$1"
  local repo_label="$2"
  local file="$3"
  local label="$4"

  if [[ -f "$repo_root/$file" ]]; then
    pass "$repo_label" "$label"
    return 0
  fi

  fail "$repo_label" "$label (missing: $file)"
  return 1
}

check_required_credentials() {
  if [[ "$CREDENTIAL_ENFORCEMENT" != "true" ]]; then
    printf "Credential enforcement: disabled\n" | tee -a "$REPORT_FILE"
    return 0
  fi

  local credential
  local missing=0
  while IFS= read -r credential; do
    [[ -z "$credential" ]] && continue
    if [[ -n "${!credential:-}" ]]; then
      pass "global" "CREDENTIAL_AVAILABLE $credential"
    else
      fail "global" "CREDENTIAL_AVAILABLE $credential (missing env var)"
      missing=1
    fi
  done < <(printf "%s" "$REQUIRED_CREDENTIAL_ENVS" | tr ',' '\n' | sed 's#^[[:space:]]*##; s#[[:space:]]*$##' | awk 'NF')

  return "$missing"
}

run_repo_checks() {
  local repo_root="$1"
  local repo_label
  repo_label="$(basename "$repo_root")"

  repo_count=$((repo_count + 1))

  printf "\n=== Repository: %s (%s) ===\n" "$repo_label" "$repo_root" | tee -a "$REPORT_FILE"

  check_file_exists "$repo_root" "$repo_label" "docs/discovered-system-architecture-map.md" "BUILD_VERIFIED baseline discovery map present"

  if ! check_file_exists "$repo_root" "$repo_label" "docs/production-readiness-gap-analysis.md" "SECURITY_PASSED baseline governance documentation present"; then
    return
  fi

  if rg -n "ledger|double-entry|append-only" "$repo_root/docs/production-readiness-gap-analysis.md" >/dev/null 2>&1; then
    pass "$repo_label" "LEDGER_VALIDATED policy context declared"
  else
    fail "$repo_label" "LEDGER_VALIDATED policy context missing"
  fi

  if rg -n "event|trace|audit" "$repo_root/docs/production-readiness-gap-analysis.md" >/dev/null 2>&1; then
    pass "$repo_label" "EVENT_PIPELINE_ACTIVE policy context declared"
  else
    fail "$repo_label" "EVENT_PIPELINE_ACTIVE policy context missing"
  fi

  if rg -n "sandbox|external integration|adapter" "$repo_root/docs/production-readiness-gap-analysis.md" >/dev/null 2>&1; then
    pass "$repo_label" "PAYMENT_SANDBOX_VERIFIED policy context declared"
  else
    fail "$repo_label" "PAYMENT_SANDBOX_VERIFIED policy context missing"
  fi

  if rg -n "audit" "$repo_root/docs/production-readiness-gap-analysis.md" >/dev/null 2>&1; then
    pass "$repo_label" "AUDIT_PIPELINE_ACTIVE policy context declared"
  else
    fail "$repo_label" "AUDIT_PIPELINE_ACTIVE policy context missing"
  fi
}

collect_repositories() {
  case "$SCAN_MODE" in
    current)
      printf "%s\n" "$(pwd)"
      ;;
    workspace)
      find "$WORKSPACE_ROOT" -maxdepth 4 -type d -name .git -print | sed 's#/.git$##' | sort -u
      ;;
    paths)
      if [[ -z "$REPO_PATHS" ]]; then
        printf "REPO_PATHS is required when SCAN_MODE=paths\n" >&2
        exit 2
      fi
      printf "%s" "$REPO_PATHS" | tr ',' '\n' | sed 's#^[[:space:]]*##; s#[[:space:]]*$##' | awk 'NF' | sort -u
      ;;
    *)
      printf "Unsupported SCAN_MODE: %s\n" "$SCAN_MODE" >&2
      exit 2
      ;;
  esac
}

# Reset report
: > "$REPORT_FILE"
printf "Production Readiness Assessment - %s\n" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" | tee -a "$REPORT_FILE"
printf "Scan mode: %s\n" "$SCAN_MODE" | tee -a "$REPORT_FILE"
printf "Workspace root: %s\n" "$WORKSPACE_ROOT" | tee -a "$REPORT_FILE"
printf "Credential enforcement: %s\n" "$CREDENTIAL_ENFORCEMENT" | tee -a "$REPORT_FILE"

while IFS= read -r repo; do
  [[ -z "$repo" ]] && continue

  if [[ ! -d "$repo" ]]; then
    fail "global" "Repository path does not exist: $repo"
    continue
  fi

  run_repo_checks "$repo"
done < <(collect_repositories)

check_required_credentials || true

printf "\nRepositories evaluated: %d\n" "$repo_count" | tee -a "$REPORT_FILE"
printf "Total failures: %d\n" "$fail_count" | tee -a "$REPORT_FILE"

if [[ "$STRICT_MODE" == "true" && "$fail_count" -gt 0 ]]; then
  exit 1
fi
