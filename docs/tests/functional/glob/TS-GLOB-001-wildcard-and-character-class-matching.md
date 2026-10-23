---
id: TS-GLOB-001
title: Verify wildcard (*, ?), character class ([a-z], [!a-z]), case-insensitive, and list filtering operations
level: unit
covers: [FR-GLOB-001, API-GLOB-001]
status: automated
automated_in: [src/test/ridgun/test glob.rg]
---
# TS-GLOB-001 — Verify wildcard (`*`, `?`), character class (`[a-z]`, `[!a-z]`), case-insensitive, and list filtering operations

## Preconditions / fixtures
- Pure-Ridgun `glob` module (`src/main/ridgun/lib/glob.rg`).

## Steps / inputs
1. Call `glob match` and `glob match ci` with `*`, `***`, `?`, empty strings, and mixed-case inputs.
2. Call `glob match` with `[a-z]`, `[0-9]`, `[!0-9]`, `[^a-z]`, and unclosed `[` brackets.
3. Call `glob filter` and `glob any match` on file lists (`["socket.rg", "README.md", "test socket.rg"]`).

## Expected results (map to acceptance criteria)
- AC1 → `*`, `?`, and case-insensitive matching return exact booleans.
- AC2 → Positive and negated bracket character classes and ranges match accurately.
- AC3 → `glob filter` and `glob any match` select the exact matching items.

## Not covered here (to avoid duplication)
- Directory listing is covered in `TS-IO-002`.
