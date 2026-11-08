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
| fill | [V] | `[]` or one element | The first value put; a `Tensor[V * n]` needs a fill value |
| vals | [Tensor[V * room]] | `[]` until the first put | Values at positions `0 .. size - 1` |
| slots | Tensor[Int * cap] | `0` = free | Otherwise `hash * 2^31 + position` |
| keys | Tensor[String * room] | | Keys at positions `0 .. size - 1`, in insertion order |
| cap | Int | power of 2, `>= 16` | Number of slots |
| room | Int | power of 2, `>= 8` | Positions in `keys` and `vals` |
| count | Tensor[Int * 1] | `>= 0` | Number of keys, in a tensor so an insert does not copy the record |
| seed | String | 16 random bytes | From `/dev/urandom`; the clock when it cannot be read |

## Relations
- Built on `DM-Tensor` (general tensors, ridgunc 0.9.41).

## Invariants
- `hash` is 31 bits of SHA-256(`seed` + key), plus 1, so a used slot is never 0.
- `2 * size <= cap` and `size <= room`. The slot table doubles when an insert would pass half full; the dense tensors double when full.
- Each key appears in exactly one slot; probing is linear from `hash % cap`.

## Lifecycle
- Created by `hashmap empty`; changed in place by `put` and `add` (ADR-0009); freed by RMM when the last reference goes.
