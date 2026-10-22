---
id: FR-PATH-001
title: Provide pure-Ridgun path joining, normalization, component extraction, and safe subpath confinement
type: functional
status: implemented
priority: must
domain: PATH
depends_on: []
related: [ADR-0002, VUL-INJ-002, VUL-INPUT-001]
tests: [TS-PATH-001]
---
# FR-PATH-001 — Provide pure-Ridgun path joining, normalization, component extraction, and safe subpath confinement

## Statement
The `path` library SHALL provide pure-Ridgun path manipulation and confinement primitives (`path clean`, `path join`, `path dirname`, `path basename`, `path ext`, `path stem`, `path replace ext`, `path is abs`, `path is rel`, `path split`, `path is safe subpath`).

## Rationale
Applications, build tools, and HTTP/file servers require deterministic lexical path normalization (resolving `.` and `..` segments without touching the filesystem) and strict directory-confinement checks (`path is safe subpath`) to prevent path traversal (`VUL-INJ-002`).

## Acceptance criteria
- AC1: Given arbitrary paths with redundant slashes, `.`, or `..` segments, when `path clean` and `path join` are called, then `path clean "/a/b/../c/./d//"` returns `"/a/c/d"`, `path clean "a/../../b"` returns `"../b"`, `path clean "/../a"` clamps at root returning `"/a"`, and `path join "/var/log" "app/server.log"` returns `"/var/log/app/server.log"`.
- AC2: Given file paths, when `path dirname`, `path basename`, `path ext`, `path stem`, `path replace ext`, `path is abs`, and `path is rel` are called, then they extract the directory, filename, extension (including `.`), stem without extension, and replaced extension accurately.
- AC3: Given a base directory and a candidate child path, when `path is safe subpath base child` is called, then it returns `True` only when the normalized target path stays strictly inside `base` (and rejects `..` escapes, null/shell metacharacters, or absolute overrides).

## Actors & permissions
- Any Ridgun module importing `path`.

## Constraints & edge cases
- Leading dotfiles such as `".gitignore"` have `path stem ".gitignore" == ".gitignore"` and `path ext ".gitignore" == ""`.

## Data & privacy
- Pure lexical path operations in memory.

## Security & observability notes
- Mitigates `VUL-INJ-002` and `VUL-INPUT-001` via `path is safe subpath`.

## Out of scope
- Filesystem symlink resolution (covered by `posix`/`io`).
