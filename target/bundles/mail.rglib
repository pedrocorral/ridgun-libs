-- ============================================================
-- src/main/ridgun/lib/mail.rg
-- Pure-Ridgun RFC 5322 message builder/renderer and RFC 5321/6409/8314/3207/4954
-- SMTP submission client over TLS (implicit TLS on port 465, STARTTLS otherwise).
-- @implements FR-MAIL-001
-- @implements API-MAIL-001
-- @implements DM-Mail
-- @mitigates VUL-AUTHN-004
-- @mitigates VUL-INPUT-003
-- @mitigates VUL-INJ-003
-- ============================================================
-- `mail render` returns the message exactly as sent after DATA: CRLF line endings,
-- quoted-printable bodies (every line <= 76 bytes) and RFC 5321 §4.5.2 dot-stuffing.
-- SMTP never continues in cleartext: without implicit TLS the server must offer STARTTLS,
-- and AUTH is only sent after the TLS handshake.

module :: mail

import crypto
import socket
import posix
import time
import tls

type MailMessage = from_addr: String, to_addrs: [String], reply_to_addr: String, subject_line: String, text_body: String, html_body: String, message_id: String, date_sec: Int
type MailResult  = MailOk String | MailErr String
type SmtpConfig  = host: String, port: Int, smtp_user: String, smtp_password: String, auth_method: String, timeout_ms: Int, tls_config: TlsConfig
type SmtpError   = SmtpConnectionError String | SmtpTlsError String | SmtpAuthError Int String | SmtpRejectedRecipient Int String | SmtpTemporaryError Int String | SmtpProtocolError Int String | SmtpInvalidMessage String
type SmtpResult  = SmtpOk Int String | SmtpErr SmtpError

-- Transport (plain kernel socket or TLS) and SMTP session state.
type SmtpIo = io_fd: Int, io_tls: Bool, io_conn: TlsConn, io_timeout: Int
type SmtpSt = ss_io: SmtpIo, ss_failed: Bool, ss_error: SmtpError, ss_code: Int, ss_text: String, ss_ehlo: [String]

-- ============================================================
-- Small string helpers
-- ============================================================

fn :: m u8 String Int => Int
      m u8 s      i   =  norm byte (str char at s i)

fn :: m index of String Int Int Int => Int
      m index of s      ch  idx slen =
        | idx >= slen            = 0 - 1
        | (m u8 s idx) == ch     = idx
        | otherwise              = m index of s ch (idx + 1) slen

fn :: m last index of String Int Int => Int
      m last index of s      ch  idx =
        | idx < 0            = 0 - 1
        | (m u8 s idx) == ch = idx
        | otherwise          = m last index of s ch (idx - 1)

fn :: m has crlf String => Bool
      m has crlf s      =  (str contains s "\r") or (str contains s "\n")

fn :: m upper hex Int => String
      m upper hex b   =
        digits = "0123456789ABCDEF"
        (str slice digits (b / 16) ((b / 16) + 1)) + (str slice digits (b % 16) ((b % 16) + 1))

fn :: m pad2 Int => String
      m pad2 n   =
        | n < 10    = "0" + (int to str n)
        | otherwise = int to str n

-- Join with O(n log n) copying: merge neighbours until one string is left.
fn :: m pair join [String] [String] => [String]
      m pair join []       acc =  tls reverse acc []
      m pair join (a:rest) acc =  m pair join with a rest acc

fn :: m pair join with String [String] [String] => [String]
      m pair join with a      []       acc =  tls reverse ([a] :: acc) []
      m pair join with a      (b:rest) acc =  m pair join rest ([a + b] :: acc)

fn :: m join all [String] => String
      m join all []       =  ""
      m join all (x:rest) =  m join all with x rest

fn :: m join all with String [String] => String
      m join all with x      []    =  x
      m join all with x      (y:r) =  m join all (m pair join ([x] :: ([y] :: r)) [])

fn :: m interleave [String] String [String] => [String]
      m interleave []       _   acc =  tls reverse acc []
      m interleave (x:rest) sep acc =  m interleave with x rest sep acc

fn :: m interleave with String [String] String [String] => [String]
      m interleave with x      []    _   acc =  tls reverse ([x] :: acc) []
      m interleave with x      (y:r) sep acc =  m interleave ([y] :: r) sep ([sep] :: ([x] :: acc))

