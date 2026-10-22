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

fn :: sk lower char String Int Int => String
      sk lower char s idx c =
        | c >= 65 and c <= 90 = char_from_code (c + 32)
        | otherwise           = str_slice s idx (idx + 1)

fn :: sk to lower loop String Int Int => String
      sk to lower loop s idx len =
        | idx >= len = ""
        | otherwise  = (sk lower char s idx (str_char_at s idx)) + (sk to lower loop s (idx + 1) len)

fn :: sk to lower String => String
      sk to lower s      =  sk to lower loop s 0 (str_len s)

fn :: sk is ws Int => Bool
      sk is ws c   =  c == 32 or c == 9 or c == 13

fn :: sk split ws loop String Int Int Int Bool => [String]
      sk split ws loop s start idx len in_tok =
        | idx >= len =
          | in_tok    = [str_slice s start len]
          | otherwise = [] |.
        | sk is ws (str_char_at s idx) =
          | in_tok    = [str_slice s start idx] :: (sk split ws loop s (idx + 1) (idx + 1) len False)
          | otherwise = sk split ws loop s (idx + 1) (idx + 1) len False |.
        | otherwise =
          | in_tok    = sk split ws loop s start (idx + 1) len True
          | otherwise = sk split ws loop s idx (idx + 1) len True

fn :: sk strip comment String Int   => String
      sk strip comment line   h_idx =
        | h_idx < 0 = line
        | otherwise = str_slice line 0 h_idx

fn :: sk list has host [String] String => Bool
      sk list has host [] _ = False
      sk list has host (x:rest) target =
        | (sk to lower x) == target = True
        | otherwise                 = sk list has host rest target

fn :: sk match hosts tokens [String] String => String
      sk match hosts tokens [] _ = ""
      sk match hosts tokens (ip:aliases) target =
        | not (is valid ipv4 ip)          = ""
        | sk list has host aliases target = ip
        | otherwise                       = ""

fn :: sk search hosts after found String [String] String => String
      sk search hosts after found found rest target =
        | (str_len found) > 0 = found
        | otherwise           = sk search hosts lines rest target

fn :: sk search hosts lines [String] String => String
      sk search hosts lines [] _ = ""
      sk search hosts lines (line:rest) target =
        clean = sk strip comment line (find str index line "#")
        toks  = sk split ws loop clean 0 0 (str_len clean) False
        sk search hosts after found (sk match hosts tokens toks target) rest target

fn :: sk lstat exists (Bool, String, Int, Int, Int, String, String, Int, String) => Bool
      sk lstat exists (ex, _, _, _, _, _, _, _, _) = ex

fn :: sk lookup etc hosts String => String
      sk lookup etc hosts host   =
        | not (sk lstat exists (file_lstat "/etc/hosts")) = ""
        | otherwise =
          raw   = read_file "/etc/hosts"
          lines = split by char raw 10
          sk search hosts lines lines (sk to lower host)

fn :: sk check valid ipv4 String => String
      sk check valid ipv4 ns     =
        | is valid ipv4 ns = ns
        | otherwise        = ""

fn :: sk match resolv tokens [String] => String
      sk match resolv tokens []       =  ""
      sk match resolv tokens (k:rest) =
        | k != "nameserver" = ""
        | otherwise         = sk check valid ipv4 (nth str rest 0)

fn :: sk search resolv after found String [String] => String
      sk search resolv after found found rest =
        | (str_len found) > 0 = found
        | otherwise           = sk search resolv lines rest

fn :: sk search resolv lines [String]    => String
      sk search resolv lines []          =  "8.8.8.8"
      sk search resolv lines (line:rest) =
        clean = sk strip comment line (find str index line "#")
        toks  = sk split ws loop clean 0 0 (str_len clean) False
        sk search resolv after found (sk match resolv tokens toks) rest

fn :: sk system nameserver => String
      sk system nameserver =
        | not (sk lstat exists (file_lstat "/etc/resolv.conf")) = "8.8.8.8"
        | otherwise =
          raw   = read_file "/etc/resolv.conf"
          lines = split by char raw 10
          sk search resolv lines lines

fn :: sk encode qname label String Int [String] => String
      sk encode qname label lbl llen rest =
        | llen <= 0 or llen > 63 = sk raw byte 0
        | otherwise              = (sk raw byte llen) + lbl + (sk encode qname rest)

