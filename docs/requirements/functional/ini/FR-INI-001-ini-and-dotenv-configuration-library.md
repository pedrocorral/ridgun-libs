---
id: FR-INI-001
title: Provide INI sectioned configuration and Dotenv parsing, interpolation, and serialization
type: functional
status: approved
priority: must
domain: INI
depends_on: []
related: [ADR-0002, DM-Ini, API-INI-001, VUL-INPUT-001]
tests: [TS-INI-001]
---
# FR-INI-001 — Provide INI sectioned configuration and Dotenv parsing, interpolation, and serialization

## Statement
The `ini` library SHALL provide `.ini` and `.env` configuration parsing (`ini parse`, `dotenv parse`), typed lookups (`ini get`, `ini get int`, `ini get bool`, `dotenv get`), mutation (`ini set`), variable interpolation (`${VAR}`), and serialization (`ini stringify`).

## Rationale
Applications and services need lightweight configuration files (`.env` and sectioned `.ini`) without external dependencies.

## Acceptance criteria
- AC1: Given an INI string with `[section]` headers, `key = value` pairs, quoted strings, and `#`/`;`/`--` comments, when `ini parse` is called, then `ini get`, `ini get int`, and `ini get bool` return the expected values per section.
- AC2: Given a `.env` text with `export KEY=VAL`, quoted values, and `${OTHER_KEY}` references, when `dotenv parse` is called, then variables are resolved and accessible via `dotenv get`.
- AC3: Given an `IniDoc` modified with `ini set`, when `ini stringify` is called, then it produces valid `.ini` text that round-trips through `ini parse`.

## Actors & permissions
- Any Ridgun module importing `ini`.

## Constraints & edge cases
- Comments starting with `#`, `;`, or `--` are stripped outside quotes.

## Data & privacy
- Pure in-memory parsing in `RMM1`/`RMM2` regions.

## Security & observability notes
- Mitigates `VUL-INPUT-001` by bounding `${VAR}` expansion to already-defined keys (no shell execution).

## Out of scope
- Full TOML datetime/array-of-tables grammar.