fn :: m join sep [String] String => String
      m join sep xs       sep    =  m join all (m interleave xs sep [])

-- Split on LF, dropping a trailing CR from each line (CRLF, LF and lone CR-free input).
fn :: m lines String Int Int [String] => [String]
      m lines s      idx slen acc      =
        | idx > slen = tls reverse acc []
        | otherwise  =
          e = tls next nl s idx slen
          m lines s (e + 1) slen ([tls trim cr (str slice s idx e)] :: acc)

fn :: m split lines String => [String]
      m split lines s      =
        | (str len s) == 0 = [""]
        | otherwise        = m lines s 0 (str len s) []

-- ============================================================
-- Message construction (API-MAIL-001)
-- ============================================================

-- @implements FR-MAIL-001
-- @implements API-MAIL-001
fn :: mail message String String String String => MailMessage
      mail message from_a to_a   subject text   =  MailMessage from_a [to_a] "" subject text "" "" 0

-- @implements API-MAIL-001
fn :: mail with html MailMessage String => MailMessage
      mail with html msg         html   =  msg with html_body = html

-- @implements API-MAIL-001
fn :: mail with reply to MailMessage String => MailMessage
      mail with reply to msg         addr   =  msg with reply_to_addr = addr

-- @implements API-MAIL-001
fn :: mail add to MailMessage String => MailMessage
      mail add to msg         addr   =  msg with to_addrs = (to_addrs msg) :: [addr]

-- @implements API-MAIL-001
fn :: mail with to MailMessage [String] => MailMessage
      mail with to msg         addrs    =  msg with to_addrs = addrs

-- @implements API-MAIL-001
fn :: mail with date MailMessage Int => MailMessage
      mail with date msg         sec =  msg with date_sec = sec

-- @implements API-MAIL-001
fn :: mail with message id MailMessage String => MailMessage
      mail with message id msg         mid    =  msg with message_id = mid

-- ============================================================
-- Address validation (RFC 5321 §4.1.2 Mailbox = Dot-string "@" Domain)
-- ============================================================

fn :: m is atext Int => Bool
      m is atext c   =
        (c >= 97 and c <= 122) or (c >= 65 and c <= 90) or (c >= 48 and c <= 57) or c == 33 or (c >= 35 and c <= 39) or c == 42 or c == 43 or c == 45 or c == 47 or c == 61 or c == 63 or (c >= 94 and c <= 96) or (c >= 123 and c <= 126)

fn :: m valid local String Int Int Bool => Bool
      m valid local s      idx slen prev_dot =
        | idx >= slen              = not prev_dot
        | (m u8 s idx) == 46       = (not prev_dot) and idx > 0 and (m valid local s (idx + 1) slen True)
        | m is atext (m u8 s idx)  = m valid local s (idx + 1) slen False
        | otherwise                = False

fn :: m is ld Int => Bool
      m is ld c   =  (c >= 97 and c <= 122) or (c >= 65 and c <= 90) or (c >= 48 and c <= 57)

-- Domain = sub-domain *("." sub-domain); sub-domain = Let-dig [Ldh-str] (max 63 per label).
fn :: m valid domain String Int Int Int => Bool
      m valid domain s      idx slen label_len =
        | idx >= slen =
          label_len > 0 and (m is ld (m u8 s (slen - 1)))
        | (m u8 s idx) == 46 =
          label_len > 0 and (m is ld (m u8 s (idx - 1))) and (m valid domain s (idx + 1) slen 0)
        | label_len == 0 and not (m is ld (m u8 s idx)) = False
        | (m is ld (m u8 s idx)) or (m u8 s idx) == 45  =
          label_len < 63 and (m valid domain s (idx + 1) slen (label_len + 1))
        | otherwise = False

-- @implements FR-MAIL-001
-- @implements API-MAIL-001
-- @mitigates VUL-INJ-003
fn :: mail valid address String => Bool
      mail valid address addr   =
        at  = m last index of addr 64 ((str len addr) - 1)
        lp  = str slice addr 0 at
        dom = tls rest addr (at + 1)
        res =
          | (str len addr) > 254 or at <= 0 or at > 64       = False
          | (str len dom) == 0 or (str len dom) > 253        = False
          | otherwise = (m valid local lp 0 (str len lp) False) and (m valid domain dom 0 (str len dom) 0)
        res

