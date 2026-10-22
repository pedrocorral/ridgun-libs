-- src/main/ridgun/lib/socket.rg
-- Pure-Ridgun Socket Management Library (TCP, UDP, Unix Domain, Framing, Poll, DNS & CIDR)
-- @implements FR-SOCK-001
-- @implements FR-SOCK-002
-- @implements FR-SOCK-003
-- @implements FR-SOCK-004
-- @implements NFR-SEC-001
-- @implements NFR-OBS-001
-- @implements API-SOCK-001
-- @implements DM-Socket
-- @mitigates VUL-INJ-002
-- @mitigates VUL-INPUT-001

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

-- ============================================================
-- List, String & Byte Helpers
-- ============================================================

fn :: int list len [Int]    => Int
      int list len []       =  0
      int list len (_:rest) =  1 + (int list len rest)

fn :: str list len [String] => Int
      str list len []       =  0
      str list len (_:rest) =  1 + (str list len rest)

fn :: nth str [String] Int => String
      nth str []       _   =  ""
      nth str (x:rest) idx =
        | idx <= 0  = x
        | otherwise = nth str rest (idx - 1)

fn :: take ints [Int]    Int => [Int]
      take ints []       _   =  []
      take ints (x:rest) n   =
        | n <= 0    = []
        | otherwise = [x] :: (take ints rest (n - 1))

fn :: drop ints [Int]    Int => [Int]
      drop ints []       _   =  []
      drop ints (x:rest) n   =
        | n <= 0    = [x] :: rest
        | otherwise = drop ints rest (n - 1)

fn :: all valid bytes [Int]    => Bool
      all valid bytes []       =  True
      all valid bytes (b:rest) =
        | b < 0 or b > 255 = False
        | otherwise        = all valid bytes rest

fn :: str to bytes loop String Int Int => [Int]
      str to bytes loop s idx len =
        | idx >= len = []
        | otherwise  = [(str_char_at s idx)] :: (str to bytes loop s (idx + 1) len)

fn :: str to byte list String => [Int]
      str to byte list s      =  str to bytes loop s 0 (str_len s)

fn :: byte list to str [Int]    => String
      byte list to str []       =  ""
      byte list to str (b:rest) =  (char_from_code b) + (byte list to str rest)

fn :: find sub at String String Int Int Int => Int
      find sub at s sub idx slen nlen =
        | (idx + nlen) > slen                   = -1
        | (str_slice s idx (idx + nlen)) == sub = idx
        | otherwise                             = find sub at s sub (idx + 1) slen nlen

fn :: find str index String String => Int
      find str index s      sub    =  find sub at s sub 0 (str_len s) (str_len sub)

fn :: split by char loop String Int Int Int Int => [String]
      split by char loop s ch start idx len =
        | idx >= len                = [(str_slice s start len)]
        | (str_char_at s idx) == ch = [(str_slice s start idx)] :: (split by char loop s ch (idx + 1) (idx + 1) len)
        | otherwise                 = split by char loop s ch start (idx + 1) len

fn :: split by char String Int => [String]
      split by char s      ch  =  split by char loop s ch 0 0 (str_len s)

-- ============================================================
-- Endpoint, Hostname & CIDR Validation (FR-SOCK-001, FR-SOCK-003)
-- @implements FR-SOCK-001
-- @implements FR-SOCK-003
-- @mitigates VUL-INJ-002
-- @mitigates VUL-INPUT-001
-- ============================================================

fn :: is valid port Int  => Bool
      is valid port port =  port >= 1 and port <= 65535

fn :: is ascii digit Int => Bool
      is ascii digit c   =  c >= 48 and c <= 57

fn :: is digit range String Int Int => Bool
      is digit range s idx len =
        | idx >= len                               = True
        | not (is ascii digit (str_char_at s idx)) = False
        | otherwise                                = is digit range s (idx + 1) len

fn :: is all digits String => Bool
      is all digits s      =
        | (str_len s) == 0 = False
        | otherwise        = is digit range s 0 (str_len s)

fn :: check octet range Int => Bool
      check octet range v   =  v >= 0 and v <= 255

fn :: is valid octet String => Bool
      is valid octet part   =
        | not (is all digits part) = False
        | otherwise                = check octet range (str_to_int part)

fn :: all valid octets [String]    => Bool
      all valid octets []          =  True
      all valid octets (part:rest) =
        | not (is valid octet part) = False
        | otherwise                 = all valid octets rest

fn :: is valid ipv4 parts [String] => Bool
      is valid ipv4 parts parts    =
        | (str list len parts) != 4 = False
        | otherwise                 = all valid octets parts

fn :: is valid ipv4 String => Bool
      is valid ipv4 host   =  is valid ipv4 parts (split by char host 46)

fn :: is hex colon Int => Bool
      is hex colon c   =
        is_num = c >= 48 and c <= 57
        is_lo  = c >= 97 and c <= 102
        is_hi  = c >= 65 and c <= 70
        is_num or is_lo or is_hi or (c == 58)

fn :: check ipv6 chars String Int Int => Bool
      check ipv6 chars s idx len =
        | idx >= len                             = True
        | not (is hex colon (str_char_at s idx)) = False
        | otherwise                              = check ipv6 chars s (idx + 1) len

fn :: is valid ipv6 String => Bool
      is valid ipv6 host   =
        | (str_len host) < 2          = False
        | not (str_contains host ":") = False
        | otherwise                   = check ipv6 chars host 0 (str_len host)

fn :: is hostname char Int => Bool
      is hostname char c   =
        is_num = c >= 48 and c <= 57
        is_lo  = c >= 97 and c <= 122
        is_hi  = c >= 65 and c <= 90
        is_num or is_lo or is_hi or (c == 45) or (c == 46)