fn :: sk encode qname [String]   => String
      sk encode qname []         =  sk raw byte 0
      sk encode qname (lbl:rest) =  sk encode qname label lbl (str_len lbl) rest

fn :: sk build dns query String => String
      sk build dns query host   =
        hdr   = (sk raw byte 18) + (sk raw byte 52) + (sk raw byte 1) + (sk raw byte 0) + (sk raw byte 0) + (sk raw byte 1) + (sk raw byte 0) + (sk raw byte 0) + (sk raw byte 0) + (sk raw byte 0) + (sk raw byte 0) + (sk raw byte 0)
        qname = sk encode qname (split by char (sk to lower host) 46)
        qtail = (sk raw byte 0) + (sk raw byte 1) + (sk raw byte 0) + (sk raw byte 1)
        hdr + qname + qtail

fn :: sk skip dns name step String Int Int Int => Int
      sk skip dns name step pkt off plen b =
        | b == 0    = off + 1
        | b >= 192  = off + 2
        | otherwise = sk skip dns name pkt (off + 1 + b) plen

fn :: sk skip dns name String Int Int => Int
      sk skip dns name pkt off plen =
        | off >= plen = plen
        | otherwise   = sk skip dns name step pkt off plen (str_char_at pkt off)

fn :: sk check dns rdata String Int Int Int Int Int Int => String
      sk check dns rdata pkt rtype rclass rdlen rdata rem plen =
        | (rdata + rdlen) > plen = ""
        | rtype == 1 and rclass == 1 and rdlen == 4 =
          "{str_char_at pkt rdata}.{str_char_at pkt (rdata + 1)}.{str_char_at pkt (rdata + 2)}.{str_char_at pkt (rdata + 3)}"
        | otherwise =
          sk parse dns answers pkt (rdata + rdlen) (rem - 1) plen

fn :: sk parse dns after name String Int Int Int => String
      sk parse dns after name pkt noff rem plen =
        | (noff + 10) > plen = ""
        | otherwise =
          rtype  = sk decode u16 be pkt noff
          rclass = sk decode u16 be pkt (noff + 2)
          rdlen  = sk decode u16 be pkt (noff + 8)
          sk check dns rdata pkt rtype rclass rdlen (noff + 10) rem plen

fn :: sk parse dns answers String Int Int Int => String
      sk parse dns answers pkt off rem plen =
        | rem <= 0 or (off + 10) > plen = ""
        | otherwise                     = sk parse dns after name pkt (sk skip dns name pkt off plen) rem plen

fn :: sk extract dns after ancount String Int Int => String
      sk extract dns after ancount pkt plen ancount =
        | ancount <= 0 = ""
        | otherwise    = sk parse dns answers pkt ((sk skip dns name pkt 12 plen) + 4) ancount plen

fn :: sk extract dns after len String Int => String
      sk extract dns after len pkt plen =
        | plen < 12 = ""
        | otherwise = sk extract dns after ancount pkt plen (sk decode u16 be pkt 6)

fn :: sk extract dns ipv4 String => String
      sk extract dns ipv4 pkt    =  sk extract dns after len pkt (str_len pkt)

fn :: sk read dns after poll Int Int => String
      sk read dns after poll ufd prc =
        | prc <= 0 =
          _ = sys_close ufd
          ""
        | otherwise =
          resp = sys_read_fd ufd 512
          _    = sys_close ufd
          sk extract dns ipv4 resp

fn :: sk udp dns query String String Int => String
      sk udp dns query ns_ip host timeout_ms =
        | not (is valid ipv4 ns_ip) or not (is valid hostname host) = ""
        | otherwise =
          ptr  = sk alloc page 4096
          mfd  = sk alloc mfd
          ufd  = sys_call 41 2 2 0 0 0 0
          sin  = sk build sockaddr in ns_ip 53 True
          _    = sk poke mfd ptr sin
          _    = sys_call 42 ufd ptr 16 0 0 0
          q    = sk build dns query host
          qlen = str_len q
          _    = sk poke mfd ptr q
          _    = sys_call 44 ufd ptr qlen 16384 0 0
          _    = sk free page mfd ptr 4096
          prc  = sys_poll ufd 1 timeout_ms
          sk read dns after poll ufd prc

fn :: sk resolve after dns String => (Int, String)
      sk resolve after dns d_ip   =
        | (str_len d_ip) > 0 = (0, d_ip)
        | otherwise          = (0 - 3, "")

