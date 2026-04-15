# Security Baseline Controls (Dry-Run Reference)

**Status:** Proposed only (not enforced in runtime)
**Date:** 2026-04-15

## Minimum enterprise control set
1. TLS 1.3+ for all external ingress.
2. Encryption at rest for all managed/unmanaged data stores.
3. Centralized secret manager usage (no plaintext repo secrets).
4. Least-privilege RBAC with periodic access recertification.
5. Dependency vulnerability scanning with severity gating.
6. Immutable audit trails for CI/CD and privileged actions.
7. Centralized logging, metrics, and distributed tracing.

## Non-breaking rollout model (future)
- Phase A: Observe-only policy checks.
- Phase B: Warn in CI.
- Phase C: Block merge on CRITICAL/HIGH findings.
