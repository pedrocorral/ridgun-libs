---
id: ADR-0013
title: On x86-64, socket and posix use the runtime's net and file operations
status: accepted
date: 2026-11-12
supersedes: []
affects: [FR-SOCK-004, API-SOCK-001, FR-POSIX-002, FR-POSIX-004, ADR-0007, src/main/ridgun/lib/socket.ridgun, src/main/ridgun/lib/posix.ridgun]
---
# ADR-0013 — On x86-64, socket and posix use the runtime's net and file operations

## Context
ridgunc 1.0.5 added socket operations to the runtime (`net connect`, `net listen`, `net accept`, `net send`, `net recv into`, `net shutdown`, `net option`, `net local port`, `net peer ip`, `net resolve`; FR-VM-003 of the compiler). ridgunc 1.0.3 added `remove file`, `remove dir` and `rename path`. They return a count or a negative Linux errno, and they exist on x86-64 for Linux and Windows. They do not exist on ARM64 yet.
ADR-0007 sends every kernel call through the `posix` syscall bridge (`sys call (nr …)`).

## Options considered
1. Keep `sys call` for everything.
2. Use the runtime operations where they exist (`sys arch == X86_64`) and keep the `sys call` bridge for ARM64.
3. Use the runtime operations only, and drop ARM64.

## Decision
Option 2.
- `socket.ridgun`: on x86-64, `sys resolve ipv4`, `sys tcp listen`, `sys tcp connect`, `sys accept`, `sys send`, `sys recv`, `sys shutdown write`, `sys local port` and `sys set reuseport` call `net …`. The errno values map to the existing RGF-001 status codes (`-110` → `-2`, `-111` → `-3`, `-104`/`-32` → `-4`, `-98` → `-5`, `-13` → `-6`, others → `-7`).
- `posix.ridgun`: on x86-64, `sys unlink`, `sys rmdir` and `sys rename` call `remove file`, `remove dir` and `rename path`.
- On ARM64 both libs keep the ADR-0007 `sys call (nr …)` code.
- `sys tcp listen reuseport` and the `AF_UNIX` functions keep `sys call` on every architecture: `net listen` binds in the same step, so `SO_REUSEPORT` cannot be set before `bind`, and the runtime has no `AF_UNIX` operations.

## Consequences
- Return values and status codes of the public functions do not change.
- ADR-0007 still applies to ARM64, to `SO_REUSEPORT`, to `AF_UNIX` and to every other kernel call.
- When the runtime adds these operations on ARM64, the `sys call` branches for them can go.
- The ARM64 branch is checked by cross-building only, until an ARM64 host is available.
