-- ============================================================
-- src/test/ridgun/test mail.rg
-- Test suite for mail.rg (TS-MAIL-001)
-- The SMTP peer is a Ridgun test server: this same binary re-launched with
-- `--smtp-server <port> <mode> <dir>`. It speaks SMTP and upgrades to TLS 1.3
-- (X25519, AES-128-GCM, Ed25519 certificate) with a minimal server built from
-- tls.rg's verified key schedule and record layer.
-- Live cases need network access; set RIDGUN_TLS_LIVE=0 to skip them.
-- @tests TS-MAIL-001
-- ============================================================

import test
import posix
import crypto
import socket
import tls
import mail

-- ============================================================
-- Generic helpers
-- ============================================================

fn :: find from String String Int => Int
      find from s      sub    idx =
        | (idx + (str len sub)) > (str len s)                  = 0 - 1
        | (str slice s idx (idx + (str len sub))) == sub       = idx
        | otherwise                                            = find from s sub (idx + 1)

fn :: index of String String => Int
      index of s      sub    =  find from s sub 0

fn :: nth arg [String] Int => String
      nth arg []       _ =  ""
      nth arg (a:rest) i =
        | i <= 0    = a
        | otherwise = nth arg rest (i - 1)

fn :: test dir => String
      test dir =  "/tmp/ridgun-mail-test-" + (int to str (sys getpid))

fn :: base port => Int
      base port =  40000 + ((sys getpid) % 20000)

fn :: wait for String String Int => Bool
      wait for path   needle tries =
        | tries <= 0                           = False
        | str contains (read file path) needle = True
        | otherwise                            =
          sys sleep ms 100
          wait for path needle (tries - 1)

-- Longest line (bytes between CRLFs) and whether every LF is preceded by CR.
fn :: max line String Int Int Int => Int
      max line s      idx start best =
        | idx >= (str len s)          = best
        | (str char at s idx) == 10   =
          len = idx - start
          nb  =
            | len > best = len
            | otherwise  = best
          max line s (idx + 1) (idx + 1) nb
        | otherwise = max line s (idx + 1) start best

fn :: bare lf String Int => Bool
      bare lf s      idx =
        | idx >= (str len s)                                                  = False
        | (str char at s idx) == 10 and (idx == 0 or (str char at s (idx - 1)) != 13) = True
        | otherwise                                                           = bare lf s (idx + 1)

-- ============================================================
-- Ridgun TLS 1.3 test server (test-only; X25519 + AES-128-GCM + Ed25519)
-- ============================================================

fn :: srv find share String Int Int => String
      srv find share d      pos end =
        | (pos + 4) > end           = ""
        | (tls u16 d pos) == 29     = tls sub d (pos + 4) (tls u16 d (pos + 2))
        | otherwise                 = srv find share d (pos + 4 + (tls u16 d (pos + 2))) end

fn :: srv on record Int Int String Int Int String => String
      srv on record fd  timeout acc    rc  ctype payload =
        | rc != 0 or ctype != 22 = ""
        | otherwise              = srv read hello fd timeout (acc + payload)

fn :: srv read hello Int Int String => String
      srv read hello fd  timeout acc    =
        | (hs msg len acc) > 0 and (str len acc) >= (hs msg len acc) = str slice acc 0 (hs msg len acc)
        | otherwise                                                  =
          rc, ctype, payload = tls read record fd timeout
          srv on record fd timeout acc rc ctype payload

fn :: srv on client record Int Int String String Int Int String => String
      srv on client record fd  timeout key    iv     rc  ctype payload =
        | rc != 0     = ""
        | ctype == 20 = srv read client fin fd timeout key iv
        | otherwise   =
          rc2, itype, content = tls13 open record 4865 key iv 0 payload
          res                 =
            | rc2 == 0 and itype == 22 = content
            | otherwise                = ""
          res