fn :: m trim String => String
      m trim s      =  c trim s

-- "Name <addr>" -> (name, addr); a bare address -> ("", addr).
fn :: mail split mailbox String => String String
      mail split mailbox s      =
        t   = m trim s
        lt  = m index of t 60 0 (str len t)
        res =
          | lt >= 0 and (str len t) > 0 and (m u8 t ((str len t) - 1)) == 62 =
            (m unquote (m trim (str slice t 0 lt)), m trim (str slice t (lt + 1) ((str len t) - 1)))
          | otherwise = ("", t)
        res

fn :: m unquote String => String
      m unquote s      =
        | (str len s) >= 2 and (m u8 s 0) == 34 and (m u8 s ((str len s) - 1)) == 34 = str slice s 1 ((str len s) - 1)
        | otherwise                                                                  = s

fn :: mail address of String => String
      mail address of s      =
        name, addr = mail split mailbox s
        addr

fn :: m domain of String => String
      m domain of addr   =  tls rest addr ((m last index of addr 64 ((str len addr) - 1)) + 1)

fn :: m all valid [String] => Bool
      m all valid []       =  True
      m all valid (a:rest) =  (mail valid address (mail address of a)) and (m all valid rest)

fn :: m any crlf [String] => Bool
      m any crlf []       =  False
      m any crlf (a:rest) =  (m has crlf a) or (m any crlf rest)

fn :: m no addrs [String] => Bool
      m no addrs []    =  True
      m no addrs (_:_) =  False

-- ============================================================
-- RFC 2047 encoded-words, display names, dates
-- ============================================================

fn :: m needs encoding String Int Int => Bool
      m needs encoding s      idx slen =
        | idx >= slen                                   = False
        | (m u8 s idx) < 32 or (m u8 s idx) > 126       = True
        | otherwise                                     = m needs encoding s (idx + 1) slen

-- Cut point <= want that does not split a UTF-8 sequence.
fn :: m utf8 cut String Int => Int
      m utf8 cut s      want =
        | want >= (str len s)                                     = str len s
        | want <= 0                                               = 0
        | (m u8 s want) >= 128 and (m u8 s want) < 192           = m utf8 cut s (want - 1)
        | otherwise                                               = want

fn :: m encoded words String [String] => [String]
      m encoded words s      acc      =
        | (str len s) == 0 = tls reverse acc []
        | otherwise        =
          cut0 = m utf8 cut s 45
          cut  =
            | cut0 == 0 = 45
            | otherwise = cut0
          m encoded words (tls rest s cut) (["=?UTF-8?B?" + (c b64 encode (str slice s 0 cut)) + "?="] :: acc)

-- Non-ASCII text -> RFC 2047 "B" encoded-words (each <= 75 chars), folded with CRLF SP.
-- @implements FR-MAIL-001
-- @implements API-MAIL-001
fn :: mail encode rfc2047 String => String
      mail encode rfc2047 s      =
        | not (m needs encoding s 0 (str len s)) = s
        | otherwise                              = m join sep (m encoded words s []) "\r\n "

fn :: m is special Int => Bool
      m is special c   =  c == 40 or c == 41 or c == 60 or c == 62 or c == 91 or c == 93 or c == 58 or c == 59 or c == 64 or c == 92 or c == 44 or c == 46 or c == 34

fn :: m has special String Int Int => Bool
      m has special s      idx slen =
        | idx >= slen              = False
        | m is special (m u8 s idx) = True
        | otherwise                = m has special s (idx + 1) slen

fn :: m quote escape String Int Int String => String
      m quote escape s      idx slen acc    =
        | idx >= slen                                 = acc
        | (m u8 s idx) == 34 or (m u8 s idx) == 92    = m quote escape s (idx + 1) slen (acc + "\\" + (str slice s idx (idx + 1)))
        | otherwise                                   = m quote escape s (idx + 1) slen (acc + (str slice s idx (idx + 1)))

fn :: m display name String => String
      m display name name   =
        | m needs encoding name 0 (str len name) = mail encode rfc2047 name
        | m has special name 0 (str len name)    = "\"" + (m quote escape name 0 (str len name) "") + "\""
        | otherwise                              = name

