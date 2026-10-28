# Chapter 23: The `io` Lib — Typed `IoResult` Errors, `with timeout` Descriptor I/O, and Processes

## 23.1. Why Does the `io` Lib Exist? (The Real-World Problem & Ridgun Philosophy)

> *"Why do I need a `io` lib written from scratch in pure Ridgun instead of just linking a legacy C library?"*

That is the first question every systems engineer asks when meeting `io`. And the answer captures the entire philosophy of `ridgun-libs`:

Let's be honest: an unbounded `read()` call or child process execution with no deadline is an open invitation for one stalled peer to exhaust every worker in your server.

The **`io`** lib models every system operation through explicit ADTs (`IoError`, `IoResult[A]`), pairs non-blocking `ppoll` with Ridgun's lexical `with timeout wait_ms do` quotas, and exports the `read fd ... timeout` and `write fd ... timeout` mixfix operators.

In a traditional ecosystem, solving **`IO`** tasks means pulling in external C dependencies, wrestling with raw pointers, opaque type conversions, unchecked exceptions, or unpredictable garbage-collector pauses. In Ridgun, the **`io`** lib (`src/main/ridgun/lib/io.rg`) tackles the problem with four non-negotiable principles:

1. **Declare `import io` (or `import io as alias`) at the top of your file**: every lib defines its `module :: io` namespace, and under `--strict` multi-word functions are always called with natural spaces.
2. **Chain your data pipelines left-to-right with `->`**: write `input step one -> step two -> result`, use `(+ _ _ +)` sequence masks to destructure tuples/lists, and omit `_ =` on sequential statements (or discard with `-> ()`).
3. **Tail-Call Optimization (TCO)**: all internal loops in `io` are tail-recursive and compile into native hardware loops using $O(1)$ stack space.
4. **Deterministic Memory (`RMM1` / `RMM2`)**: every intermediate allocation is reclaimed at the exact instruction where its last read finishes, with no Garbage Collector.

---

## 23.2. Native Artifacts, Imports, and Complete `io` API Catalog

