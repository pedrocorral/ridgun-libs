---
id: FR-IO-002
title: Provide high-level file I/O helpers, path metadata predicates, and line-stream utilities
type: functional
status: implemented
priority: must
domain: IO
depends_on: [FR-IO-001]
related: [ADR-0002, VUL-INPUT-001]
tests: [TS-IO-002]
---
# FR-IO-002 — Provide high-level file I/O helpers, path metadata predicates, and line-stream utilities

## Statement
The `io` library SHALL provide the `RG-010` high-level file operations (`read_file`, `write_file`, `append_file`, `read_bytes`, `write_bytes`, `list_dir`), path metadata predicates and attributes (`file_exists`, `is_dir`, `is_file`, `is_symlink`, `file_size`, `file_mtime`, `file_mode`), safe file reading with `IoResult` (`io read file safe`), and line-stream splitting/joining (`io read lines`, `io write lines`).

## Rationale
Applications need both the exact `RG-010` standard library file functions and high-level `IoResult`-returning file and line utilities in a single `io` module.

## Acceptance criteria
- AC1: Given a file path and content, when `write_file`, `append_file`, `read_file`, `write_bytes`, and `read_bytes` are called, then `write_file` creates/overwrites the file, `append_file` appends to existing content (or creates the file if missing), and `read_file` / `read_bytes` return the exact combined content.
- AC2: Given regular files, directories, symlinks, and non-existent paths, when `file_exists`, `is_file`, `is_dir`, `is_symlink`, `file_size`, `file_mtime`, and `file_mode` are called, then predicates return accurate `Bool` values (`is_symlink` is `True` for a symlink, `file_exists` is `False` for a missing path), and `file_size`, `file_mtime` (`> 1700000000`), and `file_mode` return the file's exact metadata (or `-1` on missing paths).
- AC3: Given a existing or missing path, when `io read file safe path` or `io read lines path` / `io write lines path lines` is called, then `io read file safe` returns `NotFound path` when the file does not exist and its `String` content when it does, and `io write lines` / `io read lines` round-trip newline-separated lines cleanly.

## Actors & permissions
- Any Ridgun module importing `io`.

## Constraints & edge cases
- `is_symlink` uses `lstat` semantics so symbolic links are distinguished from their target files.

## Data & privacy
- Operates only on caller-specified filesystem paths.

## Security & observability notes
- Mitigates `VUL-INPUT-001` by checking file existence and metadata before reading in `io read file safe`.

## Out of scope
- Recursive directory archiving (`tar`/`zip`).