fn :: m format mailbox String => String
      m format mailbox s      =
        name, addr = mail split mailbox s
        res        =
          | name == "" = addr
          | otherwise  = (m display name name) + " <" + addr + ">"
        res

fn :: m format list [String] [String] => [String]
      m format list []       acc =  tls reverse acc []
      m format list (a:rest) acc =  m format list rest ([m format mailbox a] :: acc)

fn :: m day name Int => String
      m day name d   =  str slice "SunMonTueWedThuFriSat" (d * 3) ((d * 3) + 3)

fn :: m month name Int => String
      m month name mo  =  str slice "JanFebMarAprMayJunJulAugSepOctNovDec" ((mo - 1) * 3) (mo * 3)

-- RFC 5322 §3.3 date-time in UTC, e.g. "Fri, 06 Nov 2026 19:04:05 +0000".
-- @implements FR-MAIL-001
-- @implements API-MAIL-001
fn :: mail format date Int => String
      mail format date sec =
        y, mo, d, hh, mi, ss = time epoch to utc sec
        (m day name (time day of week y mo d)) + ", " + (m pad2 d) + " " + (m month name mo) + " " + (int to str y) + " " + (m pad2 hh) + ":" + (m pad2 mi) + ":" + (m pad2 ss) + " +0000"

-- ============================================================
-- Bodies: quoted-printable (RFC 2045 §6.7) and dot-stuffing
-- ============================================================

fn :: m qp token String Int Int => String
      m qp token s      idx slen =
        | (m u8 s idx) == 61                                          = "=3D"
        | ((m u8 s idx) == 32 or (m u8 s idx) == 9) and idx == (slen - 1) = "=" + (m upper hex (m u8 s idx))
        | (m u8 s idx) == 32 or (m u8 s idx) == 9                     = str slice s idx (idx + 1)
        | (m u8 s idx) >= 33 and (m u8 s idx) <= 126                  = str slice s idx (idx + 1)
        | otherwise                                                   = "=" + (m upper hex (m u8 s idx))

-- Encode one source line into output lines of <= 76 chars using "=" soft breaks.
fn :: m qp line String Int Int String [String] => [String]
      m qp line s      idx slen cur    acc      =
        | idx >= slen = [cur] :: acc
        | otherwise   =
          tok = m qp token s idx slen
          res =
            | (str len cur) + (str len tok) > 75 = m qp line s (idx + 1) slen tok ([cur + "="] :: acc)
            | otherwise                          = m qp line s (idx + 1) slen (cur + tok) acc
          res

fn :: m qp lines [String] [String] => [String]
      m qp lines []       acc =  tls reverse acc []
      m qp lines (l:rest) acc =  m qp lines rest (m qp line l 0 (str len l) "" acc)

fn :: mail qp encode String => String
      mail qp encode body   =  m join sep (m qp lines (m split lines body) []) "\r\n"

fn :: m stuff lines [String] [String] => [String]
      m stuff lines []       acc =  tls reverse acc []
      m stuff lines (l:rest) acc =
        | (str len l) > 0 and (m u8 l 0) == 46 = m stuff lines rest (["." + l] :: acc)
        | otherwise                           = m stuff lines rest ([l] :: acc)

-- Normalise line endings to CRLF and prefix "." to lines that start with "." (RFC 5321 §4.5.2).
-- @implements FR-MAIL-001
-- @implements API-MAIL-001
-- @mitigates VUL-INJ-003
fn :: smtp dot stuff String => String
      smtp dot stuff data   =  m join sep (m stuff lines (m split lines data) []) "\r\n"

-- ============================================================
-- Rendering (FR-MAIL-001 AC1)
-- ============================================================

fn :: m hex random Int => String
      m hex random n   =  bytes to hex str (tls random "m" n)

fn :: m header String String => String
      m header name  value  =  name + ": " + value + "\r\n"

fn :: m qp part String String => String
      m qp part ctype  body   =  (m header "Content-Type" (ctype + "; charset=UTF-8")) + (m header "Content-Transfer-Encoding" "quoted-printable") + "\r\n" + (mail qp encode body) + "\r\n"

fn :: m body part MailMessage => String
      m body part msg         =
        | (html_body msg) == "" = m qp part "text/plain" (text_body msg)
        | otherwise             =
          b = "=_ridgun_" + (m hex random 12)
          (m header "Content-Type" ("multipart/alternative; boundary=\"" + b + "\"")) + "\r\n" + "--" + b + "\r\n" + (m qp part "text/plain" (text_body msg)) + "--" + b + "\r\n" + (m qp part "text/html" (html_body msg)) + "--" + b + "--\r\n"

