---
id: ADR-0004
title: X509Cert field names follow API-CRYPTO-001
status: accepted
date: 2026-11-06
supersedes: []
affects: [API-CRYPTO-001, FR-CRYPTO-006, TS-CRYPTO-006, src/main/ridgun/lib/crypto.ridgun, "src/test/ridgun/test crypto.ridgun"]
---
# ADR-0004 — X509Cert field names follow API-CRYPTO-001

## Context
`CONFLICT-0002`: the uncommitted `X509Cert` type in `crypto.ridgun` named four fields differently from `API-CRYPTO-001`.
The code used `not_before_unix`, `not_after_unix`, `key_usage` and `ext_server_auth`.
The contract uses `not_before_at`, `not_after_at`, `key_usage_bits` and `has_server_auth`.

## Options considered
1. Change the code to match the contract.
2. Change the contract, `FR-CRYPTO-006` AC6 and the field dictionary to match the code.

## Decision
Option 1, chosen by the user on 2026-11-06.
The contract stays unchanged.
The `_at` suffix for UTC epoch-second timestamps is the project convention, as in `DM-Jwt`.

## Consequences
- Requirements to update: none.
- Tests to update: `TS-CRYPTO-006` assertions in `src/test/ridgun/test crypto.ridgun` use the contract names.
- Code to update: `X509Cert` in `src/main/ridgun/lib/crypto.ridgun` and every accessor that reads these four fields.
- Known effect: `JwtClaims` (`jwt.ridgun`) also has a `not_before_at` field.
  A file that imports both `crypto` and `jwt` directly gets a compile-time `__ambiguous__.not_before_at` error on the bare accessor.
  It must write `crypto.not_before_at c` or `jwt.not_before_at c`.
  A lib that imports `crypto` (for example `tls`) does not pass the ambiguity on to its importers.
  Verified with `ridgunc check --strict` on 2026-11-06.