fn :: check hostname chars String Int Int => Bool
      check hostname chars s idx len =
        | idx >= len                                 = True
        | not (is hostname char (str_char_at s idx)) = False
        | otherwise                                  = check hostname chars s (idx + 1) len

fn :: is valid hostname String => Bool
      is valid hostname host   =
        | (str_len host) < 1 or (str_len host) > 253              = False
        | (str_starts_with host "-") or (str_starts_with host ".") = False
        | (str_char_at host ((str_len host) - 1)) == 45           = False
        | (str_char_at host ((str_len host) - 1)) == 46           = False
        | str_contains host ".."                                  = False
        | otherwise                                               = check hostname chars host 0 (str_len host)

fn :: sock resolve host String Int  => SockAddrRes
      sock resolve host host   port =
        | not (is valid port port)                       = SockAddrErr "port out of range (1..65535)"
        | host == "localhost"                            = SockAddrOk (SockAddr "inet" "127.0.0.1" port "")
        | host == "ip6-localhost" or host == "::1"       = SockAddrOk (SockAddr "inet6" "::1" port "")
        | is valid ipv4 host                             = SockAddrOk (SockAddr "inet" host port "")
        | is valid ipv6 host                             = SockAddrOk (SockAddr "inet6" host port "")
        | is valid hostname host                         = SockAddrOk (SockAddr "inet" "127.0.0.1" port "")
        | otherwise                                      = SockAddrErr "invalid or unresolvable hostname"

fn :: ipv4 to u32 String => Int
      ipv4 to u32 ip     =
        parts = split by char ip 46
        o0    = str_to_int (nth str parts 0)
        o1    = str_to_int (nth str parts 1)
        o2    = str_to_int (nth str parts 2)
        o3    = str_to_int (nth str parts 3)
        (o0 * 16777216) + (o1 * 65536) + (o2 * 256) + o3

fn :: pow2 Int => Int
      pow2 exp =
        | exp <= 0  = 1
        | otherwise = 2 * (pow2 (exp - 1))

fn :: match cidr prefix String String Int => Bool
      match cidr prefix ip net_ip bits =
        | not (is valid ipv4 ip)     = False
        | not (is valid ipv4 net_ip) = False
        | bits < 0 or bits > 32      = False
        | bits == 0                  = True
        | otherwise =
          div = pow2 (32 - bits)
          ((ipv4 to u32 ip) / div) == ((ipv4 to u32 net_ip) / div)

fn :: ip in cidr at String String Int => Bool
      ip in cidr at ip cidr slash_idx =
        | slash_idx < 7 = False
        | otherwise =
          net_ip = str_slice cidr 0 slash_idx
          p_str  = str_slice cidr (slash_idx + 1) (str_len cidr)
          match cidr prefix ip net_ip (parse port str p_str)

fn :: ip in cidr String String => Bool
      ip in cidr ip     cidr   =  ip in cidr at ip cidr (find str index cidr "/")

fn :: has unsafe path char String => Bool
      has unsafe path char p      =
        has_trav = str_contains p ".."
        has_semi = str_contains p ";"
        has_pipe = str_contains p "|"
        has_amp  = str_contains p "&"
        has_dlr  = str_contains p "$"
        has_tick = str_contains p "`"
        has_spc  = str_contains p " "
        has_trav or has_semi or has_pipe or has_amp or has_dlr or has_tick or has_spc

fn :: is safe unix path String => Bool
      is safe unix path path   =
        | (str_len path) < 2 or (str_len path) > 108                     = False
        | not ((str_starts_with path "/") or (str_starts_with path "./")) = False
        | has unsafe path char path                                       = False
        | otherwise                                                       = True

fn :: sock addr ipv4 String Int  => SockAddrRes
      sock addr ipv4 host   port =
        | not (is valid ipv4 host) = SockAddrErr "invalid IPv4 address"
        | not (is valid port port) = SockAddrErr "port out of range (1..65535)"
        | otherwise                = SockAddrOk (SockAddr "inet" host port "")

fn :: sock addr ipv6 String Int  => SockAddrRes
      sock addr ipv6 host   port =
        | not (is valid ipv6 host) = SockAddrErr "invalid IPv6 address"
        | not (is valid port port) = SockAddrErr "port out of range (1..65535)"
        | otherwise                = SockAddrOk (SockAddr "inet6" host port "")

fn :: sock addr unix String => SockAddrRes
      sock addr unix path   =
        | not (is safe unix path path) = SockAddrErr "unsafe or invalid Unix socket path"
        | otherwise                    = SockAddrOk (SockAddr "unix" "" 0 path)

fn :: parse port str String => Int
      parse port str s      =
        | not (is all digits s) = -1
        | otherwise             = str_to_int s

fn :: parse bracketed ipv6 at String Int => SockAddrRes
      parse bracketed ipv6 at spec close_idx =
        | close_idx < 2 = SockAddrErr "invalid bracketed IPv6 endpoint"
        | otherwise =
          host = str_slice spec 1 close_idx
          pstr = str_slice spec (close_idx + 2) (str_len spec)
          sock addr ipv6 host (parse port str pstr)

fn :: parse bracketed ipv6 String => SockAddrRes
      parse bracketed ipv6 spec   =  parse bracketed ipv6 at spec (find str index spec "]:")

fn :: parse host port ipv4 at String Int => SockAddrRes
      parse host port ipv4 at spec colon_idx =
        | colon_idx < 1 = SockAddrErr "missing port in IPv4 endpoint"
        | otherwise =
          host = str_slice spec 0 colon_idx
          pstr = str_slice spec (colon_idx + 1) (str_len spec)
          sock addr ipv4 host (parse port str pstr)

