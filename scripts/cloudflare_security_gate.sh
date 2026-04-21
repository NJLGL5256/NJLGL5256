#!/usr/bin/env bash
set -euo pipefail

REPORT_FILE="${REPORT_FILE:-cloudflare-security-report.txt}"
STRICT_MODE="${STRICT_MODE:-true}"
SCAN_MODE="${SCAN_MODE:-current}" # current | workspace | paths
WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(pwd)}"
REPO_PATHS="${REPO_PATHS:-}"
CHECK_SECRET_LEAKS="${CHECK_SECRET_LEAKS:-true}"

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

check_control() {
  local repo_root="$1"
  local repo_label="$2"
  local config_file="$3"
  local key="$4"
  local expected="$5"

  if rg -n "^${key}=${expected}$" "$config_file" >/dev/null 2>&1; then
    pass "$repo_label" "${key}=${expected}"
  else
    fail "$repo_label" "${key} must be ${expected}"
  fi
}

check_min_tls() {
  local repo_label="$1"
  local config_file="$2"

  local value
  value="$(awk -F'=' '/^MIN_TLS_VERSION=/{print $2}' "$config_file" | tail -n 1)"
  case "$value" in
    1.2|1.3)
      pass "$repo_label" "MIN_TLS_VERSION=${value}"
      ;;
    *)
      fail "$repo_label" "MIN_TLS_VERSION must be 1.2 or 1.3"
      ;;
  esac
}

check_date() {
  local repo_label="$1"
  local config_file="$2"

  local value
  value="$(awk -F'=' '/^LAST_REVIEW_DATE=/{print $2}' "$config_file" | tail -n 1)"
  if [[ -n "$value" ]] && date -d "$value" +%F >/dev/null 2>&1; then
    pass "$repo_label" "LAST_REVIEW_DATE is a valid ISO date"
  else
    fail "$repo_label" "LAST_REVIEW_DATE missing or invalid"
  fi
}

secret_scan() {
  local repo_root="$1"
  local repo_label="$2"

  local leak_output
  leak_output="$(rg -n -I --hidden --glob '!.git/*' --glob '!*.md' \
    --glob '!*.lock' --glob '!*.sum' --glob '!*.txt' --glob '!tests/*' \
    -e '-----BEGIN (RSA|EC|OPENSSH|DSA|PRIVATE) KEY-----' \
    -e 'AKIA[0-9A-Z]{16}' \
    -e 'ghp_[A-Za-z0-9]{36}' \
    -e 'xox[baprs]-[A-Za-z0-9-]+' \
    -e 'api[_-]?key[[:space:]]*[:=][[:space:]]*["\x27][A-Za-z0-9_\-]{20,}["\x27]' \
    "$repo_root" || true)"

  if [[ -n "$leak_output" ]]; then
    fail "$repo_label" "Potential credential leakage detected"
    printf "%s\n" "$leak_output" | tee -a "$REPORT_FILE"
  else
    pass "$repo_label" "No obvious credential leakage patterns detected"
  fi
}

run_repo_checks() {
  local repo_root="$1"
  local repo_label
  repo_label="$(basename "$repo_root")"
  repo_count=$((repo_count + 1))

  printf "\n=== Repository: %s (%s) ===\n" "$repo_label" "$repo_root" | tee -a "$REPORT_FILE"

  local config_file="$repo_root/security/cloudflare_controls.env"

  if [[ ! -f "$config_file" ]]; then
    fail "$repo_label" "Missing Cloudflare control manifest (security/cloudflare_controls.env)"
    return
  fi

  pass "$repo_label" "Cloudflare control manifest present"

  check_control "$repo_root" "$repo_label" "$config_file" "DNS_PROXIED" "true"
  check_control "$repo_root" "$repo_label" "$config_file" "SSL_MODE" "strict"
  check_min_tls "$repo_label" "$config_file"
  check_control "$repo_root" "$repo_label" "$config_file" "ALWAYS_USE_HTTPS" "true"
  check_control "$repo_root" "$repo_label" "$config_file" "HSTS_ENABLED" "true"
  check_control "$repo_root" "$repo_label" "$config_file" "WAF_MANAGED_RULES" "true"
  check_control "$repo_root" "$repo_label" "$config_file" "RATE_LIMITING" "true"
  check_control "$repo_root" "$repo_label" "$config_file" "BOT_PROTECTION" "true"
  check_control "$repo_root" "$repo_label" "$config_file" "ORIGIN_CERT_ROTATION_DAYS" "90"
  check_date "$repo_label" "$config_file"

  if [[ "$CHECK_SECRET_LEAKS" == "true" ]]; then
    secret_scan "$repo_root" "$repo_label"
  fi
}

collect_repositories() {
  case "$SCAN_MODE" in
    current)
      printf "%s\n" "$(pwd)"
      ;;
    workspace)
      find "$WORKSPACE_ROOT" -mindepth 1 -maxdepth 4 -type d -name .git -print | sed 's#/.git$##' | sort -u
      ;;
    paths)
      if [[ -z "$REPO_PATHS" ]]; then
        printf "REPO_PATHS is required when SCAN_MODE=paths\n" >&2
        exit 2
      fi
      printf "%s" "$REPO_PATHS" | tr ',' '\n' | sed 's#^[[:space:]]*##; s#[[:space:]]*$##' | awk 'NF'
      ;;
    *)
      printf "Unsupported SCAN_MODE: %s\n" "$SCAN_MODE" >&2
      exit 2
      ;;
  esac
}

: > "$REPORT_FILE"
printf "Cloudflare Security Compliance Gate - %s\n" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" | tee -a "$REPORT_FILE"
printf "Scan mode: %s\n" "$SCAN_MODE" | tee -a "$REPORT_FILE"
printf "Workspace root: %s\n" "$WORKSPACE_ROOT" | tee -a "$REPORT_FILE"

while IFS= read -r repo; do
  [[ -z "$repo" ]] && continue
  run_repo_checks "$repo"
done < <(collect_repositories)

printf "\nRepositories evaluated: %d\n" "$repo_count" | tee -a "$REPORT_FILE"
printf "Total failures: %d\n" "$fail_count" | tee -a "$REPORT_FILE"

if [[ "$STRICT_MODE" == "true" && "$fail_count" -gt 0 ]]; then
  exit 1
fi
