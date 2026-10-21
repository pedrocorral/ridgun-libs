---
id: ADR-0001
title: Adopt AIX and choose the pure-Ridgun stable library stack
status: accepted
date: 2026-10-21
supersedes: []
affects: [.aix/config.yaml, build.rg, src/main/ridgun/lib, src/test/ridgun]
---
# ADR-0001 — Adopt AIX and choose the pure-Ridgun stable library stack

## Context
`ridgun-libs` is a multi-library repository for Ridgun (`v0.9.3`) built and verified using `stable` and `ridgunc`. Consumer projects synchronize library modules from `src/main/ridgun/lib/*.rg` using `stable deps` / `stable add`. Documentation is the ground truth under AIX.

## Options considered
1. **Single root `stable` project (`build.rg` at root)**: All reusable libraries live in `src/main/ridgun/lib/*.rg` (`socket.rg`, `blake2b.rg`, `argon2id.rg`, `bit64.rg`) and all test suites live in `src/test/ridgun/test_*.rg`.
2. **Separate `stable` sub-projects per library**: Independent `build.rg` manifests under subdirectories.

## Decision
- **Language & Toolchain**: Pure Ridgun `v0.9.3` compiled with `ridgunc` and orchestrated with `stable`.
- **Project Layout**: Single root `build.rg` project (`project name = "ridgun-libs"`).
  - Shared library modules: `src/main/ridgun/lib/*.rg` (imported by bare module name: `import socket`, `import blake2b`, `import argon2id`, `import bit64`).
  - Minimal verification entrypoint for `stable check`/`stable info`: `src/main/ridgun/ridgun_libs/main.rg` (no standalone CLI app installed, library-only distribution).
  - Test suites: `src/test/ridgun/test_*.rg`, executed via `stable test`.
- **Persistence / Frontend**: Not applicable (pure-Ridgun library package).

## Consequences
- Any Ridgun project adding `ridgun-libs` via `stable add` automatically receives `src/main/ridgun/lib/*.rg` via `stable deps`.
- `stable check`, `stable format`, and `stable test` validate all libraries in a single command from the repository root.
