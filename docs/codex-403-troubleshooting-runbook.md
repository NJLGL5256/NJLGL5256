# Codex 403 / Cloudflare Challenge Troubleshooting Runbook

## Purpose
Use this runbook when Codex IDE/CLI startup logs show remote plugin sync failures with `403 Forbidden`, especially responses containing Cloudflare challenge HTML such as "Enable JavaScript and cookies to continue".

## Symptom pattern
Typical errors:
- `startup remote plugin sync failed ... /backend-api/plugins/list ... 403 Forbidden`
- `failed to warm featured plugin ids cache ... /backend-api/plugins/featured ... 403 Forbidden`
- HTML challenge page in the response body.

## Scope and ownership
- **Developer workstation owner**: local auth/session/cache, extension/CLI versions, local network path.
- **IT / Security / Network**: VPN/proxy/TLS inspection/allowlisting.
- **Platform owner**: only if there is a managed edge in your own environment.

## Quick triage matrix

| Signal | Likely cause | Owner | Priority |
|---|---|---|---|
| 403 with Cloudflare challenge HTML | session/challenge clearance missing | Developer + IT | P0 |
| Works on home network but not corp network | proxy/VPN/security middleware | IT/Security | P0 |
| Intermittent after updates | stale cache/session or version skew | Developer | P1 |
| Same user broken on all networks/devices | account/session issue | Developer/OpenAI support | P1 |

## Step-by-step checklist

### 1) Developer local checks (first)
1. Restart IDE and Codex process.
2. Sign out and sign back into Codex extension.
3. Update Codex extension and CLI/app-server to latest available version.
4. Clear local Codex temp/plugin cache and restart.
5. Verify system clock is correct and synced.
6. Retest with VPN/proxy disabled (if policy allows).

**Exit criteria:** plugin sync no longer returns 403 challenge pages.

### 2) Network/security path checks
1. Verify outbound access to `chatgpt.com` and required subdomains is allowed.
2. Confirm proxy does not strip cookies/headers required for auth/session.
3. Confirm TLS inspection is not altering traffic in a way that breaks challenge/session continuity.
4. Test from a clean network path (mobile hotspot / non-corporate).

**Exit criteria:** issue reproducibly tied to (or ruled out from) managed network controls.

### 3) Cloudflare/WAF checks (only if you control a relevant edge)
1. Review managed challenge and bot rules for machine-originated authenticated requests.
2. Add narrowly scoped exceptions for trusted routes/actors where justified.
3. Monitor for false positives and gradually tighten rules.

**Important:** If failing endpoints are on `chatgpt.com/backend-api/...`, this is typically **not** a repository-controlled Cloudflare configuration.

## What is usually NOT the blocker
These warnings are often non-blocking and can be deprioritized while handling the 403 issue:
- plugin manifest warnings about `defaultPrompt` length/count limits
- broadcast handler warnings for noncritical methods
- read-repair state DB discrepancy warnings

## Incident template (copy/paste)

- **Date/Time (UTC):**
- **User/Host:**
- **Codex extension version:**
- **Codex CLI/app-server version:**
- **Network path:** (corp vpn / corp no-vpn / home / hotspot)
- **Observed endpoint:**
- **HTTP status:**
- **Challenge HTML present:** yes/no
- **Steps attempted:**
- **Result:**
- **Next owner:**

## Escalation package
When escalating to IT/security or support, include:
1. Sanitized log excerpt showing endpoint + status code + timestamp.
2. Network comparison results (corp vs non-corp).
3. Version info (extension/CLI).
4. Confirmation that re-auth + cache reset was attempted.

## Recovery target
- Plugin sync succeeds without challenge HTML.
- No recurring 403 for plugin list/featured on app-server startup.
- Workspace can proceed without manual retries.
