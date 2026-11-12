---
id: OPS-DEPLOY
title: Library Build, Packaging, and Distribution
status: approved
---
# Deployment — Library Build, Packaging, and Distribution

## Environments
- **Local / CI Build Toolchain**: Ridgun `v0.9.3` (`ridgunc` native ELF64 compiler + `stable` project manager) on Linux (`x86_64` / `ARM64`).
- **Source Modules**: `src/main/ridgun/lib/*.ridgun` (`socket.ridgun`, `argon2id.ridgun`, `crypto.ridgun`, `posix.ridgun`, `io.ridgun`, `str.ridgun`, `test.ridgun`).
- **Compiled Artifacts**:
  - `.rgc` precompiled module caches in `target/cache/`
  - `.so` ELF64 shared objects in `target/lib*.so` (`libsocket.so`, `libargon2id.so`, `libcrypto.so`, `libposix.so`, `libio.so`, `libstr.so`, `libtest.so`)
  - `.ridgunlib` self-contained library bundles in `target/bundles/*.ridgunlib` (`socket.ridgunlib`, `argon2id.ridgunlib`, `crypto.ridgunlib`, `posix.ridgunlib`, `io.ridgunlib`, `str.ridgunlib`, `test.ridgunlib`)

## Promotion & rollback
1. Format all `.ridgun` sources in canonical tabular style: `stable format`.
2. Run static type, RMM1/RMM2, and DAG verification: `stable check`.
3. Run all automated test suites in `src/test/ridgun/test_*.ridgun`: `stable test`.
4. Build all `.rgc`, `.so`, and `.ridgunlib` artifacts: `stable built lib`.
5. Validate documentation and coverage traceability: `aix docs validate && aix docs coverage`.
6. Downstream projects consume a pinned version of `ridgun-libs` via `stable add` / `stable deps`, and roll back by reverting the dependency ref or `.ridgunlib` bundle in `lib/`.

## Feature flags in use (link FR/task that removes each)
- None (all library modules are statically typed and compiled).