fn :: m message id MailMessage => String
      m message id msg         =
        | (message_id msg) == ""                                       = "<" + (m hex random 16) + "@" + (m domain of (mail address of (from_addr msg))) + ">"
        | str starts with (message_id msg) "<"                         = message_id msg
        | otherwise                                                    = "<" + (message_id msg) + ">"

fn :: m date of MailMessage => Int
      m date of msg         =
        | (date_sec msg) > 0 = date_sec msg
        | otherwise          = (sys wall time ms) / 1000

fn :: m render ok MailMessage => String
      m render ok msg         =
        reply =
          | (reply_to_addr msg) == "" = ""
          | otherwise                 = m header "Reply-To" (m format mailbox (reply_to_addr msg))
        heads = (m header "From" (m format mailbox (from_addr msg))) + (m header "To" (m join sep (m format list (to_addrs msg) []) ", ")) + reply + (m header "Subject" (mail encode rfc2047 (subject_line msg))) + (m header "Date" (mail format date (m date of msg))) + (m header "Message-ID" (m message id msg)) + (m header "MIME-Version" "1.0")
        smtp dot stuff (heads + (m body part msg))

-- Render the message as sent after DATA (CRLF, quoted-printable, dot-stuffed).
-- @implements FR-MAIL-001
-- @implements API-MAIL-001
-- @mitigates VUL-INJ-003
-- @mitigates VUL-INPUT-003
fn :: mail render MailMessage => MailResult
      mail render msg         =
        | m has crlf (from_addr msg)                    = MailErr "header injection: CR or LF in From"
        | m any crlf (to_addrs msg)                     = MailErr "header injection: CR or LF in To"
        | m has crlf (reply_to_addr msg)                = MailErr "header injection: CR or LF in Reply-To"
        | m has crlf (subject_line msg)                 = MailErr "header injection: CR or LF in Subject"
        | m has crlf (message_id msg)                   = MailErr "header injection: CR or LF in Message-ID"
        | not (mail valid address (mail address of (from_addr msg))) = MailErr "invalid From address"
        | m no addrs (to_addrs msg)                     = MailErr "no recipients"
        | not (m all valid (to_addrs msg))              = MailErr "invalid To address"
        | (reply_to_addr msg) != "" and not (mail valid address (mail address of (reply_to_addr msg))) = MailErr "invalid Reply-To address"
        | otherwise                                     = MailOk (m render ok msg)

-- @implements API-MAIL-001
fn :: mail is ok MailResult => Bool
      mail is ok (MailOk _)  =  True
      mail is ok (MailErr _) =  False

-- @implements API-MAIL-001
fn :: mail unwrap MailResult => String
      mail unwrap (MailOk s)  =  s
      mail unwrap (MailErr _) =  ""

-- @implements API-MAIL-001
fn :: mail error MailResult => String
      mail error (MailOk _)  =  ""
      mail error (MailErr e) =  e

-- ============================================================
-- SMTP configuration and replies (API-MAIL-001)
-- ============================================================

-- @implements FR-MAIL-001
-- @implements API-MAIL-001
fn :: smtp config String Int String String => SmtpConfig
      smtp config server port user   password =  SmtpConfig server port user password "PLAIN" 30000 (tls defaults)

-- @implements API-MAIL-001
fn :: smtp with tls SmtpConfig TlsConfig => SmtpConfig
      smtp with tls cfg        tcfg      =  cfg with tls_config = tcfg

-- "PLAIN" or "LOGIN".
-- @implements API-MAIL-001
fn :: smtp with auth SmtpConfig String => SmtpConfig
      smtp with auth cfg        method =  cfg with auth_method = m to upper method

-- @implements API-MAIL-001
fn :: smtp with timeout SmtpConfig Int => SmtpConfig
      smtp with timeout cfg        ms  =  cfg with timeout_ms = ms

fn :: m upper char Int => Int
      m upper char c   =
        | c >= 97 and c <= 122 = c - 32
        | otherwise            = c

fn :: m to upper String => String
      m to upper s      =  tls join (m upper chars s 0 (str len s) []) ""

