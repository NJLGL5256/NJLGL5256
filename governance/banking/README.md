# Banking Evidence and Compliance Controls

Status: `NOT_VERIFIED`  
Execution status: `NOT_AUTHORIZED`  
Production status: `BLOCKED`

This directory contains redacted control schemas only. It contains no bank statements, account identifiers, credentials, signatures, holdings, delivery instructions, tax records, or source evidence.

## Governing rules

1. Documentation alone never proves custody, ownership, settlement, cash availability, or production readiness.
2. Institution-issued evidence must be attributable, current, complete, and independently reviewed.
3. Holdings value must remain separate from settled, unrestricted, withdrawable cash.
4. Every claimed position must reconcile across custodian evidence, settlement evidence when applicable, and the general ledger.
5. Missing evidence produces `NOT_VERIFIED`, never a pass.
6. Every exception requires an owner, cause, disposition, evidence reference, reviewer, and date.
7. No communication, configuration change, account change, transfer, liquidation, withdrawal, payment, deployment, or certification claim is authorized by these files.
8. Nicholas James Lee Gray is the internal accountable owner and final human approver; independent institutional and professional conclusions remain required.

## Required gates

| Gate | Acceptance condition | Default |
|---|---|---|
| Entity authority | Legal entity, authority, signer, and account title agree | NOT_VERIFIED |
| Custodian recognition | Institution confirms legal title, account status, authority, and restrictions | NOT_VERIFIED |
| Holdings | Current institution record proves identifier, quantity, settlement state, and restrictions | NOT_VERIFIED |
| Transfer settlement | Delivering and receiving records agree and include institutional control evidence | NOT_VERIFIED |
| Cash availability | Institution confirms settled, unrestricted, withdrawable cash | NOT_VERIFIED |
| Accounting | Custodian, settlement, and ledger records reconcile | NOT_VERIFIED |
| Operational controls | Least privilege, dual control, logging, rollback, and testing pass | NOT_VERIFIED |
| Independent review | Qualified reviewers conclude within defined scope and criteria | NOT_VERIFIED |
| Human approval | Exact final payload and action are approved before execution | REQUIRED |

See the machine-readable schemas in this directory. Source evidence belongs only in an approved private evidence system with access logging, encryption, retention controls, and integrity hashes.