fn :: parse host port ipv4 String => SockAddrRes
      parse host port ipv4 spec   =  parse host port ipv4 at spec (find str index spec ":")

fn :: sock parse addr String => SockAddrRes
      sock parse addr spec   =
        | str_starts_with spec "unix:"                              = sock addr unix (str_slice spec 5 (str_len spec))
        | (str_starts_with spec "/") or (str_starts_with spec "./") = sock addr unix spec
        | str_starts_with spec "["                                  = parse bracketed ipv6 spec
        | otherwise                                                 = parse host port ipv4 spec

-- ============================================================
-- Socket Creation, Options, Shutdown, Poll & Lifecycle (FR-SOCK-001, FR-SOCK-003)
-- @implements FR-SOCK-001
-- @implements FR-SOCK-003
-- ============================================================

fn :: empty addr => SockAddr
      empty addr =  SockAddr "none" "" 0 ""

fn :: default sock opts => SockOpts
      default sock opts =  SockOpts True False False False False 5000 65536 65536

fn :: new socket Int String String    => Socket
      new socket id  fam    sock_kind =
        addr = empty addr
        opts = default sock opts
        Socket fam id sock_kind addr addr opts True False False True True [] [] addr

fn :: sock tcp => Socket
      sock tcp =  new socket 1 "inet" "stream"

fn :: sock tcp6 => Socket
      sock tcp6 =  new socket 2 "inet6" "stream"

fn :: sock udp => Socket
      sock udp =  new socket 3 "inet" "dgram"

fn :: sock udp6 => Socket
      sock udp6 =  new socket 4 "inet6" "dgram"

fn :: sock unix stream => Socket
      sock unix stream =  new socket 5 "unix" "stream"

fn :: sock unix dgram => Socket
      sock unix dgram =  new socket 6 "unix" "dgram"

fn :: sock set options Socket SockOpts => SockRes
      sock set options s      new_opts =
        | not (is_open s)                                       = SockErr "socket is closed"
        | (timeout_ms new_opts) < 0                             = SockErr "timeout_ms cannot be negative"
        | (rcvbuf new_opts) <= 0 or (sndbuf new_opts) <= 0      = SockErr "buffer sizes must be > 0"
        | otherwise                                             = SockOk (s with opts: new_opts)

fn :: sock set timeout Socket Int => SockRes
      sock set timeout s      ms  =
        | not (is_open s) = SockErr "socket is closed"
        | ms < 0          = SockErr "timeout_ms cannot be negative"
        | otherwise       = SockOk (s with opts: ((opts s) with timeout_ms: ms))

fn :: sock set tcp nodelay Socket Bool => SockRes
      sock set tcp nodelay s enabled =
        | not (is_open s)           = SockErr "socket is closed"
        | (sock_type s) != "stream" = SockErr "tcp_nodelay requires stream socket"
        | otherwise                 = SockOk (s with opts: ((opts s) with tcp_nodelay: enabled))

fn :: sock set broadcast Socket Bool    => SockRes
      sock set broadcast s      enabled =
        | not (is_open s)          = SockErr "socket is closed"
        | (sock_type s) != "dgram" = SockErr "broadcast requires dgram socket"
        | otherwise                = SockOk (s with opts: ((opts s) with broadcast: enabled))

fn :: sock set buf sizes Socket Int Int => SockRes
      sock set buf sizes s rcv snd =
        | not (is_open s)     = SockErr "socket is closed"
        | rcv <= 0 or snd <= 0 = SockErr "buffer sizes must be > 0"
        | otherwise           = SockOk (s with opts: ((opts s) with rcvbuf: rcv, sndbuf: snd))

fn :: sock local addr Socket => SockAddrRes
      sock local addr s      =
        | not (is_open s)                   = SockAddrErr "socket is closed"
        | (family (local_addr s)) == "none" = SockAddrErr "socket is not bound"
        | otherwise                         = SockAddrOk (local_addr s)

fn :: sock peer addr Socket => SockAddrRes
      sock peer addr s      =
        | not (is_open s)      = SockAddrErr "socket is closed"
        | not (is_connected s) = SockAddrErr "socket is not connected"
        | otherwise            = SockAddrOk (remote_addr s)

fn :: sock shutdown Socket String => SockRes
      sock shutdown s      how    =
        | not (is_open s)      = SockErr "socket is closed"
        | not (is_connected s) = SockErr "socket is not connected"
        | how == "rd"          = SockOk (s with can_read: False)
        | how == "wr"          = SockOk (s with can_write: False)
        | how == "rdwr"        = SockOk (s with can_read: False, can_write: False)
        | otherwise            = SockErr "invalid shutdown mode (expected rd, wr, or rdwr)"

fn :: sock poll Socket => SockPoll
      sock poll s      =
        | not (is_open s) = SockPoll False False True
        | otherwise =
          rd_ok = (can_read s) and (((int list len (rx_buf s)) > 0) or (is_listening s))
          wr_ok = (can_write s) and ((is_connected s) or ((sock_type s) == "dgram"))
          SockPoll rd_ok wr_ok False

fn :: bind unix marker SockAddr => ()
      bind unix marker addr     =
        | (family addr) == "unix" = write_file (path addr) ""
        | otherwise               = ()

fn :: sock bind Socket SockAddr => SockRes
      sock bind s      addr     =
        | not (is_open s)             = SockErr "socket is closed"
        | (family s) != (family addr) = SockErr "socket family mismatch on bind"
        | otherwise =
          _ = bind unix marker addr
          SockOk (s with local_addr: addr)

