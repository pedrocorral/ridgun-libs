---
id: TASK-0048
title: Add hashmap lib and list sort, count by and group by for Solstice
status: completed
created: 2026-11-08
completed: 2026-11-08
requirements: [FR-HASHMAP-001, FR-LIST-002, FR-LIST-001]  # FR-*/NFR-* this task delivers or touches
tests: [TS-HASHMAP-001, TS-LIST-002]  # TS-* to automate
security: [VUL-INPUT-001]   # VUL-* to address
context_files: [/tmp/ridgun-lib/requirements/2026-11-07-comparar-textos-y-mapa-hash.md, docs/requirements/decisions/ADR-0009-hashmap-is-updated-in-place.md, src/main/ridgun/lib/hashmap.ridgun, src/main/ridgun/lib/list.ridgun]  # THE ONLY files an agent must read to work on this task
scope: [src/main/ridgun/lib/hashmap.ridgun, src/main/ridgun/lib/list.ridgun, "src/test/ridgun/test hashmap.ridgun", "src/test/ridgun/test list.ridgun", build.ridgun, docs/requirements, docs/tests]  # paths/globs this task will change (aix task start warns when two going-on tasks overlap)
owner: agent-001
claimed: 2026-11-08T15:02:39Z
claimed_by: claude claude@solarfall
policy:                     # a cycle for this task only (hotfix, release, ...); empty = the project's (aix policy)
---
# TASK-0048 — Add hashmap lib and list sort, count by and group by for Solstice

## Goal (one sentence)
Deliver Solstice's request `2026-11-07-comparar-textos-y-mapa-hash.md`: a String-keyed hash map and native-speed sort, count by and group by in `list`.

## Plan
- [x] `hashmap` lib, compact layout (ADR-0009)
- [x] `list sort ints/texts/by int/by text` on the native `sort by ints` / `sort by texts` (ridgunc 0.9.44)
- [x] `list count by` / `list group by` on `hashmap`
- [x] FR/API/DM/TS/ADR docs, glossary, field dictionary, indexes
- [x] Suites, strict check, docs validate
- [x] Compiler note and reply to Solstice

## Progress log (append-only, newest last)
- 2026-11-08: Sorts switched to native primitives; radix and merge-sort code removed. Hashmap rewritten as compact layout (Int slot table + dense keys/values in insertion order), fields prefixed `hm_` because a program function named like a lib record field replaces its accessor (compiler bug). Hot paths take the record apart once (calls ~20 ns, accessors ~40 ns).
- 2026-11-08: Compiler note `/tmp/ridgun-compiler/2026-11-08/hashmap-tensores-y-campos.md` (field leak, generic tensor write, `@` on Real, slow String/generic tensor creation, call cost). Reply appended to the Solstice request.

## Files changed (keep current)
- `src/main/ridgun/lib/hashmap.ridgun` (new), `src/main/ridgun/lib/list.ridgun`, `build.ridgun`
- `src/test/ridgun/test hashmap.ridgun` (new), `src/test/ridgun/test list.ridgun`
- FR-HASHMAP-001, API-HASHMAP-001, DM-HashMap, TS-HASHMAP-001, ADR-0009, FR-LIST-002, TS-LIST-002 (new); FR-LIST-001 AC2, API-LIST-001, glossary, field dictionary, indexes

## Verification performed (command → result, newest last)
- `ridgunc check --strict` on all 37 libs → 0 errors.
- All 36 suites under `src/test/ridgun/` → pass (tls and mail run from the repo root).
- `aix docs validate` → 0 errors, 0 warnings; `aix docs coverage` → regenerated.
- Benchmarks, ridgunc 0.9.44, x86_64, 100k elements: sort ints 5 ms, sort by int (records) 22 ms, sort texts 92 ms, count by 116 ms. 1M `hashmap add` over 100k keys 1.49 s (inserts 0.55 s, of which ~0.39 s String/generic tensor creation; updates ~1 µs each); 1M get 0.82 s.

## Exact next actions
1. Commit when the user asks.
2. When the compiler speeds up String/generic tensor creation, re-measure `hashmap add` (estimate ~1.1 s).
3. When the compiler fixes the field-accessor leak and the generic tensor write, consider dropping the `hm_` prefix and `hm val get/set`.

## Decisions / open questions
- ADR-0009: map updated in place, keys in insertion order.
- Target 1 s for 1M `add` not met (1.5 s); the remaining gap is compiler work (note above).

## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green
- [x] security entries updated  - [x] docs INDEX updated  - [x] coverage matrix regenerated