fn :: srv read client fin Int Int String String => String
      srv read client fin fd  timeout key    iv     =
        rc, ctype, payload = tls read record fd timeout
        srv on client record fd timeout key iv rc ctype payload

fn :: srv conn Int String String String String => TlsConn
      srv conn fd  wkey   wiv    rkey   riv    =
        stt = Tensor[U64 * 16]
        buf = Tensor[U64 * 65536]
        stt_(0) = 0
        stt_(1) = 0
        stt_(2) = 0
        stt_(3) = 0
        stt_(4) = 0
        TlsConn fd "server" 772 4865 "" wkey wiv rkey riv 10000 stt buf

fn :: srv tls accept Int String String => TlsResult
      srv tls accept fd  der    seed   =
        ch = srv read hello fd 10000 ""
        srv tls on hello fd der seed ch

fn :: srv tls on hello Int String String String => TlsResult
      srv tls on hello fd  der    seed   ch     =
        | (str len ch) < 43 or (tls u8 ch 0) != 1 = TlsErr (TlsIoError "no ClientHello")
        | otherwise =
          sid_len = tls u8 ch 38
          sid     = tls sub ch 39 sid_len
          pos     = 39 + sid_len
          pos2    = pos + 2 + (tls u16 ch pos)
          pos3    = pos2 + 1 + (tls u8 ch pos2)
          exts    = tls sub ch (pos3 + 2) (tls u16 ch pos3)
          found, off, len = tls find ext exts 0 51
          cpub    = srv find share exts (off + 2) (off + len)
          srv tls respond fd der seed ch sid cpub

fn :: srv tls respond Int String String String String String => TlsResult
      srv tls respond fd  der    seed   ch     sid    cpub   =
        | (str len cpub) != 32 = TlsErr (TlsIoError "no X25519 key share")
        | otherwise =
          spriv  = tls random "srv-x" 32
          srand  = tls random "srv-r" 32
          sh     = tls hs msg 2 ((tls be2 771) + srand + (tls vec1 sid) + (tls be2 4865) + (byte str 0) + (tls vec2 ((tls ext (tls be2 43) (tls be2 772)) + (tls ext (tls be2 51) ((tls be2 29) + (tls vec2 (x25519 public key spriv)))))))
          hsec   = tls13 hs secret (x25519 spriv cpub)
          tr1    = ch + sh
          c_hs   = derive secret hsec "c hs traffic" tr1
          s_hs   = derive secret hsec "s hs traffic" tr1
          ee     = tls hs msg 8 (tls vec2 "")
          cert   = tls hs msg 11 ((byte str 0) + (tls vec3 ((tls vec3 der) + (tls be2 0))))
          tr2    = tr1 + ee + cert
          cv     = tls hs msg 15 ((tls be2 2055) + (tls vec2 (ed25519 sign seed (tls13 cv content tr2))))
          tr3    = tr2 + cv
          fin    = tls hs msg 20 (tls13 finished mac s_hs tr3)
          tr4    = tr3 + fin
          flight = (tls plain record 22 771 sh) + (tls13 seal record 4865 (tls13 key s_hs 16) (tls13 iv s_hs) 0 22 (ee + cert + cv + fin))
          tls send all fd flight 10000 -> ()
          cfin   = srv read client fin fd 10000 (tls13 key c_hs 16) (tls13 iv c_hs)
          master = tls13 master secret hsec
          c_ap   = derive secret master "c ap traffic" tr4
          s_ap   = derive secret master "s ap traffic" tr4
          res    =
            | ct equal (tls rest cfin 4) (tls13 finished mac c_hs tr4) = TlsOk (srv conn fd (tls13 key s_ap 16) (tls13 iv s_ap) (tls13 key c_ap 16) (tls13 iv c_ap))
            | otherwise                                                = TlsErr (TlsIoError "client Finished invalid")
          res

-- ============================================================
-- Ridgun SMTP test server
-- Modes: starttls | nostarttls | implicit | badauth | tempfail
-- ============================================================