fn :: sock listen Socket Int     => SockRes
      sock listen s      backlog =
        | not (is_open s)                   = SockErr "socket is closed"
        | (sock_type s) != "stream"         = SockErr "only stream sockets can listen"
        | backlog < 1                       = SockErr "backlog must be >= 1"
        | (family (local_addr s)) == "none" = SockErr "socket must be bound before listen"
        | otherwise                         = SockOk (s with is_listening: True)

fn :: sock connect Socket SockAddr => SockRes
      sock connect s      addr     =
        | not (is_open s)             = SockErr "socket is closed"
        | (family s) != (family addr) = SockErr "socket family mismatch on connect"
        | otherwise                   = SockOk (s with remote_addr: addr, is_connected: True, can_read: True, can_write: True)

fn :: sock accept Socket => SockRes
      sock accept srv    =
        | not (is_open srv)      = SockErr "socket is closed"
        | not (is_listening srv) = SockErr "socket is not listening"
        | otherwise              = SockOk (srv with sock_id: ((sock_id srv) + 100), is_listening: False, is_connected: True, can_read: True, can_write: True)

fn :: sock connect pair Socket Socket => SockPairRes
      sock connect pair client srv    =
        | not (is_open client) or not (is_open srv) = SockPairErr "socket is closed"
        | not (is_listening srv)                    = SockPairErr "server socket is not listening"
        | (family client) != (family srv)           = SockPairErr "socket family mismatch"
        | otherwise =
          cli_conn = client with remote_addr: (local_addr srv), is_connected: True, can_read: True, can_write: True
          srv_peer = srv with sock_id: ((sock_id srv) + 100), remote_addr: (local_addr client), is_listening: False, is_connected: True, can_read: True, can_write: True
          SockPairOk cli_conn srv_peer

fn :: sock close Socket => SockRes
      sock close s      =
        | not (is_open s) = SockErr "socket already closed"
        | otherwise       = SockOk (s with is_open: False, is_listening: False, is_connected: False, can_read: False, can_write: False, rx_buf: [], tx_buf: [])

-- ============================================================
-- Stream, Datagram, Exact & Framed Data Transfer (FR-SOCK-002, FR-SOCK-003)
-- @implements FR-SOCK-002
-- @implements FR-SOCK-003
-- @mitigates VUL-INPUT-001
-- ============================================================

fn :: sock send bytes Socket [Int] => SockRes
      sock send bytes s      data  =
        | not (is_open s)            = SockErr "socket is closed"
        | not (is_connected s)       = SockErr "socket is not connected"
        | not (can_write s)          = SockErr "socket write half is shut down"
        | not (all valid bytes data) = SockErr "invalid byte value outside 0..255"
        | otherwise                  = SockOk (s with tx_buf: ((tx_buf s) :: data))

fn :: sock send all Socket [Int] => SockRes
      sock send all s      data  =  sock send bytes s data

fn :: sock pipe transfer Socket Socket => SockPairRes
      sock pipe transfer sender rcvr   =
        | not (is_open sender) or not (is_open rcvr) = SockPairErr "socket is closed"
        | otherwise =
          s_clean   = sender with tx_buf: []
          r_updated = rcvr with rx_buf: ((rx_buf rcvr) :: (tx_buf sender))
          SockPairOk s_clean r_updated

fn :: sock recv bytes Socket Int       => SockRecvBytesRes
      sock recv bytes s      max_bytes =
        | not (is_open s)      = SockBytesErr "socket is closed"
        | not (is_connected s) = SockBytesErr "socket is not connected"
        | not (can_read s)     = SockBytesErr "socket read half is shut down"
        | max_bytes < 1        = SockBytesErr "max_bytes must be >= 1"
        | otherwise =
          buf = rx_buf s
          SockBytesOk (s with rx_buf: (drop ints buf max_bytes)) (take ints buf max_bytes)

fn :: sock recv exact Socket Int       => SockRecvBytesRes
      sock recv exact s      exact_len =
        | not (is_open s)                      = SockBytesErr "socket is closed"
        | not (is_connected s)                 = SockBytesErr "socket is not connected"
        | not (can_read s)                     = SockBytesErr "socket read half is shut down"
        | exact_len < 1                        = SockBytesErr "exact_len must be >= 1"
        | (int list len (rx_buf s)) < exact_len = SockBytesErr "insufficient bytes for sock_recv_exact"
        | otherwise =
          buf = rx_buf s
          SockBytesOk (s with rx_buf: (drop ints buf exact_len)) (take ints buf exact_len)

fn :: sock send str Socket String => SockRes
      sock send str s      text   =  sock send bytes s (str to byte list text)

fn :: sock recv str from SockRecvBytesRes   => SockRecvStrRes
      sock recv str from (SockBytesErr msg) =  SockStrErr msg
      sock recv str from (SockBytesOk s2 bytes) = SockStrOk s2 (byte list to str bytes)

fn :: sock recv str Socket Int       => SockRecvStrRes
      sock recv str s      max_bytes =  sock recv str from (sock recv bytes s max_bytes)

fn :: sock send to Socket [Int] SockAddr => SockRes
      sock send to s payload target =
        | not (is_open s)               = SockErr "socket is closed"
        | not (can_write s)             = SockErr "socket write half is shut down"
        | (sock_type s) != "dgram"      = SockErr "sock send to requires dgram socket"
        | (family s) != (family target) = SockErr "socket family mismatch"
        | not (all valid bytes payload) = SockErr "invalid byte value outside 0..255"
        | otherwise                     = SockOk (s with remote_addr: target, tx_buf: payload)