fn :: sk resolve after hosts String String => (Int, String)
      sk resolve after hosts host h_ip =
        | (str_len h_ip) > 0 = (0, h_ip)
        | otherwise          = sk resolve after dns (sk udp dns query (sk system nameserver) host 500)

-- @implements FR-SOCK-003
-- @implements FR-SOCK-004
-- @implements API-SOCK-001
-- @mitigates VUL-INPUT-001
fn :: sys resolve ipv4 String => (Int, String)
      sys resolve ipv4 host   =
        | host == "localhost"          = (0, "127.0.0.1")
        | host == "0.0.0.0"            = (0, "0.0.0.0")
        | is valid ipv4 host           = (0, host)
        | not (is valid hostname host) = (0 - 7, "")
        | otherwise                    = sk resolve after hosts host (sk lookup etc hosts host)

fn :: sk wrap resolved host (Int, String) Int => SockAddrRes
      sk wrap resolved host (rc, ip_str) port =
        | rc == 0   = SockAddrOk (SockAddr "inet" ip_str port "")
        | otherwise = SockAddrOk (SockAddr "inet" "127.0.0.1" port "")

fn :: sock resolve host String Int  => SockAddrRes
      sock resolve host host   port =
        | not (is valid port port)                       = SockAddrErr "port out of range (1..65535)"
        | host == "localhost"                            = SockAddrOk (SockAddr "inet" "127.0.0.1" port "")
        | host == "ip6-localhost" or host == "::1"       = SockAddrOk (SockAddr "inet6" "::1" port "")
        | is valid ipv4 host                             = SockAddrOk (SockAddr "inet" host port "")
        | is valid ipv6 host                             = SockAddrOk (SockAddr "inet6" host port "")
        | is valid hostname host                         = sk wrap resolved host (sys resolve ipv4 host) port
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

fn :: sk raw byte ub Int => String
      sk raw byte ub ub  =
        | ub >= 1 and ub <= 127 = char_from_code ub
        | otherwise =
          efd = sys_call 290 (256 + ub) 526336 0 0 0 0
          s   = sys_read_fd efd 8
          _   = sys_close efd
          str_slice s 0 1

fn :: sk raw byte Int => String
      sk raw byte b   =  sk raw byte ub (((b % 256) + 256) % 256)

fn :: sk u64 le Int => String
      sk u64 le val =
        | val <= 0 =
          b0 = sk raw byte 0
          b0 + b0 + b0 + b0 + b0 + b0 + b0 + b0
        | otherwise =
          efd = sys_call 290 val 526336 0 0 0 0
          s   = sys_read_fd efd 8
          _   = sys_close efd
          s

fn :: sk decode u16 le String Int => Int
      sk decode u16 le s off =
        (str_char_at s off) + ((str_char_at s (off + 1)) * 256)

fn :: sk decode u16 be String Int => Int
      sk decode u16 be s off =
        ((str_char_at s off) * 256) + (str_char_at s (off + 1))

fn :: sk decode u32 le String Int => Int
      sk decode u32 le s off =
        b0 = str_char_at s off
        b1 = str_char_at s (off + 1)
        b2 = str_char_at s (off + 2)
        b3 = str_char_at s (off + 3)
        b0 + (b1 * 256) + (b2 * 65536) + (b3 * 16777216)

fn :: sk alloc page Int => Int
      sk alloc page sz  =
        neg1 = 0 - 1
        sys_call 9 0 sz 3 34 neg1 0

fn :: sk free page Int Int Int => Int
      sk free page mfd ptr sz =
        _ = sys_close mfd
        sys_call 11 ptr sz 0 0 0 0

fn :: sk alloc mfd => Int
      sk alloc mfd =  sys_call 319 4194311 1 0 0 0 0

fn :: sk poke Int Int String => Int
      sk poke mfd ptr s      =
        slen = str_len s
        _    = sys_call 8 mfd 0 0 0 0 0
        _    = sys_write_fd mfd s
        sys_call 17 mfd ptr slen 0 0 0

fn :: sk peek Int Int Int => String
      sk peek mfd ptr len =
        _ = sys_call 18 mfd ptr len 0 0 0
        _ = sys_call 8 mfd 0 0 0 0 0
        sys_read_fd mfd len

