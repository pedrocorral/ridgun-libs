---
id: TS-PATH-001
title: Verify path normalization, joining, component extraction, and safe subpath confinement
level: unit
covers: [FR-PATH-001, API-PATH-001]
status: automated
automated_in: [src/test/ridgun/test_path.rg]
---
# TS-PATH-001 — Verify path normalization, joining, component extraction, and safe subpath confinement

## Preconditions / fixtures
- Pure-Ridgun `path` module (`src/main/ridgun/lib/path.rg`).

## Steps / inputs
1. Call `path clean`, `path join`, and `path join list` on absolute, relative, redundant-slash, `.`, and `..` paths.
2. Call `path dirname`, `path basename`, `path ext`, `path stem`, `path replace ext`, `path split`, `path is abs`, and `path is rel` on standard files, dotfiles (`.gitignore`), and root paths.
3. Call `path is safe subpath "/srv/www" "assets/app.js"` (`True`) and `path is safe subpath "/srv/www" "../etc/passwd"` (`False`).

## Expected results (map to acceptance criteria)
- AC1 → `path clean` and `path join` resolve `.` and `..` segments accurately.
- AC2 → Component extractors return exact directory, base, stem, and extension strings.
- AC3 → `path is safe subpath` rejects all traversal escapes and unsafe characters.

## Not covered here (to avoid duplication)
- Kernel filesystem `lstat` is covered in `TS-POSIX-002` and `TS-IO-002`.
