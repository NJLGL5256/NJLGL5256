# Discovered System Architecture Map (Reality-Based)

## Discovery scope
- Repository scanned: `/workspace/NJLGL5256`.
- Branch context: current working branch.
- Infrastructure and source-of-truth artifacts discovered only from files present in this repository.

## Repositories discovered
- **1 repository present** in the working directory.
- No additional checked-out sibling repositories were discovered.
- No Git submodules with application code were discovered.

## Services discovered (actual)
- No backend service code discovered.
- No frontend application code discovered.
- No deployable microservice manifests (Cloud Run/Kubernetes/Terraform) discovered.

## Data model and ledger artifacts discovered
- No database schema files discovered.
- No ledger tables, migrations, or event-store schemas discovered.
- No immutable journal or append-only financial model implementation discovered.

## Eventing and messaging discovered
- No Pub/Sub/Kafka/SNS/SQS topics or subscriptions declared in code.
- No event schema contracts (Avro/JSON Schema/TypeScript interfaces) discovered.
- No replay pipeline or dead-letter policy definitions discovered.

## Authentication and authorization discovered
- No application auth module discovered.
- No tenant-aware RBAC/ABAC policy implementation discovered.
- CI workflow uses GitHub OIDC token retrieval for deployment integration.

## CI/CD and deployment discovered
- Existing workflow: Azure Static Web Apps CI/CD.
- Existing pipeline behavior:
  - deploys static site from repository root;
  - includes OIDC token fetch step;
  - no explicit lint/test/security policy gates;
  - no financial controls, idempotency checks, schema validation, or audit emission checks.

## External integration surfaces discovered
- Azure Static Web Apps GitHub Action deployment integration.
- No payment rail adapters or financial external APIs discovered.

## Current sources of truth (actual)
- **Application truth:** profile/static content in `README.md`.
- **Deployment truth:** `.github/workflows/azure-static-web-apps-yellow-forest-051d3921e.yml`.
- **Financial truth:** not implemented in this repository.

## Architecture classification
This repository currently represents a **static/profile deployment project**, not a production financial operating system. The required financial platform capabilities are absent and must be introduced through coordinated multi-repository implementation, beginning with governance and discovery controls.
