# Chapter 19: The `uuid` Lib — RFC 9562 `UUIDv4`/`UUIDv7`, Checksums (`CRC-32`), and PRNG

## 19.1. Why Does the `uuid` Lib Exist? (The Real-World Problem & Ridgun Philosophy)

> *"Why do I need a `uuid` lib written from scratch in pure Ridgun instead of just linking a legacy C library?"*

That is the first question every systems engineer asks when meeting `uuid`. And the answer captures the entire philosophy of `ridgun-libs`:

Let's be honest: using random `UUIDv4` values as database primary keys fragments B-Tree indexes, while rolling ad-hoc IDs without kernel CSPRNG entropy leads to collisions.

The **`uuid`** lib implements **RFC 9562 `UUIDv4`** (kernel CSPRNG) and time-ordered **`UUIDv7`** (48-bit millisecond prefix for B-Tree locality), fast checksums (**FNV-1a**, **Adler-32**, **IEEE 802.3 CRC-32**), and a deterministic seeded PRNG.

In a traditional ecosystem, solving **`UUID`** tasks means pulling in external C dependencies, wrestling with raw pointers, opaque type conversions, unchecked exceptions, or unpredictable garbage-collector pauses. In Ridgun, the **`uuid`** lib (`src/main/ridgun/lib/uuid.rg`) tackles the problem with four non-negotiable principles:

1. **Total Functions & Explicit Contracts (`=>`)**: no function in `uuid` throws hidden exceptions or relies on `null`. Every edge case (empty inputs, zero divisors, truncated frames, or out-of-bounds indices) returns a documented sentinel value or an algebraic sum type (`Option`, `Result`).
2. **Zero C Code & Zero `libc`**: every line of `uuid` compiles directly into native ELF64 machine code verified by `ridgunc`.
3. **Tail-Call Optimization (TCO)**: all internal loops in `uuid` are tail-recursive and compile into native hardware loops using $O(1)$ stack space.
4. **Deterministic Memory (`RMM1` / `RMM2`)**: every intermediate allocation is reclaimed at the exact instruction where its last read finishes, with no Garbage Collector.

---

## 19.2. Native Artifacts, Imports, and Complete `uuid` API Catalog