fn :: is valid listen host String => Bool
      is valid listen host host   =
        | host == "0.0.0.0" or host == "localhost" = True
        | otherwise                                = is valid ipv4 host

fn :: sk ipv4 bytes String Bool  => String
      sk ipv4 bytes host   is_cn =
        | host == "localhost" = (sk raw byte 127) + (sk raw byte 0) + (sk raw byte 0) + (sk raw byte 1)
        | host == "0.0.0.0" =
          | is_cn     = (sk raw byte 127) + (sk raw byte 0) + (sk raw byte 0) + (sk raw byte 1)
          | otherwise = (sk raw byte 0) + (sk raw byte 0) + (sk raw byte 0) + (sk raw byte 0) |.
        | otherwise =
          parts = split by char host 46
          b0    = sk raw byte (str_to_int (nth str parts 0))
          b1    = sk raw byte (str_to_int (nth str parts 1))
          b2    = sk raw byte (str_to_int (nth str parts 2))
          b3    = sk raw byte (str_to_int (nth str parts 3))
          b0 + b1 + b2 + b3

fn :: sk build sockaddr in String Int Bool => String
      sk build sockaddr in host port is_cn =
        fam  = (sk raw byte 2) + (sk raw byte 0)
        p_be = (sk raw byte (port / 256)) + (sk raw byte (port % 256))
        ip4  = sk ipv4 bytes host is_cn
        pad8 = sk u64 le 0
        fam + p_be + ip4 + pad8

fn :: sk finish tcp listen Int Int Int => (Int, Int)
      sk finish tcp listen lfd rc_b rc_l =
        | rc_b == (0 - 13) =
          _ = sys_close lfd
          (0 - 6, 0 - 1)
        | rc_b == (0 - 98) =
          _ = sys_close lfd
          (0 - 5, 0 - 1)
        | rc_b < 0 or rc_l < 0 =
          _ = sys_close lfd
          (0 - 7, 0 - 1)
        | otherwise = (0, lfd)

fn :: sk exec tcp listen String Int Int => (Int, Int)
      sk exec tcp listen host port backlog =
        ptr  = sk alloc page 4096
        mfd  = sk alloc mfd
        lfd  = sys_call 41 2 1 0 0 0 0
        _    = sk poke mfd ptr (sk u64 le 1)
        _    = sys_call 54 lfd 1 2 ptr 4 0
        sin  = sk build sockaddr in host port False
        _    = sk poke mfd ptr sin
        rc_b = sys_call 49 lfd ptr 16 0 0 0
        rc_l = sys_call 50 lfd backlog 0 0 0 0
        _    = sk free page mfd ptr 4096
        sk finish tcp listen lfd rc_b rc_l

-- @implements FR-SOCK-004
-- @implements API-SOCK-001
-- @mitigates VUL-INPUT-001
fn :: sys tcp listen String Int Int => (Int, Int)
      sys tcp listen host port backlog =
        | backlog < 1 or port < 0 or port > 65535 = (0 - 7, 0 - 1)
        | not (is valid listen host host)         = (0 - 7, 0 - 1)
        | otherwise                               = sk exec tcp listen host port backlog

fn :: sk finish unix listen Int Int Int => (Int, Int)
      sk finish unix listen lfd rc_b rc_l =
        | rc_b < 0 or rc_l < 0 =
          _ = sys_close lfd
          (0 - 7, 0 - 1)
        | otherwise = (0, lfd)

fn :: sk exec unix listen String Int => (Int, Int)
      sk exec unix listen path backlog =
        ptr  = sk alloc page 4096
        mfd  = sk alloc mfd
        b0   = sk raw byte 0
        _    = sk poke mfd ptr (path + b0)
        _    = sys_call 87 ptr 0 0 0 0 0
        lfd  = sys_call 41 1 1 0 0 0 0
        sun  = (sk raw byte 1) + b0 + path + b0
        ulen = str_len sun
        _    = sk poke mfd ptr sun
        rc_b = sys_call 49 lfd ptr ulen 0 0 0
        rc_l = sys_call 50 lfd backlog 0 0 0 0
        _    = sk free page mfd ptr 4096
        sk finish unix listen lfd rc_b rc_l

-- @implements FR-SOCK-004
-- @implements API-SOCK-001
-- @mitigates VUL-INJ-002
-- @mitigates VUL-INPUT-001
fn :: sys unix listen String Int     => (Int, Int)
      sys unix listen path   backlog =
        | backlog < 1 or (not (is safe unix path path)) = (0 - 7, 0 - 1)
        | otherwise                                     = sk exec unix listen path backlog

