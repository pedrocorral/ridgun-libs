---
id: OPS-DEPLOY
title: Library Build, Packaging, and Distribution
status: approved
---
# Deployment — Library Build, Packaging, and Distribution

## Environments
- **Local / CI Build Toolchain**: Ridgun `v0.9.3` (`ridgunc` native ELF64 compiler + `stable` project manager) on Linux (`x86_64` / `ARM64`).
- **Source Modules**: `src/main/ridgun/lib/*.rg` (`socket.rg`, `argon2id.rg`, `crypto.rg`, `posix.rg`, `io.rg`, `str.rg`, `test.rg`).
- **Compiled Artifacts**:
  - `.rgc` precompiled module caches in `target/cache/`
  - `.so` ELF64 shared objects in `target/lib*.so` (`libsocket.so`, `libargon2id.so`, `libcrypto.so`, `libposix.so`, `libio.so`, `libstr.so`, `libtest.so`)
  - `.rglib` self-contained library bundles in `target/bundles/*.rglib` (`socket.rglib`, `argon2id.rglib`, `crypto.rglib`, `posix.rglib`, `io.rglib`, `str.rglib`, `test.rglib`)

## Promotion & rollback
1. Format all `.rg` sources in canonical tabular style: `stable format`.
2. Run static type, RMM1/RMM2, and DAG verification: `stable check`.
3. Run all automated test suites in `src/test/ridgun/test_*.rg`: `stable test`.
4. Build all `.rgc`, `.so`, and `.rglib` artifacts: `stable built lib`.
5. Validate documentation and coverage traceability: `aix docs validate && aix docs coverage`.
6. Downstream projects consume a pinned version of `ridgun-libs` via `stable add` / `stable deps`, and roll back by reverting the dependency ref or `.rglib` bundle in `lib/`.

## Feature flags in use (link FR/task that removes each)
- None (all library modules are statically typed and compiled).
