# Chapter 22: The `posix` Lib — 2-Layer PAL (`SysOs`, `SysArch`), Clocks, Signals, and CSPRNG

## 1. Why Does the `posix` Lib Exist?

Let's be honest: flags like `O_CREAT` and `O_NONBLOCK` or syscall numbers differ across Linux, macOS, and CPU architectures (`X86_64` vs `Arm64`), and C codebases solve it with an unreadable `#ifdef` jungle.

The **`posix`** lib implements Ridgun's 2-layer **Platform Abstraction Layer (PAL)** via tabular pattern matching on `sys os` (`Linux | MacOS | Windows`) and `sys arch` (`X86_64 | Arm64 | RiscV64`), plus descriptor polling (`wait fd` / `PollStatus`), monotonic/wall clocks (`RGF-017`), signal watchers (`RGF-018`), and kernel CSPRNG (`sys random bytes`).

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`posix`** is a first-class **lib** located at `src/main/ridgun/lib/posix.rg` (domain `POSIX`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/posix.rglib` | Portable distribution and direct `import posix` resolution |
| **Compiled Archive** | `target/posix.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libposix.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import posix` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `posix`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `pal open create trunc wr / pal o nonblock` | Target-aware OS flag translation via `sys os` (`Linux | MacOS | Windows`) |
| `wait fd : Int -> Int -> Int -> PollStatus` | Poll descriptor readiness returning `PollReady`, `PollTimeout`, or `PollError errno` |
| `clock monotonic ms / clock monotonic ns / clock wall ms` | Monotonic elapsed clocks and UTC wall-clock milliseconds (`RGF-017`) |
| `signal watch / signal poll / sys random bytes` | Non-blocking signal polling (`SIGINT`, `SIGTERM`) and kernel CSPRNG bytes |
| `read text / write text / file exists / run cmd` | High-level file I/O, directory operations, and child process wrappers |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `posix`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import posix

fn :: medir operacion () => (Int, Int)
      medir operacion =
        t0  = clock monotonic ms
        rnd = len (sys random bytes 32)
        t1  = clock monotonic ms
        (rnd, t1 - t0)
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `posix` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import posix

fn :: esperar lectura (fd : Int) => Bool
      esperar lectura fd =
        est = wait fd fd poll_in 100
        est == PollReady
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: Non-matching `sys os` and `sys arch` branches are statically pruned at compile time (Dead-Code Elimination) by `ridgunc`.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_posix.rg`.