fn :: m upper chars String Int Int [String] => [String]
      m upper chars s      idx slen acc      =
        | idx >= slen = tls reverse acc []
        | otherwise   = m upper chars s (idx + 1) slen ([char from code (m upper char (m u8 s idx))] :: acc)

fn :: m is digit Int => Bool
      m is digit c   =  c >= 48 and c <= 57

fn :: m reply line ok String => Bool
      m reply line ok line   =  (str len line) >= 3 and (m is digit (m u8 line 0)) and (m is digit (m u8 line 1)) and (m is digit (m u8 line 2))

fn :: m reply loop String Int [String] => Int [String] String
      m reply loop s      idx acc      =
        nl = m index of s 10 idx (str len s)
        m reply at s idx nl acc

fn :: m reply at String Int Int [String] => Int [String] String
      m reply at s      idx nl  acc      =
        | nl < 0    = (0 - 1, [], s)
        | otherwise = m reply step s nl (tls trim cr (str slice s idx nl)) acc

fn :: m reply step String Int String [String] => Int [String] String
      m reply step s      nl  line   acc      =
        | not (m reply line ok line)                       = (0 - 2, [], s)
        | (str len line) > 3 and (m u8 line 3) == 45      = m reply loop s (nl + 1) ([tls rest line 4] :: acc)
        | otherwise                                        = (str to int (str slice line 0 3), tls reverse ([tls rest line 4] :: acc) [], tls rest s (nl + 1))

-- Parse one (possibly multi-line) SMTP reply: (code, text lines, remaining input).
-- code -1 = incomplete, -2 = malformed.
-- @implements FR-MAIL-001
-- @implements API-MAIL-001
-- @mitigates VUL-INPUT-003
fn :: smtp parse response String => Int [String] String
      smtp parse response s      =  m reply loop s 0 []

-- ============================================================
-- SMTP transport
-- ============================================================

fn :: m io send SmtpIo String => Bool
      m io send io     data   =
        | io_tls io = (tls send (io_conn io) data) == (str len data)
        | otherwise = tls send all (io_fd io) data (io_timeout io)

fn :: m io recv plain Int String => String
      m io recv plain rc  data   =
        | rc == 0   = data
        | otherwise = ""

fn :: m io recv SmtpIo => String
      m io recv io     =
        | io_tls io = tls recv (io_conn io) 4096
        | otherwise =
          rc, data = sys recv (io_fd io) 4096 (io_timeout io)
          m io recv plain rc data

fn :: m read reply SmtpIo String Int => Int [String]
      m read reply io     acc    tries =
        code, lines, _ = smtp parse response acc
        res            =
          | code >= 0 or code == (0 - 2)       = (code, lines)
          | tries <= 0 or (str len acc) > 65536 = (0 - 1, [])
          | otherwise                          = m read reply more io acc tries (m io recv io)
        res

fn :: m read reply more SmtpIo String Int String => Int [String]
      m read reply more io     acc    tries chunk  =
        | chunk == "" = (0 - 1, [])
        | otherwise   = m read reply io (acc + chunk) (tries - 1)

-- ============================================================
-- SMTP session (FR-MAIL-001 AC2/AC3)
-- ============================================================

fn :: m fail SmtpSt SmtpError => SmtpSt
      m fail st    err       =
        | ss_failed st = st
        | otherwise    = st with ss_failed = True, ss_error = err

fn :: m reply error String Int String => SmtpError
      m reply error stage  code text   =
        | code == (0 - 2)               = SmtpProtocolError 0 ("malformed reply during " + stage)
        | code < 0                      = SmtpConnectionError ("no reply during " + stage)
        | code >= 400 and code < 500    = SmtpTemporaryError code text
        | stage == "AUTH"               = SmtpAuthError code text
        | stage == "RCPT"               = SmtpRejectedRecipient code text
        | otherwise                     = SmtpProtocolError code text

fn :: m code in Int [Int] => Bool
      m code in _    []       =  False
      m code in code (c:rest) =  code == c or (m code in code rest)

fn :: m on reply SmtpSt String [Int] Int [String] => SmtpSt
      m on reply st    stage  okc   code lines    =
        text = m join sep lines " "
        res  =
          | m code in code okc = st with ss_code = code, ss_text = text, ss_ehlo = lines
          | otherwise          = m fail st (m reply error stage code text)
        res

