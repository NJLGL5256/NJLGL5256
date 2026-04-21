# Cloudflare Security Compliance Runbook

## Purpose

This runbook defines a repeatable gate to verify that repositories in the workspace are configured for Cloudflare DNS proxying, TLS encryption, baseline edge security controls, and basic secret leakage detection.

## Baseline control manifest

Each repository should include:

- `security/cloudflare_controls.env`

Required controls:

- `DNS_PROXIED=true`
- `SSL_MODE=strict`
- `MIN_TLS_VERSION=1.2` or `1.3`
- `ALWAYS_USE_HTTPS=true`
- `HSTS_ENABLED=true`
- `WAF_MANAGED_RULES=true`
- `RATE_LIMITING=true`
- `BOT_PROTECTION=true`
- `ORIGIN_CERT_ROTATION_DAYS=90`
- `LAST_REVIEW_DATE=<YYYY-MM-DD>`

## Run compliance gate

Current repository:

```bash
STRICT_MODE=true scripts/cloudflare_security_gate.sh
```

All repositories under the workspace:

```bash
SCAN_MODE=workspace WORKSPACE_ROOT=/workspace STRICT_MODE=true scripts/cloudflare_security_gate.sh
```

Explicit repository list:

```bash
SCAN_MODE=paths REPO_PATHS="/repo/a,/repo/b" STRICT_MODE=true scripts/cloudflare_security_gate.sh
```

## What the gate validates

1. Cloudflare control manifest exists.
2. Mandatory Cloudflare and TLS security settings are enforced.
3. `LAST_REVIEW_DATE` is valid.
4. Basic secret leakage signatures are not present in non-doc source files.

## Notes

- This gate is a policy and static-content check. It does **not** call the Cloudflare API.
- Use it as a pre-merge and CI guardrail before infra rollout and periodic compliance audits.