type SrvCtx = sv_mode: String, sv_log: String, sv_der: String, sv_seed: String

fn :: srv log SrvCtx String => ()
      srv log ctx    line   =  append file (sv_log ctx) (line + "\n")

fn :: srv say SmtpIo String => ()
      srv say io     text   =  m io send io text -> ()

fn :: srv on chunk SmtpIo String String Int String => Bool String String
      srv on chunk io     buf    delim  tries chunk  =
        | chunk == "" = (False, "", "")
        | otherwise   = srv read until io (buf + chunk) delim (tries - 1)

-- Read until `delim`: (ok, text before delim, rest after it).
fn :: srv read until SmtpIo String String Int => Bool String String
      srv read until io     buf    delim  tries =
        | (index of buf delim) >= 0 = (True, str slice buf 0 (index of buf delim), tls rest buf ((index of buf delim) + (str len delim)))
        | tries <= 0                = (False, "", "")
        | otherwise                 = srv on chunk io buf delim tries (m io recv io)

fn :: srv ehlo SmtpIo SrvCtx => String
      srv ehlo io     ctx    =
        | (io_tls io) or (sv_mode ctx) == "nostarttls" = "250-localhost\r\n250-AUTH PLAIN LOGIN\r\n250 8BITMIME\r\n"
        | otherwise                                    = "250-localhost\r\n250-STARTTLS\r\n250 8BITMIME\r\n"

fn :: srv creds ok String => Bool
      srv creds ok plain  =  plain == ((byte str 0) + "alice" + (byte str 0) + "s3cret")

fn :: srv b64 String => String
      srv b64 s      =
        ok, raw = c b64 decode s
        raw

fn :: srv auth reply SrvCtx Bool => String
      srv auth reply ctx    ok   =
        | (sv_mode ctx) == "badauth" or not ok = "535 5.7.8 Authentication credentials invalid\r\n"
        | otherwise                            = "235 2.7.0 Authentication successful\r\n"

fn :: srv loop SmtpIo SrvCtx String String => ()
      srv loop io     ctx    buf    stage  =
        ok, line, rest = srv read until io buf "\r\n" 200
        srv step io ctx rest stage ok line

fn :: srv step SmtpIo SrvCtx String String Bool String => ()
      srv step io     ctx    rest   stage  ok   line   =
        | not ok = ()
        | otherwise =
          srv log ctx ("C: " + line)
          srv handle io ctx rest stage line (m to upper line)

-- Reply with `text`, then keep reading commands in `stage`.
fn :: srv respond SmtpIo SrvCtx String String String => ()
      srv respond io     ctx    rest   text   stage  =
        srv say io text
        srv loop io ctx rest stage

fn :: srv starttls SmtpIo SrvCtx => ()
      srv starttls io     ctx    =
        srv say io "220 2.0.0 Ready to start TLS\r\n"
        srv after starttls io ctx (srv tls accept (io_fd io) (sv_der ctx) (sv_seed ctx))

fn :: srv begin data SmtpIo SrvCtx String => ()
      srv begin data io     ctx    rest   =
        srv say io "354 End data with <CR><LF>.<CR><LF>\r\n"
        srv data io ctx rest

fn :: srv login pass String String => Bool
      srv login pass stage  line   =  srv creds ok ((byte str 0) + (tls rest stage 11) + (byte str 0) + (srv b64 line))

