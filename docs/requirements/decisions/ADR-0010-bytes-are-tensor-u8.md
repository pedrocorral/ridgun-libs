---
id: ADR-0010
title: Byte sequences in libs are Tensor[U8], not lists of Int or memfd buffers
status: accepted
date: 2026-11-09
supersedes: []
affects: [src/main/ridgun/lib/posix.ridgun, src/main/ridgun/lib/socket.ridgun, src/main/ridgun/lib/uuid.ridgun, src/main/ridgun/lib/argon2id.ridgun, src/main/ridgun/lib/crypto.ridgun, src/main/ridgun/lib/jwt.ridgun, src/main/ridgun/lib/ws.ridgun]
---
# ADR-0010 — Byte sequences in libs are Tensor[U8], not lists of Int or memfd buffers

## Context
ridgunc 0.9.48 (compiler notes of 2026-11-09) makes bytes a one-dimensional `Tensor[U8]`, stored one byte per element, like `[]byte` in Go:
- `tensor to str` and `tensor from str` convert with one allocation and one copy.
- `sys call` passes the address of the first byte of a `Tensor[U8]` to the kernel; `sys read into` and `sys write from` read and write a range without allocating.
- `read bytes` returns `Tensor[U8]`; a list of `Int` is no longer a byte format.
- Native `sys time ns`, `sys wall time ms` (vDSO) and `crc32 range`.

Before this, libs held bytes in two slow ways:
- `[Int]` lists (`argon2id`, `crypto`, `jwt`, `ws`, `socket`, `posix`): O(n) indexing, one allocation per byte.
- Kernel buffers through `memfd` (`px alloc page`, `px alloc mfd`, `px peek`, `px poke`): about 8 system calls per buffer. Reading the clock this way cost 15 µs.

## Options considered
1. Keep `[Int]` and `memfd`, and only add `Tensor[U8]` variants.
2. Move every byte sequence to `Tensor[U8]` and every kernel buffer to a `Tensor[U8]` passed to `sys call`.

## Decision
Option 2.
- A function parameter, result or record field that holds bytes as `[Int]` becomes `Tensor[U8]`. Lists of numbers that are not bytes (`math`, `list`, `regex`, `diff`, `fmt`) do not change.
- `String` stays for text and for raw byte strings handled as a whole (`sha256 raw`, TLS records, file contents): it is already contiguous with O(1) `str char at`.
- Kernel buffers are `Tensor[U8]` passed to `sys call`. The `memfd` helpers stay, deprecated, for `posix execve` and existing callers in unix-tools: execve needs a table of absolute pointers, no `Tensor[U8]` address is known, and the built-in `sys execve` always passes `path` as argv[0]. They go when the compiler offers an execve that keeps the caller's argv[0].
- The clock functions use `sys time ms`, `sys time ns` and `sys wall time ms`; `crc32` uses `crc32 range`.
- `bytes from list [Int] => String` and `bytes to list String => [Int]` stay as conversions for list literals, built on `Tensor[U8]`.

## Consequences
- Breaking changes for callers of the byte functions of `posix`, `socket`, `argon2id`, `crypto` and `ws` that took or returned `[Int]`; the list is in TASK-0049. In the ecosystem: `sys random bytes list` (unix-tools, 2 uses) and `sock send to` (unix-tools, 1 use).
- Libs require ridgunc 0.9.48 or later.
