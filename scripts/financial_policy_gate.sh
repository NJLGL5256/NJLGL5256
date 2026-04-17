#!/usr/bin/env bash
set -euo pipefail

REPORT_FILE="financial-readiness-report.txt"
STRICT_MODE="${STRICT_MODE:-true}"

fail_count=0

pass() {
  printf "PASS: %s\n" "$1" | tee -a "$REPORT_FILE"
}

fail() {
  printf "FAIL: %s\n" "$1" | tee -a "$REPORT_FILE"
  fail_count=$((fail_count + 1))
}

check_file_exists() {
  local file="$1"
  local label="$2"
  if [[ -f "$file" ]]; then
    pass "$label"
  else
    fail "$label (missing: $file)"
  fi
}

# Reset report
: > "$REPORT_FILE"
printf "Production Readiness Assessment - %s\n" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" | tee -a "$REPORT_FILE"
printf "Repository: %s\n\n" "$(basename "$(pwd)")" | tee -a "$REPORT_FILE"

# State-machine aligned checks
check_file_exists "docs/discovered-system-architecture-map.md" "BUILD_VERIFIED baseline discovery map present"
check_file_exists "docs/production-readiness-gap-analysis.md" "SECURITY_PASSED baseline governance documentation present"

if rg -n "ledger|double-entry|append-only" docs/production-readiness-gap-analysis.md >/dev/null 2>&1; then
  pass "LEDGER_VALIDATED policy context declared"
else
  fail "LEDGER_VALIDATED policy context missing"
fi

if rg -n "event|trace|audit" docs/production-readiness-gap-analysis.md >/dev/null 2>&1; then
  pass "EVENT_PIPELINE_ACTIVE policy context declared"
else
  fail "EVENT_PIPELINE_ACTIVE policy context missing"
fi

if rg -n "sandbox|external integration|adapter" docs/production-readiness-gap-analysis.md >/dev/null 2>&1; then
  pass "PAYMENT_SANDBOX_VERIFIED policy context declared"
else
  fail "PAYMENT_SANDBOX_VERIFIED policy context missing"
fi

if rg -n "audit" docs/production-readiness-gap-analysis.md >/dev/null 2>&1; then
  pass "AUDIT_PIPELINE_ACTIVE policy context declared"
else
  fail "AUDIT_PIPELINE_ACTIVE policy context missing"
fi

printf "\nTotal failures: %d\n" "$fail_count" | tee -a "$REPORT_FILE"

if [[ "$STRICT_MODE" == "true" && "$fail_count" -gt 0 ]]; then
  exit 1
fi