fn :: srv handle SmtpIo SrvCtx String String String String => ()
      srv handle io     ctx    rest   stage  line   up     =
        | stage == "login-user"                                              = srv respond io ctx rest "334 UGFzc3dvcmQ6\r\n" ("login-pass:" + (srv b64 line))
        | (str starts with stage "login-pass:")                              = srv respond io ctx rest (srv auth reply ctx (srv login pass stage line)) ""
        | (str starts with up "EHLO")                                        = srv respond io ctx rest (srv ehlo io ctx) ""
        | up == "STARTTLS"                                                   = srv starttls io ctx
        | (str starts with up "AUTH PLAIN ")                                 = srv respond io ctx rest (srv auth reply ctx (srv creds ok (srv b64 (tls rest line 11)))) ""
        | up == "AUTH LOGIN"                                                 = srv respond io ctx rest "334 VXNlcm5hbWU6\r\n" "login-user"
        | (str starts with up "MAIL FROM:") and (sv_mode ctx) == "tempfail"  = srv respond io ctx rest "451 4.3.0 Mail server temporarily unavailable\r\n" ""
        | (str starts with up "MAIL FROM:")                                  = srv respond io ctx rest "250 2.1.0 Sender OK\r\n" ""
        | (str starts with up "RCPT TO:") and (str contains up "REJECT")     = srv respond io ctx rest "550 5.1.1 Mailbox does not exist\r\n" ""
        | (str starts with up "RCPT TO:")                                    = srv respond io ctx rest "250 2.1.5 Recipient OK\r\n" ""
        | up == "DATA"                                                       = srv begin data io ctx rest
        | up == "QUIT"                                                       = srv say io "221 2.0.0 Bye\r\n"
        | otherwise                                                          = srv respond io ctx rest "502 5.5.2 Command not recognized\r\n" ""

fn :: srv data SmtpIo SrvCtx String => ()
      srv data io     ctx    rest   =
        ok, body, after = srv read until io rest "\r\n.\r\n" 2000
        srv log ctx ("DATA-BEGIN\n" + body + "\nDATA-END")
        srv say io "250 2.0.0 Queued as RIDGUN1\r\n"
        srv loop io ctx after ""

fn :: srv after starttls SmtpIo SrvCtx TlsResult => ()
      srv after starttls io     ctx    res       =
        | tls is ok res =
          srv log ctx "TLS: established"
          srv loop (io with io_tls = True, io_conn = tls unwrap res) ctx "" ""
        | otherwise     = srv log ctx ("TLS: failed " + (tls error reason res))

fn :: srv start session SmtpIo SrvCtx => ()
      srv start session io     ctx    =
        | (sv_mode ctx) == "implicit" = srv implicit io ctx (srv tls accept (io_fd io) (sv_der ctx) (sv_seed ctx))
        | otherwise                   =
          srv say io "220 localhost Ridgun test ESMTP\r\n"
          srv loop io ctx "" ""

fn :: srv implicit SmtpIo SrvCtx TlsResult => ()
      srv implicit io     ctx    res       =
        | tls is ok res =
          tio = io with io_tls = True, io_conn = tls unwrap res
          srv log ctx "TLS: established"
          srv say tio "220 localhost Ridgun test ESMTP\r\n"
          srv loop tio ctx "" ""
        | otherwise     = srv log ctx ("TLS: failed " + (tls error reason res))

fn :: srv serve Int Int SrvCtx => ()
      srv serve arc cfd ctx    =
        | arc != 0 = srv log ctx "accept failed"
        | otherwise =
          srv start session (SmtpIo cfd False (tls unwrap (TlsErr (TlsIoError ""))) 10000) ctx
          sys close cfd -> ()

fn :: srv main [String] => ()
      srv main args    =
        port     = str to int (nth arg args 2)
        dir      = nth arg args 4
        ctx      = SrvCtx (nth arg args 3) (dir + "/smtp-" + (nth arg args 2) + ".log") (c nth str (pem decode blocks (read file (dir + "/ed.pem")) "CERTIFICATE") 0) (hex to byte str (read file (dir + "/ed.seed.hex")))
        lrc, lfd = sys tcp listen "127.0.0.1" port 8
        srv log ctx "READY"
        arc, cfd, _ = sys accept lfd 30000
        srv serve arc cfd ctx
        sys close lfd -> ()

-- ============================================================
-- Client-side helpers
-- ============================================================

