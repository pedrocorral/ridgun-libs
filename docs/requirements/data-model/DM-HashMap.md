---
id: DM-HashMap
title: Compact open-addressing hash map on tensors
status: approved
related: [FR-HASHMAP-001, API-HASHMAP-001, ADR-0009, DM-Tensor]
---
# DM-HashMap — Compact open-addressing hash map on tensors

## Fields
| Field | Type | Constraints | Notes |
|---|---|---|---|
| hm_fill | [V] | `[]` or one element | The first value put; a `Tensor[V * n]` needs a fill value |
| hm_vals | [Tensor[V * room]] | `[]` until the first put | Values at positions `0 .. size - 1` |
| hm_slots | Tensor[Int * cap] | `0` = free | Otherwise `hash * 2^31 + position` |
| hm_keys | Tensor[String * room] | | Keys at positions `0 .. size - 1`, in insertion order |
| hm_cap | Int | power of 2, `>= 16` | Number of slots |
| hm_room | Int | power of 2, `>= 8` | Positions in `hm_keys` and `hm_vals` |
| hm_n | Tensor[Int * 1] | `>= 0` | Number of keys, in a tensor so an insert does not copy the record |
| hm_seed | String | 16 random bytes | From `/dev/urandom`; the clock when it cannot be read |

## Relations
- Built on `DM-Tensor` (general tensors, ridgunc 0.9.41).

## Invariants
- `hash` is 31 bits of SHA-256(`hm_seed` + key), plus 1, so a used slot is never 0.
- `2 * size <= hm_cap` and `size <= hm_room`. The slot table doubles when an insert would pass half full; the dense tensors double when full.
- Each key appears in exactly one slot; probing is linear from `hash % hm_cap`.
- Field names start with `hm_`: with ridgunc 0.9.44, a program function with the name of a lib record field replaces that field's accessor inside the lib.

## Lifecycle
- Created by `hashmap empty`; changed in place by `put` and `add` (ADR-0009); freed by RMM when the last reference goes.