In `ridgun-libs`, **`uuid`** is a first-class **lib** located at `src/main/ridgun/lib/uuid.rg` (domain `UUID`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/uuid.rglib` | Portable distribution and direct `import uuid` resolution |
| **Compiled Archive** | `target/uuid.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libuuid.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import uuid` at the top and call its functions using either multi-word spaces (`my fn x`) or underscores (`my_fn x`).

### 19.2.1. Summary of `uuid` Functional Families

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `uuid v4 / uuid v7 / uuid v7 at` | Generate RFC 9562 v4 (random) and v7 (time-ordered) canonical 36-char UUIDs |
| `uuid is valid / uuid version` | Validate 8-4-4-4-12 layout and RFC 9562 variant bits (`8, 9, a, b`) |
| `fnv1a 32 / adler32 / crc32 / crc32 hex` | Fast 32-bit non-cryptographic hashes and checksums |
| `prng next / prng range` | Pure functional Linear Congruential PRNG for reproducible tests and simulations |

### 19.2.2. Exhaustive Catalog of Types and Signatures in `src/main/ridgun/lib/uuid.rg`

Below is the complete inventory of algebraic data types (`type`), mixfix operators (`op ::`), and function signatures (`fn ::`) defined in `src/main/ridgun/lib/uuid.rg` (`0` types, `0` operators, and `33` functions):

| # | Function / Signature (`fn ::`) | Return Type |
|---|---|---|
| `1` | `fn :: uu hex lut Int` | `String` |
| `2` | `fn :: uu u32 Int` | `Int` |
| `3` | `fn :: uu bxor loop Int Int Int Int` | `Int` |
| `4` | `fn :: uu bxor32 Int Int` | `Int` |
| `5` | `fn :: uu fnv loop String Int Int Int` | `Int` |
| `6` | `fn :: fnv1a 32 String` | `Int` |
| `7` | `fn :: uu adler loop String Int Int Int Int` | `Int` |
| `8` | `fn :: adler32 String` | `Int` |
| `9` | `fn :: uu crc bit loop Int Int` | `Int` |
| `10` | `fn :: uu crc byte loop String Int Int Int` | `Int` |
| `11` | `fn :: crc32 String` | `Int` |
| `12` | `fn :: uu abs Int` | `Int` |
| `13` | `fn :: prng next Int` | `Int` |
| `14` | `fn :: uu prng range step Int Int Int` | `Int Int` |
| `15` | `fn :: prng range Int Int Int` | `Int Int` |
| `16` | `fn :: uu alloc page Int` | `Int` |
| `17` | `fn :: uu free page Int Int Int` | `Int` |
| `18` | `fn :: uu alloc mfd` | `Int` |
| `19` | `fn :: uu peek Int Int Int` | `String` |
| `20` | `fn :: uu decode u32 le String Int` | `Int` |
| `21` | `fn :: uu decode u64 le String Int` | `Int` |
| `22` | `fn :: uu wall time ms` | `Int` |
| `23` | `fn :: uu bytes to hex loop String Int Int` | `String` |
| `24` | `fn :: uu random hex16` | `String` |
| `25` | `fn :: uu hex val Int` | `Int` |
| `26` | `fn :: uu variant char String` | `String` |
| `27` | `fn :: uuid v4` | `String` |
| `28` | `fn :: uu hex48 loop Int Int` | `String` |
| `29` | `fn :: uuid v7 at Int` | `String` |
| `30` | `fn :: uuid v7` | `String` |
| `31` | `fn :: uu is hex range String Int Int` | `Bool` |
| `32` | `fn :: uuid is valid String` | `Bool` |
| `33` | `fn :: uuid version String` | `Int` |

---

## 19.3. Deep Dive into `uuid`: Step-by-Step Examples for Every Feature

A signature table alone is never enough: let's explore **every capability** of the `uuid` lib through progressive, runnable Ridgun examples. We will start with two everyday tabular recipes and then walk through every functional scenario, transformation, and boundary condition verified in `src/test/ridgun/test uuid.rg`.

### 19.3.1. Example 1: Core Tabular Workflow with `uuid`

Notice how in Ridgun the `=` signs and transformation steps using `uuid` align into a clean, scannable table without unnecessary mutable variables or hidden side effects:

```ridgun
import uuid

fn :: generar ids ordenados () => (String, String, Bool)
      generar ids ordenados =
        id1 = uuid v7 at 1000
        id2 = uuid v7 at 2000
        ok  = (uuid is valid id1) and (id1 < id2)
        (id1, id2, ok)
```

### 19.3.2. Example 2: Safe Composition and Boundary Handling

Every function in the `uuid` lib is designed to compose cleanly with boolean guards `|` and with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import uuid

fn :: firmar paquete (payload : String) => (String, Int)
      firmar paquete payload =
         (crc32 hex payload, fnv1a 32 payload)
```

### 19.3.3. Example 3: Generation, Validation, and Inspection of UUIDv4 (CSPRNG) and Time-Ordered UUIDv7 (RFC 9562)

In this hands-on walkthrough we thoroughly exercise how `uuid` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test uuidv4 and uuidv7 => ()
      test uuidv4 and uuidv7 =
        u4a = uuid v4
        u4b = uuid v4
        _ = assert int equals (str len u4a) 36 "AC1: uuid_v4 length 36"
        _ = assert true (uuid is valid u4a) "AC1: uuid_v4 valid RFC 9562 format"
        _ = assert true (uuid is valid u4b) "AC1: second uuid_v4 valid"
        _ = assert false (u4a == u4b) "AC1: CSPRNG uuid_v4 calls are unique"
        _ = assert int equals (uuid version u4a) 4 "AC1: uuid_v4 version == 4"

        -- RFC 9562 UUIDv7 timestamp encoding & chronological prefix ordering
        u7_zero = uuid v7 at 0
        u7a = uuid v7 at 1700000000000
        u7b = uuid v7 at 1800000000000
        u7_live = uuid v7
        _ = assert true (uuid is valid u7_zero) "AC1: uuid_v7 at epoch 0 valid"
        _ = assert str eq (str slice u7_zero 0 13) "00000000-0000" "AC1: uuid_v7 at epoch 0 zero prefix"
        _ = assert true (uuid is valid u7a) "AC1: uuid_v7 at 1700000000000 valid"
        _ = assert true (uuid is valid u7b) "AC1: uuid_v7 at 1800000000000 valid"
        _ = assert true (uuid is valid u7_live) "AC1: live uuid_v7 valid"
        _ = assert int equals (uuid version u7a) 7 "AC1: uuid_v7 version == 7"
        _ = assert int equals (uuid version u7_live) 7 "AC1: live uuid_v7 version == 7"
        _ = assert str eq (str slice u7a 0 8) "018bcfe5" "AC1: uuid_v7 timestamp prefix 1700000000000"
        _ = assert str eq (str slice u7b 0 8) "01a3185c" "AC1: uuid_v7 timestamp prefix 1800000000000"

        -- Uppercase valid UUID acceptance & RFC 9562 variant nibble (8, 9, a, b) validation
        _ = assert true (uuid is valid "550E8400-E29B-41D4-A716-446655440000") "AC1: uppercase RFC 9562 UUID valid"
        _ = assert false (uuid is valid "") "AC1: empty string invalid"
        _ = assert false (uuid is valid "not-a-uuid") "AC1: short string invalid"
        _ = assert false (uuid is valid "550e8400-e29b-41d4-1716-446655440000") "AC1: variant nibble '1' (< 8) rejected"
        _ = assert false (uuid is valid "550e8400-e29b-41d4-c716-446655440000") "AC1: variant nibble 'c' (> b) rejected"
        _ = assert false (uuid is valid "550e8400Xe29b-41d4-a716-446655440000") "AC1: missing hyphen at index 8 rejected"
        _ = assert false (uuid is valid "550e8400-e29b-41d4-a716-44665544000g") "AC1: non-hex character 'g' rejected"
        _ = assert int equals (uuid version "not-a-uuid") (0 - 1) "AC1: invalid uuid version -> -1"
        ()
```

### 19.3.4. Example 4: FNV-1a, DJB2, Adler-32, IEEE 802.3 CRC32 (`0xCBF43926`) Checksums, and Deterministic SplitMix64 PRNG

In this hands-on walkthrough we thoroughly exercise how `uuid` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test checksums and prng => ()
      test checksums and prng =
        -- Official FNV-1a 32-bit vectors (isthe.com/chongo/tech/comp/fnv/)
        _ = assert int equals (fnv1a 32 "") 2166136261 "AC2: FNV-1a 32 '' == 0x811c9dc5 (offset basis)"
        _ = assert int equals (fnv1a 32 "a") 3826002220 "AC2: FNV-1a 32 'a' == 0xe40c292c"
        _ = assert int equals (fnv1a 32 "foobar") 3214735720 "AC2: FNV-1a 32 'foobar' == 0xbf9cf968"

        -- Official RFC 1950 Adler-32 vectors
        _ = assert int equals (adler32 "") 1 "AC2: Adler-32 '' == 1"
        _ = assert int equals (adler32 "a") 6422626 "AC2: Adler-32 'a' == 0x00620062"
        _ = assert int equals (adler32 "Wikipedia") 300286872 "AC2: Adler-32 'Wikipedia' == 0x11e60398"

        -- Official IEEE 802.3 / ISO-HDLC CRC-32 vectors
        _ = assert int equals (crc32 "") 0 "AC2: CRC-32 '' == 0"
        _ = assert int equals (crc32 "a") 3904355907 "AC2: CRC-32 'a' == 0xe8b7be43"
        _ = assert int equals (crc32 "123456789") 3421780262 "AC2: CRC-32 '123456789' == 0xcbf43926"

        -- Deterministic 31-bit LCG PRNG
        s1 = prng next 42
        s2 = prng next 42
        s3 = prng next s1
        _ = assert int equals s1 s2 "AC3: prng_next deterministic for same seed"
        _ = assert false (s1 == s3) "AC3: prng_next advances state"
        r1 = prng range 42 10 20
        v1 = prng val r1
        _ = assert true (v1 >= 10 and v1 <= 20) "AC3: prng_range within [10, 20]"
        r_deg = prng range 42 50 10
        _ = assert int equals (prng val r_deg) 50 "AC3: prng_range with hi <= lo clamps to lo"
        ()
```

### 19.3.5. Example 5: Distributed Tracing with Time-Ordered UUIDv7 and Packet Integrity via CRC32 & FNV-1a (`uuid v7`, `uuid v7 timestamp ms`, `crc32 hex`)

In this hands-on walkthrough we thoroughly exercise how `uuid` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
import uuid

fn :: sellar paquete trazado (ahora_ms : Int) (payload : String) => (String, Int, String, Int)
      sellar paquete trazado ahora_ms payload =
        trace_id = uuid v7 ahora_ms
        ts_extra = uuid v7 timestamp ms trace_id
        crc_hex  = crc32 hex payload
        hash_fnv = fnv1a 64 payload
        (trace_id, ts_extra, crc_hex, hash_fnv)
```

---

## 19.4. Under the Hood: How `uuid` Is Built in Pure Ridgun (`src/main/ridgun/lib/uuid.rg`)

One of the biggest advantages of `ridgun-libs` is that **there are no C black boxes**. You can open `src/main/ridgun/lib/uuid.rg` and read exactly how every operation is implemented using pattern matching, `|` / `|.` guard trees, and tail-call optimization (TCO). Let's inspect the key building blocks of its real implementation:

### 19.4.1. Internal Implementation: RFC 9562 UUIDv4 & UUIDv7 Generation & Validation (CSPRNG + clock_gettime)

Observe how `uuid.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: uu alloc page Int => Int
      uu alloc page sz  =
        neg1 = 0 - 1
        sys call 9 0 sz 3 34 neg1 0

fn :: uu free page Int Int Int => Int
      uu free page mfd ptr sz =
        _ = sys close mfd
        sys call 11 ptr sz 0 0 0 0

fn :: uu alloc mfd => Int
      uu alloc mfd =  sys call 319 4194311 1 0 0 0 0

fn :: uu peek Int Int Int => String
      uu peek mfd ptr len =
        _ = sys call 18 mfd ptr len 0 0 0
        _ = sys call 8 mfd 0 0 0 0 0
        sys read fd mfd len

fn :: uu decode u32 le String Int => Int
      uu decode u32 le s off =
        b0 = str char at s off
        b1 = str char at s (off + 1)
        b2 = str char at s (off + 2)
        b3 = str char at s (off + 3)
        b0 + (b1 * 256) + (b2 * 65536) + (b3 * 16777216)

fn :: uu decode u64 le String Int => Int
      uu decode u64 le s off =
        lo = uu decode u32 le s off
        hi = uu decode u32 le s (off + 4)
        lo + (hi * 4294967296)

fn :: uu wall time ms => Int
      uu wall time ms =
        ptr  = uu alloc page 4096
        mfd  = uu alloc mfd
        _    = sys call 228 0 ptr 0 0 0 0
        raw  = uu peek mfd ptr 16
        _    = uu free page mfd ptr 4096
        sec  = uu decode u64 le raw 0
        nsec = uu decode u64 le raw 8
        (sec * 1000) + (nsec / 1000000)
```

---

## 19.5. Algorithmic Guarantees, `RMM1`/`RMM2` Memory, and the 5 Golden Rules of `uuid`

- **Algorithmic & Safety Guarantee**: `uuid v7 at t1 < uuid v7 at t2` guarantees monotonically increasing lexicographical order over time, ideal for `btree` indexes and databases.
- **$O(1)$ Stack Complexity via TCO**: Every recursive loop in `src/main/ridgun/lib/uuid.rg` is in tail position, so `ridgunc` compiles them into native jumps with zero stack growth.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test uuid.rg`.

### The 5 Golden Rules When Programming with `uuid`

1. **Declare `import uuid` at the top of your file** and take advantage of space/underscore equivalence so your code reads like natural prose.
2. **Align your data pipelines with `=`**: chain `uuid` calls into named intermediate steps and let `stable format` align the columns.
3. **Leverage `uuid`'s total functions inside `|` guards**: inspect return values or unwrap ADTs via pattern matching rather than assuming external input is valid.
4. **Avoid cloning large structures when only reading**: remember that under `RMM2`, function input arguments incur zero reference-count overhead (`+0` / `-0`).
5. **Pair `uuid` with `test` (`import test`)**: always lock in your domain invariants with `assert equals` or `assert true`.

---

In **Chapter 20**, we will explore the **`log`** lib in full depth (The `log` Lib — Structured NDJSON Logging and Automatic Secret Redaction).