-- `s` as one shell word: the test binary of `stable test` has spaces in its path.
fn :: sh quote String => String
      sh quote s      =
        q = char from code 39
        q + (sh quote loop s 0 "") + q

fn :: sh quote loop String Int String => String
      sh quote loop s      i   acc    =
        | i >= (str len s)           = acc
        | (str char at s i) == 39    = sh quote loop s (i + 1) (acc + (char from code 39) + (char from code 92) + (char from code 39) + (char from code 39))
        | otherwise                  = sh quote loop s (i + 1) (acc + (str slice s i (i + 1)))

fn :: start smtp String Int String => Bool
      start smtp dir    port mode   =
        exe = sys readlink "/proc/self/exe"
        shell exec ("(timeout 60 " + (sh quote exe) + " --smtp-server " + (int to str port) + " " + mode + " " + (sh quote dir) + " > /dev/null 2>&1 &)") -> ()
        wait for (dir + "/smtp-" + (int to str port) + ".log") "READY" 100

fn :: smtp log String Int => String
      smtp log dir    port =  read file (dir + "/smtp-" + (int to str port) + ".log")

fn :: client cfg String Int => SmtpConfig
      client cfg dir    port =
        roots = tls with root pem (tls defaults) (read file (dir + "/ed.pem"))
        smtp config "localhost" port "alice" "s3cret" -> smtp with tls roots -> smtp with timeout 10000

fn :: sample msg => MailMessage
      sample msg =
        mail message "Ridgun <noreply@ridgun.com>" "bob@example.org" "Verify your account" "Hello Bob,\n.hidden line\nBye"
          -> mail add to "Carol <carol@example.org>"
          -> mail with date 1735689600

fn :: run local String Int String SmtpConfig MailMessage Bool => SmtpResult
      run local dir    port mode   cfg        msg         implicit =
        assert true (start smtp dir port mode) ("SMTP test server did not start (" + mode + ")") -> ()
        res = smtp send mode cfg msg implicit
        sys sleep ms 200
        res

-- ============================================================
-- TS-MAIL-001 case 1: rendering (AC1)
-- ============================================================

-- @tests TS-MAIL-001
fn :: test render basics => ()
      test render basics =
        r = mail render ((sample msg) -> mail with message id "abc@ridgun.com" -> mail with reply to "support@ridgun.com")
        assert true (mail is ok r) ("render: " + (mail error r)) -> ()
        s = mail unwrap r
        assert true (str starts with s "From: Ridgun <noreply@ridgun.com>\r\n") "From header first" -> ()
        assert true (str contains s "\r\nTo: bob@example.org, Carol <carol@example.org>\r\n") "To header lists all recipients" -> ()
        assert true (str contains s "\r\nReply-To: support@ridgun.com\r\n") "Reply-To header" -> ()
        assert true (str contains s "\r\nSubject: Verify your account\r\n") "ASCII subject unchanged" -> ()
        assert true (str contains s "\r\nDate: Wed, 01 Jan 2025 00:00:00 +0000\r\n") "RFC 5322 date" -> ()
        assert true (str contains s "\r\nMessage-ID: <abc@ridgun.com>\r\n") "Message-ID wrapped in <>" -> ()
        assert true (str contains s "\r\nMIME-Version: 1.0\r\n") "MIME-Version" -> ()
        assert true (str contains s "\r\nContent-Type: text/plain; charset=UTF-8\r\n") "text/plain UTF-8" -> ()
        assert true (str contains s "\r\nContent-Transfer-Encoding: quoted-printable\r\n") "quoted-printable" -> ()
        assert true (str contains s "\r\n..hidden line\r\n") "dot-stuffing of body lines starting with ." -> ()
        assert false (bare lf s 0) "only CRLF line endings" -> ()
        gen = mail unwrap (mail render (sample msg))
        assert true (str contains gen "@ridgun.com>\r\n") "generated Message-ID uses the sender domain" -> ()
        assert str eq (mail format date 0) "Thu, 01 Jan 1970 00:00:00 +0000" "epoch date" -> ()

