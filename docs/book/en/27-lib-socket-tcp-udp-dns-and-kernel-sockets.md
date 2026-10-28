# Chapter 27: The `socket` Lib — TCP, UDP, AF_UNIX, Framing, DNS, and `RGF-001` Kernel Sockets

## 27.1. Why Does the `socket` Lib Exist? (The Real-World Problem & Ridgun Philosophy)

> *"Why do I need a `socket` lib written from scratch in pure Ridgun instead of just linking a legacy C library?"*

That is the first question every systems engineer asks when meeting `socket`. And the answer captures the entire philosophy of `ridgun-libs`:

Let's be honest: programming BSD sockets in C with `struct sockaddr_in`, `htons`, `inet_pton`, and `getaddrinfo` (which drags in `glibc`'s dynamic `libnss` plugins) is an arcane 1980s ritual.

The **`socket`** lib provides two complementary zero-C layers: (1) the **`RGF-001`** kernel descriptor API built for production servers like **Solstice** (`sys tcp listen`, `sys tcp listen reuseport`, `sys accept`, `sys tcp connect`, `sys send`, `sys recv`, `sys resolve ipv4` via `/etc/hosts` + RFC 1035 UDP port 53 DNS wire packets) and (2) the immutable functional `Socket` state machine with length-prefixed framing, CRLF line I/O, and CIDR matching.

In a traditional ecosystem, solving **`SOCK`** tasks means pulling in external C dependencies, wrestling with raw pointers, opaque type conversions, unchecked exceptions, or unpredictable garbage-collector pauses. In Ridgun, the **`socket`** lib (`src/main/ridgun/lib/socket.rg`) tackles the problem with four non-negotiable principles:

1. **Declare `import socket` (or `import socket as alias`) at the top of your file**: every lib defines its `module :: socket` namespace, and under `--strict` multi-word functions are always called with natural spaces.
2. **Chain your data pipelines left-to-right with `->`**: write `input step one -> step two -> result`, use `(+ _ _ +)` sequence masks to destructure tuples/lists, and omit `_ =` on sequential statements (or discard with `-> ()`).
3. **Tail-Call Optimization (TCO)**: all internal loops in `socket` are tail-recursive and compile into native hardware loops using $O(1)$ stack space.
4. **Deterministic Memory (`RMM1` / `RMM2`)**: every intermediate allocation is reclaimed at the exact instruction where its last read finishes, with no Garbage Collector.

---

## 27.2. Native Artifacts, Imports, and Complete `socket` API Catalog

