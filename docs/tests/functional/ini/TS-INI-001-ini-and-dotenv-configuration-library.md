---
id: TS-INI-001
title: Verify INI sectioned configuration and Dotenv parsing, interpolation, and serialization
level: unit
covers: [FR-INI-001, API-INI-001]
status: automated
automated_in: ["src/test/ridgun/test ini.rg"]
---
# TS-INI-001 — Verify INI sectioned configuration and Dotenv parsing, interpolation, and serialization

## Preconditions / fixtures
- Pure-Ridgun `ini` and `test` modules (`src/main/ridgun/lib/ini.rg`, `src/main/ridgun/lib/test.rg`).

## Steps / inputs
1. Parse an INI string with `[database]` and `[server]` sections, comments, and quoted values; verify `ini get`, `ini get int`, `ini get bool`, and `ini sections`.
2. Parse a `.env` string with `export`, quoted values, and `${VAR}` interpolation via `dotenv parse`; verify `dotenv get`.
3. Update values with `ini set`, serialize with `ini stringify`, and re-parse.

## Expected results (map to acceptance criteria)
- AC1 → Sectioned INI values and typed getters return exact values.
- AC2 → `.env` `${VAR}` references expand against prior definitions.
- AC3 → `ini set` + `ini stringify` round-trips cleanly.

## Not covered here (to avoid duplication)
- OS environment syscalls (`TS-CLI-001`).
