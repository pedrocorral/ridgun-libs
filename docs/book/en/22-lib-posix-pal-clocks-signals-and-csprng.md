# Chapter 22: The `posix` Lib — 2-Layer PAL (`SysOs`, `SysArch`), Clocks, Signals, and CSPRNG

## 22.1. Why Does the `posix` Lib Exist? (The Real-World Problem & Ridgun Philosophy)

> *"Why do I need a `posix` lib written from scratch in pure Ridgun instead of just linking a legacy C library?"*

That is the first question every systems engineer asks when meeting `posix`. And the answer captures the entire philosophy of `ridgun-libs`:

Let's be honest: flags like `O_CREAT` and `O_NONBLOCK` or syscall numbers differ across Linux, macOS, and CPU architectures (`X86_64` vs `Arm64`), and C codebases solve it with an unreadable `#ifdef` jungle.

The **`posix`** lib implements Ridgun's 2-layer **Platform Abstraction Layer (PAL)** via tabular pattern matching on `sys os` (`Linux | MacOS | Windows`) and `sys arch` (`X86_64 | Arm64 | RiscV64`), plus descriptor polling (`wait fd` / `PollStatus`), monotonic/wall clocks (`RGF-017`), signal watchers (`RGF-018`), and kernel CSPRNG (`sys random bytes`).

In a traditional ecosystem, solving **`POSIX`** tasks means pulling in external C dependencies, wrestling with raw pointers, opaque type conversions, unchecked exceptions, or unpredictable garbage-collector pauses. In Ridgun, the **`posix`** lib (`src/main/ridgun/lib/posix.rg`) tackles the problem with four non-negotiable principles:

1. **Total Functions & Explicit Contracts (`=>`)**: no function in `posix` throws hidden exceptions or relies on `null`. Every edge case (empty inputs, zero divisors, truncated frames, or out-of-bounds indices) returns a documented sentinel value or an algebraic sum type (`Option`, `Result`).
2. **Zero C Code & Zero `libc`**: every line of `posix` compiles directly into native ELF64 machine code verified by `ridgunc`.
3. **Tail-Call Optimization (TCO)**: all internal loops in `posix` are tail-recursive and compile into native hardware loops using $O(1)$ stack space.
4. **Deterministic Memory (`RMM1` / `RMM2`)**: every intermediate allocation is reclaimed at the exact instruction where its last read finishes, with no Garbage Collector.

---

## 22.2. Native Artifacts, Imports, and Complete `posix` API Catalog

