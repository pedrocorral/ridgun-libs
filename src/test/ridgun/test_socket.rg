-- src/test/ridgun/test_socket.rg
-- Automated test suite for the socket management library
-- @tests TS-SOCK-001
-- @tests TS-SOCK-002
-- @tests TS-SOCK-003
-- @tests TS-SOCK-004
-- @tests TS-SEC-001
-- @tests TS-OBS-001

import test
import crypto
import socket

fn :: is addr ok SockAddrRes     => Bool
      is addr ok (SockAddrOk  _) =  True
      is addr ok (SockAddrErr _) =  False

fn :: unwrap addr SockAddrRes       => SockAddr
      unwrap addr (SockAddrOk addr) =  addr
      unwrap addr (SockAddrErr _)   =  empty addr

fn :: is sock ok SockRes     => Bool
      is sock ok (SockOk  _) =  True
      is sock ok (SockErr _) =  False

fn :: unwrap sock SockRes     => Socket
      unwrap sock (SockOk  s) =  s
      unwrap sock (SockErr _) =  sock tcp

fn :: unwrap pair left SockPairRes     => Socket
      unwrap pair left (SockPairOk left _) = left
      unwrap pair left (SockPairErr _) =  sock tcp

fn :: unwrap pair right SockPairRes     => Socket
      unwrap pair right (SockPairOk _ right) = right
      unwrap pair right (SockPairErr _) =  sock tcp

fn :: is recv bytes ok SockRecvBytesRes   => Bool
      is recv bytes ok (SockBytesOk  _ _) =  True
      is recv bytes ok (SockBytesErr _)   =  False

fn :: unwrap recv bytes SockRecvBytesRes => [Int]
      unwrap recv bytes (SockBytesOk _ payload) = payload
      unwrap recv bytes (SockBytesErr _) =  []

fn :: unwrap recv bytes sock SockRecvBytesRes  => Socket
      unwrap recv bytes sock (SockBytesOk s _) =  s
      unwrap recv bytes sock (SockBytesErr _)  =  sock tcp

fn :: is recv str ok SockRecvStrRes   => Bool
      is recv str ok (SockStrOk  _ _) =  True
      is recv str ok (SockStrErr _)   =  False

fn :: unwrap recv str SockRecvStrRes     => String
      unwrap recv str (SockStrOk _ text) =  text
      unwrap recv str (SockStrErr _)     =  ""

fn :: unwrap recv str sock SockRecvStrRes  => Socket
      unwrap recv str sock (SockStrOk s _) =  s
      unwrap recv str sock (SockStrErr _)  =  sock tcp

fn :: unwrap dgram payload SockRecvFromRes => [Int]
      unwrap dgram payload (SockFromOk _ bytes _) = bytes
      unwrap dgram payload (SockFromErr _) =  []

fn :: unwrap dgram sender SockRecvFromRes => SockAddr
      unwrap dgram sender (SockFromOk _ _ sender) = sender
      unwrap dgram sender (SockFromErr _) =  empty addr

