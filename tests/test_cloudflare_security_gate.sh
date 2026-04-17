#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/scripts/cloudflare_security_gate.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

create_repo() {
  local repo_root="$1"
  local compliant="${2:-true}"
  local inject_secret="${3:-false}"

  mkdir -p "$repo_root/.git" "$repo_root/security"

  if [[ "$compliant" == "true" ]]; then
    cat > "$repo_root/security/cloudflare_controls.env" <<'CFG'
DNS_PROXIED=true
SSL_MODE=strict
MIN_TLS_VERSION=1.2
ALWAYS_USE_HTTPS=true
HSTS_ENABLED=true
WAF_MANAGED_RULES=true
RATE_LIMITING=true
BOT_PROTECTION=true
ORIGIN_CERT_ROTATION_DAYS=90
LAST_REVIEW_DATE=2026-04-17
CFG
  else
    cat > "$repo_root/security/cloudflare_controls.env" <<'CFG'
DNS_PROXIED=false
SSL_MODE=flexible
MIN_TLS_VERSION=1.0
ALWAYS_USE_HTTPS=false
HSTS_ENABLED=false
WAF_MANAGED_RULES=false
RATE_LIMITING=false
BOT_PROTECTION=false
ORIGIN_CERT_ROTATION_DAYS=365
LAST_REVIEW_DATE=not-a-date
CFG
  fi

  if [[ "$inject_secret" == "true" ]]; then
    mkdir -p "$repo_root/app"
    echo 'AWS_KEY="AKIAABCDEFGHIJKLMNOP"' > "$repo_root/app/secrets.py"
  fi
}

assert_contains() {
  local needle="$1"
  local file="$2"
  if ! rg -F "$needle" "$file" >/dev/null; then
    echo "Expected to find: $needle"
    echo "In: $file"
    cat "$file"
    exit 1
  fi
}

REPO_OK="$TMP_DIR/repo-ok"
create_repo "$REPO_OK" true false
(
  cd "$REPO_OK"
  STRICT_MODE=true REPORT_FILE="$TMP_DIR/current.txt" "$SCRIPT"
)
assert_contains "Total failures: 0" "$TMP_DIR/current.txt"

REPO_BAD="$TMP_DIR/repo-bad"
create_repo "$REPO_BAD" false false
set +e
SCAN_MODE=paths REPO_PATHS="$REPO_OK,$REPO_BAD" STRICT_MODE=true REPORT_FILE="$TMP_DIR/paths.txt" "$SCRIPT"
exit_code=$?
set -e
if [[ "$exit_code" -eq 0 ]]; then
  echo "Expected strict mode failure for non-compliant controls"
  exit 1
fi
assert_contains "Repositories evaluated: 2" "$TMP_DIR/paths.txt"
assert_contains "FAIL [repo-bad]: SSL_MODE must be strict" "$TMP_DIR/paths.txt"

REPO_SECRET="$TMP_DIR/repo-secret"
create_repo "$REPO_SECRET" true true
set +e
SCAN_MODE=paths REPO_PATHS="$REPO_SECRET" STRICT_MODE=true REPORT_FILE="$TMP_DIR/secrets.txt" "$SCRIPT"
exit_code=$?
set -e
if [[ "$exit_code" -eq 0 ]]; then
  echo "Expected strict mode failure for detected secret"
  exit 1
fi
assert_contains "Potential credential leakage detected" "$TMP_DIR/secrets.txt"

echo "All cloudflare_security_gate tests passed"
