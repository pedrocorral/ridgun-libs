# Chapter 27: The `socket` Lib — TCP, UDP, AF_UNIX, Framing, DNS, and `RGF-001` Kernel Sockets

## 1. Why Does the `socket` Lib Exist?

Let's be honest: programming BSD sockets in C with `struct sockaddr_in`, `htons`, `inet_pton`, and `getaddrinfo` (which drags in `glibc`'s dynamic `libnss` plugins) is an arcane 1980s ritual.

The **`socket`** lib provides two complementary zero-C layers: (1) the **`RGF-001`** kernel descriptor API built for production servers like **Solstice** (`sys tcp listen`, `sys tcp listen reuseport`, `sys accept`, `sys tcp connect`, `sys send`, `sys recv`, `sys resolve ipv4` via `/etc/hosts` + RFC 1035 UDP port 53 DNS wire packets) and (2) the immutable functional `Socket` state machine with length-prefixed framing, CRLF line I/O, and CIDR matching.

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`socket`** is a first-class **lib** located at `src/main/ridgun/lib/socket.rg` (domain `SOCK`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/socket.rglib` | Portable distribution and direct `import socket` resolution |
| **Compiled Archive** | `target/socket.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libsocket.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import socket` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `socket`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `sys tcp listen / sys tcp listen reuseport / sys unix listen` | Bind and listen on IPv4 TCP (`SO_REUSEADDR` / `SO_REUSEPORT`) or `AF_UNIX` |
| `sys accept / sys tcp connect / sys unix connect` | Deadline-bounded accept and connect returning `SockFdResult` / `SockAcceptResult` |
| `sys send / sys recv / sys shutdown write` | Timeout-bounded kernel socket send, receive, and half-close (`SHUT_WR`) |
| `sys resolve ipv4 / dns resolve a` | Pure-Ridgun IPv4 resolution via `/etc/hosts` and RFC 1035 UDP DNS wire queries |
| `sock send frame / sock recv frame / ipv4 in cidr` | Length-prefixed (`N:payload`) framing and IPv4 CIDR subnet matching |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `socket`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import socket

fn :: eco tcp local () => String
      eco tcp local =
        l_res = sys tcp listen "127.0.0.1" 0 16
        lfd   = sock fd l_res
        port  = sys local port lfd
        c_res = sys tcp connect "127.0.0.1" port 1000
        cfd   = sock fd c_res
        a_res = sys accept lfd 1000
        sfd   = sock accept fd a_res
        _     = sys send cfd "hola-solstice" 1000
        r_res = sys recv sfd 64 1000
        datos = sock recv data r_res
        _     = sys_close cfd
        _     = sys_close sfd
        _     = sys_close lfd
        datos
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `socket` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import socket

fn :: verificar ip interna (ip : String) => Bool
      verificar ip interna ip =
        ipv4 in cidr ip "10.0.0.0/8"
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: Record updates using immutable `s with field = val` syntax, zero-`glibc`/`libnss` DNS resolution, and deterministic status codes (`0` OK, `-1` EOF, `-2` TIMEOUT, `-3` REFUSED).
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_socket.rg`.