-- @tests TS-SOCK-001
fn :: test_sock_address_and_lifecycle => ()
      test_sock_address_and_lifecycle =
        r_v4       = sock parse addr "127.0.0.1:8080"
        r_v6       = sock parse addr "[::1]:9090"
        r_ux       = sock parse addr "/tmp/ridgun_test.sock"
        b_ip       = sock parse addr "999.0.0.1:8080"
        b_prt      = sock addr ipv4 "127.0.0.1" 70000
        b_ux1      = sock parse addr "../unsafe.sock"
        b_ux2      = sock parse addr "/tmp/bad;rm.sock"
        _          = assert ok (is addr ok r_v4)
        _          = assert ok (is addr ok r_v6)
        _          = assert ok (is addr ok r_ux)
        _          = assert eq (is addr ok b_ip) False
        _          = assert eq (is addr ok b_prt) False
        _          = assert eq (is addr ok b_ux1) False
        _          = assert eq (is addr ok b_ux2) False
        a_v4       = unwrap addr r_v4
        _          = assert eq (host a_v4) "127.0.0.1"
        _          = assert eq (port a_v4) 8080
        s0         = sock tcp
        s_to       = sock set timeout s0 2500
        s_neg      = sock set timeout s0 (-5)
        _          = assert ok (is sock ok s_to)
        _          = assert eq (is sock ok s_neg) False
        s1         = unwrap sock s_to
        _          = assert eq (timeout_ms (opts s1)) 2500
        srv0       = unwrap sock (sock bind s1 a_v4)
        srv1       = unwrap sock (sock listen srv0 16)
        _          = assert ok (is_listening srv1)
        cli0       = unwrap sock (sock bind (sock tcp) (unwrap addr (sock parse addr "127.0.0.1:50000")))
        pair       = sock connect pair cli0 srv1
        cli1       = unwrap pair left pair
        peer1      = unwrap pair right pair
        _          = assert ok (is_connected cli1)
        _          = assert ok (is_connected peer1)
        closed_cli = unwrap sock (sock close cli1)
        _          = assert eq (is_open closed_cli) False
        _          = assert eq (is sock ok (sock close closed_cli)) False
        -- Additional family, option, and lifecycle negative edge cases
        _          = assert ok (is addr ok (sock parse addr "unix:/tmp/ridgun_prefixed.sock"))
        _          = assert ok (is addr ok (sock addr ipv6 "::1" 8443))
        _          = assert eq (is addr ok (sock addr ipv6 "invalid_v6" 8443)) False
        _          = assert eq (is addr ok (sock parse addr "/tmp/bad|pipe.sock")) False
        _          = assert eq (is addr ok (sock parse addr "/tmp/bad$dollar.sock")) False
        _          = assert eq (is addr ok (sock parse addr "/tmp/bad space.sock")) False
        _          = assert eq (family (sock tcp6)) "inet6"
        _          = assert eq (family (sock udp6)) "inet6"
        _          = assert eq (family (sock unix stream)) "unix"
        _          = assert eq (sock_type (sock unix dgram)) "dgram"
        good_opts  = SockOpts True True True True False 1000 32768 32768
        bad_opts1  = SockOpts True False False False False (0 - 1) 32768 32768
        bad_opts2  = SockOpts True False False False False 1000 0 32768
        _          = assert ok (is sock ok (sock set options (sock tcp) good_opts))
        _          = assert eq (is sock ok (sock set options (sock tcp) bad_opts1)) False
        _          = assert eq (is sock ok (sock set options (sock tcp) bad_opts2)) False
        _          = assert eq (is sock ok (sock bind (sock tcp) (unwrap addr r_v6))) False
        _          = assert eq (is sock ok (sock listen (sock tcp) 8)) False
        _          = assert eq (is sock ok (sock listen srv0 0)) False
        _          = assert eq (is sock ok (sock listen (sock udp) 8)) False
        _          = assert eq (is sock ok (sock accept srv0)) False
        assert eq (is sock ok (sock connect (sock tcp) (unwrap addr r_ux))) False