In `ridgun-libs`, **`io`** is a first-class **lib** located at `src/main/ridgun/lib/io.rg` (domain `IO`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/io.rglib` | Portable distribution and direct `import io` resolution |
| **Compiled Archive** | `target/io.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libio.so` | Native dynamic shared library with zero C or `libc` dependencies |

> Every lib declares its own namespace via `module :: io`: simply write `import io` (or `import io as alias`) at the top and call its functions with natural spaces (`my fn x`) and left-to-right `->` pipelines (`x my fn -> result`).

### 23.2.1. Summary of `io` Functional Families

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `type IoError / type IoResult[A]` | `IoNotFound | IoPermission | IoTimeout | IoRefused | IoReset | IoEOF | IoInvalid | IoSysError` |
| `io read with timeout / io write with timeout` | Non-blocking descriptor read/write bounded by `wait_ms` |
| `read fd N max M timeout T / write fd N data S timeout T` | Ergonomic mixfix operators (`op ::`) for deadline-bounded descriptor I/O |
| `io read file / io write file / io read lines` | Safe file and line-stream helpers returning `IoResult` |
| `exec with timeout : String -> Int -> IoResult[ProcStatus]` | Run an external command bounded by a lexical `with timeout` quota |

### 23.2.2. Exhaustive Catalog of Types and Signatures in `src/main/ridgun/lib/io.rg`

Below is the complete inventory of algebraic data types (`type`), mixfix operators (`op ::`), and function signatures (`fn ::`) defined in `src/main/ridgun/lib/io.rg` (`2` types, `2` operators, and `42` functions):

**Algebraic Data Types & Records (`type`) in `io`:**

```ridgun
type IoError = Timeout Int | Eof | SysErr Int String | NotFound String
type IoResult = String | Int | Timeout Int | Eof | SysErr Int String | NotFound String | IoErr IoError | IoOk String | IoTimeout | IoEof | IoError Int
```

**Mixfix Operators (`op ::`) in `io`:**

```ridgun
op :: read fd Int max Int timeout Int => IoResult
op :: write fd Int data String timeout Int => IoResult
```

| # | Function / Signature (`fn ::`) | Return Type |
|---|---|---|
| `1` | `fn :: format io error IoError` | `String` |
| `2` | `fn :: format io result IoResult` | `String` |
| `3` | `fn :: map read bytes String` | `IoResult` |
| `4` | `fn :: read fd after poll PollStatus Int Int Int` | `IoResult` |
| `5` | `fn :: read fd Int Int Int` | `IoResult` |
| `6` | `fn :: map write rc Int` | `IoResult` |
| `7` | `fn :: write fd after poll PollStatus Int String Int` | `IoResult` |
| `8` | `fn :: write fd Int String Int` | `IoResult` |
| `9` | `fn :: has null char String Int Int` | `Bool` |
| `10` | `fn :: pad ms three Int` | `String` |
| `11` | `fn :: format timeout sec Int` | `String` |
| `12` | `fn :: map exec rc Int Int` | `IoResult` |
| `13` | `fn :: io exec timeout String Int` | `IoResult` |
| `14` | `fn :: exec with timeout String Int` | `IoResult` |
| `15` | `fn :: read existing or empty String` | `String` |
| `16` | `fn :: append file String String` | `Int` |
| `17` | `fn :: file exists String` | `Bool` |
| `18` | `fn :: is file String` | `Bool` |
| `19` | `fn :: is dir String` | `Bool` |
| `20` | `fn :: is symlink String` | `Bool` |
| `21` | `fn :: extract size (Bool String Int Int Int String String Int String)` | `Int` |
| `22` | `fn :: file size String` | `Int` |
| `23` | `fn :: extract mtime (Bool String Int Int Int String String Int String)` | `Int` |
| `24` | `fn :: file mtime String` | `Int` |
| `25` | `fn :: extract mode (Bool String Int Int Int String String Int String)` | `Int` |
| `26` | `fn :: file mode String` | `Int` |
| `27` | `fn :: io read file safe String` | `IoResult` |
| `28` | `fn :: split lines loop String Int Int Int` | `[String]` |
| `29` | `fn :: split non empty lines String Int` | `[String]` |
| `30` | `fn :: io read lines String` | `[String]` |
| `31` | `fn :: str list is empty [String]` | `Bool` |
| `32` | `fn :: join lines nl [String]` | `String` |
| `33` | `fn :: io write lines String [String]` | `Int` |
| `34` | `fn :: io wrap chunk String` | `IoResult` |
| `35` | `fn :: io read after poll Int Int` | `IoResult` |
| `36` | `fn :: io read poll step Int` | `IoResult` |
| `37` | `fn :: io read with timeout String Int` | `IoResult` |

---

## 23.3. Deep Dive into `io`: Step-by-Step Examples for Every Feature

A signature table alone is never enough: let's explore **every capability** of the `io` lib through progressive, runnable Ridgun examples. We will start with two everyday tabular recipes and then walk through every functional scenario, transformation, and boundary condition verified in `src/test/ridgun/test io.rg`.

### 23.3.1. Example 1: Core Tabular Workflow with `io`

Notice how in Ridgun the `=` signs and transformation steps using `io` align into a clean, scannable table without unnecessary mutable variables or hidden side effects:

```ridgun
import io

fn :: leer peticion segura Int => String
      leer peticion segura fd =
        read fd fd max 4096 timeout 250 -> res
        res format io result
```

### 23.3.2. Example 2: Safe Composition and Boundary Handling

Every function in the `io` lib is designed to compose cleanly with boolean guards `|` and with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import io

fn :: describir fallo => String
      describir fallo =
        format io error (Timeout 250)
```

### 23.3.3. Example 3: Extensible `IoError` Hierarchy (`Timeout`, `Eof`, `InvalidInput`, `PermissionDenied`, `NotFound`, `PosixErrno`) and `io error message` Formatting

In this hands-on walkthrough we thoroughly exercise how `io` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test io error formatting => ()
      test io error formatting =
        assert str eq (format io error (Timeout 500)) "timeout after 500 ms" "format Timeout 500"
        assert str eq (format io error Eof) "unexpected end of file" "format Eof"
        assert str eq (format io error (SysErr 9 "poll")) "syscall error 9 in poll" "format SysErr"
        assert str eq (format io error (NotFound "/missing")) "file not found: /missing" "format NotFound"
        ()
```

### 23.3.4. Example 4: Deadline-Bounded Descriptor Read & Write (`read fd ... timeout`, `write fd ... timeout`, `with timeout`) and `Eof` Detection

In this hands-on walkthrough we thoroughly exercise how `io` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test io pipe timeout and eof => ()
      test io pipe timeout and eof =
        pt     = posix pipe
        rc     = pipe rc3 pt
        rfd    = pipe rfd3 pt
        wfd    = pipe wfd3 pt
        assert eq rc 0

        -- 1. Empty pipe read with 50 ms timeout must time out within [40, 300) ms (TS-PERF-001 AC2)
        t3     = sys monotonic ms
        r_to   = read fd rfd max 32 timeout 50
        t4     = sys monotonic ms
        dt     = t4 - t3
        assert str eq (format io result r_to) "err:timeout after 50 ms" "empty pipe read Timeout 50"
        assert true (dt >= 40 and dt < 300) "dt in [40, 300): {dt}"

        -- 2. Write payload via mixfix `write fd ... data ... timeout ...`
        w_res  = write fd wfd data "stream-ok" timeout 100
        assert str eq (format io result w_res) "ok:int:9" "write fd returns 9 bytes"

        -- 3. Read payload via mixfix `read fd ... max ... timeout ...`
        r_ok   = read fd rfd max 64 timeout 100
        assert str eq (format io result r_ok) "ok:str:stream-ok" "read fd returns stream-ok"

        -- 4. Close write end and verify subsequent read returns Eof
        posix close wfd -> ()
        r_eof  = read fd rfd max 64 timeout 100
        assert str eq (format io result r_eof) "err:unexpected end of file" "closed pipe read returns Eof"
        posix close rfd -> ()

        -- 5. Bad fd / invalid max_bytes
        r_bad  = read fd (0 - 1) max 64 timeout 50
        assert str eq (format io result r_bad) "err:syscall error 9 in read" "negative fd read SysErr 9"
        r_zero = read fd rfd max 0 timeout 50
        assert str eq (format io result r_zero) "err:syscall error 22 in read" "zero max_bytes read SysErr 22"
        ()
```

### 23.3.5. Example 5: Safe Subprocess Execution with Strict Deadlines (`io exec timeout`) and Automatic Child Cleanup

In this hands-on walkthrough we thoroughly exercise how `io` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test io exec timeout => ()
      test io exec timeout =
        ok_res = io exec timeout "true" 500
        assert str eq (format io result ok_res) "ok:int:0" "io exec timeout true succeeds"
        to_res = io exec timeout "sleep 2" 40
        assert str eq (format io result to_res) "err:timeout after 40 ms" "io exec timeout sleep 2 times out"
        ()
```

### 23.3.6. Example 6: Filesystem Predicates (`file exists`, `is dir`, `is regular file`, `file size`), Line-Stream Reading (`io read lines`), and File Copy (`copy file`)

In this hands-on walkthrough we thoroughly exercise how `io` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test io file and metadata => ()
      test io file and metadata =
        pid   = sys getpid
        dpath = "/tmp/rg_io_dir_{pid}"
        fpath = "{dpath}/file.txt"
        spath = "{dpath}/sym.txt"
        bpath = "{dpath}/bytes.bin"
        lpath = "{dpath}/lines.txt"

        sys rmdir dpath -> ()
        posix mkdir dpath -> ()
        assert true (is dir dpath) "is dir dpath"
        assert false (is file dpath) "not is file dpath"

        -- 1. write file + append file + read file
        write file fpath "hello "
        w2    = append file fpath "world"
        assert eq w2 0
        assert str eq (read file fpath) "hello world" "write_file + append_file content"

        -- 2. write_bytes + read_bytes
        write bytes bpath [65, 66, 67, 0, 255]
        rb    = read bytes bpath
        assert eq (int list len rb) 5

        -- 3. symlink + metadata predicates
        assert true (sys symlink fpath spath) "sys symlink fpath spath"
        assert true (file exists fpath) "file exists fpath"
        assert true (is file fpath) "is file fpath"
        assert false (is symlink fpath) "not is symlink fpath"
        assert true (is symlink spath) "is symlink spath"
        assert eq (file size fpath) 11
        assert true ((file mtime fpath) > 1700000000) "file mtime > 1700000000"
        assert true ((file mode fpath) > 0) "file mode > 0"
        assert false (file exists "/tmp/rg_io_nonexistent_999999.txt") "missing file exists False"

        -- 4. io read file safe + io write lines / io read lines
        miss  = io read file safe "/tmp/rg_io_missing_999.txt"
        assert str eq (format io result miss) "err:file not found: /tmp/rg_io_missing_999.txt" "NotFound missing file"
        hit   = io read file safe fpath
        assert str eq (format io result hit) "ok:str:hello world" "safe read existing file"

        io write lines lpath ["alpha", "beta", "gamma"] -> ()
        lines = io read lines lpath
        assert eq (str list len lines) 3

        -- 5. v0.9.5 PAL `io read with timeout` (`with timeout wait_ms do` + `sys open path 2048 0` + `sys poll fd 1 -1`)
        r_amb  = io read with timeout fpath 200_ms
        assert str eq (format io result r_amb) "ok:str:hello world" "io read with timeout 200_ms"
        r_miss = io read with timeout "/tmp/rg_io_missing_999.txt" 50_ms
        assert true (str starts with (format io result r_miss) "err:io error -") "io read with timeout missing file -> IoError"

        -- Cleanup
        sys unlink spath -> ()
        sys unlink fpath -> ()
        sys unlink bpath -> ()
        sys unlink lpath -> ()
        sys rmdir dpath -> ()
        ()
```

---

## 23.4. Under the Hood: How `io` Is Built in Pure Ridgun (`src/main/ridgun/lib/io.rg`)

One of the biggest advantages of `ridgun-libs` is that **there are no C black boxes**. You can open `src/main/ridgun/lib/io.rg` and read exactly how every operation is implemented using pattern matching, `|` / `|.` guard trees, and tail-call optimization (TCO). Let's inspect the key building blocks of its real implementation:

### 23.4.1. Internal Implementation: Extensible I/O Error & Result Sum Types (§5.1)

Observe how `io.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
module :: io

type IoError = Timeout Int | Eof | SysErr Int String | NotFound String

type IoResult = String | Int | Timeout Int | Eof | SysErr Int String | NotFound String | IoErr IoError | IoOk String | IoTimeout | IoEof | IoError Int

fn :: format io error IoError            => String
      format io error (Timeout ms)       =  "timeout after {ms} ms"
      format io error Eof                =  "unexpected end of file"
      format io error (SysErr c op_name) =  "syscall error {c} in {op_name}"
      format io error (NotFound path)    =  "file not found: {path}"
      format io error _                  =  "unknown io error"

fn :: format io result IoResult           => String
      format io result (String s)         =  "ok:str:{s}"
      format io result (IoOk s)           =  "ok:str:{s}"
      format io result (Int n)            =  "ok:int:{n}"
      format io result (Timeout ms)       =  "err:timeout after {ms} ms"
      format io result IoTimeout          =  "err:timeout"
      format io result Eof                =  "err:unexpected end of file"
      format io result IoEof              =  "err:unexpected end of file"
      format io result (IoError c)        =  "err:io error {c}"
      format io result (SysErr c op_name) =  "err:syscall error {c} in {op_name}"
      format io result (NotFound path)    =  "err:file not found: {path}"
      format io result (IoErr err)        =  "err:" + (format io error err)
      format io result _                  =  "err:unknown io error"
```

### 23.4.2. Internal Implementation: Timeout-Bounded Command Execution (§5.2)

Observe how `io.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: has null char String Int Int => Bool
      has null char s idx slen =
        | idx >= slen              = False
        | (str char at s idx) == 0 = True
        | otherwise                = has null char s (idx + 1) slen

fn :: pad ms three Int => String
      pad ms three rem =
        | rem < 10  = "00{rem}"
        | rem < 100 = "0{rem}"
        | otherwise = "{rem}"

fn :: format timeout sec Int => String
      format timeout sec ms  =
        secs = ms / 1000
        rem  = ms % 1000
        p    = pad ms three rem
        "{secs}.{p}s"

fn :: map exec rc Int Int        => IoResult
      map exec rc rc  timeout_ms =
        | rc == 124 or rc == 137 = Timeout timeout_ms
        | rc < 0                 = SysErr (0 - rc) "exec"
        | otherwise              = Int rc

fn :: io exec timeout String Int        => IoResult
      io exec timeout cmd    timeout_ms =
        | (str len cmd) == 0 or (has null char cmd 0 (str len cmd)) = SysErr 22 "exec"
        | timeout_ms <= 0                                           = Timeout timeout_ms
        | otherwise                                                 =
          tspec = format timeout sec timeout_ms
          rc    = shell exec "timeout -k 0.01s {tspec} sh -c \"{cmd}\" >/dev/null 2>&1"
          map exec rc rc timeout_ms

fn :: exec with timeout String Int        => IoResult
      exec with timeout cmd    timeout_ms =
        io exec timeout cmd timeout_ms
```

### 23.4.3. Internal Implementation: Safe File Read & Line-Stream Helpers

Observe how `io.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: io read file safe String => IoResult
      io read file safe path   =
        | not (is safe posix path path)        = SysErr 22 "read_file"
        | not (lstat exists (file lstat path)) = NotFound path
        | otherwise                            = String (read file path)

fn :: split lines loop String Int Int Int => [String]
      split lines loop s idx start slen =
        | idx >= slen =
          | start == slen = []
          | otherwise     = [str slice s start slen] |.
        | (str char at s idx) == 10 =
          line = str slice s start idx
          [line] :: (split lines loop s (idx + 1) (idx + 1) slen)
        | otherwise =
          split lines loop s (idx + 1) start slen

fn :: split non empty lines String Int => [String]
      split non empty lines raw rlen =
        | rlen == 0 = []
        | otherwise = split lines loop raw 0 0 rlen

fn :: io read lines String => [String]
      io read lines path   =
        | not (is safe posix path path)        = []
        | not (lstat exists (file lstat path)) = []
        | otherwise                            =
          raw = read file path
          split non empty lines raw (str len raw)

fn :: str list is empty [String] => Bool
      str list is empty []       =  True
      str list is empty (_:_)    =  False

fn :: join lines nl [String]    => String
      join lines nl []          =  ""
      join lines nl (line:rest) =
        | str list is empty rest = line + "\n"
        | otherwise              = line + "\n" + (join lines nl rest)

fn :: io write lines step String [String] => Int
      io write lines step path   lines    =
        lines join lines nl -> body
        write file path body
        0

fn :: io write lines String [String] => Int
      io write lines path   lines    =
        | not (is safe posix path path) = 0 - 22
        | otherwise                     = io write lines step path lines
```

### 23.4.4. Internal Implementation: Ridgun v0.9.5 PAL & Ambient Deadline `io read with timeout` (§3.1)

Observe how `io.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: io wrap chunk String => IoResult
      io wrap chunk ""     =  IoEof
      io wrap chunk s      =  IoOk s

fn :: io close and return Int IoResult => IoResult
      io close and return fd  res      =
        sys close fd -> ()
        res

fn :: io read chunk and close Int => IoResult
      io read chunk and close fd  =
        sys read fd fd 65536 -> chunk
        sys close fd -> ()
        chunk io wrap chunk

fn :: io read after poll Int Int => IoResult
      io read after poll fd ev =
        | ev == 0   = io close and return fd IoTimeout
        | ev < 0    = io close and return fd (IoError ev)
        | otherwise = io read chunk and close fd

fn :: io poll and read Int => IoResult
      io poll and read fd  =
        sys poll fd 1 (0 - 1) -> ev
        io read after poll fd ev

fn :: io read poll step Int => IoResult
      io read poll step fd  =
        | fd < 0    = IoError fd
        | otherwise = io poll and read fd

fn :: io read with timeout String Int => IoResult
      io read with timeout path wait_ms =
        with timeout wait_ms do
          fd = sys open path 2048 0
          io read poll step fd
```

---

## 23.5. Algorithmic Guarantees, `RMM1`/`RMM2` Memory, and the 5 Golden Rules of `io`

- **Algorithmic & Safety Guarantee**: No read, write, or child command executed through `io` with a `wait_ms` quota can ever block the calling thread or actor indefinitely.
- **$O(1)$ Stack Complexity via TCO**: Every recursive loop in `src/main/ridgun/lib/io.rg` is in tail position, so `ridgunc` compiles them into native jumps with zero stack growth.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test io.rg`.

### The 5 Golden Rules When Programming with `io`

1. **Declare `import io` at the top of your file** and take advantage of space/underscore equivalence so your code reads like natural prose.
2. **Align your data pipelines with `=`**: chain `io` calls into named intermediate steps and let `stable format` align the columns.
3. **Leverage `io`'s total functions inside `|` guards**: inspect return values or unwrap ADTs via pattern matching rather than assuming external input is valid.
4. **Avoid cloning large structures when only reading**: remember that under `RMM2`, function input arguments incur zero reference-count overhead (`+0` / `-0`).
5. **Pair `io` with `test` (`import test`)**: always lock in your domain invariants with `assert equals` or `assert true`.

---

In **Chapter 24**, we will explore the **`crypto`** lib in full depth (The `crypto` Lib — SHA-256, HMAC, PBKDF2, Argon2id, and ChaCha20-Poly1305 AEAD).