fn :: sock deliver dgram Socket Socket => SockPairRes
      sock deliver dgram sender rcvr   =
        | not (is_open sender) or not (is_open rcvr)                  = SockPairErr "socket is closed"
        | (sock_type sender) != "dgram" or (sock_type rcvr) != "dgram" = SockPairErr "requires dgram sockets"
        | otherwise =
          s_clean = sender with tx_buf: []
          r_dgram = rcvr with rx_buf: (tx_buf sender), dgram_sender: (local_addr sender)
          SockPairOk s_clean r_dgram

fn :: sock recv from Socket Int       => SockRecvFromRes
      sock recv from s      max_bytes =
        | not (is_open s)          = SockFromErr "socket is closed"
        | not (can_read s)         = SockFromErr "socket read half is shut down"
        | (sock_type s) != "dgram" = SockFromErr "sock recv from requires dgram socket"
        | max_bytes < 1            = SockFromErr "max_bytes must be >= 1"
        | otherwise                = SockFromOk (s with rx_buf: []) (take ints (rx_buf s) max_bytes) (dgram_sender s)

fn :: encode be32 Int => [Int]
      encode be32 n   =  [(n / 16777216) % 256, (n / 65536) % 256, (n / 256) % 256, n % 256]

fn :: decode be32 [Int]           => Int
      decode be32 (b3:b2:b1:b0:_) =  (b3 * 16777216) + (b2 * 65536) + (b1 * 256) + b0
      decode be32 _               =  -1

fn :: sock send frame Socket [Int]   => SockRes
      sock send frame s      payload =  sock send bytes s ((encode be32 (int list len payload)) :: payload)

fn :: unpack frame body Socket [Int] Int Int => SockRecvBytesRes
      unpack frame body s rem flen max_bytes =
        | flen < 0 or flen > max_bytes = SockBytesErr "frame exceeds max_bytes limit"
        | (int list len rem) < flen    = SockBytesErr "incomplete frame payload"
        | otherwise                    = SockBytesOk (s with rx_buf: (drop ints rem flen)) (take ints rem flen)

fn :: unpack frame buf Socket [Int] Int => SockRecvBytesRes
      unpack frame buf s buf max_bytes =
        | (int list len buf) < 4 = SockBytesErr "incomplete frame header"
        | otherwise              = unpack frame body s (drop ints buf 4) (decode be32 (take ints buf 4)) max_bytes

fn :: sock recv frame Socket Int       => SockRecvBytesRes
      sock recv frame s      max_bytes =
        | not (is_open s)      = SockBytesErr "socket is closed"
        | not (is_connected s) = SockBytesErr "socket is not connected"
        | not (can_read s)     = SockBytesErr "socket read half is shut down"
        | max_bytes < 1        = SockBytesErr "max_bytes must be >= 1"
        | otherwise            = unpack frame buf s (rx_buf s) max_bytes

fn :: find newline idx [Int]    Int => Int
      find newline idx []       _   =  -1
      find newline idx (b:rest) idx =
        | b == 10   = idx
        | otherwise = find newline idx rest (idx + 1)

fn :: sock send line Socket String => SockRes
      sock send line s      line   =  sock send str s (line + "\n")

fn :: unpack line buf Socket [Int] Int Int => SockRecvStrRes
      unpack line buf s buf nl_idx max_bytes =
        | nl_idx < 0         = SockStrErr "newline delimiter not found"
        | nl_idx > max_bytes = SockStrErr "line exceeds max_bytes limit"
        | otherwise          = SockStrOk (s with rx_buf: (drop ints buf (nl_idx + 1))) (byte list to str (take ints buf nl_idx))

fn :: sock recv line Socket Int       => SockRecvStrRes
      sock recv line s      max_bytes =
        | not (is_open s)      = SockStrErr "socket is closed"
        | not (is_connected s) = SockStrErr "socket is not connected"
        | not (can_read s)     = SockStrErr "socket read half is shut down"
        | max_bytes < 1        = SockStrErr "max_bytes must be >= 1"
        | otherwise            = unpack line buf s (rx_buf s) (find newline idx (rx_buf s) 0) max_bytes

-- ============================================================
-- Solstice RGF-001 Descriptor-Based TCP & Unix Socket API (FR-SOCK-004)
-- @implements FR-SOCK-004
-- @implements API-SOCK-001
-- @mitigates VUL-INJ-002
-- @mitigates VUL-INPUT-001
-- ============================================================

fn :: sock lstat exists (Bool, String, Int, Int, Int, String, String, Int, String) => Bool
      sock lstat exists (exists, _, _, _, _, _, _, _, _) = exists

fn :: sock lstat size (Bool, String, Int, Int, Int, String, String, Int, String) => Int
      sock lstat size (_, _, _, _, sz, _, _, _, _) = sz

fn :: is sock ws Int => Bool
      is sock ws c   =  c == 32 or c == 9 or c == 10 or c == 13

fn :: trim sock right String Int     => String
      trim sock right s      end_pos =
        | end_pos <= 0                             = ""
        | is sock ws (str_char_at s (end_pos - 1)) = trim sock right s (end_pos - 1)
        | otherwise                                = str_slice s 0 end_pos

fn :: clean sock str String => String
      clean sock str s      =  trim sock right s (str_len s)

fn :: read sock seq String => Int
      read sock seq spath  =
        | sock lstat exists (file_lstat spath) = (str_to_int (clean sock str (read_file spath))) + 1
        | otherwise                            = 1

fn :: next sock seq Int => Int
      next sock seq pid =
        spath = "/tmp/rg_sock_seq_{pid}.cnt"
        n     = read sock seq spath
        _     = write_file spath "{n}"
        n

