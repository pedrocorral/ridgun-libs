---
id: API-HASH-001
title: Public lib contract for hash (hash.ridgunlib)
status: implemented
implements: [FR-HASH-001]
auth: none
---
# API-HASH-001 — Public lib contract for `hash` (`hash.ridgun`)

## Request
- Imported via `import hash`.
- `siphash13 range key data from to => Int`: key (16 bytes), data, from (included), to (excluded). The 64 bits of SipHash-1-3. Native operation of the compiler (ridgunc 1.0.44); it needs no import.
- `siphash13 range low key data from to => Int`: the low 32 bits of the same hash. Native too.
- `siphash13 reference String String Int Int Int => Int`: the same hash in plain Ridgun (last argument 0 for the low 32 bits, 1 for the 64 bits). For tests and for reading.
- `siphash13 String String => Int`: key, the whole data.
- `siphash new key => String`: 16 random bytes.

## Responses
| Result | When | Meaning |
|---|---|---|
| `Int` | key of 16 bytes and a range inside the data | The hash. With all 64 bits it can be negative as an `Int`. |
| `0` | any other key length or range | Invalid input |
| `""` | `siphash new key` when the random source cannot be read | No key |

## Rules
- The same key and bytes give the same result in every version and on every architecture (`FR-HASH-001`).
- Speed: see `FR-HASH-001`, Constraints. The lib does not define `siphash13 range`, so that the native operation is the one called.
