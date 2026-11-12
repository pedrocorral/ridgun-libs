---
id: TASK-0052
title: Public SHA-1 in crypto; ws uses it
status: completed
created: 2026-11-12
completed: 2026-11-12
requirements: [FR-CRYPTO-003, FR-WS-001]            # FR-*/NFR-* this task delivers or touches
tests: [TS-CRYPTO-003, TS-WS-001]                   # TS-* to automate
security: []                # VUL-* to address
context_files: [src/main/ridgun/lib/crypto.ridgun, src/main/ridgun/lib/ws.ridgun]
scope: [src/main/ridgun/lib/crypto.ridgun, src/main/ridgun/lib/ws.ridgun, src/test/ridgun/test crypto.ridgun]
owner: agent-001
claimed: 2026-11-12T08:50:43Z
claimed_by: claude claude@solarfall
policy:                     # a cycle for this task only (hotfix, release, ...); empty = the project's (aix policy)
---
# TASK-0052 — Public SHA-1 in crypto; ws uses it

## Goal (one sentence)
crypto exports SHA-1 (FIPS 180-4) as sha1 bytes and sha1 hex; ws uses it instead of its private copy.

## Plan
- [x] crypto: sha1 bytes String => String (20 raw bytes) and sha1 hex String => String, with native 32-bit operations.
- [x] ws imports crypto for the RFC 6455 accept key; its SHA-1, Sha1State and the bit-by-bit u32 helpers are gone; frame masking uses native xor.
- [x] TS-CRYPTO-003: FIPS 180-4 vectors, padding boundaries, bytes 0..255, one million a.

## Progress log (append-only, newest last)
- 2026-11-11: done. SHA-1 of 1 MB: 65 ms.

## Files changed (keep current)
- src/main/ridgun/lib/crypto.ridgun, ws.ridgun
- src/test/ridgun/test crypto.ridgun
- docs: FR-CRYPTO-003 (AC4), TS-CRYPTO-003, API-CRYPTO-001, FR-WS-001

## Verification performed (command → result, newest last)
- ridgunc check --strict of the 37 libs → 37/37.
- stable test → 35/35; ws keeps the RFC 6455 accept vector.

## Exact next actions
1. None.

## Decisions / open questions
- None.

## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green
- [x] security entries updated  - [x] docs INDEX updated  - [x] coverage matrix regenerated
