# Chapter 35: The `hash` Lib — SipHash-1-3 Keyed Hashing for Hash Tables

## 35.1. Why Does the `hash` Lib Exist? (The Real-World Problem & Ridgun Philosophy)

> *"Why do I need a `hash` lib written from scratch in pure Ridgun instead of just linking a legacy C library?"*

That is the first question every systems engineer asks when meeting `hash`. And the answer captures the entire philosophy of `ridgun-libs`:

Let's be honest: when the hash function of a hash table is public, whoever controls the keys can send thousands that land in the same slot, and one request then costs what a million should (hash flooding).

The **`hash`** lib implements **SipHash-1-3** (Aumasson & Bernstein) with a 128-bit key and a 64-bit result. `siphash13` hashes a whole string; the compiler's native operations `siphash13 range` and `siphash13 range low` (ridgunc 1.0.44) hash a range of bytes in some tens of nanoseconds; `siphash13 reference` is the same hash written in plain Ridgun, to read and to test against; and `siphash new key` draws a random 16-byte key from the system.

In a traditional ecosystem, solving **`HASH`** tasks means pulling in external C dependencies, wrestling with raw pointers, opaque type conversions, unchecked exceptions, or unpredictable garbage-collector pauses. In Ridgun, the **`hash`** lib (`src/main/ridgun/lib/hash.ridgun`) tackles the problem with four non-negotiable principles:

1. **Declare `import hash` (or `import hash as alias`) at the top of your file**: every lib defines its `module :: hash` namespace, and under `--strict` multi-word functions are always called with natural spaces.
2. **Chain your data pipelines left-to-right with `->`**: write `input step one -> step two -> result`, use `(+ _ _ +)` sequence masks to destructure tuples/lists, and omit `_ =` on sequential statements (or discard with `-> ()`).
3. **Tail-Call Optimization (TCO)**: all internal loops in `hash` are tail-recursive and compile into native hardware loops using $O(1)$ stack space.
4. **Deterministic Memory (`RMM1` / `RMM2`)**: every intermediate allocation is reclaimed at the exact instruction where its last read finishes, with no Garbage Collector.

---

## 35.2. Native Artifacts, Imports, and Complete `hash` API Catalog

In `ridgun-libs`, **`hash`** is a first-class **lib** located at `src/main/ridgun/lib/hash.ridgun` (domain `HASH`). When built with `stable bundle`, it compiles into one native artifact:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/hash.ridgunlib` | Portable distribution and direct `import hash` resolution |

> Every lib declares its own namespace via `module :: hash`: simply write `import hash` (or `import hash as alias`) at the top and call its functions with natural spaces (`my fn x`) and left-to-right `->` pipelines (`x my fn -> result`).

### 35.2.1. Summary of `hash` Functional Families

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `siphash13` | SipHash-1-3 of a whole string under a 16-byte key, as a 64-bit `Int` |
| `siphash13 range / siphash13 range low` | Native operations of the compiler: the 64 bits, or the low 32 bits, of the hash of a range of bytes |
| `siphash13 reference` | The same hash in plain Ridgun, on 32-bit halves: the definition the native operation is tested against |
| `siphash new key` | A random 16-byte key from the system random source (`""` when it cannot be read) |

### 35.2.2. Exhaustive Catalog of Types and Signatures in `src/main/ridgun/lib/hash.ridgun`

Below is the complete inventory of algebraic data types (`type`), mixfix operators (`op ::`), and function signatures (`fn ::`) defined in `src/main/ridgun/lib/hash.ridgun` (`0` types, `0` operators, and `11` functions):

| # | Function / Signature (`fn ::`) | Return Type |
|---|---|---|
| `1` | `fn :: hs byte String Int` | `Int` |
| `2` | `fn :: hs tail String Int Int` | `Int` |
| `3` | `fn :: hs pick Int Int Int` | `Int` |
| `4` | `fn :: hs key word String Int` | `Int` |
| `5` | `fn :: siphash13 loop String Int Int Int Int Int Int Int Int Int Int Int Int Int` | `Int` |
| `6` | `fn :: siphash13 last String Int Int Int Int Int Int Int Int Int Int Int Int` | `Int` |
| `7` | `fn :: siphash13 start String String Int Int Int` | `Int` |
| `8` | `fn :: siphash13 String String` | `Int` |
| `9` | `fn :: siphash13 reference String String Int Int Int` | `Int` |
| `10` | `fn :: siphash new key` | `String` |
| `11` | `fn :: hs key of (Int String)` | `String` |

---

## 35.3. Deep Dive into `hash`: Step-by-Step Examples for Every Feature

A signature table alone is never enough: let's explore **every capability** of the `hash` lib through progressive, runnable Ridgun examples. We will start with two everyday tabular recipes and then walk through every functional scenario, transformation, and boundary condition verified in `src/test/ridgun/test hash.ridgun`.

### 35.3.1. Example 1: Core Tabular Workflow with `hash`

Notice how in Ridgun the `=` signs and transformation steps using `hash` align into a clean, scannable table without unnecessary mutable variables or hidden side effects:

```ridgun
import hash