-- @tests TS-SOCK-002
fn :: test_sock_data_transfer_and_framing => ()
      test_sock_data_transfer_and_framing =
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
        _        = assert ok (is recv str ok r_str)
        _        = assert eq (unwrap recv str r_str) "hello ridgun"
        p2       = unwrap recv str sock r_str
        c2       = unwrap sock (sock send frame (unwrap pair left pair1) [10, 20, 30, 40])
        pair2    = sock pipe transfer c2 p2
        p3       = unwrap pair right pair2
        r_frm_sm = sock recv frame p3 2
        _        = assert eq (is recv bytes ok r_frm_sm) False
        r_frm_ok = sock recv frame p3 16
        _        = assert ok (is recv bytes ok r_frm_ok)
        _        = assert eq (unwrap recv bytes r_frm_ok) [10, 20, 30, 40]
        p4       = unwrap recv bytes sock r_frm_ok
        c3       = unwrap sock (sock send line (unwrap pair left pair2) "PING 1")
        pair3    = sock pipe transfer c3 p4
        p5       = unwrap pair right pair3
        r_line   = sock recv line p5 32
        _        = assert ok (is recv str ok r_line)
        _        = assert eq (unwrap recv str r_line) "PING 1"
        p6       = unwrap recv str sock r_line
        u_sender = unwrap sock (sock bind (sock udp) cli_addr)
        u_rcvr   = unwrap sock (sock bind (sock udp) srv_addr)
        u_sent   = unwrap sock (sock send to u_sender [1, 2, 3] srv_addr)
        d_pair   = sock deliver dgram u_sent u_rcvr
        u_rcvr2  = unwrap pair right d_pair
        d_res    = sock recv from u_rcvr2 16
        _        = assert eq (unwrap dgram payload d_res) [1, 2, 3]
        _        = assert eq (port (unwrap dgram sender d_res)) 50001
        -- Additional framing, line, byte-range, and datagram negative edge cases
        _        = assert eq (is sock ok (sock send bytes c0 [0, 256])) False
        _        = assert eq (is sock ok (sock send bytes c0 [0 - 1])) False
        c_short  = unwrap sock (sock send bytes (unwrap pair left pair3) [0, 1])
        p_short  = unwrap pair right (sock pipe transfer c_short p6)
        _        = assert eq (is recv bytes ok (sock recv frame p_short 16)) False
        _        = assert eq (is recv str ok (sock recv line p_short 16)) False
        c_longl  = unwrap sock (sock send line (unwrap pair left pair3) "LINE_TOO_LONG_FOR_LIMIT")
        p_longl  = unwrap pair right (sock pipe transfer c_longl (unwrap recv bytes sock (sock recv bytes p_short 2)))
        _        = assert eq (is recv str ok (sock recv line p_longl 4)) False
        assert eq (is sock ok (sock send to c0 [1, 2] srv_addr)) False

-- @tests TS-SOCK-003
fn :: test_sock_advanced_ops_dns_cidr_and_polling => ()
      test_sock_advanced_ops_dns_cidr_and_polling =
        srv_addr  = unwrap addr (sock resolve host "localhost" 8082)
        cli_addr  = unwrap addr (sock resolve host "api.example.com" 50002)
        bad_host  = sock resolve host "-bad..host" 8082
        _         = assert eq (host srv_addr) "127.0.0.1"
        _         = assert eq (port srv_addr) 8082
        _         = assert eq (is addr ok bad_host) False
        _         = assert ok (ip in cidr "192.168.1.42" "192.168.1.0/24")
        _         = assert eq (ip in cidr "192.168.2.42" "192.168.1.0/24") False
        _         = assert ok (ip in cidr "10.20.30.40" "10.0.0.0/8")
        _         = assert eq (ip in cidr "10.20.30.40" "10.0.0.0/99") False
        s_nd      = sock set tcp nodelay (sock tcp) True
        s_bc      = sock set broadcast (sock udp) True
        s_buf_ok  = sock set buf sizes (sock tcp) 131072 131072
        s_buf_bad = sock set buf sizes (sock tcp) 0 1024
        _         = assert ok (is sock ok s_nd)
        _         = assert ok (is sock ok s_bc)
        _         = assert ok (is sock ok s_buf_ok)
        _         = assert eq (is sock ok s_buf_bad) False
        _         = assert ok (tcp_nodelay (opts (unwrap sock s_nd)))
        _         = assert ok (broadcast (opts (unwrap sock s_bc)))
        _         = assert eq (rcvbuf (opts (unwrap sock s_buf_ok))) 131072
        srv       = unwrap sock (sock listen (unwrap sock (sock bind (sock tcp) srv_addr)) 8)
        cli       = unwrap sock (sock bind (sock tcp) cli_addr)
        pair0     = sock connect pair cli srv
        c0        = unwrap pair left pair0
        p0        = unwrap pair right pair0
        _         = assert eq (port (unwrap addr (sock local addr c0))) 50002
        _         = assert eq (port (unwrap addr (sock peer addr c0))) 8082
        poll0     = sock poll p0
        _         = assert eq (readable poll0) False
        _         = assert ok (writable poll0)
        c1        = unwrap sock (sock send all c0 [5, 6, 7, 8, 9])
        pair1     = sock pipe transfer c1 p0
        p1        = unwrap pair right pair1
        poll1     = sock poll p1
        _         = assert ok (readable poll1)
        ex_fail   = sock recv exact p1 10
        _         = assert eq (is recv bytes ok ex_fail) False
        ex_ok     = sock recv exact p1 5
        _         = assert ok (is recv bytes ok ex_ok)
        _         = assert eq (unwrap recv bytes ex_ok) [5, 6, 7, 8, 9]
        c_shut_wr = unwrap sock (sock shutdown (unwrap pair left pair1) "wr")
        _         = assert eq (is sock ok (sock send bytes c_shut_wr [1])) False
        p_shut_rd = unwrap sock (sock shutdown p1 "rd")
        _         = assert eq (is recv bytes ok (sock recv bytes p_shut_rd 4)) False
        c_shut_all = unwrap sock (sock shutdown p1 "rdwr")
        _         = assert eq (can_read c_shut_all) False
        _         = assert eq (can_write c_shut_all) False
        _         = assert eq (is sock ok (sock shutdown p1 "bad_mode")) False
        _         = assert ok (is addr ok (sock resolve host "ip6-localhost" 9090))
        _         = assert ok (ip in cidr "203.0.113.5" "0.0.0.0/0")
        _         = assert ok (ip in cidr "192.168.1.1" "192.168.1.1/32")
        _         = assert eq (ip in cidr "192.168.1.2" "192.168.1.1/32") False
        _         = assert eq ( is addr ok (sock local addr (sock tcp))) False
        assert eq (is addr ok (sock peer addr (sock tcp))) False

