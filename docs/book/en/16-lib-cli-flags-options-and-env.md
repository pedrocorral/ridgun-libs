# Chapter 16: The `cli` Lib — Flags, Options, `--` Barrier, Subcommands, and Typed Env Readers

## 1. Why Does the `cli` Lib Exist?

Let's be honest: hand-rolling `argv` parsing always starts as an innocent loop and breaks the moment a user passes bundled `-la` flags, `--port=9090`, or `--` followed by a filename starting with a dash.

The **`cli`** lib handles long flags (`--verbose`), short flags (`-v`), bundled short flags (`-la`), valued options (`--port=8080`, `--port 8080`, `-p 8080`), the POSIX `--` end-of-options barrier, positional arguments, subcommands, and typed environment variable readers.

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`cli`** is a first-class **lib** located at `src/main/ridgun/lib/cli.rg` (domain `CLI`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/cli.rglib` | Portable distribution and direct `import cli` resolution |
| **Compiled Archive** | `target/cli.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libcli.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import cli` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `cli`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `cli has flag : [String] -> String -> String -> Bool` | Detect `--long`, `-s`, or bundled `-xyz` before `--` |
| `cli get opt / cli get int opt` | Extract string or integer option (`--k=v`, `--k v`, `-k v`) with default |
| `cli positionals / cli subcommand` | Collect non-flag positional arguments (including everything after `--`) |
| `env get or / env get int or / env get bool or` | Read environment variables with typed fallback defaults |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `cli`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import cli

fn :: analizar comando (args : [String]) => (String, Bool, Int, [String])
      analizar comando args =
        sub   = cli subcommand args
        all_f = cli has flag args "--all" "-a"
        port  = cli get int opt args "--port" "-p" 8080
        arch  = cli positionals args ["--port", "-p"]
        (sub, all_f, port, arch)
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `cli` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import cli

fn :: leer config entorno () => (Int, Bool)
      leer config entorno =
        workers = env get int or "SOLSTICE_WORKERS" 4
        debug   = env get bool or "SOLSTICE_DEBUG" False
        (workers, debug)
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: Strict adherence to the POSIX `--` barrier: no token after `--` is ever misinterpreted as a flag or option.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_cli.rg`.
