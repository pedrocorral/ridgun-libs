---
id: TASK-0020
title: Implement tensor library and v0.9.15 BlaMka tensor block compression in crypto and argon2id
status: completed
created: 2026-10-23
completed: 2026-10-23
requirements: [FR-TENSOR-001, API-TENSOR-001, DM-Tensor, FR-CRYPTO-004, API-CRYPTO-001]
tests: [TS-TENSOR-001, TS-CRYPTO-004]
security: [VUL-INPUT-001, VUL-AUTHN-001]
context_files:
  - src/main/ridgun/lib/tensor.rg
  - src/main/ridgun/lib/crypto.rg
  - src/main/ridgun/lib/argon2id.rg
  - src/test/ridgun/test tensor.rg
  - src/test/ridgun/test crypto.rg
  - src/test/ridgun/test argon2id.rg
  - docs/requirements/functional/tensor/FR-TENSOR-001-typed-tensor-operations-views-and-linear-algebra.md
  - docs/requirements/api/tensor/API-TENSOR-001-tensor-module-contract.md
  - docs/requirements/data-model/DM-Tensor.md
  - docs/tests/functional/tensor/TS-TENSOR-001-typed-tensor-operations-views-and-linear-algebra.md
scope:
  - src/main/ridgun/lib/
  - src/test/ridgun/
  - build.rg
  - docs/
owner: agent-001
claimed: 2026-10-23T17:23:51Z
claimed_by: agent gemini@solarfall
policy:                     # a cycle for this task only (hotfix, release, ...); empty = the project's (aix policy)
---
# TASK-0020 — Implement tensor library and v0.9.15 BlaMka tensor block compression in crypto and argon2id

## Goal (one sentence)
Implement `src/main/ridgun/lib/tensor.rg` (`tensor.rglib` / `libtensor.so`), `src/test/ridgun/test tensor.rg`, and the Ridgun `v0.9.15` `Tensor[U64 * 8 * 16]` `BlaMka` block compression and 1-cycle CPU bitwise primitives in `crypto.rg` and `argon2id.rg` per `/tmp/ridgun_tensor_libraries_spec.md`.

## Plan
- [x] Step 0: Document `TENSOR` domain (`glossary.md`, `field-dictionary.md`, `DM-Tensor.md`, `FR-TENSOR-001`, `API-TENSOR-001`, `API-CRYPTO-001`, `TS-TENSOR-001`, `TASK-0020`, `STATE.md`) and validate with `aix docs validate`.
- [x] Step 1: Implement `src/main/ridgun/lib/tensor.rg` (`tensor rows`, `tensor cols`, `tensor shape`, `tensor row`, `tensor col`, `tensor xor blocks`, `tensor and blocks`, `tensor or blocks`, `tensor add blocks`, `tensor sub blocks`, `tensor mul blocks`, `tensor clone`, `tensor matmul`).
- [x] Step 2: Update `src/main/ridgun/lib/crypto.rg` and `src/main/ridgun/lib/argon2id.rg` with Ridgun `v0.9.15` 1-cycle bitwise operators (`xor`, `and`, `or`, `shl`, `shr`, `rotr`, `rotl`) and `BlaMka` tensor block compression (`f blamka`, `blamka g`, `blamka p16`, `compress block`).
- [x] Step 3: Implement `src/test/ridgun/test tensor.rg`, run `test tensor.rg`, `test crypto.rg`, and `test argon2id.rg`, update `build.rg`, and build all 21 `.rglib` / `.rgc` / `.so` bundles.

## Progress log (append-only, newest last)
- 2026-10-23: Documented `TENSOR` domain (`FR-TENSOR-001`, `API-TENSOR-001`, `DM-Tensor`, `TS-TENSOR-001`) and `BlaMka` tensor block compression in `API-CRYPTO-001`.
- 2026-10-23: Implemented `src/main/ridgun/lib/tensor.rg`, updated `crypto.rg` and `argon2id.rg` with 1-cycle CPU bitwise ops and `Tensor[U64 * 8 * 16]` `BlaMka` block compression (`f blamka`, `blamka g`, `blamka p16`, `compress block`), created `src/test/ridgun/test tensor.rg`, and verified all tests and `.rglib`/`.so` builds pass.

## Files changed (keep current)
- `docs/requirements/product/glossary.md`
- `docs/requirements/data-model/field-dictionary.md`
- `docs/requirements/data-model/DM-Tensor.md`
- `docs/requirements/functional/tensor/FR-TENSOR-001-typed-tensor-operations-views-and-linear-algebra.md`
- `docs/requirements/api/tensor/API-TENSOR-001-tensor-module-contract.md`
- `docs/requirements/api/crypto/API-CRYPTO-001-crypto-and-argon2id-contract.md`
- `docs/tests/functional/tensor/TS-TENSOR-001-typed-tensor-operations-views-and-linear-algebra.md`
- `src/main/ridgun/lib/tensor.rg`
- `src/main/ridgun/lib/crypto.rg`
- `src/main/ridgun/lib/argon2id.rg`
- `src/test/ridgun/test tensor.rg`
- `build.rg`
- `target/bundles/tensor.rglib`, `target/libtensor.so`, `target/bundles/crypto.rglib`, `target/libcrypto.so`, `target/bundles/argon2id.rglib`, `target/libargon2id.so`

## Verification performed (command → result, newest last)
- `ridgunc check "src/test/ridgun/test tensor.rg" && ridgunc run "src/test/ridgun/test tensor.rg"` → `[PASS] test tensor: TS-TENSOR-001 passed` (0 errors)
- `ridgunc run "src/test/ridgun/test crypto.rg"` → `[PASS] test_crypto: TS-CRYPTO-003, TS-CRYPTO-004, and TS-PERF-001 passed`
- `ridgunc run "src/test/ridgun/test argon2id.rg"` → `=== All argon2id tests passed ===`
- `aix docs coverage && aix docs validate` → `0 errors, 0 warnings`

## Exact next actions
1. Task complete.

## Decisions / open questions
- Follow `/tmp/ridgun_tensor_libraries_spec.md` (`v0.9.15`) syntax: glued `Tensor[...]`, multi-target subscript assignment `v_(0), v_(4), v_(8), v_(12) = blamka g ...`, `r_ij = x_ij xor y_ij`, `z_ij = r_ij`, and `||map blamka p16 in z_(i,)` / `||map blamka p16 in z_(,j)`.

## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green
- [x] security entries updated  - [x] docs INDEX updated  - [x] coverage matrix regenerated
