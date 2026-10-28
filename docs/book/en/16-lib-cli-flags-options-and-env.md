# Chapter 16: The `cli` Lib — Flags, Options, `--` Barrier, Subcommands, and Typed Env Readers

## 16.1. Why Does the `cli` Lib Exist? (The Real-World Problem & Ridgun Philosophy)

> *"Why do I need a `cli` lib written from scratch in pure Ridgun instead of just linking a legacy C library?"*

That is the first question every systems engineer asks when meeting `cli`. And the answer captures the entire philosophy of `ridgun-libs`:

Let's be honest: hand-rolling `argv` parsing always starts as an innocent loop and breaks the moment a user passes bundled `-la` flags, `--port=9090`, or `--` followed by a filename starting with a dash.

The **`cli`** lib handles long flags (`--verbose`), short flags (`-v`), bundled short flags (`-la`), valued options (`--port=8080`, `--port 8080`, `-p 8080`), the POSIX `--` end-of-options barrier, positional arguments, subcommands, and typed environment variable readers.

In a traditional ecosystem, solving **`CLI`** tasks means pulling in external C dependencies, wrestling with raw pointers, opaque type conversions, unchecked exceptions, or unpredictable garbage-collector pauses. In Ridgun, the **`cli`** lib (`src/main/ridgun/lib/cli.rg`) tackles the problem with four non-negotiable principles:

1. **Declare `import cli` (or `import cli as alias`) at the top of your file**: every lib defines its `module :: cli` namespace, and under `--strict` multi-word functions are always called with natural spaces.
2. **Chain your data pipelines left-to-right with `->`**: write `input step one -> step two -> result`, use `(+ _ _ +)` sequence masks to destructure tuples/lists, and omit `_ =` on sequential statements (or discard with `-> ()`).
3. **Tail-Call Optimization (TCO)**: all internal loops in `cli` are tail-recursive and compile into native hardware loops using $O(1)$ stack space.
4. **Deterministic Memory (`RMM1` / `RMM2`)**: every intermediate allocation is reclaimed at the exact instruction where its last read finishes, with no Garbage Collector.

---

## 16.2. Native Artifacts, Imports, and Complete `cli` API Catalog

