---
id: TS-IO-002
title: Verify high-level file I/O helpers, path metadata predicates, and line-stream utilities
level: unit
covers: [FR-IO-002]
status: automated
automated_in: [src/test/ridgun/test_io.rg]
---
# TS-IO-002 — Verify high-level file I/O helpers, path metadata predicates, and line-stream utilities

## Preconditions / fixtures
- Pure-Ridgun `io` module (`src/main/ridgun/lib/io.rg`).

## Steps / inputs
1. Write `"hello "` to `/tmp/rg_io_test.txt` via `write_file`, append `"world"` via `append_file`, read back via `read_file`, and verify `"hello world"`. Test `write_bytes` and `read_bytes` on raw byte lists.
2. Create directory `/tmp/rg_io_dir`, regular file `/tmp/rg_io_dir/file.txt`, and symlink `/tmp/rg_io_dir/sym.txt` → `/tmp/rg_io_dir/file.txt`; verify `file_exists`, `is_dir`, `is_file`, `is_symlink` (must be `True` for `sym.txt` and `False` for `file.txt`), `file_size == 11`, `file_mtime > 1700000000`, and `file_mode > 0`.
3. Call `io read file safe "/tmp/rg_io_missing_999.txt"` and verify `NotFound`; call `io write lines` and `io read lines` on `["alpha", "beta", "gamma"]` and verify round-trip equality.

## Expected results (map to acceptance criteria)
- AC1 → `write_file`, `append_file`, `read_file`, `write_bytes`, and `read_bytes` round-trip content accurately.
- AC2 → `file_exists`, `is_dir`, `is_file`, `is_symlink`, `file_size`, `file_mtime`, and `file_mode` match `RG-010` semantics.
- AC3 → `io read file safe`, `io write lines`, and `io read lines` handle missing files and multi-line streams cleanly.

## Not covered here (to avoid duplication)
- see `TS-IO-001` for `read fd` / `write fd` timeout polling and `io exec timeout`.