In `ridgun-libs`, **`socket`** is a first-class **lib** located at `src/main/ridgun/lib/socket.rg` (domain `SOCK`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/socket.rglib` | Portable distribution and direct `import socket` resolution |
| **Compiled Archive** | `target/socket.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libsocket.so` | Native dynamic shared library with zero C or `libc` dependencies |

> Every lib declares its own namespace via `module :: socket`: simply write `import socket` (or `import socket as alias`) at the top and call its functions with natural spaces (`my fn x`) and left-to-right `->` pipelines (`x my fn -> result`).

### 27.2.1. Summary of `socket` Functional Families

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `sys tcp listen / sys tcp listen reuseport / sys unix listen` | Bind and listen on IPv4 TCP (`SO_REUSEADDR` / `SO_REUSEPORT`) or `AF_UNIX` |
| `sys accept / sys tcp connect / sys unix connect` | Deadline-bounded accept and connect returning `SockFdResult` / `SockAcceptResult` |
| `sys send / sys recv / sys shutdown write` | Timeout-bounded kernel socket send, receive, and half-close (`SHUT_WR`) |
| `sys resolve ipv4 / dns resolve a` | Pure-Ridgun IPv4 resolution via `/etc/hosts` and RFC 1035 UDP DNS wire queries |
| `sock send frame / sock recv frame / ipv4 in cidr` | Length-prefixed (`N:payload`) framing and IPv4 CIDR subnet matching |

### 27.2.2. Exhaustive Catalog of Types and Signatures in `src/main/ridgun/lib/socket.rg`

Below is the complete inventory of algebraic data types (`type`), mixfix operators (`op ::`), and function signatures (`fn ::`) defined in `src/main/ridgun/lib/socket.rg` (`10` types, `0` operators, and `183` functions):

**Algebraic Data Types & Records (`type`) in `socket`:**

```ridgun
type SockAddr = family: String, host: String, port: Int, path: String
type SockOpts = reuse_addr: Bool, keep_alive: Bool, non_blocking: Bool, tcp_nodelay: Bool, broadcast: Bool, timeout_ms: Int, rcvbuf: Int, sndbuf: Int
type SockPoll = readable: Bool, writable: Bool, has_error: Bool
type Socket   = family: String, sock_id: Int, sock_type: String, local_addr: SockAddr, remote_addr: SockAddr, opts: SockOpts, is_open: Bool, is_listening: Bool, is_connected: Bool, can_read: Bool, can_write: Bool, rx_buf: [Int], tx_buf: [Int], dgram_sender: SockAddr
type SockAddrRes      = SockAddrOk SockAddr | SockAddrErr String
type SockRes          = SockOk Socket | SockErr String
type SockPairRes      = SockPairOk Socket Socket | SockPairErr String
type SockRecvBytesRes = SockBytesOk Socket [Int] | SockBytesErr String
type SockRecvStrRes   = SockStrOk Socket String | SockStrErr String
type SockRecvFromRes  = SockFromOk Socket [Int] SockAddr | SockFromErr String
```

| # | Function / Signature (`fn ::`) | Return Type |
|---|---|---|
| `1` | `fn :: int list len [Int]` | `Int` |
| `2` | `fn :: str list len [String]` | `Int` |
| `3` | `fn :: nth str [String] Int` | `String` |
| `4` | `fn :: take ints [Int] Int` | `[Int]` |
| `5` | `fn :: drop ints [Int] Int` | `[Int]` |
| `6` | `fn :: all valid bytes [Int]` | `Bool` |
| `7` | `fn :: str to bytes loop String Int Int` | `[Int]` |
| `8` | `fn :: str to byte list String` | `[Int]` |
| `9` | `fn :: byte list to str [Int]` | `String` |
| `10` | `fn :: find sub at String String Int Int Int` | `Int` |
| `11` | `fn :: find str index String String` | `Int` |
| `12` | `fn :: split by char loop String Int Int Int Int` | `[String]` |
| `13` | `fn :: split by char String Int` | `[String]` |
| `14` | `fn :: is valid port Int` | `Bool` |
| `15` | `fn :: is ascii digit Int` | `Bool` |
| `16` | `fn :: is digit range String Int Int` | `Bool` |
| `17` | `fn :: is all digits String` | `Bool` |
| `18` | `fn :: check octet range Int` | `Bool` |
| `19` | `fn :: is valid octet String` | `Bool` |
| `20` | `fn :: all valid octets [String]` | `Bool` |
| `21` | `fn :: is valid ipv4 parts [String]` | `Bool` |
| `22` | `fn :: is valid ipv4 String` | `Bool` |
| `23` | `fn :: is hex colon Int` | `Bool` |
| `24` | `fn :: check ipv6 chars String Int Int` | `Bool` |
| `25` | `fn :: is valid ipv6 String` | `Bool` |
| `26` | `fn :: is hostname char Int` | `Bool` |
| `27` | `fn :: check hostname chars String Int Int` | `Bool` |
| `28` | `fn :: is valid hostname String` | `Bool` |
| `29` | `fn :: sk lower char String Int Int` | `String` |
| `30` | `fn :: sk to lower loop String Int Int` | `String` |
| `31` | `fn :: sk to lower String` | `String` |
| `32` | `fn :: sk is ws Int` | `Bool` |
| `33` | `fn :: sk split ws loop String Int Int Int Bool` | `[String]` |
| `34` | `fn :: sk strip comment String Int` | `String` |
| `35` | `fn :: sk list has host [String] String` | `Bool` |
| `36` | `fn :: sk match hosts tokens [String] String` | `String` |
| `37` | `fn :: sk search hosts after found String [String] String` | `String` |
| `38` | `fn :: sk search hosts lines [String] String` | `String` |
| `39` | `fn :: sk file exists (Bool String Int Int Int String String Int String)` | `Bool` |
| `40` | `fn :: sk lookup etc hosts String` | `String` |
| `41` | `fn :: sk check valid ipv4 String` | `String` |
| `42` | `fn :: sk match resolv tokens [String]` | `String` |
| `43` | `fn :: sk search resolv after found String [String]` | `String` |
| `44` | `fn :: sk search resolv lines [String]` | `String` |
| `45` | `fn :: sk system nameserver` | `String` |
| `46` | `fn :: sk encode qname label String Int [String]` | `String` |
| `47` | `fn :: sk encode qname [String]` | `String` |
| `48` | `fn :: sk build dns query String` | `String` |
| `49` | `fn :: sk skip dns name step String Int Int Int` | `Int` |
| `50` | `fn :: sk skip dns name String Int Int` | `Int` |
| `51` | `fn :: sk check dns rdata String Int Int Int Int Int Int` | `String` |
| `52` | `fn :: sk parse dns after name String Int Int Int` | `String` |
| `53` | `fn :: sk parse dns answers String Int Int Int` | `String` |
| `54` | `fn :: sk extract dns after ancount String Int Int` | `String` |
| `55` | `fn :: sk extract dns after len String Int` | `String` |
| `56` | `fn :: sk extract dns ipv4 String` | `String` |
| `57` | `fn :: sk read dns after poll Int Int` | `String` |
| `58` | `fn :: sk udp dns query String String Int` | `String` |
| `59` | `fn :: sk resolve after dns String` | `Int String` |
| `60` | `fn :: sk resolve after hosts String String` | `Int String` |
| `61` | `fn :: sys resolve ipv4 String` | `Int String` |
| `62` | `fn :: sk wrap resolved host (Int String) Int` | `SockAddrRes` |
| `63` | `fn :: sock resolve host String Int` | `SockAddrRes` |
| `64` | `fn :: ipv4 to u32 String` | `Int` |
| `65` | `fn :: pow2 Int` | `Int` |
| `66` | `fn :: match cidr prefix String String Int` | `Bool` |
| `67` | `fn :: ip in cidr at String String Int` | `Bool` |
| `68` | `fn :: ip in cidr String String` | `Bool` |
| `69` | `fn :: has unsafe path char String` | `Bool` |
| `70` | `fn :: is safe unix path String` | `Bool` |
| `71` | `fn :: sock addr ipv4 String Int` | `SockAddrRes` |
| `72` | `fn :: sock addr ipv6 String Int` | `SockAddrRes` |
| `73` | `fn :: sock addr unix String` | `SockAddrRes` |
| `74` | `fn :: parse port str String` | `Int` |
| `75` | `fn :: parse bracketed ipv6 at String Int` | `SockAddrRes` |
| `76` | `fn :: parse bracketed ipv6 String` | `SockAddrRes` |
| `77` | `fn :: parse host port ipv4 at String Int` | `SockAddrRes` |
| `78` | `fn :: parse host port ipv4 String` | `SockAddrRes` |
| `79` | `fn :: sock parse addr String` | `SockAddrRes` |
| `80` | `fn :: empty addr` | `SockAddr` |
| `81` | `fn :: default sock opts` | `SockOpts` |
| `82` | `fn :: new socket Int String String` | `Socket` |
| `83` | `fn :: sock tcp` | `Socket` |
| `84` | `fn :: sock tcp6` | `Socket` |
| `85` | `fn :: sock udp` | `Socket` |
| `86` | `fn :: sock udp6` | `Socket` |
| `87` | `fn :: sock unix stream` | `Socket` |
| `88` | `fn :: sock unix dgram` | `Socket` |
| `89` | `fn :: sock set options Socket SockOpts` | `SockRes` |
| `90` | `fn :: sock set timeout Socket Int` | `SockRes` |
| `91` | `fn :: sock set tcp nodelay Socket Bool` | `SockRes` |
| `92` | `fn :: sock set broadcast Socket Bool` | `SockRes` |
| `93` | `fn :: sock set buf sizes Socket Int Int` | `SockRes` |
| `94` | `fn :: sock local addr Socket` | `SockAddrRes` |
| `95` | `fn :: sock peer addr Socket` | `SockAddrRes` |
| `96` | `fn :: sock shutdown Socket String` | `SockRes` |
| `97` | `fn :: sock poll Socket` | `SockPoll` |
| `98` | `fn :: bind unix marker SockAddr` | `()` |
| `99` | `fn :: sock bind Socket SockAddr` | `SockRes` |
| `100` | `fn :: sock listen Socket Int` | `SockRes` |
| `101` | `fn :: sock connect Socket SockAddr` | `SockRes` |
| `102` | `fn :: sock accept Socket` | `SockRes` |
| `103` | `fn :: sock connect pair Socket Socket` | `SockPairRes` |
| `104` | `fn :: sock close Socket` | `SockRes` |
| `105` | `fn :: sock send bytes Socket [Int]` | `SockRes` |
| `106` | `fn :: sock send all Socket [Int]` | `SockRes` |
| `107` | `fn :: sock pipe transfer Socket Socket` | `SockPairRes` |
| `108` | `fn :: sock recv bytes Socket Int` | `SockRecvBytesRes` |
| `109` | `fn :: sock recv exact Socket Int` | `SockRecvBytesRes` |
| `110` | `fn :: sock send str Socket String` | `SockRes` |
| `111` | `fn :: sock recv str from SockRecvBytesRes` | `SockRecvStrRes` |
| `112` | `fn :: sock recv str Socket Int` | `SockRecvStrRes` |
| `113` | `fn :: sock send to Socket [Int] SockAddr` | `SockRes` |
| `114` | `fn :: sock deliver dgram Socket Socket` | `SockPairRes` |
| `115` | `fn :: sock recv from Socket Int` | `SockRecvFromRes` |
| `116` | `fn :: encode be32 Int` | `[Int]` |
| `117` | `fn :: decode be32 [Int]` | `Int` |
| `118` | `fn :: sock send frame Socket [Int]` | `SockRes` |
| `119` | `fn :: unpack frame body Socket [Int] Int Int` | `SockRecvBytesRes` |
| `120` | `fn :: unpack frame buf Socket [Int] Int` | `SockRecvBytesRes` |
| `121` | `fn :: sock recv frame Socket Int` | `SockRecvBytesRes` |
| `122` | `fn :: find newline idx [Int] Int` | `Int` |
| `123` | `fn :: sock send line Socket String` | `SockRes` |
| `124` | `fn :: unpack line buf Socket [Int] Int Int` | `SockRecvStrRes` |
| `125` | `fn :: sock recv line Socket Int` | `SockRecvStrRes` |
| `126` | `fn :: sk raw byte ub Int` | `String` |
| `127` | `fn :: sk raw byte Int` | `String` |
| `128` | `fn :: sk u64 le Int` | `String` |
| `129` | `fn :: sk decode u16 le String Int` | `Int` |
| `130` | `fn :: sk decode u16 be String Int` | `Int` |
| `131` | `fn :: sk decode u32 le String Int` | `Int` |
| `132` | `fn :: sk alloc page Int` | `Int` |
| `133` | `fn :: sk free page Int Int Int` | `Int` |
| `134` | `fn :: sk alloc mfd` | `Int` |
| `135` | `fn :: sk poke Int Int String` | `Int` |
| `136` | `fn :: sk peek Int Int Int` | `String` |
| `137` | `fn :: is valid listen host String` | `Bool` |
| `138` | `fn :: sk ipv4 bytes String Bool` | `String` |
| `139` | `fn :: sk build sockaddr in String Int Bool` | `String` |
| `140` | `fn :: sk finish tcp listen Int Int Int` | `Int Int` |
| `141` | `fn :: sk apply reuseport Int Int Int Bool` | `Int` |
| `142` | `fn :: sk exec tcp listen opt String Int Int Bool` | `Int Int` |
| `143` | `fn :: sk exec tcp listen String Int Int` | `Int Int` |
| `144` | `fn :: sk map setsockopt rc Int` | `Int` |
| `145` | `fn :: sys set reuseport Int Bool` | `Int` |
| `146` | `fn :: sys tcp listen opt String Int Int Bool` | `Int Int` |
| `147` | `fn :: sys tcp listen reuseport String Int Int` | `Int Int` |
| `148` | `fn :: sys tcp listen String Int Int` | `Int Int` |
| `149` | `fn :: sk finish unix listen Int Int Int` | `Int Int` |
| `150` | `fn :: sk exec unix listen String Int` | `Int Int` |
| `151` | `fn :: sys unix listen String Int` | `Int Int` |
| `152` | `fn :: sk extract local port Int String` | `Int` |
| `153` | `fn :: sys local port Int` | `Int` |
| `154` | `fn :: sk finish connect Int Int` | `Int Int` |
| `155` | `fn :: sk exec tcp connect ip String Int` | `Int Int` |
| `156` | `fn :: sk connect resolved (Int String) Int` | `Int Int` |
| `157` | `fn :: sys tcp connect String Int Int` | `Int Int` |
| `158` | `fn :: sys unix connect String Int` | `Int Int` |
| `159` | `fn :: sk decode acceptconn Int String` | `Int` |
| `160` | `fn :: sk sock acceptconn Int` | `Int` |
| `161` | `fn :: sk format peer ip String` | `String` |
| `162` | `fn :: sk finish accept Int String` | `Int Int String` |
| `163` | `fn :: sk accept after poll Int Int` | `Int Int String` |
| `164` | `fn :: sys accept Int Int` | `Int Int String` |
| `165` | `fn :: sk clamp nonneg Int` | `Int` |
| `166` | `fn :: sk send rem ms Int Int` | `Int` |
| `167` | `fn :: sk send after rc Int Int Int Int Int Int Int` | `Int Int` |
| `168` | `fn :: sk send after poll Int Int Int Int Int Int Int` | `Int Int` |
| `169` | `fn :: sk send loop Int Int Int Int Int Int` | `Int Int` |
| `170` | `fn :: sk exec send Int String Int` | `Int Int` |
| `171` | `fn :: sys send Int String Int` | `Int Int` |
| `172` | `fn :: sys shutdown write Int` | `Int` |
| `173` | `fn :: sk wrap recv chunk String` | `Int String` |
| `174` | `fn :: sk recv after poll Int Int Int` | `Int String` |
| `175` | `fn :: sys recv Int Int Int` | `Int String` |
| `176` | `fn :: sock rc (Int Int)` | `Int` |
| `177` | `fn :: sock fd (Int Int)` | `Int` |
| `178` | `fn :: sock accept rc (Int Int String)` | `Int` |
| `179` | `fn :: sock accept fd (Int Int String)` | `Int` |
| `180` | `fn :: sock accept ip (Int Int String)` | `String` |
| `181` | `fn :: sock recv rc (Int String)` | `Int` |
| `182` | `fn :: sock recv data (Int String)` | `String` |

---

## 27.3. Deep Dive into `socket`: Step-by-Step Examples for Every Feature

A signature table alone is never enough: let's explore **every capability** of the `socket` lib through progressive, runnable Ridgun examples. We will start with two everyday tabular recipes and then walk through every functional scenario, transformation, and boundary condition verified in `src/test/ridgun/test socket.rg`.

### 27.3.1. Example 1: Core Tabular Workflow with `socket`

Notice how in Ridgun the `=` signs and transformation steps using `socket` align into a clean, scannable table without unnecessary mutable variables or hidden side effects:

```ridgun
import socket

fn :: eco tcp local => String
      eco tcp local =
        sys tcp listen "127.0.0.1" 0 16 -> (_ +) -> lfd
        lfd sys local port -> port
        sys tcp connect "127.0.0.1" port 1000 -> (_ +) -> cfd
        sys accept lfd 1000 -> a_res
        a_res sock accept fd -> sfd
        sys send cfd "hola-solstice" 1000 -> ()
        sys recv sfd 64 1000 -> r_res
        r_res sock recv data -> datos
        sys close cfd -> ()
        sys close sfd -> ()
        sys close lfd -> ()
        datos
```

### 27.3.2. Example 2: Safe Composition and Boundary Handling

Every function in the `socket` lib is designed to compose cleanly with boolean guards `|` and with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import socket

fn :: verificar ip interna String => Bool
      verificar ip interna ip =
        ip in cidr ip "10.0.0.0/8"
```

### 27.3.3. Example 3: Typed Addresses (`IPv4`, `IPv6`, `Unix`), Port Validation, and Full Socket Lifecycle (`tcp listen`, `accept`, `connect`, `close`)

In this hands-on walkthrough we thoroughly exercise how `socket` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test sock address and lifecycle => ()
      test sock address and lifecycle =
        r_v4       = sock parse addr "127.0.0.1:8080"
        r_v6       = sock parse addr "[::1]:9090"
        r_ux       = sock parse addr "/tmp/ridgun_test.sock"
        b_ip       = sock parse addr "999.0.0.1:8080"
        b_prt      = sock addr ipv4 "127.0.0.1" 70000
        b_ux1      = sock parse addr "../unsafe.sock"
        b_ux2      = sock parse addr "/tmp/bad;rm.sock"
        assert ok (is addr ok r_v4)
        assert ok (is addr ok r_v6)
        assert ok (is addr ok r_ux)
        assert eq (is addr ok b_ip) False
        assert eq (is addr ok b_prt) False
        assert eq (is addr ok b_ux1) False
        assert eq (is addr ok b_ux2) False
        a_v4       = unwrap addr r_v4
        assert eq (host a_v4) "127.0.0.1"
        assert eq (port a_v4) 8080
        s0         = sock tcp
        s_to       = sock set timeout s0 2500
        s_neg      = sock set timeout s0 (-5)
        assert ok (is sock ok s_to)
        assert eq (is sock ok s_neg) False
        s1         = unwrap sock s_to
        assert eq (timeout_ms (opts s1)) 2500
        srv0       = unwrap sock (sock bind s1 a_v4)
        srv1       = unwrap sock (sock listen srv0 16)
        assert ok (is_listening srv1)
        cli0       = unwrap sock (sock bind (sock tcp) (unwrap addr (sock parse addr "127.0.0.1:50000")))
        pair       = sock connect pair cli0 srv1
        cli1       = unwrap pair left pair
        peer1      = unwrap pair right pair
        assert ok (is_connected cli1)
        assert ok (is_connected peer1)
        closed_cli = unwrap sock (sock close cli1)
        assert eq (is_open closed_cli) False
        assert eq (is sock ok (sock close closed_cli)) False
        -- Additional family, option, and lifecycle negative edge cases
        assert ok (is addr ok (sock parse addr "unix:/tmp/ridgun_prefixed.sock"))
        assert ok (is addr ok (sock addr ipv6 "::1" 8443))
        assert eq (is addr ok (sock addr ipv6 "invalid_v6" 8443)) False
        assert eq (is addr ok (sock parse addr "/tmp/bad|pipe.sock")) False
        assert eq (is addr ok (sock parse addr "/tmp/bad$dollar.sock")) False
        assert eq (is addr ok (sock parse addr "/tmp/bad space.sock")) False
        assert eq (family (sock tcp6)) "inet6"
        assert eq (family (sock udp6)) "inet6"
        assert eq (family (sock unix stream)) "unix"
        assert eq (sock_type (sock unix dgram)) "dgram"
        good_opts  = SockOpts True True True True False 1000 32768 32768
        bad_opts1  = SockOpts True False False False False (0 - 1) 32768 32768
        bad_opts2  = SockOpts True False False False False 1000 0 32768
        assert ok (is sock ok (sock set options (sock tcp) good_opts))
        assert eq (is sock ok (sock set options (sock tcp) bad_opts1)) False
        assert eq (is sock ok (sock set options (sock tcp) bad_opts2)) False
        assert eq (is sock ok (sock bind (sock tcp) (unwrap addr r_v6))) False
        assert eq (is sock ok (sock listen (sock tcp) 8)) False
        assert eq (is sock ok (sock listen srv0 0)) False
        assert eq (is sock ok (sock listen (sock udp) 8)) False
        assert eq (is sock ok (sock accept srv0)) False
        assert eq (is sock ok (sock connect (sock tcp) (unwrap addr r_ux))) False
```

### 27.3.4. Example 4: Stream Transfer (`send all`, `recv exact`), Lines (`send line`, `recv line`), 32-Bit Length-Prefixed Framing (`send frame u32be`), and UDP Datagrams

In this hands-on walkthrough we thoroughly exercise how `socket` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test sock data transfer and framing => ()
      test sock data transfer and framing =
        srv_addr = unwrap addr (sock parse addr "127.0.0.1:8081")
        cli_addr = unwrap addr (sock parse addr "127.0.0.1:50001")
        srv      = unwrap sock (sock listen (unwrap sock (sock bind (sock tcp) srv_addr)) 8)
        cli      = unwrap sock (sock bind (sock tcp) cli_addr)
        pair0    = sock connect pair cli srv
        c0       = unwrap pair left pair0
        p0       = unwrap pair right pair0
        c1       = unwrap sock (sock send str c0 "hello ridgun")
        pair1    = sock pipe transfer c1 p0
        p1       = unwrap pair right pair1
        r_str    = sock recv str p1 64
        assert ok (is recv str ok r_str)
        assert eq (unwrap recv str r_str) "hello ridgun"
        p2       = unwrap recv str sock r_str
        c2       = unwrap sock (sock send frame (unwrap pair left pair1) [10, 20, 30, 40])
        pair2    = sock pipe transfer c2 p2
        p3       = unwrap pair right pair2
        r_frm_sm = sock recv frame p3 2
        assert eq (is recv bytes ok r_frm_sm) False
        r_frm_ok = sock recv frame p3 16
        assert ok (is recv bytes ok r_frm_ok)
        assert eq (unwrap recv bytes r_frm_ok) [10, 20, 30, 40]
        p4       = unwrap recv bytes sock r_frm_ok
        c3       = unwrap sock (sock send line (unwrap pair left pair2) "PING 1")
        pair3    = sock pipe transfer c3 p4
        p5       = unwrap pair right pair3
        r_line   = sock recv line p5 32
        assert ok (is recv str ok r_line)
        assert eq (unwrap recv str r_line) "PING 1"
        p6       = unwrap recv str sock r_line
        u_sender = unwrap sock (sock bind (sock udp) cli_addr)
        u_rcvr   = unwrap sock (sock bind (sock udp) srv_addr)
        u_sent   = unwrap sock (sock send to u_sender [1, 2, 3] srv_addr)
        d_pair   = sock deliver dgram u_sent u_rcvr
        u_rcvr2  = unwrap pair right d_pair
        d_res    = sock recv from u_rcvr2 16
        assert eq (unwrap dgram payload d_res) [1, 2, 3]
        assert eq (port (unwrap dgram sender d_res)) 50001
        -- Additional framing, line, byte-range, and datagram negative edge cases
        assert eq (is sock ok (sock send bytes c0 [0, 256])) False
        assert eq (is sock ok (sock send bytes c0 [0 - 1])) False
        c_short  = unwrap sock (sock send bytes (unwrap pair left pair3) [0, 1])
        p_short  = unwrap pair right (sock pipe transfer c_short p6)
        assert eq (is recv bytes ok (sock recv frame p_short 16)) False
        assert eq (is recv str ok (sock recv line p_short 16)) False
        c_longl  = unwrap sock (sock send line (unwrap pair left pair3) "LINE_TOO_LONG_FOR_LIMIT")
        p_longl  = unwrap pair right (sock pipe transfer c_longl (unwrap recv bytes sock (sock recv bytes p_short 2)))
        assert eq (is recv str ok (sock recv line p_longl 4)) False
        assert eq (is sock ok (sock send to c0 [1, 2] srv_addr)) False
```

### 27.3.5. Example 5: Socket Options (`NODELAY`, `KEEPALIVE`), CIDR Subnets (`ipv4 in cidr`), DNS Resolution (`resolve host`), and `sock select` Multiplexing

In this hands-on walkthrough we thoroughly exercise how `socket` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test sock advanced ops dns cidr and polling => ()
      test sock advanced ops dns cidr and polling =
        srv_addr  = unwrap addr (sock resolve host "localhost" 8082)
        cli_addr  = unwrap addr (sock resolve host "api.example.com" 50002)
        bad_host  = sock resolve host "-bad..host" 8082
        assert eq (host srv_addr) "127.0.0.1"
        assert eq (port srv_addr) 8082
        assert eq (is addr ok bad_host) False
        assert ok (ip in cidr "192.168.1.42" "192.168.1.0/24")
        assert eq (ip in cidr "192.168.2.42" "192.168.1.0/24") False
        assert ok (ip in cidr "10.20.30.40" "10.0.0.0/8")
        assert eq (ip in cidr "10.20.30.40" "10.0.0.0/99") False
        s_nd      = sock set tcp nodelay (sock tcp) True
        s_bc      = sock set broadcast (sock udp) True
        s_buf_ok  = sock set buf sizes (sock tcp) 131072 131072
        s_buf_bad = sock set buf sizes (sock tcp) 0 1024
        assert ok (is sock ok s_nd)
        assert ok (is sock ok s_bc)
        assert ok (is sock ok s_buf_ok)
        assert eq (is sock ok s_buf_bad) False
        assert ok (tcp_nodelay (opts (unwrap sock s_nd)))
        assert ok (broadcast (opts (unwrap sock s_bc)))
        assert eq (rcvbuf (opts (unwrap sock s_buf_ok))) 131072
        srv       = unwrap sock (sock listen (unwrap sock (sock bind (sock tcp) srv_addr)) 8)
        cli       = unwrap sock (sock bind (sock tcp) cli_addr)
        pair0     = sock connect pair cli srv
        c0        = unwrap pair left pair0
        p0        = unwrap pair right pair0
        assert eq (port (unwrap addr (sock local addr c0))) 50002
        assert eq (port (unwrap addr (sock peer addr c0))) 8082
        poll0     = sock poll p0
        assert eq (readable poll0) False
        assert ok (writable poll0)
        c1        = unwrap sock (sock send all c0 [5, 6, 7, 8, 9])
        pair1     = sock pipe transfer c1 p0
        p1        = unwrap pair right pair1
        poll1     = sock poll p1
        assert ok (readable poll1)
        ex_fail   = sock recv exact p1 10
        assert eq (is recv bytes ok ex_fail) False
        ex_ok     = sock recv exact p1 5
        assert ok (is recv bytes ok ex_ok)
        assert eq (unwrap recv bytes ex_ok) [5, 6, 7, 8, 9]
        c_shut_wr = unwrap sock (sock shutdown (unwrap pair left pair1) "wr")
        assert eq (is sock ok (sock send bytes c_shut_wr [1])) False
        p_shut_rd = unwrap sock (sock shutdown p1 "rd")
        assert eq (is recv bytes ok (sock recv bytes p_shut_rd 4)) False
        c_shut_all = unwrap sock (sock shutdown p1 "rdwr")
        assert eq (can_read c_shut_all) False
        assert eq (can_write c_shut_all) False
        assert eq (is sock ok (sock shutdown p1 "bad_mode")) False
        assert ok (is addr ok (sock resolve host "ip6-localhost" 9090))
        assert ok (ip in cidr "203.0.113.5" "0.0.0.0/0")
        assert ok (ip in cidr "192.168.1.1" "192.168.1.1/32")
        assert eq (ip in cidr "192.168.1.2" "192.168.1.1/32") False
        assert eq ( is addr ok (sock local addr (sock tcp))) False
        assert eq (is addr ok (sock peer addr (sock tcp))) False

fn :: tup2 fst (Int Int) => Int
      tup2 fst (a, _)    =  a

fn :: tup2 snd (Int Int) => Int
      tup2 snd (_, b)    =  b

fn :: tup2 str (Int String) => String
      tup2 str (_, s)       =  s

fn :: tup2 rc (Int String) => Int
      tup2 rc (rc, _)      =  rc

fn :: tup3 rc (Int Int String) => Int
      tup3 rc (rc, _, _)       =  rc

fn :: tup3 fd (Int Int String) => Int
      tup3 fd (_, fd, _)       =  fd
```

### 27.3.6. Example 6: Live Linux x86_64 Kernel Sockets (RGF-001): Loopback TCP Client/Server (`127.0.0.1`) and Unix Domain Sockets (`AF_UNIX`)

In this hands-on walkthrough we thoroughly exercise how `socket` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test sock rgf001 kernel tcp and unix => ()
      test sock rgf001 kernel tcp and unix =
        -- 1. Ephemeral TCP listen + sys local port + ADDR_IN_USE + invalid/permission checks
        assert int equals (tup2 fst (sys tcp listen "bad_host" 8080 16)) (0 - 7) "invalid host -> -7"
        assert int equals (tup2 fst (sys tcp listen "127.0.0.1" 70000 16)) (0 - 7) "invalid port -> -7"
        assert int equals (tup2 fst (sys tcp listen "127.0.0.1" 8080 0)) (0 - 7) "invalid backlog -> -7"
        assert int equals (tup2 fst (sys tcp listen "127.0.0.1" 80 16)) (0 - 6) "privileged port 80 -> -6"
        l_res  = sys tcp listen "127.0.0.1" 0 16
        assert int equals (tup2 fst l_res) 0 "sys_tcp_listen status"
        lfd    = tup2 snd l_res
        assert true (lfd >= 0) "lfd >= 0"
        assert true ((sys call 72 lfd 1 0 0 0 0) >= 0) "lfd is real kernel fd (fcntl F_GETFD >= 0)"
        lport  = sys local port lfd
        assert true (lport > 0) "ephemeral port > 0"
        dup_l  = sys tcp listen "127.0.0.1" lport 8
        assert int equals (tup2 fst dup_l) (0 - 5) "dup sys_tcp_listen -> -5"

        -- 1b. Real DNS resolution (/etc/hosts + RFC 1035 wire packet parser + localhost + literal IP + hostname connect)
        r_loc  = sys resolve ipv4 "localhost"
        assert int equals (tup2 rc r_loc) 0 "sys_resolve_ipv4 localhost ok"
        assert str eq (tup2 str r_loc) "127.0.0.1" "sys_resolve_ipv4 localhost -> 127.0.0.1"
        r_bad  = sys resolve ipv4 "-bad..host"
        assert int equals (tup2 rc r_bad) (0 - 7) "sys_resolve_ipv4 invalid hostname -> -7"
        dns_q  = sk build dns query "example.com"
        assert int equals (str len dns_q) 29 "RFC 1035 DNS query length for example.com == 29"
        -- Construct an RFC 1035 DNS response packet with 1 A record (93.184.216.34) using 0xC00C name compression
        dns_hd = (sk raw byte 18) + (sk raw byte 52) + (sk raw byte 129) + (sk raw byte 128) + (sk raw byte 0) + (sk raw byte 1) + (sk raw byte 0) + (sk raw byte 1) + (sk raw byte 0) + (sk raw byte 0) + (sk raw byte 0) + (sk raw byte 0)
        dns_qn = sk encode qname ["example", "com"]
        dns_qt = (sk raw byte 0) + (sk raw byte 1) + (sk raw byte 0) + (sk raw byte 1)
        dns_an = (sk raw byte 192) + (sk raw byte 12) + (sk raw byte 0) + (sk raw byte 1) + (sk raw byte 0) + (sk raw byte 1) + (sk raw byte 0) + (sk raw byte 0) + (sk raw byte 0) + (sk raw byte 60) + (sk raw byte 0) + (sk raw byte 4) + (sk raw byte 93) + (sk raw byte 184) + (sk raw byte 216) + (sk raw byte 34)
        dns_ip = sk extract dns ipv4 (dns_hd + dns_qn + dns_qt + dns_an)
        assert str eq dns_ip "93.184.216.34" "sk_extract_dns_ipv4 parses RFC 1035 A record (93.184.216.34)"
        c_host = sys tcp connect "localhost" lport 500
        assert int equals (tup2 fst c_host) 0 "sys_tcp_connect via hostname localhost ok"
        a_host = sys accept lfd 500
        assert int equals (tup3 rc a_host) 0 "sys_accept from hostname connect ok"
        assert int equals (sys close (tup2 snd c_host)) 0 "close c_host"
        assert int equals (sys close (tup3 fd a_host)) 0 "close a_host"

        -- 2. Accept timeout (-2) when no client pending + connect refused (-3) on unbound port
        acc_to = sys accept lfd 30
        assert int equals (tup3 rc acc_to) (0 - 2) "sys_accept timeout -> -2"
        ref_c  = sys tcp connect "127.0.0.1" 39999 100
        assert int equals (tup2 fst ref_c) (0 - 3) "sys_tcp_connect refused -> -3"

        -- 3. TCP multi-client queue, bidirectional I/O, chunked recv, recv timeout (-2), shutdown_write, send after shutdown (-4), EOF (-1)
        c_res  = sys tcp connect "127.0.0.1" lport 500
        c_res2 = sys tcp connect "127.0.0.1" lport 500
        assert int equals (tup2 fst c_res) 0 "sys_tcp_connect 1 ok"
        assert int equals (tup2 fst c_res2) 0 "sys_tcp_connect 2 ok"
        cfd    = tup2 snd c_res
        cfd2   = tup2 snd c_res2
        a_res  = sys accept lfd 500
        a_res2 = sys accept lfd 500
        assert int equals (tup3 rc a_res) 0 "sys_accept 1 ok"
        assert int equals (tup3 rc a_res2) 0 "sys_accept 2 ok"
        sfd    = tup3 fd a_res
        sfd2   = tup3 fd a_res2

        -- Empty recv with timeout=20 returns (-2, "")
        rcv_to = sys recv sfd 16 20
        assert int equals (tup2 rc rcv_to) (0 - 2) "sys_recv timeout on idle stream -> -2"

        -- Chunked recv: send 10 bytes, read 4 + 4 + 2 bytes, plus reverse direction sfd -> cfd
        snd1   = sys send cfd "0123456789" 500
        assert int equals (tup2 fst snd1) 0 "sys_send status"
        assert int equals (tup2 snd snd1) 10 "sys_send len 10"
        ch1    = sys recv sfd 4 500
        ch2    = sys recv sfd 4 500
        ch3    = sys recv sfd 4 500
        assert str eq (tup2 str ch1) "0123" "chunk 1 (4B)"
        assert str eq (tup2 str ch2) "4567" "chunk 2 (4B)"
        assert str eq (tup2 str ch3) "89" "chunk 3 (2B)"
        assert int equals (tup2 fst (sys send sfd "pong" 500)) 0 "server->client send ok"
        assert str eq (tup2 str (sys recv cfd 16 500)) "pong" "client recv pong"

        -- Raw binary bytes (0, 1, 127, 128, 254, 255) + AEAD ciphertext over TCP sys send/sys recv
        raw_bin = bytes from list [0, 1, 127, 128, 254, 255]
        assert int equals (str len raw_bin) 6 "raw_bin len == 6"
        assert int equals (tup2 fst (sys send cfd2 raw_bin 500)) 0 "sys_send raw binary ok"
        r_bin   = tup2 str (sys recv sfd2 16 500)
        assert int equals (str len r_bin) 6 "raw binary recv len == 6"
        assert int equals (str char at r_bin 0) 0 "raw binary byte[0] == 0"
        assert int equals (str char at r_bin 1) 1 "raw binary byte[1] == 1"
        assert int equals (str char at r_bin 3) 128 "raw binary byte[3] == 128"
        assert int equals (str char at r_bin 5) 255 "raw binary byte[5] == 255"
        k32     = sha256 bytes "socket-session-key"
        n12     = "0123456789ab"
        ct_wire = aead seal k32 n12 "tcp-aad" "confidential-payload-over-tcp"
        assert int equals (tup2 fst (sys send cfd2 ct_wire 500)) 0 "sys_send AEAD ciphertext ok"
        rx_wire = tup2 str (sys recv sfd2 128 500)
        opened  = aead open k32 n12 "tcp-aad" rx_wire
        assert int equals (tup2 rc opened) 0 "aead_open over TCP socket ok"
        assert str eq (tup2 str opened) "confidential-payload-over-tcp" "decrypted TCP payload matches"

        -- Shutdown write -> subsequent send returns (-4, -1) RESET, peer recv returns (-1, "") EOF
        assert int equals (sys shutdown write cfd) 0 "sys_shutdown_write"
        assert int equals (tup2 fst (sys send cfd "after-shut" 100)) (0 - 4) "send after shutdown_write -> -4"
        rcv_ef = sys recv sfd 64 500
        assert int equals (tup2 rc rcv_ef) (0 - 1) "sys_recv EOF -> -1"
        assert int equals (sys close cfd) 0 "sys_close cfd"
        assert int equals (sys close sfd) 0 "sys_close sfd"
        assert int equals (sys close cfd2) 0 "sys_close cfd2"
        assert int equals (sys close sfd2) 0 "sys_close sfd2"
        assert int equals (sys close lfd) 0 "sys_close lfd"

        -- Operations on closed fd return -7 (INVALID)
        assert int equals (sys local port lfd) (0 - 7) "sys_local_port on closed lfd -> -7"
        assert int equals (tup3 rc (sys accept lfd 10)) (0 - 7) "sys_accept on closed lfd -> -7"
        assert int equals (tup2 fst (sys send cfd "x" 10)) (0 - 7) "sys_send on closed cfd -> -7"
        assert int equals (tup2 rc (sys recv sfd 16 10)) (0 - 7) "sys_recv on closed sfd -> -7"

        -- 4. AF_UNIX listen + connect + send + recv + path traversal (-7) + missing listener (-3)
        u_bad  = sys unix listen "../traversal.sock" 8
        assert int equals (tup2 fst u_bad) (0 - 7) "sys_unix_listen traversal -> -7"
        assert int equals (tup2 fst (sys unix connect "/tmp/rg_nonexistent_99999.sock" 50)) (0 - 3) "sys_unix_connect missing -> -3"
        upath  = "/tmp/rg_sock_rgf001_{sys_getpid}.sock"
        ul_res = sys unix listen upath 8
        assert int equals (tup2 fst ul_res) 0 "sys_unix_listen ok"
        ulfd   = tup2 snd ul_res
        uc_res = sys unix connect upath 500
        assert int equals (tup2 fst uc_res) 0 "sys_unix_connect ok"
        ucfd   = tup2 snd uc_res
        ua_res = sys accept ulfd 500
        assert int equals (tup3 rc ua_res) 0 "sys_accept unix ok"
        usfd   = tup3 fd ua_res
        assert int equals (tup2 fst (sys send ucfd "unix-msg" 500)) 0 "sys_send unix ok"
        urcv   = sys recv usfd 64 500
        assert int equals (tup2 rc urcv) 0 "sys_recv unix ok"
        assert str eq (tup2 str urcv) "unix-msg" "AF_UNIX sys_recv"
        assert int equals (sys close ucfd) 0 "sys_close ucfd"
        assert int equals (sys close usfd) 0 "sys_close usfd"
        assert int equals (sys close ulfd) 0 "sys_close ulfd"
        assert int equals (shell exec "rm -f '{upath}'") 0 "unlink AF_UNIX socket"

        -- 5. RG-049: sys send honours timeout_ms when peer never reads (8 MiB send with timeout_ms=1000)
        tl_res = sys tcp listen "127.0.0.1" 0 8
        tlfd   = tup2 snd tl_res
        tlport = sys local port tlfd
        tc_res = sys tcp connect "127.0.0.1" tlport 500
        tcfd   = tup2 snd tc_res
        ta_res = sys accept tlfd 500
        tsfd   = tup3 fd ta_res
        big8m  = str repeat "x" 8000000
        ts0    = sys time ms
        tsnd   = sys send tsfd big8m 1000
        ts1    = sys time ms
        dt_ms  = ts1 - ts0
        assert int equals (tup2 fst tsnd) (0 - 2) "RG-049: sys_send 8 MiB to non-reading peer times out -> -2"
        assert true ((tup2 snd tsnd) > 0) "RG-049: sys_send returns partial bytes sent > 0 on timeout"
        assert true (dt_ms >= 800 and dt_ms <= 2500) "RG-049: sys_send timeout elapsed ~1000 ms"
        assert int equals (sys close tcfd) 0 "sys_close tcfd"
        assert int equals (sys close tsfd) 0 "sys_close tsfd"
        assert int equals (sys close tlfd) 0 "sys_close tlfd"

        -- 6. Wish (multi-core): SO_REUSEPORT allows two TCP listeners on the same (ip, port)
        rp1    = sys tcp listen reuseport "127.0.0.1" 0 16
        assert int equals (tup2 fst rp1) 0 "sys_tcp_listen_reuseport 1 ok"
        rp_fd1 = tup2 snd rp1
        rp_prt = sys local port rp_fd1
        rp2    = sys tcp listen reuseport "127.0.0.1" rp_prt 16
        assert int equals (tup2 fst rp2) 0 "sys_tcp_listen_reuseport 2 on same port ok"
        rp_fd2 = tup2 snd rp2
        assert int equals (sys close rp_fd1) 0 "sys_close rp_fd1"
        assert int equals (sys close rp_fd2) 0 "sys_close rp_fd2"
        ()
```

---

## 27.4. Under the Hood: How `socket` Is Built in Pure Ridgun (`src/main/ridgun/lib/socket.rg`)

One of the biggest advantages of `ridgun-libs` is that **there are no C black boxes**. You can open `src/main/ridgun/lib/socket.rg` and read exactly how every operation is implemented using pattern matching, `|` / `|.` guard trees, and tail-call optimization (TCO). Let's inspect the key building blocks of its real implementation:

### 27.4.1. Internal Implementation: RGF-001 Tuple Accessor Helpers

Observe how `socket.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
module :: socket

fn :: sock rc (Int Int) => Int
      sock rc (rc, _)   =  rc

fn :: sock fd (Int Int) => Int
      sock fd (_, fd)   =  fd

fn :: sock accept rc (Int Int String) => Int
      sock accept rc (rc, _, _)       =  rc

fn :: sock accept fd (Int Int String) => Int
      sock accept fd (_, fd, _)       =  fd

fn :: sock accept ip (Int Int String) => String
      sock accept ip (_, _, ip)       =  ip

fn :: sock recv rc (Int String) => Int
      sock recv rc (rc, _)      =  rc

fn :: sock recv data (Int String) => String
      sock recv data (_, data)    =  data
```

---

## 27.5. Algorithmic Guarantees, `RMM1`/`RMM2` Memory, and the 5 Golden Rules of `socket`

- **Algorithmic & Safety Guarantee**: Record updates using immutable `s with field = val` syntax, zero-`glibc`/`libnss` DNS resolution, and deterministic status codes (`0` OK, `-1` EOF, `-2` TIMEOUT, `-3` REFUSED).
- **$O(1)$ Stack Complexity via TCO**: Every recursive loop in `src/main/ridgun/lib/socket.rg` is in tail position, so `ridgunc` compiles them into native jumps with zero stack growth.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test socket.rg`.

### The 5 Golden Rules When Programming with `socket`

1. **Declare `import socket` at the top of your file** and take advantage of space/underscore equivalence so your code reads like natural prose.
2. **Align your data pipelines with `=`**: chain `socket` calls into named intermediate steps and let `stable format` align the columns.
3. **Leverage `socket`'s total functions inside `|` guards**: inspect return values or unwrap ADTs via pattern matching rather than assuming external input is valid.
4. **Avoid cloning large structures when only reading**: remember that under `RMM2`, function input arguments incur zero reference-count overhead (`+0` / `-0`).
5. **Pair `socket` with `test` (`import test`)**: always lock in your domain invariants with `assert equals` or `assert true`.

---

In **Chapter 28**, we will explore the **`http`** lib in full depth (The `http` Lib — RFC 3986 URIs, RFC 9112 HTTP/1.1 Wire Codec, and Live TCP Client).
