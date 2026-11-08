---
id: FR-HASHMAP-001
title: Provide a hash map from String keys to values of any type with constant amortized time
type: functional
status: implemented
priority: must
domain: HASHMAP
depends_on: []
related: [ADR-0009, FR-LIST-002, VUL-INPUT-001]
tests: [TS-HASHMAP-001]
---
# FR-HASHMAP-001 — Provide a hash map from String keys to values of any type with constant amortized time

## Statement
The `hashmap` lib SHALL provide a map from `String` keys to values of any type `V`:
- `hashmap empty`: a map with no keys.
- `hashmap put m k v`: the map with key `k` set to `v`.
- `hashmap get m k d`: the value of `k`, or `d` when `k` is missing.
- `hashmap has m k`: whether `k` is in the map.
- `hashmap add m k d`: for `HashMap Int`, adds `d` to the value of `k`; a missing key starts at 0.
- `hashmap size m`: the number of keys.
- `hashmap pairs m`: every `(key, value)` pair, in the order the keys were first inserted.

`put`, `get`, `has` and `add` SHALL run in constant amortized time.

## Rationale
Solstice groups, counts and indexes text by key (request `2026-11-07-comparar-textos-y-mapa-hash.md`).
`list kv` and `btree` take O(N) and O(log N) per operation, which is too slow for millions of operations.

## Acceptance criteria
- AC1: Given a map, when `put`, `get`, `has`, `size` and `pairs` are called, then they return the values put, the default for missing keys, and one pair per key in first-insertion order. Putting an existing key replaces its value and does not add a pair.
- AC2: Given a `HashMap Int`, when `add` is called, then a missing key starts at 0 and the value is the sum of the amounts added.
- AC3: Given keys with bytes >= 128, the empty key, keys of 10 KB and keys that differ only in their last byte, when they are put and read, then each key keeps its own value.
- AC4: Given values that are records, when they are put and read, then the record comes back unchanged.
- AC5: Given 1,000,000 `add` calls over 100,000 distinct keys, when they run, then the total time grows linearly with the number of calls (target: under 1 s on x86_64; see Constraints).

## Actors & permissions
- Any Ridgun program or lib that imports `hashmap`.

## Constraints & edge cases
- The map is updated in place (ADR-0009). After `m2 = hashmap put m k v`, only `m2` may be used; `m` is not a separate copy.
- With ridgunc 0.9.45, 1,000,000 `add` calls over 100,000 keys take about 0.9 s and 1,000,000 `get` calls about 0.7 s.
- Keys are compared byte by byte, so keys with bytes >= 128 and the empty key are ordinary keys.

## Data & privacy
- In-memory only.

## Security & observability notes
- Mitigates `VUL-INPUT-001`: slots are chosen with SHA-256 of a per-map random seed and the key, so input cannot be chosen to make keys collide on purpose.

## Out of scope
- Removing keys.
- Sharing one map between agents: a map sent to an agent is a copy.