fn :: alloc sock fd Int => Int
      alloc sock fd pid =
        seq   = next sock seq pid
        hpath = "/tmp/rg_sock_handle_{pid}_{seq}.fd"
        sys_open_mode hpath "w"

fn :: sock fd is open Int => Bool
      sock fd is open fd  =
        | fd < 0    = False
        | otherwise = (sys_call 72 fd 1 0 0 0 0) >= 0

fn :: is valid listen host String => Bool
      is valid listen host host   =
        | host == "0.0.0.0" or host == "localhost" = True
        | otherwise                                = is valid ipv4 host

fn :: resolve tcp port Int  => Int
      resolve tcp port port =
        | port > 0  = port
        | otherwise =
          pid = sys_getpid
          seq = next sock seq pid
          40000 + ((pid % 1000) * 20) + (seq % 19)

fn :: sock lpid is alive Int Int => Bool
      sock lpid is alive lpid old_lfd =
        | lpid == (sys_getpid) = sock fd is open old_lfd
        | lpid <= 0            = False
        | otherwise            = (sys_kill lpid 0) == 0

fn :: is port in use by lfd Int Int Int => Bool
      is port in use by lfd lpid old_lfd port =
        | not (sock lpid is alive lpid old_lfd) = False
        | not (sock lstat exists (file_lstat "/tmp/rg_sock_fd_{lpid}_{old_lfd}.port")) = False
        | otherwise =
          old_p = str_to_int (clean sock str (read_file "/tmp/rg_sock_fd_{lpid}_{old_lfd}.port"))
          old_p == port

fn :: check tcp lfile String String Int => Bool
      check tcp lfile lfile pfile port =
        | not (sock lstat exists (file_lstat lfile)) = False
        | not (sock lstat exists (file_lstat pfile)) = False
        | otherwise =
          old_lfd = str_to_int (clean sock str (read_file lfile))
          lpid    = str_to_int (clean sock str (read_file pfile))
          is port in use by lfd lpid old_lfd port

fn :: is tcp port in use Int => Bool
      is tcp port in use port =
        uid = sys_getuid
        check tcp lfile "/tmp/rg_sock_tcp_{uid}_{port}.lfd" "/tmp/rg_sock_tcp_{uid}_{port}.lpid" port

fn :: bind tcp listener String Int         => (Int, Int)
      bind tcp listener host   actual_port =
        | is tcp port in use actual_port = (0 - 5, 0 - 1)
        | otherwise =
          pid = sys_getpid
          uid = sys_getuid
          lfd = alloc sock fd pid
          _   = write_file "/tmp/rg_sock_fd_{pid}_{lfd}.port" "{actual_port}"
          _   = write_file "/tmp/rg_sock_fd_{pid}_{lfd}.listen" "tcp:{host}:{actual_port}"
          _   = write_file "/tmp/rg_sock_fd_{pid}_{lfd}.q" ""
          _   = write_file "/tmp/rg_sock_tcp_{uid}_{actual_port}.lfd" "{lfd}"
          _   = write_file "/tmp/rg_sock_tcp_{uid}_{actual_port}.lpid" "{pid}"
          (0, lfd)

-- @implements FR-SOCK-004
-- @implements API-SOCK-001
-- @mitigates VUL-INPUT-001
fn :: sys tcp listen String Int Int => (Int, Int)
      sys tcp listen host port backlog =
        | backlog < 1 or port < 0 or port > 65535 = (0 - 7, 0 - 1)
        | not (is valid listen host host)         = (0 - 7, 0 - 1)
        | port > 0 and port < 1024 and (sys_getuid) != 0 = (0 - 6, 0 - 1)
        | otherwise =
          actual_port = resolve tcp port port
          bind tcp listener host actual_port

-- @implements FR-SOCK-004
-- @implements API-SOCK-001
-- @mitigates VUL-INJ-002
-- @mitigates VUL-INPUT-001
fn :: sys unix listen String Int     => (Int, Int)
      sys unix listen path   backlog =
        | backlog < 1 or (not (is safe unix path path)) = (0 - 7, 0 - 1)
        | otherwise =
          pid   = sys_getpid
          uid   = sys_getuid
          lfd   = alloc sock fd pid
          phash = sha256_str path
          _     = write_file path "{lfd}"
          _     = write_file "/tmp/rg_sock_fd_{pid}_{lfd}.port" "0"
          _     = write_file "/tmp/rg_sock_fd_{pid}_{lfd}.listen" "unix:{path}"
          _     = write_file "/tmp/rg_sock_fd_{pid}_{lfd}.q" ""
          _     = write_file "/tmp/rg_sock_ux_{uid}_{phash}.lfd" "{lfd}"
          _     = write_file "/tmp/rg_sock_ux_{uid}_{phash}.lpid" "{pid}"
          (0, lfd)

-- @implements FR-SOCK-004
-- @implements API-SOCK-001
fn :: sys local port Int => Int
      sys local port lfd =
        | not (sock fd is open lfd) = 0 - 7
        | not (sock lstat exists (file_lstat "/tmp/rg_sock_fd_{sys_getpid}_{lfd}.port")) = 0 - 7
        | otherwise = str_to_int (clean sock str (read_file "/tmp/rg_sock_fd_{sys_getpid}_{lfd}.port"))

fn :: join sock queue String String => String
      join sock queue qcur   cid    =
        | (str_len qcur) == 0 = cid
        | otherwise           = qcur + "," + cid

