---
id: TASK-0049
title: Move byte sequences to Tensor[U8] for ridgunc 0.9.48
status: completed
created: 2026-11-09
completed: 2026-11-09
requirements: [FR-JWT-001, ADR-0011, FR-CRYPTO-001, FR-CRYPTO-002, FR-CRYPTO-003, FR-CRYPTO-004, FR-IO-002, FR-POSIX-002, FR-POSIX-004, FR-SOCK-002, FR-UUID-001, FR-WS-001, ADR-0010]
tests: [TS-CRYPTO-001, TS-CRYPTO-002, TS-CRYPTO-003, TS-IO-002, TS-JWT-001, TS-POSIX-002, TS-POSIX-003, TS-SOCK-002, TS-UUID-001, TS-WS-001]
security: []                # VUL-* to address
context_files: [docs/requirements/decisions/ADR-0010-bytes-are-tensor-u8.md]
scope: [src/main/ridgun/lib/argon2id.ridgun, src/main/ridgun/lib/crypto.ridgun, src/main/ridgun/lib/jwt.ridgun, src/main/ridgun/lib/posix.ridgun, src/main/ridgun/lib/socket.ridgun, src/main/ridgun/lib/uuid.ridgun, src/main/ridgun/lib/ws.ridgun, src/test/ridgun/]
owner: agent-001
claimed: 2026-11-09T18:57:57Z
claimed_by: claude claude@solarfall
policy:                     # a cycle for this task only (hotfix, release, ...); empty = the project's (aix policy)
---
# TASK-0049 — Move byte sequences to Tensor[U8] for ridgunc 0.9.48

## Goal (one sentence)
Every byte sequence that libs held as `[Int]` or in a memfd page is a `Tensor[U8]`, and clocks and CRC-32 use the 0.9.48 built-ins (ADR-0010).

## Plan
- [x] ADR-0010
- [x] posix, socket, uuid, io tests
- [x] argon2id, crypto
- [x] jwt, ws
- [x] FR/API/DM/TS docs of those libs
- [x] Compiler report for what 0.9.49 gets wrong

## Progress log (append-only, newest last)
- 2026-11-09: ADR-0010 written. Three groups migrated: posix/socket/uuid; argon2id/crypto; jwt/ws.
- 2026-11-09: `posix execve` keeps the memfd page: the built-in `sys execve` always uses `path` as argv[0], and a pointer table needs a known address. Requested from the compiler.
- 2026-11-09: CONFLICT-0005 → ADR-0011: jwt uses standard HMAC-SHA256 and ChaCha20-Poly1305; RFC 4231, RFC 7515 A.1 and RFC 8439 vectors added to `test jwt.ridgun`.
- 2026-11-09: Compiler report `/tmp/ridgun-compiler/2026-11-09/tensor-u8.md`: `n` wrong with `(Tensor[U8 * n] _)`; `Tensor[U8]` from a constructor pattern read by words; `Tensor[U8]` from a list; `xor` in a function name; execve with the caller's argv[0].

## Breaking changes (public API)
- posix: `sys random bytes list` → `sys random tensor Int => Int Tensor[U8]`. The lib's `sys wall time ms` is gone (the built-in is used). `px alloc page`, `px alloc mfd`, `px peek`, `px poke`, `px free page` are deprecated.
- socket: `Socket.rx_buf`/`tx_buf`, `SockBytesOk`, `SockFromOk`, `sock send bytes`, `sock send all`, `sock send frame`, `sock send to`, `encode be32`, `decode be32` use `Tensor[U8]`. `str to byte list`, `byte list to str` and the int-list helpers are removed.
- argon2id: `Argon2KeyOk`, `bytes to hex`, `derive raw tag`, `argon2id hash bytes`, `constant time bytes eq`, `b64 encode nopad`, `b64 decode nopad`, `validate argon2 params` use `Tensor[U8]`.
- crypto: ChaCha20, Poly1305, AEAD, HMAC key helpers and `bitxor byte lists`, `bytes list to hex` use `Tensor[U8]`; new `hex str to bytes`. `bytes from list` and `bytes to list` stay.
- jwt: `jwt b64url enc bytes Tensor[U8]`, `jwt b64url decode bytes => Tensor[U8]`. HS256 is now standard HMAC and the AEAD is ChaCha20-Poly1305 with `RGAEAD2` tokens (ADR-0011): earlier tokens no longer verify or open.
- ws: `WsFrame.payload_bytes`, `ws encode *`, `ws decode frame`, `ws mask bytes` use `Tensor[U8]`.
- Behaviour fixes: 64-bit WebSocket lengths now work; bytes ≥ 128 round-trip in ws/jwt.

## Ecosystem callers that break
- unix-tools `fs_lib.ridgun:1785`, `filter_lib.ridgun:444`: `sys random bytes list`.
- unix-tools `proc_lib.ridgun:3833`: `sock send to` with `str to byte list`.

## Files changed (keep current)
- `src/main/ridgun/lib/{argon2id,crypto,jwt,posix,socket,uuid,ws}.ridgun`
- `src/test/ridgun/test {argon2id,crypto,io,jwt,posix,socket,uuid,ws}.ridgun`
- ADR-0010, decisions/INDEX.md; FR/API/DM/TS docs listed in the front matter

## Verification performed (command → result, newest last)
- `ridgunc build --strict --so` on all 37 libs → 0 errors.
- All 35 suites built with `--strict` and run from the repo root → all pass (`test socket.ridgun`: fixed a `sys_getpid` strict error inside an interpolation).
- `aix docs validate` → 0 errors, 0 warnings; `aix docs coverage` regenerated.
- Bundles and .so rebuilt for posix, socket, uuid, io, argon2id, crypto, jwt, ws, tls, mail, http.
- Timings (before → after): 10k JWT HS256 sign+verify 5.0 s → 0.52 s; 64 KB ws frame ~300 → 13 ms; ChaCha20-Poly1305 64 KB 460 → 36 ms; Argon2id m=64 60 → 9 ms; 1M `sys monotonic ns` 15 s → 23 ms; 1k crc32 60 → 1 ms; uuid v7 392 → 106 ms.

## Exact next actions
1. Commit when the user asks.

## Decisions / open questions
- CONFLICT-0005 (resolved, option A, ADR-0011): jwt's HMAC was non-standard and `jwt seal aead` was a SHA-256 keystream. jwt now uses `crypto`'s `hmac sha256` and `aead seal`/`aead open`; sealed tokens are `RGAEAD2`. Old tokens stop working; nothing in the ecosystem calls jwt.

## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green
- [x] security entries updated  - [x] docs INDEX updated  - [x] coverage matrix regenerated