fn :: sk extract local port Int String => Int
      sk extract local port rc sa =
        | rc < 0                       = 0 - 7
        | (sk decode u16 le sa 0) == 2 = sk decode u16 be sa 2
        | (sk decode u16 le sa 0) == 1 = 0
        | otherwise                    = 0 - 7

-- @implements FR-SOCK-004
-- @implements API-SOCK-001
fn :: sys local port Int => Int
      sys local port lfd =
        | lfd < 0 = 0 - 7
        | otherwise =
          ptr = sk alloc page 4096
          mfd = sk alloc mfd
          p64 = ptr + 64
          _   = sk poke mfd p64 (sk u64 le 112)
          rc  = sys_call 51 lfd ptr p64 0 0 0
          sa  = sk peek mfd ptr 16
          _   = sk free page mfd ptr 4096
          sk extract local port rc sa

fn :: sk finish connect Int Int => (Int, Int)
      sk finish connect cfd rc  =
        | rc == 0 = (0, cfd)
        | rc == (0 - 110) =
          _ = sys_close cfd
          (0 - 2, 0 - 1)
        | rc == (0 - 13) =
          _ = sys_close cfd
          (0 - 6, 0 - 1)
        | otherwise =
          _ = sys_close cfd
          (0 - 3, 0 - 1)

fn :: sk exec tcp connect ip String Int => (Int, Int)
      sk exec tcp connect ip ip_addr port =
        ptr = sk alloc page 4096
        mfd = sk alloc mfd
        cfd = sys_call 41 2 1 0 0 0 0
        sin = sk build sockaddr in ip_addr port True
        _   = sk poke mfd ptr sin
        rc  = sys_call 42 cfd ptr 16 0 0 0
        _   = sk free page mfd ptr 4096
        sk finish connect cfd rc

fn :: sk connect resolved (Int, String)   Int  => (Int, Int)
      sk connect resolved (r_rc, ip_addr) port =
        | r_rc != 0 = (r_rc, 0 - 1)
        | otherwise = sk exec tcp connect ip ip_addr port

-- @implements FR-SOCK-004
-- @implements API-SOCK-001
-- @mitigates VUL-INPUT-001
fn :: sys tcp connect String Int Int => (Int, Int)
      sys tcp connect host port timeout_ms =
        | not (is valid port port) or timeout_ms < (0 - 1) = (0 - 7, 0 - 1)
        | is valid listen host host                        = sk exec tcp connect ip host port
        | is valid hostname host                           = sk connect resolved (sys resolve ipv4 host) port
        | otherwise                                        = (0 - 7, 0 - 1)

-- @implements FR-SOCK-004
-- @implements API-SOCK-001
-- @mitigates VUL-INJ-002
-- @mitigates VUL-INPUT-001
fn :: sys unix connect String Int        => (Int, Int)
      sys unix connect path   timeout_ms =
        | not (is safe unix path path) or timeout_ms < (0 - 1) = (0 - 7, 0 - 1)
        | otherwise =
          ptr  = sk alloc page 4096
          mfd  = sk alloc mfd
          b0   = sk raw byte 0
          cfd  = sys_call 41 1 1 0 0 0 0
          sun  = (sk raw byte 1) + b0 + path + b0
          ulen = str_len sun
          _    = sk poke mfd ptr sun
          rc   = sys_call 42 cfd ptr ulen 0 0 0
          _    = sk free page mfd ptr 4096
          sk finish connect cfd rc

fn :: sk decode acceptconn Int String => Int
      sk decode acceptconn rc  raw    =
        | rc < 0    = 0 - 1
        | otherwise = sk decode u32 le raw 0

fn :: sk sock acceptconn Int => Int
      sk sock acceptconn fd  =
        | fd < 0 = 0 - 1
        | otherwise =
          ptr = sk alloc page 4096
          mfd = sk alloc mfd
          p64 = ptr + 64
          _   = sk poke mfd ptr (sk u64 le 0)
          _   = sk poke mfd p64 (sk u64 le 4)
          rc  = sys_call 55 fd 1 30 ptr p64 0
          raw = sk peek mfd ptr 4
          _   = sk free page mfd ptr 4096
          sk decode acceptconn rc raw

