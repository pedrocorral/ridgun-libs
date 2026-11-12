---
id: CONFLICT-0002
title: X509Cert field names in crypto.ridgun differ from API-CRYPTO-001
status: resolved            # open | resolved
date: 2026-11-06
affects: [API-CRYPTO-001, FR-CRYPTO-006, TS-CRYPTO-006, src/main/ridgun/lib/crypto.ridgun, "src/test/ridgun/test crypto.ridgun"]
adr: ADR-0004
---
# CONFLICT-0002 — X509Cert field names in crypto.ridgun differ from API-CRYPTO-001

## Conflict
`API-CRYPTO-001` (FR-CRYPTO-006 section) declares:
`type X509Cert = ..., not_before_at: Int, not_after_at: Int, ..., key_usage_bits: Int, has_server_auth: Bool`.
`FR-CRYPTO-006` AC6 also names `not_before_at` and `not_after_at`.
`field-dictionary.md` defines `not_after_at` for X.509.

The uncommitted code in `src/main/ridgun/lib/crypto.ridgun:26` declares a different set of field names.
`src/test/ridgun/test crypto.ridgun:516-517` reads the code's names.

| Requirement says | Code / other spec does | Impact if we follow the requirement |
|---|---|---|
| `not_before_at: Int` | `not_before_unix: Int` | Rename the field in `crypto.ridgun` and in the test. No code is committed or used by other libs yet. |
| `not_after_at: Int` | `not_after_unix: Int` | Same as above. |
| `key_usage_bits: Int` | `key_usage: Int` | Same as above. |
| `has_server_auth: Bool` | `ext_server_auth: Bool` | Same as above. |

## Options and consequences
- A. Change code to match requirement (default): rename the 4 fields in `crypto.ridgun` and `test crypto.ridgun`. Cost: small mechanical edit. Risk: none, because nothing outside TASK-0043 uses these fields. The `_at` suffix also matches `DM-Jwt` and the field dictionary.
- B. Change requirement (needs justification → ADR): rewrite `API-CRYPTO-001`, `FR-CRYPTO-006` AC6 and `field-dictionary.md` to use the code's names. Cost: doc edits and an ADR. Risk: X.509 time fields become inconsistent with the `_at` convention used for JWT.
- C. Split into two requirements: not applicable; this is naming only.

## Agent recommendation
Option A. The code is uncommitted work in progress for the same task. The requirement names follow the project's existing `_at` timestamp convention.

## Human decision
Option A, chosen by the user on 2026-11-06.

## Resolution evidence (ADR, commits, tests)
- `ADR-0004-x509cert-field-names-follow-api-crypto-001.md` (accepted).
- `crypto.ridgun:26` and `test crypto.ridgun:515-517` renamed to the contract names.
- `ridgunc check --strict` on `crypto.ridgun` and `jwt.ridgun`: 0 errors.
- `ridgunc run "src/test/ridgun/test crypto.ridgun"`: `[PASS]` for TS-CRYPTO-003/004/005/006 and TS-PERF-001.