fn :: tup2 fst (Int, Int) => Int
      tup2 fst (a, _)     =  a

fn :: tup2 snd (Int, Int) => Int
      tup2 snd (_, b)     =  b

fn :: tup2 str (Int, String) => String
      tup2 str (_, s)        =  s

fn :: tup2 rc (Int, String) => Int
      tup2 rc (rc, _)       =  rc

fn :: tup3 rc (Int, Int, String) => Int
      tup3 rc (rc, _, _)         =  rc

fn :: tup3 fd (Int, Int, String) => Int
      tup3 fd (_, fd, _)         =  fd

-- @tests TS-SOCK-004
-- @tests TS-SEC-001
-- @tests TS-OBS-001
fn :: test_sock_rgf001_kernel_tcp_and_unix => ()
      test_sock_rgf001_kernel_tcp_and_unix =
        -- 1. Ephemeral TCP listen + sys_local_port + ADDR_IN_USE + invalid/permission checks
        _      = assert_int_equals (tup2 fst (sys tcp listen "bad_host" 8080 16)) (0 - 7) "invalid host -> -7"
        _      = assert_int_equals (tup2 fst (sys tcp listen "127.0.0.1" 70000 16)) (0 - 7) "invalid port -> -7"
        _      = assert_int_equals (tup2 fst (sys tcp listen "127.0.0.1" 8080 0)) (0 - 7) "invalid backlog -> -7"
        _      = assert_int_equals (tup2 fst (sys tcp listen "127.0.0.1" 80 16)) (0 - 6) "privileged port 80 -> -6"
        l_res  = sys tcp listen "127.0.0.1" 0 16
        _      = assert_int_equals (tup2 fst l_res) 0 "sys_tcp_listen status"
        lfd    = tup2 snd l_res
        _      = assert_true (lfd >= 0) "lfd >= 0"
        lport  = sys local port lfd
        _      = assert_true (lport > 0) "ephemeral port > 0"
        dup_l  = sys tcp listen "127.0.0.1" lport 8
        _      = assert_int_equals (tup2 fst dup_l) (0 - 5) "dup sys_tcp_listen -> -5"

        -- 2. Accept timeout (-2) when no client pending + connect refused (-3) on unbound port
        acc_to = sys accept lfd 30
        _      = assert_int_equals (tup3 rc acc_to) (0 - 2) "sys_accept timeout -> -2"
        ref_c  = sys tcp connect "127.0.0.1" 39999 100
        _      = assert_int_equals (tup2 fst ref_c) (0 - 3) "sys_tcp_connect refused -> -3"

        -- 3. TCP multi-client queue, bidirectional I/O, chunked recv, recv timeout (-2), shutdown_write, send after shutdown (-4), EOF (-1)
        c_res  = sys tcp connect "127.0.0.1" lport 500
        c_res2 = sys tcp connect "127.0.0.1" lport 500
        _      = assert_int_equals (tup2 fst c_res) 0 "sys_tcp_connect 1 ok"
        _      = assert_int_equals (tup2 fst c_res2) 0 "sys_tcp_connect 2 ok"
        cfd    = tup2 snd c_res
        cfd2   = tup2 snd c_res2
        a_res  = sys accept lfd 500
        a_res2 = sys accept lfd 500
        _      = assert_int_equals (tup3 rc a_res) 0 "sys_accept 1 ok"
        _      = assert_int_equals (tup3 rc a_res2) 0 "sys_accept 2 ok"
        sfd    = tup3 fd a_res
        sfd2   = tup3 fd a_res2

        -- Empty recv with timeout=20 returns (-2, "")
        rcv_to = sys recv sfd 16 20
        _      = assert_int_equals (tup2 rc rcv_to) (0 - 2) "sys_recv timeout on idle stream -> -2"

        -- Chunked recv: send 10 bytes, read 4 + 4 + 2 bytes, plus reverse direction sfd -> cfd
        snd1   = sys send cfd "0123456789" 500
        _      = assert_int_equals (tup2 fst snd1) 0 "sys_send status"
        _      = assert_int_equals (tup2 snd snd1) 10 "sys_send len 10"
        ch1    = sys recv sfd 4 500
        ch2    = sys recv sfd 4 500
        ch3    = sys recv sfd 4 500
        _      = assert_str_eq (tup2 str ch1) "0123" "chunk 1 (4B)"
        _      = assert_str_eq (tup2 str ch2) "4567" "chunk 2 (4B)"
        _      = assert_str_eq (tup2 str ch3) "89" "chunk 3 (2B)"
        _      = assert_int_equals (tup2 fst (sys send sfd "pong" 500)) 0 "server->client send ok"
        _      = assert_str_eq (tup2 str (sys recv cfd 16 500)) "pong" "client recv pong"

        -- Raw binary bytes (0, 1, 127, 128, 254, 255) + AEAD ciphertext over TCP sys_send/sys_recv
        raw_bin = bytes from list [0, 1, 127, 128, 254, 255]
        _       = assert_int_equals (str_len raw_bin) 6 "raw_bin len == 6"
        _       = assert_int_equals (tup2 fst (sys send cfd2 raw_bin 500)) 0 "sys_send raw binary ok"
        r_bin   = tup2 str (sys recv sfd2 16 500)
        _       = assert_int_equals (str_len r_bin) 6 "raw binary recv len == 6"
        _       = assert_int_equals (str_char_at r_bin 0) 0 "raw binary byte[0] == 0"
        _       = assert_int_equals (str_char_at r_bin 1) 1 "raw binary byte[1] == 1"
        _       = assert_int_equals (str_char_at r_bin 3) 128 "raw binary byte[3] == 128"
        _       = assert_int_equals (str_char_at r_bin 5) 255 "raw binary byte[5] == 255"
        k32     = sha256 bytes "socket-session-key"
        n12     = "0123456789ab"
        ct_wire = aead seal k32 n12 "tcp-aad" "confidential-payload-over-tcp"
        _       = assert_int_equals (tup2 fst (sys send cfd2 ct_wire 500)) 0 "sys_send AEAD ciphertext ok"
        rx_wire = tup2 str (sys recv sfd2 128 500)
        opened  = aead open k32 n12 "tcp-aad" rx_wire
        _       = assert_int_equals (tup2 rc opened) 0 "aead_open over TCP socket ok"
        _       = assert_str_eq (tup2 str opened) "confidential-payload-over-tcp" "decrypted TCP payload matches"

        -- Shutdown write -> subsequent send returns (-4, -1) RESET, peer recv returns (-1, "") EOF
        _      = assert_int_equals (sys shutdown write cfd) 0 "sys_shutdown_write"
        _      = assert_int_equals (tup2 fst (sys send cfd "after-shut" 100)) (0 - 4) "send after shutdown_write -> -4"
        rcv_ef = sys recv sfd 64 500
        _      = assert_int_equals (tup2 rc rcv_ef) (0 - 1) "sys_recv EOF -> -1"
        _      = assert_int_equals (sys_close cfd) 0 "sys_close cfd"
        _      = assert_int_equals (sys_close sfd) 0 "sys_close sfd"
        _      = assert_int_equals (sys_close cfd2) 0 "sys_close cfd2"
        _      = assert_int_equals (sys_close sfd2) 0 "sys_close sfd2"
        _      = assert_int_equals (sys_close lfd) 0 "sys_close lfd"

        -- Operations on closed fd return -7 (INVALID)
        _      = assert_int_equals (sys local port lfd) (0 - 7) "sys_local_port on closed lfd -> -7"
        _      = assert_int_equals (tup3 rc (sys accept lfd 10)) (0 - 7) "sys_accept on closed lfd -> -7"
        _      = assert_int_equals (tup2 fst (sys send cfd "x" 10)) (0 - 7) "sys_send on closed cfd -> -7"
        _      = assert_int_equals (tup2 rc (sys recv sfd 16 10)) (0 - 7) "sys_recv on closed sfd -> -7"

        -- 4. AF_UNIX listen + connect + send + recv + path traversal (-7) + missing listener (-3)
        u_bad  = sys unix listen "../traversal.sock" 8
        _      = assert_int_equals (tup2 fst u_bad) (0 - 7) "sys_unix_listen traversal -> -7"
        _      = assert_int_equals (tup2 fst (sys unix connect "/tmp/rg_nonexistent_99999.sock" 50)) (0 - 3) "sys_unix_connect missing -> -3"
        upath  = "/tmp/rg_sock_rgf001_{sys_getpid}.sock"
        ul_res = sys unix listen upath 8
        _      = assert_int_equals (tup2 fst ul_res) 0 "sys_unix_listen ok"
        ulfd   = tup2 snd ul_res
        uc_res = sys unix connect upath 500
        _      = assert_int_equals (tup2 fst uc_res) 0 "sys_unix_connect ok"
        ucfd   = tup2 snd uc_res
        ua_res = sys accept ulfd 500
        _      = assert_int_equals (tup3 rc ua_res) 0 "sys_accept unix ok"
        usfd   = tup3 fd ua_res
        _      = assert_int_equals (tup2 fst (sys send ucfd "unix-msg" 500)) 0 "sys_send unix ok"
        urcv   = sys recv usfd 64 500
        _      = assert_int_equals (tup2 rc urcv) 0 "sys_recv unix ok"
        _      = assert_str_eq (tup2 str urcv) "unix-msg" "AF_UNIX sys_recv"
        _      = assert_int_equals (sys_close ucfd) 0 "sys_close ucfd"
        _      = assert_int_equals (sys_close usfd) 0 "sys_close usfd"
        _      = assert_int_equals (sys_close ulfd) 0 "sys_close ulfd"
        _      = assert_int_equals (shell_exec "rm -f '{upath}'") 0 "unlink AF_UNIX socket"
        ()

fn :: main => ()
      main =
        _ = test_sock_address_and_lifecycle
        _ = test_sock_data_transfer_and_framing
        _ = test_sock_advanced_ops_dns_cidr_and_polling
        _ = test_sock_rgf001_kernel_tcp_and_unix
        echo "=== All socket tests passed ==="