fn :: cubo de clave String String Int => Int
      cubo de clave semilla clave cubos =
        siphash13 range low semilla clave 0 (str len clave) -> h
        h % cubos
```

### 35.3.2. Example 2: Safe Composition and Boundary Handling

Every function in the `hash` lib is designed to compose cleanly with boolean guards `|` and with the rest of the 38 libs in `ridgun-libs`:

```ridgun
import hash

fn :: huella segura String String => Int
      huella segura semilla dato =
        | (str len semilla) != 16 = 0
        | otherwise               = siphash13 semilla dato
```

### 35.3.3. Example 3: SipHash-1-3 Vectors for Inputs of 0 to 64 Bytes: the Low and High 32-Bit Halves

In this hands-on walkthrough we thoroughly exercise how `hash` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test siphash13 vectors => ()
      test siphash13 vectors =
        key = tensor to str (seq bytes (Tensor[U8 * 16]) 0 16)
        msg = tensor to str (seq bytes (Tensor[U8 * 64]) 0 64)
        siphash13 range low key msg 0 0 -> assert int equals 84919516 "low 32 bits, 0 bytes"
        (siphash13 range key msg 0 0) shr 32 -> assert int equals 2880176472 "high 32 bits, 0 bytes"
        siphash13 range low key msg 0 1 -> assert int equals 2102905491 "low 32 bits, 1 bytes"
        (siphash13 range key msg 0 1) shr 32 -> assert int equals 3388251123 "high 32 bits, 1 bytes"
        siphash13 range low key msg 0 7 -> assert int equals 2612072768 "low 32 bits, 7 bytes"
        (siphash13 range key msg 0 7) shr 32 -> assert int equals 3549592984 "high 32 bits, 7 bytes"
        siphash13 range low key msg 0 8 -> assert int equals 2368313998 "low 32 bits, 8 bytes"
        (siphash13 range key msg 0 8) shr 32 -> assert int equals 915445009 "high 32 bits, 8 bytes"
        siphash13 range low key msg 0 9 -> assert int equals 1812348388 "low 32 bits, 9 bytes"
        (siphash13 range key msg 0 9) shr 32 -> assert int equals 631541427 "high 32 bits, 9 bytes"
        siphash13 range low key msg 0 15 -> assert int equals 709990742 "low 32 bits, 15 bytes"
        (siphash13 range key msg 0 15) shr 32 -> assert int equals 3542145133 "high 32 bits, 15 bytes"
        siphash13 range low key msg 0 16 -> assert int equals 2106624870 "low 32 bits, 16 bytes"
        (siphash13 range key msg 0 16) shr 32 -> assert int equals 3427786010 "high 32 bits, 16 bytes"
        siphash13 range low key msg 0 17 -> assert int equals 1675352076 "low 32 bits, 17 bytes"
        (siphash13 range key msg 0 17) shr 32 -> assert int equals 2633132176 "high 32 bits, 17 bytes"
        siphash13 range low key msg 0 25 -> assert int equals 1885014393 "low 32 bits, 25 bytes"
        (siphash13 range key msg 0 25) shr 32 -> assert int equals 1171085608 "high 32 bits, 25 bytes"
        siphash13 range low key msg 0 63 -> assert int equals 3082531752 "low 32 bits, 63 bytes"
        (siphash13 range key msg 0 63) shr 32 -> assert int equals 2635698274 "high 32 bits, 63 bytes"
        siphash13 range low key msg 0 64 -> assert int equals 1263165541 "low 32 bits, 64 bytes"
        (siphash13 range key msg 0 64) shr 32 -> assert int equals 4051277804 "high 32 bits, 64 bytes"
        (siphash13 range key msg 0 15) == (siphash13 key (str slice msg 0 15)) -> assert true "whole data equals the range"
        siphash13 range low key ("xx" + msg) 2 27 -> assert int equals 1885014393 "a range inside a longer string"
        siphash13 range low "0123456789abcdef" "abc" 0 3 -> assert int equals 1783201848 "printable key"
        siphash13 range "short" msg 0 8 -> assert int equals 0 "a key that is not 16 bytes gives 0"
        siphash13 range key msg 9 8 -> assert int equals 0 "a reversed range gives 0"
        siphash13 range key msg 0 65 -> assert int equals 0 "a range past the data gives 0"
        (siphash13 range low key msg 0 8) != (siphash13 range low "0123456789abcdef" msg 0 8) -> assert true "another key, another hash"
        k1 = siphash new key
        k2 = siphash new key
        str len k1 -> assert int equals 16 "a new key has 16 bytes"
        k1 != k2 -> assert true "two new keys differ"
```