-- Send `line` (unless "") and require one of `okc`.
fn :: m expect SmtpSt String String [Int] => SmtpSt
      m expect st    stage  line   okc   =
        | ss_failed st                                          = st
        | line != "" and not (m io send (ss_io st) (line + "\r\n")) = m fail st (SmtpConnectionError ("send failed during " + stage))
        | otherwise                                             =
          code, lines = m read reply (ss_io st) "" 64
          m on reply st stage okc code lines

fn :: m has starttls [String] => Bool
      m has starttls []       =  False
      m has starttls (l:rest) =  (str starts with (m to upper l) "STARTTLS") or (m has starttls rest)

fn :: m start tls SmtpSt String SmtpConfig => SmtpSt
      m start tls st    server cfg        =
        | ss_failed st = st
        | otherwise    =
          tcfg = tls with timeout (tls_config cfg) (timeout_ms cfg)
          res  = tls connect fd (io_fd (ss_io st)) server tcfg
          m on tls st res

fn :: m on tls SmtpSt TlsResult => SmtpSt
      m on tls st    res       =
        | tls is ok res = st with ss_io = ((ss_io st) with io_tls = True, io_conn = tls unwrap res)
        | otherwise     = m fail st (SmtpTlsError ((tls error kind res) + ": " + (tls error reason res)))

fn :: m require starttls SmtpSt => SmtpSt
      m require starttls st    =
        | ss_failed st                  = st
        | m has starttls (ss_ehlo st)   = st
        | otherwise                     = m fail st (SmtpTlsError "server does not offer STARTTLS; refusing to continue in cleartext")

fn :: m auth SmtpSt SmtpConfig => SmtpSt
      m auth st    cfg        =
        | ss_failed st or (smtp_user cfg) == "" = st
        | not (io_tls (ss_io st))               = m fail st (SmtpTlsError "refusing to authenticate without TLS")
        | (auth_method cfg) == "LOGIN"          =
          st -> m expect "AUTH" "AUTH LOGIN" [334] -> m expect "AUTH" (c b64 encode (smtp_user cfg)) [334] -> m expect "AUTH" (c b64 encode (smtp_password cfg)) [235]
        | otherwise                             =
          m expect st "AUTH" ("AUTH PLAIN " + (c b64 encode ((byte str 0) + (smtp_user cfg) + (byte str 0) + (smtp_password cfg)))) [235]

fn :: m rcpts SmtpSt [String] => SmtpSt
      m rcpts st    []       =  st
      m rcpts st    (a:rest) =  m rcpts (m expect st "RCPT" ("RCPT TO:<" + (mail address of a) + ">") [250, 251]) rest

fn :: m session SmtpSt SmtpConfig MailMessage String Bool => SmtpSt
      m session st    cfg        msg         data   implicit =
        sender = mail address of (from_addr msg)
        ehlo   = "EHLO " + (m domain of sender)
        st1    =
          | implicit  = m start tls st (host cfg) cfg -> m expect "greeting" "" [220] -> m expect "EHLO" ehlo [250]
          | otherwise = st -> m expect "greeting" "" [220] -> m expect "EHLO" ehlo [250] -> m require starttls -> m expect "STARTTLS" "STARTTLS" [220] -> m start tls (host cfg) cfg -> m expect "EHLO" ehlo [250]
        st1 -> m auth cfg -> m expect "MAIL" ("MAIL FROM:<" + sender + ">") [250] -> m rcpts (to_addrs msg) -> m expect "DATA" "DATA" [354] -> m expect "DATA" (data + ".") [250]

fn :: m finish SmtpSt => SmtpResult
      m finish st    =
        | ss_failed st = SmtpErr (ss_error st)
        | otherwise    = SmtpOk (ss_code st) (ss_text st)

fn :: m close SmtpSt => ()
      m close st    =
        quit = m io send (ss_io st) "QUIT\r\n"
        m close io (ss_io st) quit

fn :: m close io SmtpIo Bool => ()
      m close io io     _    =
        | io_tls io = tls close (io_conn io)
        | otherwise = sys close (io_fd io) -> ()

fn :: m new st Int Int => SmtpSt
      m new st fd  timeout =  SmtpSt (SmtpIo fd False (tls unwrap (TlsErr (TlsIoError ""))) timeout) False (SmtpProtocolError 0 "") 0 "" []