-- @tests TS-MAIL-001
fn :: test render encoding => ()
      test render encoding =
        assert str eq (mail encode rfc2047 "Plain subject") "Plain subject" "ASCII is not encoded" -> ()
        assert str eq (mail encode rfc2047 "Größe") ("=?UTF-8?B?" + (c b64 encode "Größe") + "?=") "RFC 2047 B encoding" -> ()
        long = mail encode rfc2047 "Verificá tu cuenta en Ridgun — enlace de un solo uso válido durante veinticuatro horas ✓"
        assert true (str contains long "?=\r\n =?UTF-8?B?") "long subjects fold into several encoded-words" -> ()
        assert true ((max line (long + "\n") 0 0 0) <= 76) "each encoded-word line <= 76 bytes" -> ()
        r1 = mail unwrap (mail render (mail message "José <jose@example.com>" "bob@example.org" "Hola" "x"))
        assert true (str contains r1 ("From: =?UTF-8?B?" + (c b64 encode "José") + "?= <jose@example.com>\r\n")) "non-ASCII display name" -> ()
        r2 = mail unwrap (mail render (mail message "Doe, John <j@example.org>" "bob@example.org" "Hi" "x"))
        assert true (str contains r2 "From: \"Doe, John\" <j@example.org>\r\n") "display name with specials is quoted" -> ()
        body = mail unwrap (mail render (mail message "a@example.org" "b@example.org" "QP" ("café a=b " + (c repeat byte 97 2000))))
        assert true (str contains body "caf=C3=A9 a=3Db") "quoted-printable escapes" -> ()
        assert true ((max line body 0 0 0) <= 78) "all lines <= 998 bytes (QP keeps them <= 76 + CRLF)" -> ()
        html = mail unwrap (mail render (mail with html (sample msg) "<p>Hello <b>Bob</b></p>"))
        assert true (str contains html "Content-Type: multipart/alternative; boundary=\"=_ridgun_") "multipart/alternative" -> ()
        assert true (str contains html "Content-Type: text/html; charset=UTF-8") "HTML part" -> ()
        assert true (str contains html "Content-Type: text/plain; charset=UTF-8") "text part" -> ()
        assert str eq (smtp dot stuff ".a\nb\r\n.c") "..a\r\nb\r\n..c" "smtp dot stuff" -> ()

-- @tests TS-MAIL-001
fn :: test render rejects => ()
      test render rejects =
        m0 = sample msg
        assert false (mail is ok (mail render (m0 with subject_line = "Hi\r\nBcc: evil@example.com"))) "CRLF in Subject" -> ()
        assert false (mail is ok (mail render (m0 with from_addr = "a@example.org\nBcc: x@y.org"))) "LF in From" -> ()
        assert false (mail is ok (mail render (mail add to m0 "c@example.org\r\nX: y"))) "CRLF in To" -> ()
        assert false (mail is ok (mail render (mail with reply to m0 "r@example.org\rX"))) "CR in Reply-To" -> ()
        assert false (mail is ok (mail render (mail with message id m0 "<a@b>\r\nX: y"))) "CRLF in Message-ID" -> ()
        assert str eq (mail error (mail render (m0 with subject_line = "a\nb"))) "header injection: CR or LF in Subject" "injection error text" -> ()
        assert false (mail is ok (mail render (mail with to m0 []))) "no recipients" -> ()
        assert false (mail is ok (mail render (mail message "not-an-address" "bob@example.org" "s" "b"))) "invalid From" -> ()
        assert true (mail valid address "first.last+tag@sub.example.co.uk") "valid dot-string address" -> ()
        assert true (mail valid address "user@localhost") "single-label domain" -> ()
        assert false (mail valid address "bob") "missing @" -> ()
        assert false (mail valid address "bob@") "missing domain" -> ()
        assert false (mail valid address "@example.org") "missing local part" -> ()
        assert false (mail valid address "a..b@example.org") "consecutive dots" -> ()
        assert false (mail valid address ".a@example.org") "leading dot" -> ()
        assert false (mail valid address "a b@example.org") "space in local part" -> ()
        assert false (mail valid address "a@-example.org") "label starts with hyphen" -> ()
        assert false (mail valid address "a@exa_mple.org") "underscore in domain" -> ()
        assert false (mail valid address "a@example..org") "empty label" -> ()