### 35.3.4. Example 4: The Native Operation against the Plain-Ridgun Reference at Any Offset

In this hands-on walkthrough we thoroughly exercise how `hash` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test native matches reference => ()
      test native matches reference =
        key = "0123456789abcdef"
        msg = tensor to str (seq bytes (Tensor[U8 * 96]) 0 96)
        same as reference key msg 0 0 0 -> assert int equals 0 "native equals reference, offset 0"
        same as reference key msg 3 0 0 -> assert int equals 0 "native equals reference, offset 3"
        same as reference key msg 25 0 0 -> assert int equals 0 "native equals reference, offset 25"
```

---

## 35.4. Under the Hood: How `hash` Is Built in Pure Ridgun (`src/main/ridgun/lib/hash.ridgun`)

One of the biggest advantages of `ridgun-libs` is that **there are no C black boxes**. You can open `src/main/ridgun/lib/hash.ridgun` and read exactly how every operation is implemented using pattern matching, `|` / `|.` guard trees, and tail-call optimization (TCO). Let's inspect the key building blocks of its real implementation:

### 35.4.1. Internal Implementation: SipRound on 32-Bit Halves: One Message Word per Turn

Observe how `hash.ridgun` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
-- The byte at `i` as 0..255.
fn :: hs byte String Int => Int
      hs byte s i =  (str char at s i) and 255

-- The byte at `i`, or 0 at or after `to`.
fn :: hs tail String Int Int => Int
      hs tail s i to =
        | i >= to   = 0
        | otherwise = (str char at s i) and 255

fn :: hs pick Int Int Int => Int
      hs pick want hi lo =
        | want == 0 = lo
        | otherwise = (hi shl 32) or lo

-- Little-endian 32-bit word of the key at `off`.
fn :: hs key word String Int => Int
      hs key word k off =  (hs byte k off) or ((hs byte k (off + 1)) shl 8) or ((hs byte k (off + 2)) shl 16) or ((hs byte k (off + 3)) shl 24)

-- One message word per turn: v3 ^= m, 1 round(s), v0 ^= m. The 8 state values are the halves of v0..v3.
fn :: siphash13 loop String Int Int Int Int Int Int Int Int Int Int Int Int Int => Int
      siphash13 loop s off full to n want a0 b0 a1 b1 a2 b2 a3 b3 =
        | off >= full = siphash13 last s off to n want a0 b0 a1 b1 a2 b2 a3 b3
        | otherwise   =
          t1 = (hs byte s off) or ((hs byte s (off + 1)) shl 8) or ((hs byte s (off + 2)) shl 16) or ((hs byte s (off + 3)) shl 24)
          t2 = (hs byte s (off + 4)) or ((hs byte s (off + 5)) shl 8) or ((hs byte s (off + 6)) shl 16) or ((hs byte s (off + 7)) shl 24)
          t3 = a3 xor t2
          t4 = b3 xor t1
          t5 = b0 + b1
          t6 = ((a0 + a1) + (t5 shr 32)) and 0xFFFFFFFF
          t7 = t5 and 0xFFFFFFFF
          t8 = ((a1 shl 13) or (b1 shr 19)) and 0xFFFFFFFF
          t9 = ((b1 shl 13) or (a1 shr 19)) and 0xFFFFFFFF
          t10 = t8 xor t6
          t11 = t9 xor t7
          t12 = b2 + t4
          t13 = ((a2 + t3) + (t12 shr 32)) and 0xFFFFFFFF
          t14 = t12 and 0xFFFFFFFF
          t15 = ((t3 shl 16) or (t4 shr 16)) and 0xFFFFFFFF
          t16 = ((t4 shl 16) or (t3 shr 16)) and 0xFFFFFFFF
          t17 = t15 xor t13
          t18 = t16 xor t14
          t19 = t6 + t18
          t20 = ((t7 + t17) + (t19 shr 32)) and 0xFFFFFFFF
          t21 = t19 and 0xFFFFFFFF
          t22 = ((t17 shl 21) or (t18 shr 11)) and 0xFFFFFFFF
          t23 = ((t18 shl 21) or (t17 shr 11)) and 0xFFFFFFFF
          t24 = t22 xor t20
          t25 = t23 xor t21
          t26 = t14 + t11
          t27 = ((t13 + t10) + (t26 shr 32)) and 0xFFFFFFFF
          t28 = t26 and 0xFFFFFFFF
          t29 = ((t10 shl 17) or (t11 shr 15)) and 0xFFFFFFFF
          t30 = ((t11 shl 17) or (t10 shr 15)) and 0xFFFFFFFF
          t31 = t29 xor t27
          t32 = t30 xor t28
          t33 = t20 xor t2
          t34 = t21 xor t1
          siphash13 loop s (off + 8) full to n want t33 t34 t31 t32 t28 t27 t24 t25
```

