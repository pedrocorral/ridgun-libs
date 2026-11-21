---
id: ADR-0016
title: SHA-256, PBKDF2 and AES run on processor operations; short SHA-256 stays on the runtime for now
status: accepted
date: 2026-11-21
supersedes: []
affects: [FR-CRYPTO-003, FR-CRYPTO-006, FR-CRYPTO-007, TS-CRYPTO-007, ADR-0014, src/main/ridgun/lib/crypto.ridgun, src/main/ridgun/lib/codec.ridgun, src/main/ridgun/lib/json.ridgun, src/test/ridgun/test crypto.ridgun]
---
# ADR-0016 — SHA-256, PBKDF2 and AES run on processor operations; short SHA-256 stays on the runtime for now

**Asked by the compiler team and ordered by the user on 2026-11-21.**

## Context
- ridgunc has processor operations (`arch ::` since 1.0.52; `cpu op` in 1.0.51, when this was written): an operation on small tensors with a portable definition in Ridgun and variants on instructions of the processor. The compiler team asks libs to write SHA-256 and AES with them, so that the runtime can drop its SHA-256.
- Measured on a Ryzen 7 8845HS with ridgunc 1.0.51:

| | Before | Now | Portable definition |
|---|---|---|---|
| PBKDF2-HMAC-SHA-256, 600 000 iterations | 327 ms | 47 ms | 139 ms |
| SHA-256 of 4 KB | 12,4 µs | 7,9 µs | — |
| SHA-256 of 1 MiB | 3,0 ms | 1,9 ms | — |
| SHA-256 of 32 bytes, all on the operations | 0,25 µs (runtime) | 0,84 µs | — |
| AES-128 key stream of 4 096 bytes | about 50 µs | 0,85 µs | 26 µs |
| AES-128-GCM seal of 64 bytes | about 65 µs | about 30 µs | — |
| AES-128-GCM seal of 16 KiB | about 800 µs | about 650 µs | — |

- A SHA-256 of a short message on the operations is slower than the runtime's: the message must be copied into a table of rows of 64 bytes, and the state and the digest need small tensors. The 64 constants were a table built on every call (1,1 µs); they are now written inside the operation.
- GCM is now almost all GHASH (about 580 of the 650 µs for 16 KiB), which needs 64-bit carry-less products.

## Options considered
1. Replace the runtime's SHA-256 everywhere now. Short messages (HMAC, HKDF, signatures, the TLS transcript) get 3 times slower.
2. Use the operations where they win, and keep the runtime's SHA-256 for short messages until the fixed costs go away.
3. Wait for the compiler before changing anything.

## Decision
Option 2.
- `sha256 compress` holds the 64 rounds with the constants written in it. `sha256 block` reads a block of bytes; `sha256 absorb` is the loop over the rows of a message.
- PBKDF2 is one loop in registers: `sha256 hmac step` does the inner and the outer hash of one iteration on word groups, with no text and no tensor per iteration.
- `sha256 bytes` and `sha256 hex` use the operations from 512 bytes on (`sha256 cpu from`), and the runtime below that.
- AES-128 and AES-256: a round, the last round, a block and the counter block of CTR mode are operations; the key stream is one loop over the rows of a table. The S-box is computed, not typed. The four-blocks-per-instruction variant is not used: it measured slower in the counter loop (1 320 ns against 850 ns per 4 096 bytes).
- `codec` and `json` no longer use the runtime's SHA-256 to make a single raw byte: they use a one-byte tensor.
- HMAC-SHA-256 of general messages stays on the runtime's SHA-256 for now.

## Update of the same day: ridgunc 1.0.55
- The declaration is `arch ::`, a variant is written `on x64` and an instruction `cpu aesenc`, without quotes. `crypto.ridgun` is migrated.
- `idem ::` (1.0.54) declares a function whose body runs once: the S-box of AES and the first state of SHA-256 are built once for the whole program. AES-128-GCM of 64 bytes goes from about 30 µs to about 16 µs.

## Consequences
- The runtime's SHA-256 cannot be removed yet: `crypto` (short messages and HMAC) and `ai` (`sha256 str`) still call it. What the compiler must give first is written in `/tmp/ridgun-compiler/2026-11-19/libs-pendiente.md` (entry of 2026-11-21).
- `stable test` runs every suite twice (the second time with `RIDGUN_CPU=2`).
- `ADR-0014` still holds for ChaCha20, Poly1305, GHASH, the big-number arithmetic and Argon2id; its AES-CTR on sixteen byte tensors is replaced by this decision.
- Requirements to update: none of the approved ones change behaviour; `FR-CRYPTO-007` adds AES-256 and the two-mode criterion.