In `ridgun-libs`, **`posix`** is a first-class **lib** located at `src/main/ridgun/lib/posix.rg` (domain `POSIX`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/posix.rglib` | Portable distribution and direct `import posix` resolution |
| **Compiled Archive** | `target/posix.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libposix.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import posix` at the top and call its functions using either multi-word spaces (`my fn x`) or underscores (`my_fn x`).

### 22.2.1. Summary of `posix` Functional Families

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `pal open create trunc wr / pal o nonblock` | Target-aware OS flag translation via `sys os` (`Linux | MacOS | Windows`) |
| `wait fd : Int -> Int -> Int -> PollStatus` | Poll descriptor readiness returning `PollReady`, `PollTimeout`, or `PollError errno` |
| `clock monotonic ms / clock monotonic ns / clock wall ms` | Monotonic elapsed clocks and UTC wall-clock milliseconds (`RGF-017`) |
| `signal watch / signal poll / sys random bytes` | Non-blocking signal polling (`SIGINT`, `SIGTERM`) and kernel CSPRNG bytes |
| `read text / write text / file exists / run cmd` | High-level file I/O, directory operations, and child process wrappers |

### 22.2.2. Exhaustive Catalog of Types and Signatures in `src/main/ridgun/lib/posix.rg`

Below is the complete inventory of algebraic data types (`type`), mixfix operators (`op ::`), and function signatures (`fn ::`) defined in `src/main/ridgun/lib/posix.rg` (`2` types, `0` operators, and `92` functions):

**Algebraic Data Types & Records (`type`) in `posix`:**

```ridgun
type PollStatus = PollReady Int | PollTimeout | PollError Int
type ProcStatus = ProcExited Int | ProcTimedOut Int | ProcSignal Int
```

| # | Function / Signature (`fn ::`) | Return Type |
|---|---|---|
| `1` | `fn :: poll in` | `Int` |
| `2` | `fn :: poll out` | `Int` |
| `3` | `fn :: poll err` | `Int` |
| `4` | `fn :: poll hup` | `Int` |
| `5` | `fn :: poll nval` | `Int` |
| `6` | `fn :: sig hup` | `Int` |
| `7` | `fn :: sig int` | `Int` |
| `8` | `fn :: sig quit` | `Int` |
| `9` | `fn :: sig kill` | `Int` |
| `10` | `fn :: sig usr1` | `Int` |
| `11` | `fn :: sig usr2` | `Int` |
| `12` | `fn :: sig pipe` | `Int` |
| `13` | `fn :: sig alrm` | `Int` |
| `14` | `fn :: sig term` | `Int` |
| `15` | `fn :: sig chld` | `Int` |
| `16` | `fn :: o rdonly` | `Int` |
| `17` | `fn :: o wronly` | `Int` |
| `18` | `fn :: o rdwr` | `Int` |
| `19` | `fn :: o creat` | `Int` |
| `20` | `fn :: o excl` | `Int` |
| `21` | `fn :: o trunc` | `Int` |
| `22` | `fn :: o append` | `Int` |
| `23` | `fn :: o nonblock` | `Int` |
| `24` | `fn :: o cloexec` | `Int` |
| `25` | `fn :: is bad posix code Int` | `Bool` |
| `26` | `fn :: has unsafe posix char String Int Int` | `Bool` |
| `27` | `fn :: is safe posix path len String Int` | `Bool` |
| `28` | `fn :: is safe posix path String` | `Bool` |
| `29` | `fn :: lstat exists (Bool String Int Int Int String String Int String)` | `Bool` |
| `30` | `fn :: lstat kind (Bool String Int Int Int String String Int String)` | `String` |
| `31` | `fn :: lstat mode (Bool String Int Int Int String String Int String)` | `Int` |
| `32` | `fn :: lstat size (Bool String Int Int Int String String Int String)` | `Int` |
| `33` | `fn :: lstat mtime sec (Bool String Int Int Int String String Int String)` | `Int` |
| `34` | `fn :: lstat symlink target (Bool String Int Int Int String String Int String)` | `String` |
| `35` | `fn :: px raw byte ub Int` | `String` |
| `36` | `fn :: px raw byte Int` | `String` |
| `37` | `fn :: px u64 le Int` | `String` |
| `38` | `fn :: px decode u32 le String Int` | `Int` |
| `39` | `fn :: px decode u64 le String Int` | `Int` |
| `40` | `fn :: px alloc page Int` | `Int` |
| `41` | `fn :: px free page Int Int Int` | `Int` |
| `42` | `fn :: px alloc mfd` | `Int` |
| `43` | `fn :: px poke Int Int String` | `Int` |
| `44` | `fn :: px peek Int Int Int` | `String` |
| `45` | `fn :: px clock gettime Int` | `Int Int` |
| `46` | `fn :: px pair fst (Int Int)` | `Int` |
| `47` | `fn :: px pair snd (Int Int)` | `Int` |
| `48` | `fn :: sys monotonic ms` | `Int` |
| `49` | `fn :: sys monotonic ns` | `Int` |
| `50` | `fn :: sys wall time ms` | `Int` |
| `51` | `fn :: map poll rc Int` | `PollStatus` |
| `52` | `fn :: wait fd Int Int Int` | `PollStatus` |
| `53` | `fn :: posix open String Int Int` | `Int` |
| `54` | `fn :: posix close Int` | `Int` |
| `55` | `fn :: posix read Int Int` | `String` |
| `56` | `fn :: posix write Int String` | `Int` |
| `57` | `fn :: posix kill Int Int` | `Int` |
| `58` | `fn :: pack pipe fds Int Int Int` | `Int Int Int` |
| `59` | `fn :: posix pipe` | `Int Int Int` |
| `60` | `fn :: posix mkdir String` | `Bool` |
| `61` | `fn :: posix chmod String Int` | `Bool` |
| `62` | `fn :: posix chdir String` | `Bool` |
| `63` | `fn :: px syscall1 path Int String` | `Int` |
| `64` | `fn :: px syscall2 path Int String String` | `Int` |
| `65` | `fn :: sys rmdir String` | `Bool` |
| `66` | `fn :: sys unlink String` | `Bool` |
| `67` | `fn :: sys rename String String` | `Bool` |
| `68` | `fn :: sys symlink String String` | `Bool` |
| `69` | `fn :: sys readlink String` | `String` |
| `70` | `fn :: valid signal list [Int]` | `Bool` |
| `71` | `fn :: valid signal rest [Int]` | `Bool` |
| `72` | `fn :: px bit shift Int` | `Int` |
| `73` | `fn :: px sig mask [Int]` | `Int` |
| `74` | `fn :: px finish sig watch Int` | `Int Int` |
| `75` | `fn :: sys signal watch [Int]` | `Int Int` |
| `76` | `fn :: px finish sig read Int String` | `Int Int` |
| `77` | `fn :: px wait sig after poll Int Int` | `Int Int` |
| `78` | `fn :: sys signal wait Int Int` | `Int Int` |
| `79` | `fn :: posix notify signal Int Int` | `Int` |
| `80` | `fn :: px bytes to list loop String Int Int` | `[Int]` |
| `81` | `fn :: px getrandom call Int Int Int` | `Int` |
| `82` | `fn :: px getrandom step Int Int Int` | `Int` |
| `83` | `fn :: px getrandom loop Int Int` | `Int` |
| `84` | `fn :: px finish getrandom Int String Int` | `Int String` |
| `85` | `fn :: px getrandom checked Int` | `Int String` |
| `86` | `fn :: sys random bytes Int` | `Int String` |
| `87` | `fn :: px finish random list (Int String)` | `Int [Int]` |
| `88` | `fn :: sys random bytes list Int` | `Int [Int]` |
| `89` | `fn :: path separator SysOs` | `String` |
| `90` | `fn :: null device for SysOs` | `String` |
| `91` | `fn :: null device` | `String` |
| `92` | `fn :: process exists Int` | `Bool` |

---

## 22.3. Deep Dive into `posix`: Step-by-Step Examples for Every Feature

A signature table alone is never enough: let's explore **every capability** of the `posix` lib through progressive, runnable Ridgun examples. We will start with two everyday tabular recipes and then walk through every functional scenario, transformation, and boundary condition verified in `src/test/ridgun/test posix.rg`.

### 22.3.1. Example 1: Core Tabular Workflow with `posix`

Notice how in Ridgun the `=` signs and transformation steps using `posix` align into a clean, scannable table without unnecessary mutable variables or hidden side effects:

```ridgun
import posix

fn :: medir operacion () => (Int, Int)
      medir operacion =
        t0  = clock monotonic ms
        rnd = len (sys random bytes 32)
        t1  = clock monotonic ms
        (rnd, t1 - t0)
```

### 22.3.2. Example 2: Safe Composition and Boundary Handling

Every function in the `posix` lib is designed to compose cleanly with boolean guards `|` and with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import posix

fn :: esperar lectura (fd : Int) => Bool
      esperar lectura fd =
        est = wait fd fd poll_in 100
        est == PollReady
```

### 22.3.3. Example 3: POSIX Constants (`O_*`, `POLL*`, `SIG*`), Safe Path Validation, Anonymous Pipes (`sys pipe`), and `sys poll status` Polling

In this hands-on walkthrough we thoroughly exercise how `posix` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test posix constants descriptors and poll => ()
      test posix constants descriptors and poll =
        _       = assert equals (poll in) 1 "POLLIN == 1"
        _       = assert equals poll_out 4 "POLLOUT == 4"
        _       = assert equals (poll err) 8 "POLLERR == 8"
        _       = assert equals (sig int) 2 "SIGINT == 2"
        _       = assert equals (sig kill) 9 "SIGKILL == 9"
        _       = assert equals (sig term) 15 "SIGTERM == 15"
        _       = assert equals (o rdonly) 0 "O_RDONLY == 0"
        _       = assert equals (o wronly) 1 "O_WRONLY == 1"
        _       = assert equals (o rdwr) 2 "O_RDWR == 2"
        _       = assert equals (o creat) 64 "O_CREAT == 64"
        _       = assert equals (o trunc) 512 "O_TRUNC == 512"
        _       = assert equals (o append) 1024 "O_APPEND == 1024"
        _       = assert equals (o nonblock) 2048 "O_NONBLOCK == 2048"
        _       = assert equals (o cloexec) 524288 "O_CLOEXEC == 524288"
        bad_p   = wait fd (0 - 1) (poll in) 10
        _       = assert true (is poll error bad_p) "wait fd on -1 returns PollError"
        p_res   = posix pipe
        _       = assert equals (tuple3 status p_res) 0 "posix pipe status == 0"
        rfd     = tuple3 rfd p_res
        wfd     = tuple3 wfd p_res
        p_to    = wait fd rfd (poll in) 20
        _       = assert true (is poll timeout p_to) "wait fd on empty pipe times out"
        written = posix write wfd "hello-posix"
        _       = assert equals written 11 "posix write 11 bytes"
        p_rdy   = wait fd rfd (poll in) 100
        _       = assert true (is poll ready p_rdy) "wait fd after write is PollReady"
        got     = posix read rfd 64
        _       = assert equals got "hello-posix" "posix read matches written payload"
        _       = assert equals (posix close rfd) 0 "posix close rfd"
        assert equals (posix close wfd) 0 "posix close wfd"
```

### 22.3.4. Example 4: `lstat` Metadata, Monotonic & Wall Clocks (`clock_gettime`), Descriptor Signal Watching (`signalfd4`), and Kernel Entropy (`sys random bytes`)

In this hands-on walkthrough we thoroughly exercise how `posix` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test posix filesystem clocks signals and random => ()
      test posix filesystem clocks signals and random =
        dir_p   = "/tmp/rg_posix_test_{sys_getpid}"
        f1      = "{dir_p}/a.txt"
        f2      = "{dir_p}/b.txt"
        lnk     = "{dir_p}/sym.txt"
        _       = sys rmdir dir_p
        _       = assert true (posix mkdir dir_p) "posix mkdir"
        _       = write file f1 "payload"
        _       = assert true (posix chmod f1 420) "posix chmod 0644"
        _       = assert true (sys rename f1 f2) "sys rename a.txt -> b.txt"
        _       = assert true (sys symlink f2 lnk) "sys symlink"
        _       = assert equals (sys readlink lnk) f2 "sys readlink target"
        _       = assert true (sys unlink lnk) "sys unlink symlink"
        _       = assert true (sys unlink f2) "sys unlink b.txt"
        _       = assert true (sys rmdir dir_p) "sys rmdir"
        _       = assert true ((sys getpid) > 0) "sys_getpid > 0"
        _       = assert true ((str len (sys getcwd)) > 0) "sys_getcwd non-empty"
        t1      = sys monotonic ms
        n1      = sys monotonic ns
        w1      = sys wall time ms
        _       = sys sleep ms 25
        t2      = sys monotonic ms
        n2      = sys monotonic ns
        w2      = sys wall time ms
        _       = assert true ((t2 - t1) >= 20) "monotonic ms elapsed >= 20"
        _       = assert true (n2 > n1) "monotonic ns non-decreasing"
        _       = assert true ((n2 - n1) >= 20000000) "monotonic ns elapsed >= 20ms (20,000,000 ns)"
        _       = assert true (w1 > 1700000000000) "wall time > 1700000000000"
        k_sec   = sys call 201 0 0 0 0 0 0
        w_sec   = w2 / 1000
        _       = assert true (((w_sec - k_sec) <= 2) and ((k_sec - w_sec) <= 2)) "sys_wall_time_ms matches kernel time(0) within 2s"
        _       = assert true ((w2 - w1) >= 20) "wall time ms elapsed >= 20"
        sw_bad  = sys signal watch [9]
        _       = assert equals (pair fst sw_bad) (0 - 7) "SIGKILL watch rejected with -7"
        sw_ok   = sys signal watch [sig term]
        _       = assert equals (pair fst sw_ok) 0 "SIGTERM watch ok"
        sh      = pair snd sw_ok
        _       = assert true ((sys call 72 sh 1 0 0 0 0) >= 0) "signalfd handle is real kernel fd"
        _       = assert equals (sys kill (sys getpid) (sig term)) 0 "real kernel sys_kill SIGTERM does not kill process"
        sw_got  = sys signal wait sh 100
        _       = assert equals (pair fst sw_got) 0 "sys_signal_wait status 0 after real sys_kill"
        _       = assert equals (pair snd sw_got) (sig term) "sys_signal_wait got real SIGTERM (15)"
        _       = assert equals (posix notify signal (sys getpid) (sig term)) 0 "notify signal"
        sw_got2 = sys signal wait sh 100
        _       = assert equals (pair fst sw_got2) 0 "sys_signal_wait status 0"
        _       = assert equals (pair snd sw_got2) (sig term) "sys_signal_wait got SIGTERM"
        sw_to   = sys signal wait sh 20
        _       = assert equals (pair fst sw_to) (0 - 2) "second sys_signal_wait times out (-2)"
        _       = assert equals (posix close sh) 0 "posix close signalfd"
        _       = assert equals (pair fst (sys signal wait sh 10)) (0 - 7) "sys_signal_wait on closed fd -> -7"
        r_bad   = sys random bytes (0 - 1)
        _       = assert equals (pair fst r_bad) (0 - 7) "negative random bytes -> -7"
        r_zero  = sys random bytes 0
        _       = assert equals (pair fst r_zero) 0 "0 random bytes -> 0"
        _       = assert equals (pair snd r_zero) "" "0 random bytes -> empty"
        r1      = sys random bytes 32
        r2      = sys random bytes 32
        rl      = sys random bytes list 256
        _       = assert equals (pair fst r1) 0 "random 32 status 0"
        _       = assert equals (str len (pair snd r1)) 32 "random 32 length == 32"
        _       = assert equals (pair fst rl) 0 "random list 256 status 0"
        _       = assert equals (path separator Linux) "/" "path separator Linux"
        _       = assert equals (path separator Windows) "\\" "path separator Windows"
        _       = assert equals (null device for Linux) "/dev/null" "null device Linux"
        _       = assert equals (null device for Windows) "NUL" "null device Windows"
        _       = assert true (process exists (sys getpid)) "process exists self"
        _       = assert false (process exists 99999999) "process exists non-existent pid"
        assert false ((pair snd r1) == (pair snd r2)) "two 32-byte random draws differ"
```

### 22.3.5. Example 5: Inter-Process Pipe Communication (`sys pipe`), Non-Blocking Polling (`sys poll status`), and Monotonic Timing (`sys monotonic ns`)

In this hands-on walkthrough we thoroughly exercise how `posix` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
import posix

fn :: medir latencia tuberia => (Int, Int)
      medir latencia tuberia =
        t0             = sys monotonic ns
        (rc, rfd, wfd) = sys pipe
        _              = sys write fd wfd "ping"
        listo          = sys poll rfd (poll in) 50
        leido          = sys read fd rfd 4
        _              = sys close rfd
        _              = sys close wfd
        t1             = sys monotonic ns
        (rc + listo + (str len leido), t1 - t0)
```

---

## 22.4. Under the Hood: How `posix` Is Built in Pure Ridgun (`src/main/ridgun/lib/posix.rg`)

One of the biggest advantages of `ridgun-libs` is that **there are no C black boxes**. You can open `src/main/ridgun/lib/posix.rg` and read exactly how every operation is implemented using pattern matching, `|` / `|.` guard trees, and tail-call optimization (TCO). Let's inspect the key building blocks of its real implementation:

### 22.4.1. Internal Implementation: Poll & Process Status ADTs

Observe how `posix.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
type PollStatus = PollReady Int | PollTimeout | PollError Int

type ProcStatus = ProcExited Int | ProcTimedOut Int | ProcSignal Int
```

### 22.4.2. Internal Implementation: Path Safety Validation (VUL-INJ-002 / VUL-INPUT-001)

Observe how `posix.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: is bad posix code Int => Bool
      is bad posix code c   =
        c == 0 or c == 10 or c == 13 or c == 59 or c == 96 or c == 124 or c == 38 or c == 36 or c == 39 or c == 34

fn :: has unsafe posix char String Int Int => Bool
      has unsafe posix char s idx slen =
        | idx >= slen                           = False
        | is bad posix code (str char at s idx) = True
        | otherwise                             = has unsafe posix char s (idx + 1) slen

fn :: is safe posix path len String Int => Bool
      is safe posix path len path plen =
        | plen == 0 or plen > 4096 = False
        | otherwise                = not (has unsafe posix char path 0 plen)

fn :: is safe posix path String => Bool
      is safe posix path path   =
        is safe posix path len path (str len path)
```

### 22.4.3. Internal Implementation: RG-010 Filesystem & Process Operations

Observe how `posix.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: posix mkdir String => Bool
      posix mkdir path   =
        | not (is safe posix path path) = False
        | otherwise                     = (sys mkdir path 493) == 0

fn :: posix chmod String Int  => Bool
      posix chmod path   mode =
        | not (is safe posix path path) = False
        | otherwise                     = (sys chmod path mode) == 0

fn :: posix chdir String => Bool
      posix chdir path   =
        | not (is safe posix path path) = False
        | otherwise                     = (sys chdir path) == 0

fn :: px syscall1 path Int String => Int
      px syscall1 path nr  path   =
        ptr = px alloc page 4096
        mfd = px alloc mfd
        b0  = px raw byte 0
        _   = px poke mfd ptr (path + b0)
        rc  = sys call nr ptr 0 0 0 0 0
        _   = px free page mfd ptr 4096
        rc

fn :: px syscall2 path Int String String => Int
      px syscall2 path nr p1 p2 =
        ptr   = px alloc page 4096
        mfd   = px alloc mfd
        b0    = px raw byte 0
        p2048 = ptr + 2048
        _     = px poke mfd ptr (p1 + b0)
        _     = px poke mfd p2048 (p2 + b0)
        rc    = sys call nr ptr p2048 0 0 0 0
        _     = px free page mfd ptr 4096
        rc

fn :: sys rmdir String => Bool
      sys rmdir path   =
        | not (is safe posix path path) = False
        | otherwise                     = (px syscall1 path 84 path) == 0

fn :: sys unlink String => Bool
      sys unlink path   =
        | not (is safe posix path path) = False
        | otherwise                     = (px syscall1 path 87 path) == 0
```

### 22.4.4. Internal Implementation: Ridgun v0.9.5 Target OS / Arch & Process Probe Helpers

Observe how `posix.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: path separator SysOs   => String
      path separator Windows =  "\\"
      path separator _       =  "/"

fn :: null device for SysOs   => String
      null device for Windows =  "NUL"
      null device for _       =  "/dev/null"

fn :: null device => String
      null device =  null device for (sys os)

fn :: process exists Int => Bool
      process exists pid =
        | pid <= 0  = False
        | otherwise = (sys kill pid 0) == 0
```

---

## 22.5. Algorithmic Guarantees, `RMM1`/`RMM2` Memory, and the 5 Golden Rules of `posix`

- **Algorithmic & Safety Guarantee**: Non-matching `sys os` and `sys arch` branches are statically pruned at compile time (Dead-Code Elimination) by `ridgunc`.
- **$O(1)$ Stack Complexity via TCO**: Every recursive loop in `src/main/ridgun/lib/posix.rg` is in tail position, so `ridgunc` compiles them into native jumps with zero stack growth.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test posix.rg`.

### The 5 Golden Rules When Programming with `posix`

1. **Declare `import posix` at the top of your file** and take advantage of space/underscore equivalence so your code reads like natural prose.
2. **Align your data pipelines with `=`**: chain `posix` calls into named intermediate steps and let `stable format` align the columns.
3. **Leverage `posix`'s total functions inside `|` guards**: inspect return values or unwrap ADTs via pattern matching rather than assuming external input is valid.
4. **Avoid cloning large structures when only reading**: remember that under `RMM2`, function input arguments incur zero reference-count overhead (`+0` / `-0`).
5. **Pair `posix` with `test` (`import test`)**: always lock in your domain invariants with `assert equals` or `assert true`.

---

In **Chapter 23**, we will explore the **`io`** lib in full depth (The `io` Lib — Typed `IoResult` Errors, `with timeout` Descriptor I/O, and Processes).
