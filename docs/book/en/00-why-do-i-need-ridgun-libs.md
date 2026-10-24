# Chapter 00: Why Do I Need `ridgun-libs`? 32 Libs Without a Single Line of C? Tell Me More!

Let's be honest: when you discover a language that compiles down to a tiny native ELF binary with no garbage collector, the very next question you ask yourself—and rightly so—is:

> *"Okay, the language itself is great... but the moment I need to open a TCP socket, hash a password with Argon2id, parse JSON, solve a linear system on tensors, or spin up an actor pool, am I going to have to link `libc`, `OpenSSL`, `libcurl`, and `pcre2`, or pull in 800 third-party packages maintained by strangers?"*

That is an excellent question. And the short answer is: **no**. That is exactly why **`ridgun-libs`** exists: a suite of **32 foundational libs** written in **100% pure Ridgun (`v0.9.16`)**, with **zero C dependencies** and **zero `libc`**.

Let's put a name to the four daily pains that `ridgun-libs` eliminates for good.

---

## Pain #1: "The `libc`, OpenSSL, and Cross-Linking Nightmare"

You have almost certainly lived through this horror movie:

1. You write a supposedly "portable" server or CLI tool.
2. As soon as you need cryptography (`SHA-256`, `Argon2id`, `ChaCha20-Poly1305`), networking (`DNS`, `HTTP`, `WebSockets`), or regular expressions, your binary ends up dynamically coupled to `glibc 2.38`, `libssl.so.3`, and C headers.
3. You copy the binary to a minimal container or an older Linux host and it crashes at startup with the infamous `version 'GLIBC_2.38' not found`.

**What changes with `ridgun-libs`?**
Every single one of the 32 libs in this repository is written in pure tabular Ridgun. System libs talk directly to the OS kernel via the Platform Abstraction Layer (`posix`), while data, math, and crypto libs execute in deterministic compiled memory (`RMM1`/`RMM2`). Every lib compiles to portable Ridgun bundles (`.rglib` / `.rgc`) and native ELF64 shared objects (`lib*.so`). Zero `libc`, zero fragile FFI glue, zero deployment surprises.

---

## Pain #2: "The 400-Dependency `node_modules` / `Cargo.lock` Syndrome"

In many modern ecosystems, the standard library is so bare-bones that reading an `.ini` file, validating a `UUIDv7`, applying a Unified Diff patch, or rendering an auto-escaped HTML template requires pulling in half a dozen external packages—each with its own error types, conventions, and supply-chain risk.

In **`ridgun-libs`**, all **32 libs** share a single, cohesive design philosophy:

```ridgun
import crypto
import json
import http

fn :: autenticar y pedir (token : String) => String
      autenticar y pedir token =
        -- Every lib shares pure types, tabular alignment, and deterministic semantics
        mac_hex = sha256 hex token
        cuerpo  = json stringify (JnObj [("token_sha256", JnStr mac_hex)])
        pet     = http build request "POST" "/v1/sesion" [("Content-Type", "application/json")] cuerpo
        pet
```

Same tabular aesthetic, same immutable ADTs (`Option`, `Result`, `IoResult`, `JsonVal`), zero hidden side effects.

---

## Pain #3: "Catastrophic Backtracking Regexes (ReDoS) and Hanging Sockets"

Two classic production time bombs:

- A malicious user sends a crafted string that drives a backtracking regex engine into $O(2^N)$ exponential time, pinning a CPU core at 100%.
- A network peer stalls mid-stream and your worker blocks forever on a `read()` with no deadline.

In **`ridgun-libs`**:
- The **`regex`** lib (Chapter 11) is built on a **Thompson NFA** engine that guarantees strict **$O(N \cdot M)$ linear time**—immune to ReDoS by construction.
- The **`posix`**, **`io`**, and **`socket`** libs (Chapters 22, 23, and 27) enforce lexical `with timeout` deadlines and `ppoll` readiness checks on every descriptor operation.

---

## Pain #4: "Cryptography and Linear Algebra That Read Like Hieroglyphics"

In **`ridgun-libs`**, Ridgun's native `Tensor[...]` types allow libs like **`tensor`** (Chapter 05), **`linalg`** (Chapter 06), and **`argon2id`** (Chapter 25) to operate over contiguous memory blocks (`Tensor[U64 * 8 * 16]`, `Tensor[Real]`) while keeping the clarity of a mathematical table.

---

## Complete Book Map: 32 Chapters for 32 Libs

Every chapter in this book is dedicated to **one lib** in `ridgun-libs`, organized in a clean bottom-up progression:

| Chapters | Lib Family | Libs Covered |
|---|---|---|
| **01 – 04** | Text, Mathematics & Data Structures | `str`, `math`, `list`, `btree` |
| **05 – 06** | Tensors & Linear Algebra | `tensor`, `linalg` |
| **07 – 10** | Encoding & Data Formats | `codec`, `json`, `csv`, `ini` |
| **11 – 15** | Text Engines, Diffs, Templates & Formatting | `regex`, `glob`, `diff`, `template`, `fmt` |
| **16 – 21** | CLI, Paths, Time, UUIDs, Logging & Testing | `cli`, `path`, `time`, `uuid`, `log`, `test` |
| **22 – 23** | POSIX Systems & Timeout-Bounded I/O | `posix`, `io` |
| **24 – 26** | Cryptography, Argon2id & JWT Tokens | `crypto`, `argon2id`, `jwt` |
| **27 – 29** | Networking, Kernel Sockets, HTTP/1.1 & WebSockets | `socket`, `http`, `ws` |
| **30 – 32** | Actor Concurrency, Worker Pools & Network Supervision | `agent`, `pool`, `net_agent` |

Let's dive right in! Turn to **Chapter 01 (`str`)** and start building.
