# Chapter 23: The `io` Lib — Typed `IoResult` Errors, `with timeout` Descriptor I/O, and Processes

## 1. Why Does the `io` Lib Exist?

Let's be honest: an unbounded `read()` call or child process execution with no deadline is an open invitation for one stalled peer to exhaust every worker in your server.

The **`io`** lib models every system operation through explicit ADTs (`IoError`, `IoResult[A]`), pairs non-blocking `ppoll` with Ridgun's lexical `with timeout wait_ms do` quotas, and exports the `read fd ... timeout` and `write fd ... timeout` mixfix operators.

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`io`** is a first-class **lib** located at `src/main/ridgun/lib/io.rg` (domain `IO`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/io.rglib` | Portable distribution and direct `import io` resolution |
| **Compiled Archive** | `target/io.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libio.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import io` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `io`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `type IoError / type IoResult[A]` | `IoNotFound | IoPermission | IoTimeout | IoRefused | IoReset | IoEOF | IoInvalid | IoSysError` |
| `io read with timeout / io write with timeout` | Non-blocking descriptor read/write bounded by `wait_ms` |
| `read fd N max M timeout T / write fd N data S timeout T` | Ergonomic mixfix operators (`op ::`) for deadline-bounded descriptor I/O |
| `io read file / io write file / io read lines` | Safe file and line-stream helpers returning `IoResult` |
| `exec with timeout : String -> Int -> IoResult[ProcStatus]` | Run an external command bounded by a lexical `with timeout` quota |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `io`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import io

fn :: leer peticion segura (fd : Int) => String
      leer peticion segura fd =
        res = read fd fd max 4096 timeout 250
        io unwrap or res ""
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `io` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import io

fn :: describir fallo () => String
      describir fallo =
        format io error (IoTimeout "read" 250)
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: No read, write, or child command executed through `io` with a `wait_ms` quota can ever block the calling thread or actor indefinitely.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_io.rg`.