fn :: sk format peer ip String => String
      sk format peer ip sa     =
        | (sk decode u16 le sa 0) == 2 =
          "{str_char_at sa 4}.{str_char_at sa 5}.{str_char_at sa 6}.{str_char_at sa 7}"
        | otherwise = "127.0.0.1"

fn :: sk finish accept Int String => (Int, Int, String)
      sk finish accept sfd sa     =
        | sfd < 0   = (0 - 7, 0 - 1, "")
        | otherwise = (0, sfd, sk format peer ip sa)

fn :: sk accept after poll Int Int => (Int, Int, String)
      sk accept after poll lfd prc =
        | prc == 0 = (0 - 2, 0 - 1, "")
        | prc < 0  = (0 - 7, 0 - 1, "")
        | otherwise =
          ptr = sk alloc page 4096
          mfd = sk alloc mfd
          p64 = ptr + 64
          _   = sk poke mfd p64 (sk u64 le 112)
          sfd = sys_call 43 lfd ptr p64 0 0 0
          sa  = sk peek mfd ptr 16
          _   = sk free page mfd ptr 4096
          sk finish accept sfd sa

-- @implements FR-SOCK-004
-- @implements API-SOCK-001
-- @mitigates VUL-INPUT-001
fn :: sys accept Int Int        => (Int, Int, String)
      sys accept lfd timeout_ms =
        | lfd < 0 or timeout_ms < (0 - 1) = (0 - 7, 0 - 1, "")
        | (sk sock acceptconn lfd) != 1   = (0 - 7, 0 - 1, "")
        | otherwise                       = sk accept after poll lfd (sys_poll lfd 1 timeout_ms)

fn :: sk map send rc Int => (Int, Int)
      sk map send rc rc  =
        | rc >= 0                           = (0, rc)
        | rc == (0 - 32) or rc == (0 - 104) = (0 - 4, 0 - 1)
        | rc == (0 - 11)                    = (0 - 2, 0 - 1)
        | otherwise                         = (0 - 7, 0 - 1)

fn :: sk exec send Int String => (Int, Int)
      sk exec send fd  data   =
        | (str_len data) == 0 = (0, 0)
        | otherwise =
          dlen = str_len data
          psz  = ((dlen / 4096) + 2) * 4096
          ptr  = sk alloc page psz
          mfd  = sk alloc mfd
          _    = sk poke mfd ptr data
          rc   = sys_call 44 fd ptr dlen 16384 0 0
          _    = sk free page mfd ptr psz
          sk map send rc rc

-- @implements FR-SOCK-004
-- @implements API-SOCK-001
-- @mitigates VUL-INPUT-001
fn :: sys send Int String Int        => (Int, Int)
      sys send fd  data   timeout_ms =
        | fd < 0 or timeout_ms < (0 - 1) = (0 - 7, 0 - 1)
        | (sk sock acceptconn fd) != 0   = (0 - 7, 0 - 1)
        | otherwise                      = sk exec send fd data

-- @implements FR-SOCK-004
-- @implements API-SOCK-001
fn :: sys shutdown write Int => Int
      sys shutdown write fd  =
        | fd < 0                          = 0 - 7
        | (sk sock acceptconn fd) != 0    = 0 - 7
        | (sys_call 48 fd 1 0 0 0 0) == 0 = 0
        | otherwise                       = 0 - 7

fn :: sk wrap recv chunk String => (Int, String)
      sk wrap recv chunk chunk  =
        | (str_len chunk) == 0 = (0 - 1, "")
        | otherwise            = (0, chunk)

fn :: sk recv after poll Int Int Int => (Int, String)
      sk recv after poll fd max_bytes prc =
        | prc == 0  = (0 - 2, "")
        | prc < 0   = (0 - 7, "")
        | otherwise = sk wrap recv chunk (sys_read_fd fd max_bytes)

-- @implements FR-SOCK-004
-- @implements API-SOCK-001
-- @mitigates VUL-INPUT-001
fn :: sys recv Int Int       Int        => (Int, String)
      sys recv fd  max_bytes timeout_ms =
        | fd < 0 or max_bytes < 1 or timeout_ms < (0 - 1) = (0 - 7, "")
        | (sk sock acceptconn fd) != 0                    = (0 - 7, "")
        | otherwise                                       = sk recv after poll fd max_bytes (sys_poll fd 1 timeout_ms)

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