### 35.4.2. Internal Implementation: Public API: `siphash13`, the Plain-Ridgun Reference, and Random Keys

Observe how `hash.ridgun` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
-- v0..v3 from the key (k0 = bytes 0-7, k1 = bytes 8-15, little-endian) and the constants "somepseudorandomlygeneratedbytes".
fn :: siphash13 start String String Int Int Int => Int
      siphash13 start key s from to want =
        k0l = hs key word key 0
        k0h = hs key word key 4
        k1l = hs key word key 8
        k1h = hs key word key 12
        n   = to - from
        siphash13 loop s from (from + ((n shr 3) shl 3)) to n want (k0h xor 0x736f6d65) (k0l xor 0x70736575) (k1h xor 0x646f7261) (k1l xor 0x6e646f6d) (k0h xor 0x6c796765) (k0l xor 0x6e657261) (k1h xor 0x74656462) (k1l xor 0x79746573)

-- `siphash13 range key data from to` (64 bits) and `siphash13 range low key data from to` (the low 32 bits)
-- are operations of the compiler since ridgunc 1.0.44: native, some tens of ns for a short key. They take
-- a 16-byte key and the bytes `from` (included) to `to` (excluded) of `data`; a key of another length or a
-- range outside `data` gives 0. This lib does not define them, so that the native ones are used.

-- SipHash-1-3 of the whole of `data`.
fn :: siphash13 String String => Int
      siphash13 key data =  siphash13 range key data 0 (str len data)

-- The same hash written in plain Ridgun (about 2 µs for a 25-byte key): the definition the native operation
-- is tested against, and the one to read. `want` 0 gives the low 32 bits, anything else the 64 bits.
fn :: siphash13 reference String String Int Int Int => Int
      siphash13 reference key data from to want =
        | (str len key) != 16 or from < 0 or to < from or to > (str len data) = 0
        | otherwise = siphash13 start key data from to want

-- A new random 16-byte key (from the system random source). "" when it cannot be read.
fn :: siphash new key => String
      siphash new key =  hs key of (sys random bytes 16)

fn :: hs key of (Int String) => String
      hs key of (rc, k) =
        | rc == 0 and (str len k) == 16 = k
        | otherwise                     = ""
```

---

## 35.5. Algorithmic Guarantees, `RMM1`/`RMM2` Memory, and the 5 Golden Rules of `hash`

- **Algorithmic & Safety Guarantee**: A key of another length, or a range outside the data, gives `0` instead of reading out of bounds, and the native operation returns the same 64 bits as the plain-Ridgun reference for every length and offset tested.
- **$O(1)$ Stack Complexity via TCO**: Every recursive loop in `src/main/ridgun/lib/hash.ridgun` is in tail position, so `ridgunc` compiles them into native jumps with zero stack growth.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test hash.ridgun`.

### The 5 Golden Rules When Programming with `hash`

1. **Declare `import hash` at the top of your file** and call its functions with spaces, exactly as they are declared, so your code reads like natural prose.
2. **Align your data pipelines with `=`**: chain `hash` calls into named intermediate steps and let `stable format` align the columns.
3. **Leverage `hash`'s total functions inside `|` guards**: inspect return values or unwrap ADTs via pattern matching rather than assuming external input is valid.
4. **Avoid cloning large structures when only reading**: remember that under `RMM2`, function input arguments incur zero reference-count overhead (`+0` / `-0`).
5. **Pair `hash` with `test` (`import test`)**: always lock in your domain invariants with `assert equals` or `assert true`.

---

In **Chapter 36**, we will explore the **`hashmap`** lib in full depth (The `hashmap` Lib — A Hash Map from `String` Keys to Any Value, on Tensors and Seeded with SipHash).