fn :: m run session Int Int SmtpConfig MailMessage String Bool => SmtpResult
      m run session rc  fd  cfg        msg         data   implicit =
        | rc == (0 - 2) = SmtpErr (SmtpConnectionError "TCP connect timed out")
        | rc != 0       = SmtpErr (SmtpConnectionError ("TCP connect failed (rc " + (int to str rc) + ")"))
        | otherwise     =
          st = m session (m new st fd (timeout_ms cfg)) cfg msg data implicit
          m close st
          m finish st

-- Submit with an explicit TLS mode (implicit = TLS from the first byte, RFC 8314).
-- @implements FR-MAIL-001
-- @mitigates VUL-AUTHN-004
-- @mitigates VUL-INJ-003
fn :: smtp send mode SmtpConfig MailMessage Bool => SmtpResult
      smtp send mode cfg        msg         implicit =
        rendered = mail render msg
        res      =
          | not (mail is ok rendered)                                    = SmtpErr (SmtpInvalidMessage (mail error rendered))
          | m has crlf (smtp_user cfg) or m has crlf (smtp_password cfg) = SmtpErr (SmtpInvalidMessage "CR or LF in SMTP credentials")
          | not (tls valid sni (host cfg))                               = SmtpErr (SmtpConnectionError "SMTP host must be a DNS hostname")
          | otherwise                                                    = m connect and run cfg msg (mail unwrap rendered) implicit
        res

fn :: m connect and run SmtpConfig MailMessage String Bool => SmtpResult
      m connect and run cfg        msg         data   implicit =
        rc, fd = sys tcp connect (host cfg) (port cfg) (timeout_ms cfg)
        m run session rc fd cfg msg data implicit

-- Port 465 uses implicit TLS (RFC 8314); any other port requires STARTTLS (RFC 3207).
-- @implements FR-MAIL-001
-- @implements API-MAIL-001
-- @mitigates VUL-AUTHN-004
fn :: smtp send SmtpConfig MailMessage => SmtpResult
      smtp send cfg        msg         =  smtp send mode cfg msg ((port cfg) == 465)

-- ============================================================
-- Result helpers (API-MAIL-001)
-- ============================================================

-- @implements API-MAIL-001
fn :: smtp is ok SmtpResult => Bool
      smtp is ok (SmtpOk _ _) =  True
      smtp is ok (SmtpErr _)  =  False

-- 4xx replies and connection failures may succeed on retry.
-- @implements API-MAIL-001
fn :: smtp is retryable SmtpResult => Bool
      smtp is retryable (SmtpErr (SmtpTemporaryError _ _)) =  True
      smtp is retryable (SmtpErr (SmtpConnectionError _))  =  True
      smtp is retryable _                                  =  False

fn :: m error name SmtpError => String
      m error name (SmtpConnectionError _)     =  "SmtpConnectionError"
      m error name (SmtpTlsError _)            =  "SmtpTlsError"
      m error name (SmtpAuthError _ _)         =  "SmtpAuthError"
      m error name (SmtpRejectedRecipient _ _) =  "SmtpRejectedRecipient"
      m error name (SmtpTemporaryError _ _)    =  "SmtpTemporaryError"
      m error name (SmtpProtocolError _ _)     =  "SmtpProtocolError"
      m error name (SmtpInvalidMessage _)      =  "SmtpInvalidMessage"

fn :: m error text SmtpError => String
      m error text (SmtpConnectionError t)     =  t
      m error text (SmtpTlsError t)            =  t
      m error text (SmtpAuthError c t)         =  (int to str c) + " " + t
      m error text (SmtpRejectedRecipient c t) =  (int to str c) + " " + t
      m error text (SmtpTemporaryError c t)    =  (int to str c) + " " + t
      m error text (SmtpProtocolError c t)     =  (int to str c) + " " + t
      m error text (SmtpInvalidMessage t)      =  t

-- @implements API-MAIL-001
fn :: smtp error kind SmtpResult => String
      smtp error kind (SmtpOk _ _) =  ""
      smtp error kind (SmtpErr e)  =  m error name e

-- @implements API-MAIL-001
fn :: smtp error reason SmtpResult => String
      smtp error reason (SmtpOk _ _) =  ""
      smtp error reason (SmtpErr e)  =  m error text e