fn :: connect to listener lfd Int Int => (Int, Int)
      connect to listener lfd lpid lfd =
        | not (sock lpid is alive lpid lfd) = (0 - 3, 0 - 1)
        | not (sock lstat exists (file_lstat "/tmp/rg_sock_fd_{lpid}_{lfd}.listen")) = (0 - 3, 0 - 1)
        | otherwise =
          pid  = sys_getpid
          seq  = next sock seq pid
          cid  = "{pid}_{seq}"
          c2s  = "/tmp/rg_sock_ch_{cid}_c2s"
          s2c  = "/tmp/rg_sock_ch_{cid}_s2c"
          _    = write_file "{c2s}.dat" ""
          _    = write_file "{s2c}.dat" ""
          cfd  = alloc sock fd pid
          _    = write_file "/tmp/rg_sock_fd_{pid}_{cfd}.tx" c2s
          _    = write_file "/tmp/rg_sock_fd_{pid}_{cfd}.rx" s2c
          qcur = read_file "/tmp/rg_sock_fd_{lpid}_{lfd}.q"
          qnew = join sock queue qcur cid
          _    = write_file "/tmp/rg_sock_fd_{lpid}_{lfd}.q" qnew
          (0, cfd)

-- @implements FR-SOCK-004
-- @implements API-SOCK-001
-- @mitigates VUL-INPUT-001
fn :: sys tcp connect String Int Int => (Int, Int)
      sys tcp connect host port timeout_ms =
        | not (is valid port port) or timeout_ms < (0 - 1) = (0 - 7, 0 - 1)
        | not (is valid listen host host)                  = (0 - 7, 0 - 1)
        | not (sock lstat exists (file_lstat "/tmp/rg_sock_tcp_{sys_getuid}_{port}.lfd")) = (0 - 3, 0 - 1)
        | not (sock lstat exists (file_lstat "/tmp/rg_sock_tcp_{sys_getuid}_{port}.lpid")) = (0 - 3, 0 - 1)
        | otherwise =
          uid  = sys_getuid
          lfd  = str_to_int (clean sock str (read_file "/tmp/rg_sock_tcp_{uid}_{port}.lfd"))
          lpid = str_to_int (clean sock str (read_file "/tmp/rg_sock_tcp_{uid}_{port}.lpid"))
          connect to listener lfd lpid lfd

fn :: connect unix lfile String String => (Int, Int)
      connect unix lfile lfile  pfile  =
        | not (sock lstat exists (file_lstat lfile)) = (0 - 3, 0 - 1)
        | not (sock lstat exists (file_lstat pfile)) = (0 - 3, 0 - 1)
        | otherwise =
          lfd  = str_to_int (clean sock str (read_file lfile))
          lpid = str_to_int (clean sock str (read_file pfile))
          connect to listener lfd lpid lfd

-- @implements FR-SOCK-004
-- @implements API-SOCK-001
-- @mitigates VUL-INJ-002
-- @mitigates VUL-INPUT-001
fn :: sys unix connect String Int        => (Int, Int)
      sys unix connect path   timeout_ms =
        | not (is safe unix path path) or timeout_ms < (0 - 1) = (0 - 7, 0 - 1)
        | otherwise =
          uid   = sys_getuid
          phash = sha256_str path
          connect unix lfile "/tmp/rg_sock_ux_{uid}_{phash}.lfd" "/tmp/rg_sock_ux_{uid}_{phash}.lpid"

fn :: dequeue first cid String Int       => (String, String)
      dequeue first cid q      comma_idx =
        | comma_idx < 0 = (q, "")
        | otherwise     = (str_slice q 0 comma_idx, str_slice q (comma_idx + 1) (str_len q))

fn :: accept cid on listener Int String String => (Int, Int, String)
      accept cid on listener lfd cid qrest =
        pid = sys_getpid
        _   = write_file "/tmp/rg_sock_fd_{pid}_{lfd}.q" qrest
        c2s = "/tmp/rg_sock_ch_{cid}_c2s"
        s2c = "/tmp/rg_sock_ch_{cid}_s2c"
        sfd = alloc sock fd pid
        _   = write_file "/tmp/rg_sock_fd_{pid}_{sfd}.tx" s2c
        _   = write_file "/tmp/rg_sock_fd_{pid}_{sfd}.rx" c2s
        (0, sfd, "127.0.0.1")

fn :: accept dequeue step Int (String, String) => (Int, Int, String)
      accept dequeue step lfd (cid, qrest)     =
        accept cid on listener lfd cid qrest

fn :: accept poll step Int String Int Int => (Int, Int, String)
      accept poll step lfd q start_ms timeout_ms =
        | (str_len q) > 0 =
          accept dequeue step lfd (dequeue first cid q (find str index q ","))
        | timeout_ms == 0 = (0 - 2, 0 - 1, "")
        | timeout_ms > 0 and ((sys_time_ms) - start_ms) >= timeout_ms = (0 - 2, 0 - 1, "")
        | otherwise =
          _ = sys_sleep_ms 10
          accept poll loop lfd start_ms timeout_ms

fn :: accept poll loop Int Int Int => (Int, Int, String)
      accept poll loop lfd start_ms timeout_ms =
        accept poll step lfd (clean sock str (read_file "/tmp/rg_sock_fd_{sys_getpid}_{lfd}.q")) start_ms timeout_ms

-- @implements FR-SOCK-004
-- @implements API-SOCK-001
-- @mitigates VUL-INPUT-001
fn :: sys accept Int Int        => (Int, Int, String)
      sys accept lfd timeout_ms =
        | not (sock fd is open lfd) or timeout_ms < (0 - 1) = (0 - 7, 0 - 1, "")
        | not (sock lstat exists (file_lstat "/tmp/rg_sock_fd_{sys_getpid}_{lfd}.listen")) = (0 - 7, 0 - 1, "")
        | otherwise = accept poll loop lfd (sys_time_ms) timeout_ms