-- @tests TS-MAIL-001
fn :: test parse response => ()
      test parse response =
        c1, l1, r1 = smtp parse response "250-mx.example.org\r\n250-STARTTLS\r\n250 8BITMIME\r\nNEXT"
        assert eq c1 250 -> ()
        assert eq (c str list len l1 0) 3 -> ()
        assert str eq (c nth str l1 1) "STARTTLS" "multi-line reply text" -> ()
        assert str eq r1 "NEXT" "remaining input" -> ()
        c2, _, _ = smtp parse response "250-partial\r\n"
        assert eq c2 (0 - 1) -> ()
        c3, _, _ = smtp parse response "hello\r\n"
        assert eq c3 (0 - 2) -> ()
        c4, l4, _ = smtp parse response "220\r\n"
        assert eq c4 220 -> ()
        assert str eq (c nth str l4 0) "" "bare code" -> ()

-- ============================================================
-- TS-MAIL-001 case 2: SMTP against the Ridgun test server (AC2)
-- ============================================================

-- @tests TS-MAIL-001
fn :: test smtp local String => ()
      test smtp local dir    =
        p   = base port
        r1  = run local dir p "starttls" (client cfg dir p) (sample msg) False
        assert true (smtp is ok r1) ("STARTTLS + AUTH PLAIN: " + (smtp error kind r1) + " " + (smtp error reason r1)) -> ()
        log1 = smtp log dir p
        assert true ((index of log1 "C: STARTTLS") >= 0 and (index of log1 "TLS: established") > (index of log1 "C: STARTTLS")) "STARTTLS before TLS" -> ()
        assert true ((index of log1 "C: AUTH PLAIN") > (index of log1 "TLS: established")) "AUTH only after TLS" -> ()
        assert true (str contains log1 "C: MAIL FROM:<noreply@ridgun.com>") "envelope sender" -> ()
        assert true (str contains log1 "C: RCPT TO:<bob@example.org>") "first recipient" -> ()
        assert true (str contains log1 "C: RCPT TO:<carol@example.org>") "second recipient" -> ()
        assert true (str contains log1 "\r\n..hidden line\r\n") "DATA is dot-stuffed on the wire" -> ()
        assert true (str contains log1 "C: QUIT") "QUIT" -> ()

        r2  = run local dir (p + 1) "nostarttls" (client cfg dir (p + 1)) (sample msg) False
        assert str eq (smtp error kind r2) "SmtpTlsError" "no STARTTLS offered -> SmtpTlsError" -> ()
        log2 = smtp log dir (p + 1)
        assert false (str contains log2 "AUTH") "credentials never sent in cleartext" -> ()
        assert false (str contains log2 "MAIL FROM") "no cleartext transaction" -> ()

        r3  = run local dir (p + 2) "implicit" (smtp with auth (client cfg dir (p + 2)) "login") (sample msg) True
        assert true (smtp is ok r3) ("implicit TLS + AUTH LOGIN: " + (smtp error kind r3) + " " + (smtp error reason r3)) -> ()
        assert true (str contains (smtp log dir (p + 2)) "C: AUTH LOGIN") "AUTH LOGIN used" -> ()

        r4  = run local dir (p + 3) "badauth" (client cfg dir (p + 3)) (sample msg) False
        assert str eq (smtp error kind r4) "SmtpAuthError" "535 -> SmtpAuthError" -> ()
        assert true (str starts with (smtp error reason r4) "535") "auth error carries the code" -> ()
        assert false (smtp is retryable r4) "auth errors are not retryable" -> ()

        r5  = run local dir (p + 4) "starttls" (client cfg dir (p + 4)) (mail add to (sample msg) "reject-me@example.org") False
        assert str eq (smtp error kind r5) "SmtpRejectedRecipient" "550 on RCPT -> SmtpRejectedRecipient" -> ()

        r6  = run local dir (p + 5) "tempfail" (client cfg dir (p + 5)) (sample msg) False
        assert str eq (smtp error kind r6) "SmtpTemporaryError" "451 -> SmtpTemporaryError" -> ()
        assert true (smtp is retryable r6) "4xx is retryable" -> ()

        bad_roots = smtp with tls (client cfg dir (p + 6)) (tls with root pem (tls defaults) (read file (dir + "/other.pem")))
        r7  = run local dir (p + 6) "starttls" bad_roots (sample msg) False
        assert str eq (smtp error kind r7) "SmtpTlsError" "untrusted server certificate -> SmtpTlsError" -> ()
        assert false (str contains (smtp log dir (p + 6)) "AUTH") "no credentials after a failed handshake" -> ()

        r8  = smtp send (client cfg dir (p + 7)) (sample msg with subject_line = "x\r\nBcc: e@example.org")
        assert str eq (smtp error kind r8) "SmtpInvalidMessage" "invalid message is rejected before connecting" -> ()
        r9  = smtp send (client cfg dir 1) (sample msg)
        assert str eq (smtp error kind r9) "SmtpConnectionError" "refused connection -> SmtpConnectionError" -> ()
        assert true (smtp is retryable r9) "connection errors are retryable" -> ()

