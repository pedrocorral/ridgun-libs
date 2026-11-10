---
id: ADR-0012
title: Generic list helpers and str join come from the compiler prelude
status: accepted
date: 2026-11-10
supersedes: []
affects: [FR-LIST-001, API-LIST-001, API-STR-001, src/main/ridgun/lib/list.rg, src/main/ridgun/lib/str.rg]
---
# ADR-0012 — Generic list helpers and str join come from the compiler prelude

## Context
ridgunc 0.9.55 has a prelude that every program calls without `import` (described in the compiler notes of 2026-11-10): `list len`, `list reverse`, `list take`, `list drop`, `list nth or`, `list last or`, `list contains` for any `[A]`, and `str join [String] String`. A module the program imports wins over the prelude. So `list.rg`, which defined these names for `[Int]` only, hid the generic versions from every program that imports `list`; `stable` is one.

## Options considered
1. Keep the `[Int]` versions in `list.rg`.
2. Delete them from `list.rg` and `str join` from `str.rg`; keep the `list str` names as one-line aliases.

## Decision
Option 2.
- `list.rg` no longer defines `list len`, `list nth or`, `list take`, `list drop`, `list reverse` or `list contains`; the prelude's generic ones apply, with the same results on `[Int]`.
- `list str len`, `list str nth or`, `list str take`, `list str drop`, `list str reverse` and `list str contains` stay, each calling the generic function.
- `str.rg` no longer defines `str join`; the prelude's is linear and gives the same result.

## Consequences
- Callers that import `list` get the generic functions for any element type. No result changes for `[Int]`.
- Libs require ridgunc 0.9.55 or later (0.9.54 breaks `import list`).
