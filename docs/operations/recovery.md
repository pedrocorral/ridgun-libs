---
id: OPS-RECOVERY
title: Artifact and Build Recovery
status: approved
---
# Recovery — Artifact and Build Recovery

## Backups (what, where, encryption, retention)
- `ridgun-libs` is a stateless pure-Ridgun library repository; no runtime database or persistent user data is stored.
- Source code (`src/`), build definitions (`build.rg`), and AIX specifications (`docs/`) are versioned in the repository.

## Restore procedure (last tested: 2026-10-21)
1. Clean stale or corrupted build artifacts: `stable clean` (or `rm -rf target/`).
2. Re-verify all modules and test suites from source: `stable check && stable test`.
3. Re-generate all `.rgc`, `.so`, and `.rglib` artifacts: `stable built lib`.
4. Re-verify AIX documentation and coverage matrix: `aix docs validate && aix docs coverage`.

## Data-loss / corruption playbook
- If a compiled `.rgc`, `.so`, or `.rglib` artifact in `target/` is corrupted or out of sync with `src/main/ridgun/lib/*.rg`, run `stable clean && stable built lib && stable test` to deterministically rebuild all library binaries from source.
