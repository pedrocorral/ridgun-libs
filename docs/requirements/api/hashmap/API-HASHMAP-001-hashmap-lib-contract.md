---
id: API-HASHMAP-001
title: Public lib contract for hashmap (hashmap.ridgunlib / libhashmap.so)
status: approved
implements: [FR-HASHMAP-001]
auth: none
---
# API-HASHMAP-001 — Public lib contract for `hashmap` (`hashmap.ridgun`)

## Request
- Imported via `import hashmap`.
- `hashmap empty => HashMap V`
- `hashmap put (HashMap V) String V => HashMap V`
- `hashmap get (HashMap V) String V => V`: the third argument is the default.
- `hashmap has (HashMap V) String => Bool`
- `hashmap add (HashMap Int) String Int => HashMap Int`
- `hashmap size (HashMap V) => Int`
- `hashmap pairs (HashMap V) => [String V]`

## Responses
| Code | When | Body |
|---|---|---|
| `HashMap V` | `empty`, `put`, `add` | The map to use from now on (the same map, updated in place) |
| `V` | `get` | The value of the key, or the default |
| `Bool` / `Int` | `has` / `size` | Whether the key is present / number of keys |
| `[String V]` | `pairs` | One pair per key, in first-insertion order |

## Rules
- Every exported function starts with `hashmap `.
- `put` and `add` change the map they receive and return it (ADR-0009). Callers use the returned map and do not keep the old one.
- The fields of `HashMap` are private (see DM-HashMap).
