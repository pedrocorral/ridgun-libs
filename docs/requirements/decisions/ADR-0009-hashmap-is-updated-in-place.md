---
id: ADR-0009
title: hashmap is updated in place and lists keys in insertion order
status: accepted
date: 2026-11-08
supersedes: []
affects: [FR-HASHMAP-001, API-HASHMAP-001, DM-HashMap, FR-LIST-002, src/main/ridgun/lib/hashmap.ridgun, src/main/ridgun/lib/list.ridgun]
---
# ADR-0009 — hashmap is updated in place and lists keys in insertion order

## Context
Solstice needs to group, count and sort millions of elements by a text key (request `2026-11-07-comparar-textos-y-mapa-hash.md`, target: 1,000,000 `add` over 100,000 keys in under 1 s).
Every other collection in libs is immutable: `list kv` is O(N) per operation and `btree` is O(log N) with allocation on every insert.
ridgunc 0.9.41 added general tensors (`Tensor[String * n]`, `Tensor[V * n] with v`) that are written in place.

Measured with ridgunc 0.9.44 on x86_64:
- A call costs about 20 ns and a record field accessor about 40 ns, so the hot paths take the record apart once in a clause pattern.
- Creating `Tensor[String * n]` or a generic `Tensor[V * n] with v` costs about 0.75 µs per element; `Tensor[Int * n]` costs about 1 ns per thousand elements.
- `sha256 raw` of a 40-byte string costs about 0.2 µs; no faster native string hash exists.

## Options considered
1. Persistent map (copy on write): every `put` copies at least one tensor. O(N) per insert.
2. Map updated in place, open addressing over key, value and hash tensors sized by the slot table.
3. Map updated in place, compact layout: an `Int` slot table points into dense key and value tensors in insertion order.

## Decision
Option 3.
- `put` and `add` change the map and return it. The caller uses the returned map; the old reference is not a separate copy.
- The slot table holds `hash * 2^31 + position` in one `Int`, so a probe reads one tensor and growing the table rehashes `Int` only.
- Keys and values live in dense tensors at most twice the number of keys, so the slow non-numeric tensor creation touches half as many elements as in option 2.
- `pairs` returns the keys in first-insertion order. `list count by` and `list group by` rely on it for first-appearance order.
- The hash is SHA-256 of a per-map random seed and the key, so input cannot force collisions.

## Consequences
- Callers must use the map linearly. Keeping an old map and using it after a `put` sees the new contents.
- A map sent to an agent or through a channel is a copy (ridgunc 0.9.43).
- With ridgunc 0.9.44, 1,000,000 `add` over 100,000 keys took about 1.5 s; about 0.4 s was tensor creation. ridgunc 0.9.45 creates those tensors about 40 times faster: the same run takes about 0.9 s, under the 1 s target.
- Removing keys is not supported; it would need tombstones in the slot table.
