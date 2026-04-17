# NJLGL5256

This repository contains production-readiness governance checks and supporting documentation.

## Governance gate

Run the financial policy gate:

```bash
./scripts/financial_policy_gate.sh
```

Run tests:

```bash
./tests/test_financial_policy_gate.sh
```

## AutoGen Studio example

A credential-aware AutoGen weather agent example is available at:

- `python/packages/autogen-studio/examples/weather_agent.py`

Credential loading helper:

- `python/packages/autogen-studio/autogen_studio/credential_loader.py`