-- ============================================================
-- TS-MAIL-001 case 2 (live, AC3): real submission servers, no credentials sent
-- ============================================================

fn :: live smtp String Int Bool => ()
      live smtp server port implicit =
        cfg = smtp config server port "" "" -> smtp with timeout 15000
        msg = mail message "ridgun-test@example.com" "nobody@example.com" "Ridgun TLS test" "not delivered"
        res = smtp send mode cfg msg implicit
        live report server port res

fn :: live report String Int SmtpResult => ()
      live report server port res =
        | (smtp error kind res) == "SmtpConnectionError" = echo "  [SKIP] " server ":" (int to str port) " unreachable"
        | otherwise =
          echo "  [LIVE] " server ":" (int to str port) " -> " (smtp error kind res) " " (smtp error reason res)
          assert true ((smtp error kind res) == "SmtpProtocolError" and (str starts with (smtp error reason res) "530")) (server + ": expected 530 after TLS + EHLO without AUTH") -> ()

-- @tests TS-MAIL-001
fn :: test smtp live => ()
      test smtp live =
        live smtp "smtp.gmail.com" 587 False
        live smtp "smtp.gmail.com" 465 True

fn :: run live Bool => ()
      run live True  =  test smtp live
      run live False =  echo "  [SKIP] live SMTP tests (RIDGUN_TLS_LIVE=0)"

fn :: run tests => ()
      run tests =
        dir = test dir
        test render basics -> ()
        test render encoding -> ()
        test render rejects -> ()
        test parse response -> ()
        rc  = shell exec ("sh src/test/ridgun/fixtures/tls/gen-certs.sh " + dir)
        assert eq rc 0 -> ()
        test smtp local dir -> ()
        run live ((sys getenv "RIDGUN_TLS_LIVE") != "0") -> ()
        shell exec ("rm -rf " + dir) -> ()
        echo "[PASS] test_mail: TS-MAIL-001 passed"

fn :: main => ()
      main =
        args = cli args
        dispatch args ((nth arg args 1) == "--smtp-server")

fn :: dispatch [String] Bool => ()
      dispatch args True  =  srv main args
      dispatch _    False =  run tests