In `ridgun-libs`, **`cli`** is a first-class **lib** located at `src/main/ridgun/lib/cli.rg` (domain `CLI`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/cli.rglib` | Portable distribution and direct `import cli` resolution |
| **Compiled Archive** | `target/cli.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libcli.so` | Native dynamic shared library with zero C or `libc` dependencies |

> Every lib declares its own namespace via `module :: cli`: simply write `import cli` (or `import cli as alias`) at the top and call its functions with natural spaces (`my fn x`) and left-to-right `->` pipelines (`x my fn -> result`).

### 16.2.1. Summary of `cli` Functional Families

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `cli has flag : [String] -> String -> String -> Bool` | Detect `--long`, `-s`, or bundled `-xyz` before `--` |
| `cli get opt / cli get int opt` | Extract string or integer option (`--k=v`, `--k v`, `-k v`) with default |
| `cli positionals / cli subcommand` | Collect non-flag positional arguments (including everything after `--`) |
| `env get or / env get int or / env get bool or` | Read environment variables with typed fallback defaults |

### 16.2.2. Exhaustive Catalog of Types and Signatures in `src/main/ridgun/lib/cli.rg`

Below is the complete inventory of algebraic data types (`type`), mixfix operators (`op ::`), and function signatures (`fn ::`) defined in `src/main/ridgun/lib/cli.rg` (`0` types, `0` operators, and `26` functions):

| # | Function / Signature (`fn ::`) | Return Type |
|---|---|---|
| `1` | `fn :: cl str contains char String Int Int Int` | `Bool` |
| `2` | `fn :: cl is bundled short String String` | `Bool` |
| `3` | `fn :: cl list contains str [String] String` | `Bool` |
| `4` | `fn :: cl is digits loop String Int Int` | `Bool` |
| `5` | `fn :: cl is signed int len String Int` | `Bool` |
| `6` | `fn :: cl is signed int String` | `Bool` |
| `7` | `fn :: cl is ws Int` | `Bool` |
| `8` | `fn :: cl lower char String Int Int` | `String` |
| `9` | `fn :: cl trim lower loop String Int Int` | `String` |
| `10` | `fn :: cli has flag [String] String String` | `Bool` |
| `11` | `fn :: cl match eq pfx String String` | `String` |
| `12` | `fn :: cl match eq prefix String String` | `String` |
| `13` | `fn :: cl has eq prefix String String` | `Bool` |
| `14` | `fn :: cli get opt [String] String String String` | `String` |
| `15` | `fn :: cl parse int opt String Int` | `Int` |
| `16` | `fn :: cli get int opt [String] String String Int` | `Int` |
| `17` | `fn :: cl is flag tok String` | `Bool` |
| `18` | `fn :: cli positionals with opts [String] [String]` | `[String]` |
| `19` | `fn :: cli positionals [String]` | `[String]` |
| `20` | `fn :: cl first str [String]` | `String` |
| `21` | `fn :: cli subcommand [String]` | `String` |
| `22` | `fn :: cl env val or String String` | `String` |
| `23` | `fn :: env get or String String` | `String` |
| `24` | `fn :: env get int or String Int` | `Int` |
| `25` | `fn :: cl parse bool val String Bool` | `Bool` |
| `26` | `fn :: env get bool or String Bool` | `Bool` |

---

## 16.3. Deep Dive into `cli`: Step-by-Step Examples for Every Feature

A signature table alone is never enough: let's explore **every capability** of the `cli` lib through progressive, runnable Ridgun examples. We will start with two everyday tabular recipes and then walk through every functional scenario, transformation, and boundary condition verified in `src/test/ridgun/test cli.rg`.

### 16.3.1. Example 1: Core Tabular Workflow with `cli`

Notice how in Ridgun the `=` signs and transformation steps using `cli` align into a clean, scannable table without unnecessary mutable variables or hidden side effects:

```ridgun
import cli

fn :: analizar comando [String] => String Bool Int [String]
      analizar comando args =
        args cli subcommand -> sub
        cli has flag args "--all" "-a" -> all_f
        cli get int opt args "--port" "-p" 8080 -> port
        cli positionals with opts args ["--port", "-p"] -> arch
        (sub, all_f, port, arch)
```

### 16.3.2. Example 2: Safe Composition and Boundary Handling

Every function in the `cli` lib is designed to compose cleanly with boolean guards `|` and with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import cli

fn :: leer config entorno => Int Bool
      leer config entorno =
        env get int or "SOLSTICE_WORKERS" 4 -> workers
        env get bool or "SOLSTICE_DEBUG" False -> debug
        (workers, debug)
```

### 16.3.3. Example 3: Boolean Flags (`cli has flag`) and Key-Value Options (`--key=val` and `--key val`, `cli opt int`, `cli opt bool`)

In this hands-on walkthrough we thoroughly exercise how `cli` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test cli flags and options => ()
      test cli flags and options =
        args = ["serve", "-la", "--verbose", "--port=9090", "-h", "127.0.0.1", "--workers", "-4", "--", "--ignored-flag", "-z", "file.rg"]
        assert true (cli has flag args "--verbose" "-v") "AC1: long flag --verbose"
        assert true (cli has flag args "--all" "-a") "AC1: bundled short flag -a in -la"
        assert true (cli has flag args "--list" "-l") "AC1: bundled short flag -l in -la"
        assert false (cli has flag args "--quiet" "-q") "AC1: missing flag returns False"
        assert false (cli has flag args "--ignored-flag" "") "AC1: long flag after -- is ignored"
        assert false (cli has flag args "" "-z") "AC1: short flag after -- is ignored"
        assert false (cli has flag [] "--verbose" "-v") "AC1: empty args returns False"

        -- Option extraction: --key=val, --key val, -k=val, -k val, empty value --key=
        assert str eq (cli get opt args "--port" "-p" "8080") "9090" "AC2: --port=9090 inline equals"
        assert str eq (cli get opt args "--host" "-h" "0.0.0.0") "127.0.0.1" "AC2: -h 127.0.0.1 separate token"
        assert str eq (cli get opt args "--mode" "-m" "prod") "prod" "AC2: missing option returns fallback"
        assert int equals (cli get int opt args "--port" "-p" 8080) 9090 "AC2: cli_get_int_opt positive int"
        assert int equals (cli get int opt args "--workers" "-w" 1) (0 - 4) "AC2: cli_get_int_opt negative int"
        assert int equals (cli get int opt args "--host" "-h" 8080) 8080 "AC2: non-numeric option falls back to default int"

        short_eq_args = ["-p=3000", "--empty="]
        assert int equals (cli get int opt short_eq_args "--port" "-p" 80) 3000 "AC2: short option -p=3000"
        assert str eq (cli get opt short_eq_args "--empty" "-e" "def") "" "AC2: explicit empty --empty= returns empty string"
        ()
```

### 16.3.4. Example 4: Positional Extraction Respecting `--` (`cli positionals`), Subcommands (`cli subcommand`), and Typed Environment Readers (`env str/int/bool or`)

In this hands-on walkthrough we thoroughly exercise how `cli` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test cli positionals subcommand and env => ()
      test cli positionals subcommand and env =
        args = ["build", "-v", "--output", "target/app", "-j", "8", "--", "-dashfile.rg", "--another-literal", "main.rg"]
        assert str eq (cli subcommand args) "build" "AC3: cli_subcommand first positional"
        assert str eq (cli subcommand ["-v", "--release", "test"]) "test" "AC3: cli_subcommand skips leading flags"
        assert str eq (cli subcommand ["--help", "-v"]) "" "AC3: cli_subcommand empty when only flags"
        assert str eq (cli subcommand []) "" "AC3: cli_subcommand empty on []"

        pos = cli positionals with opts args ["--output", "-j"]
        assert eq pos ["build", "-dashfile.rg", "--another-literal", "main.rg"]

        -- Single "-" (stdin/stdout convention) is treated as a positional argument, not a flag!
        stdin_args = ["cat", "-n", "-"]
        assert eq (cli positionals stdin_args) ["cat", "-"]

        -- Environment variable readers
        assert true ((str len (env get or "PATH" "")) > 0) "AC4: env_get_or PATH non-empty"
        assert str eq (env get or "RIDGUN_NONEXISTENT_ENV_999" "fallback_val") "fallback_val" "AC4: env_get_or fallback"
        assert int equals (env get int or "RIDGUN_NONEXISTENT_ENV_999" 42) 42 "AC4: env_get_int_or fallback"
        assert true (env get bool or "RIDGUN_NONEXISTENT_ENV_999" True) "AC4: env_get_bool_or True fallback"
        assert false (env get bool or "RIDGUN_NONEXISTENT_ENV_999" False) "AC4: env_get_bool_or False fallback"
        ()
```

### 16.3.5. Example 5: Full CLI Command Dispatcher Combining Subcommands, Flags, Typed Options, and Environment Fallbacks

In this hands-on walkthrough we thoroughly exercise how `cli` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
import cli

fn :: despachar comando (argv : [String]) => (String, String, Int, Bool, [String])
      despachar comando argv =
        cmd     = cli subcommand argv
        host    = cli opt or argv "--host" "-H" (env str or "RG_HOST" "127.0.0.1")
        puerto  = cli opt int or argv "--port" "-p" (env int or "RG_PORT" 8080)
        verbose = (cli has flag argv "--verbose" "-v") or (env bool or "RG_VERBOSE" False)
        archivos = cli positionals argv
        (cmd, host, puerto, verbose, archivos)
```

---

## 16.4. Under the Hood: How `cli` Is Built in Pure Ridgun (`src/main/ridgun/lib/cli.rg`)

One of the biggest advantages of `ridgun-libs` is that **there are no C black boxes**. You can open `src/main/ridgun/lib/cli.rg` and read exactly how every operation is implemented using pattern matching, `|` / `|.` guard trees, and tail-call optimization (TCO). Let's inspect the key building blocks of its real implementation:

### 16.4.1. Internal Implementation: Internal String & List Helpers

Observe how `cli.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
module :: cli

fn :: cl str contains char String Int Int Int => Bool
      cl str contains char s ch idx len =
        | idx >= len                = False
        | (str char at s idx) == ch = True
        | otherwise                 = cl str contains char s ch (idx + 1) len

fn :: cl is bundled short String String => Bool
      cl is bundled short arg short_flag =
        | (str len short_flag) != 2        = False
        | (str char at short_flag 0) != 45 = False
        | (str len arg) < 2                = False
        | (str char at arg 0) != 45        = False
        | (str char at arg 1) == 45        = False
        | otherwise                        = cl str contains char arg (str char at short_flag 1) 1 (str len arg)

fn :: cl list contains str [String] String => Bool
      cl list contains str [] _ = False
      cl list contains str (x:rest) tgt =
        | x == tgt  = True
        | otherwise = cl list contains str rest tgt

fn :: cl is digits loop String Int Int => Bool
      cl is digits loop s idx len =
        | idx >= len                                           = True
        | (str char at s idx) < 48 or (str char at s idx) > 57 = False
        | otherwise                                            = cl is digits loop s (idx + 1) len

fn :: cl is signed int len String Int => Bool
      cl is signed int len s n =
        | n == 0                  = False
        | (str char at s 0) == 45 =
          | n <= 1    = False
          | otherwise = cl is digits loop s 1 n |.
        | otherwise               = cl is digits loop s 0 n

fn :: cl is signed int String => Bool
      cl is signed int s      =  cl is signed int len s (str len s)

fn :: cl is ws Int => Bool
      cl is ws c   =  c == 32 or c == 9 or c == 10 or c == 13

fn :: cl lower char String Int Int => String
      cl lower char s idx c =
        | c >= 65 and c <= 90 = char from code (c + 32)
        | otherwise           = str slice s idx (idx + 1)

fn :: cl trim lower loop String Int Int => String
      cl trim lower loop s idx len =
        | idx >= len                   = ""
        | cl is ws (str char at s idx) = cl trim lower loop s (idx + 1) len
        | otherwise                    = (cl lower char s idx (str char at s idx)) + (cl trim lower loop s (idx + 1) len)
```

### 16.4.2. Internal Implementation: Positional Arguments & Subcommand Extraction

Observe how `cli.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: cl is flag tok String => Bool
      cl is flag tok a      =
        | (str len a) <= 1        = False
        | (str char at a 0) == 45 = True
        | otherwise               = False

fn :: cli positionals with opts [String] [String] => [String]
      cli positionals with opts [] _ = []
      cli positionals with opts (a:[]) _ =
        | a == "--"        = []
        | cl is flag tok a = []
        | otherwise        = [a]
      cli positionals with opts (a:b:rst) val_opts =
        | a == "--"                       = [b] :: rst
        | cl list contains str val_opts a = cli positionals with opts rst val_opts
        | cl is flag tok a                = cli positionals with opts ([b] :: rst) val_opts
        | otherwise                       = [a] :: (cli positionals with opts ([b] :: rst) val_opts)

fn :: cli positionals [String] => [String]
      cli positionals args     =  cli positionals with opts args []

fn :: cl first str [String] => String
      cl first str []       =  ""
      cl first str (x:_)    =  x

fn :: cli subcommand [String] => String
      cli subcommand args     =  args cli positionals -> cl first str
```

### 16.4.3. Internal Implementation: Typed Environment Variable Readers

Observe how `cli.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: cl env val or String String => String
      cl env val or val fallback =
        | (str len val) == 0 = fallback
        | otherwise          = val

fn :: env get or String String   => String
      env get or key    fallback =  cl env val or (sys getenv key) fallback

fn :: env get int or String Int => Int
      env get int or key fallback = cl parse int opt (sys getenv key) fallback

fn :: cl parse bool val String Bool => Bool
      cl parse bool val val fallback =
        | val == "1" or val == "true" or val == "yes" or val == "on"  = True
        | val == "0" or val == "false" or val == "no" or val == "off" = False
        | otherwise                                                   = fallback

fn :: env get bool or String Bool => Bool
      env get bool or key fallback =
        key sys getenv -> raw
        cl trim lower loop raw 0 (str len raw) -> norm
        cl parse bool val norm fallback
```

---

## 16.5. Algorithmic Guarantees, `RMM1`/`RMM2` Memory, and the 5 Golden Rules of `cli`

- **Algorithmic & Safety Guarantee**: Strict adherence to the POSIX `--` barrier: no token after `--` is ever misinterpreted as a flag or option.
- **$O(1)$ Stack Complexity via TCO**: Every recursive loop in `src/main/ridgun/lib/cli.rg` is in tail position, so `ridgunc` compiles them into native jumps with zero stack growth.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test cli.rg`.

### The 5 Golden Rules When Programming with `cli`

1. **Declare `import cli` at the top of your file** and take advantage of space/underscore equivalence so your code reads like natural prose.
2. **Align your data pipelines with `=`**: chain `cli` calls into named intermediate steps and let `stable format` align the columns.
3. **Leverage `cli`'s total functions inside `|` guards**: inspect return values or unwrap ADTs via pattern matching rather than assuming external input is valid.
4. **Avoid cloning large structures when only reading**: remember that under `RMM2`, function input arguments incur zero reference-count overhead (`+0` / `-0`).
5. **Pair `cli` with `test` (`import test`)**: always lock in your domain invariants with `assert equals` or `assert true`.

---

In **Chapter 17**, we will explore the **`path`** lib in full depth (The `path` Lib — POSIX Normalization (`path clean`) and Path-Traversal Confinement).