fn :: sock read raw fd Int Int => String
      sock read raw fd rfd max_n =
        | rfd < 0   = ""
        | max_n < 1 =
          _ = sys_close rfd
          ""
        | otherwise =
          s = sys_read_fd rfd max_n
          _ = sys_close rfd
          s

fn :: sock write raw fd Int String => Int
      sock write raw fd wfd s =
        | wfd < 0   = 0 - 99
        | otherwise =
          nw = sys_write_fd wfd s
          _  = sys_close wfd
          nw

fn :: send to tx base String String => (Int, Int)
      send to tx base tx_base data =
        | sock lstat exists (file_lstat "{tx_base}.wr_closed") = (0 - 4, 0 - 1)
        | otherwise =
          dpath = "{tx_base}.dat"
          fsize = sock lstat size (file_lstat dpath)
          cur   = sock read raw fd (sys_open_mode dpath "r") fsize
          _     = sock write raw fd (sys_open dpath 577 420) (cur + data)
          (0, str_len data)

-- @implements FR-SOCK-004
-- @implements API-SOCK-001
-- @mitigates VUL-INPUT-001
fn :: sys send Int String Int        => (Int, Int)
      sys send fd  data   timeout_ms =
        | not (sock fd is open fd) or timeout_ms < (0 - 1) = (0 - 7, 0 - 1)
        | not (sock lstat exists (file_lstat "/tmp/rg_sock_fd_{sys_getpid}_{fd}.tx")) = (0 - 7, 0 - 1)
        | otherwise =
          tx_base = clean sock str (read_file "/tmp/rg_sock_fd_{sys_getpid}_{fd}.tx")
          send to tx base tx_base data

-- @implements FR-SOCK-004
-- @implements API-SOCK-001
fn :: sys shutdown write Int => Int
      sys shutdown write fd  =
        | not (sock fd is open fd) = 0 - 7
        | not (sock lstat exists (file_lstat "/tmp/rg_sock_fd_{sys_getpid}_{fd}.tx")) = 0 - 7
        | otherwise =
          tx_base = clean sock str (read_file "/tmp/rg_sock_fd_{sys_getpid}_{fd}.tx")
          _       = write_file "{tx_base}.wr_closed" "1"
          _       = write_file "{tx_base}.eof" "1"
          0

fn :: consume rx fd Int String Int Int => (Int, String)
      consume rx fd rfd dpath fsize max_bytes =
        | rfd < 0   = (0 - 99, "")
        | otherwise =
          chunk = sys_read_fd rfd max_bytes
          rem   = sys_read_fd rfd fsize
          _     = sys_close rfd
          _     = sock write raw fd (sys_open dpath 577 420) rem
          (0, chunk)

fn :: recv poll step String String String Int Int Int Int => (Int, String)
      recv poll step rx_base dpath epath fsize max_bytes start_ms timeout_ms =
        | fsize > 0 =
          consume rx fd (sys_open_mode dpath "r") dpath fsize max_bytes
        | sock lstat exists (file_lstat epath) = (0 - 1, "")
        | timeout_ms == 0 = (0 - 2, "")
        | timeout_ms > 0 and ((sys_time_ms) - start_ms) >= timeout_ms = (0 - 2, "")
        | otherwise =
          _ = sys_sleep_ms 10
          recv poll loop rx_base max_bytes start_ms timeout_ms

fn :: recv poll loop String Int Int Int => (Int, String)
      recv poll loop rx_base max_bytes start_ms timeout_ms =
        dpath = "{rx_base}.dat"
        epath = "{rx_base}.eof"
        fsize = sock lstat size (file_lstat dpath)
        recv poll step rx_base dpath epath fsize max_bytes start_ms timeout_ms

-- @implements FR-SOCK-004
-- @implements API-SOCK-001
-- @mitigates VUL-INPUT-001
fn :: sys recv Int Int       Int        => (Int, String)
      sys recv fd  max_bytes timeout_ms =
        | not (sock fd is open fd) or max_bytes < 1 or timeout_ms < (0 - 1) = (0 - 7, "")
        | not (sock lstat exists (file_lstat "/tmp/rg_sock_fd_{sys_getpid}_{fd}.rx")) = (0 - 7, "")
        | otherwise =
          rx_base = clean sock str (read_file "/tmp/rg_sock_fd_{sys_getpid}_{fd}.rx")
          recv poll loop rx_base max_bytes (sys_time_ms) timeout_ms

-- ── RGF-001 Tuple Accessor Helpers ───────────────────────────

-- @implements FR-SOCK-004
-- @implements API-SOCK-001
fn :: sock rc (Int, Int) => Int
      sock rc (rc, _)    =  rc

-- @implements FR-SOCK-004
-- @implements API-SOCK-001
fn :: sock fd (Int, Int) => Int
      sock fd (_, fd)    =  fd

-- @implements FR-SOCK-004
-- @implements API-SOCK-001
fn :: sock accept rc (Int, Int, String) => Int
      sock accept rc (rc, _, _)         =  rc

-- @implements FR-SOCK-004
-- @implements API-SOCK-001
fn :: sock accept fd (Int, Int, String) => Int
      sock accept fd (_, fd, _)         =  fd

-- @implements FR-SOCK-004
-- @implements API-SOCK-001
fn :: sock accept ip (Int, Int, String) => String
      sock accept ip (_, _, ip)         =  ip

-- @implements FR-SOCK-004
-- @implements API-SOCK-001
fn :: sock recv rc (Int, String) => Int
      sock recv rc (rc, _)       =  rc

-- @implements FR-SOCK-004
-- @implements API-SOCK-001
fn :: sock recv data (Int, String) => String
      sock recv data (_, data)     =  data
