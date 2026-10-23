-- ============================================================
-- src/main/ridgun/lib/http.rg
-- Pure-Ridgun RFC 3986 URI & RFC 9112 HTTP/1.1 Request/Response Library (HTTP)
-- @implements FR-HTTP-001
-- @implements API-HTTP-001
-- @mitigates VUL-INPUT-001
-- ============================================================

import socket

-- ── Internal String & Case Helpers ───────────────────────────

fn :: ht index of loop String String Int Int Int => Int
      ht index of loop s sub idx slen sublen =
        | (idx + sublen) > slen                   = 0 - 1
        | (str slice s idx (idx + sublen)) == sub = idx
        | otherwise                               = ht index of loop s sub (idx + 1) slen sublen

fn :: ht index of String String => Int
      ht index of s      sub    =
        | (str len sub) == 0 = 0
        | otherwise          = ht index of loop s sub 0 (str len s) (str len sub)

fn :: ht lower char String Int Int => String
      ht lower char s idx c =
        | c >= 65 and c <= 90 = char from code (c + 32)
        | otherwise           = str slice s idx (idx + 1)

fn :: ht to lower loop String Int Int => String
      ht to lower loop s idx len =
        | idx >= len = ""
        | otherwise  = (ht lower char s idx (str char at s idx)) + (ht to lower loop s (idx + 1) len)

fn :: ht to lower String => String
      ht to lower s      =  ht to lower loop s 0 (str len s)

fn :: ht is ws Int => Bool
      ht is ws c   =  c == 32 or c == 9 or c == 10 or c == 13

fn :: ht trim left String Int Int => Int
      ht trim left s idx len =
        | idx >= len                   = len
        | ht is ws (str char at s idx) = ht trim left s (idx + 1) len
        | otherwise                    = idx

fn :: ht trim right String Int Int => Int
      ht trim right s start end_pos =
        | end_pos <= start                       = start
        | ht is ws (str char at s (end_pos - 1)) = ht trim right s start (end_pos - 1)
        | otherwise                              = end_pos

fn :: ht trim String => String
      ht trim s      =
        st = ht trim left s 0 (str len s)
        en = ht trim right s st (str len s)
        str slice s st en

fn :: ht strip crlf loop String Int Int => String
      ht strip crlf loop s idx len =
        | idx >= len = ""
        | (str char at s idx) == 10 or (str char at s idx) == 13 =
      ht strip crlf loop s (idx + 1) len
        | otherwise =
          (str slice s idx (idx + 1)) + (ht strip crlf loop s (idx + 1) len)

fn :: ht strip crlf String => String
      ht strip crlf s      =  ht strip crlf loop s 0 (str len s)

fn :: ht is digits loop String Int Int => Bool
      ht is digits loop s idx len =
        | idx >= len                                           = True
        | (str char at s idx) < 48 or (str char at s idx) > 57 = False
        | otherwise                                            = ht is digits loop s (idx + 1) len

fn :: ht parse int or String Int => Int
      ht parse int or s fallback =
        | (str len s) == 0                 = fallback
        | not (ht is digits loop s 0 (str len s)) = fallback
        | otherwise                        = str to int s

-- ── RFC 3986 URI Parsing ─────────────────────────────────────

fn :: ht default port String => Int
      ht default port scheme =
        | scheme == "https" or scheme == "wss" = 443
        | scheme == "http" or scheme == "ws"   = 80
        | otherwise                            = 0

fn :: ht split host port String Int Int => String Int
      ht split host port auth colon_idx def_port =
        | colon_idx < 0 = (auth, def_port)
        | otherwise =
          h = str slice auth 0 colon_idx
          p = ht parse int or (str slice auth (colon_idx + 1) (str len auth)) def_port
          (h, p)

fn :: ht split path query String Int => String String
      ht split path query pq q_idx =
        | q_idx < 0 = (pq, "")
        | otherwise = (str slice pq 0 q_idx, str slice pq (q_idx + 1) (str len pq))

fn :: ht split auth rest String Int => String String
      ht split auth rest rem slash_idx =
        | slash_idx < 0 = (rem, "/")
        | otherwise     = (str slice rem 0 slash_idx, str slice rem slash_idx (str len rem))

fn :: ht finish uri String (String Int) (String String) => String String Int String String
      ht finish uri scheme (host, port) (path, query) =
        (scheme, host, port, path, query)

fn :: ht parse uri after scheme String String => String String Int String String
      ht parse uri after scheme scheme rem =
        ap       = ht split auth rest rem (ht index of rem "/")
        auth     = ht pair key ap
        pq_raw   = ht pair val ap
        def_port = ht default port scheme
        hp       = ht split host port auth (ht index of auth ":") def_port
        pq       = ht split path query pq_raw (ht index of pq_raw "?")
        ht finish uri scheme hp pq

fn :: ht parse uri at String Int => String String Int String String
      ht parse uri at raw sep_idx =
        | sep_idx < 0 =
          pq = ht split path query raw (ht index of raw "?")
          ("", "", 0, ht pair key pq, ht pair val pq)
        | otherwise =
          scheme = ht to lower (str slice raw 0 sep_idx)
          rem    = str slice raw (sep_idx + 3) (str len raw)
          ht parse uri after scheme scheme rem

-- @implements FR-HTTP-001
-- @implements API-HTTP-001
fn :: uri parse String => String String Int String String
      uri parse raw    =  ht parse uri at raw (ht index of raw "://")

fn :: ht u1 (String String Int String String) => String
      ht u1 (s, _, _, _, _)                   =  s

fn :: ht u2 (String String Int String String) => String
      ht u2 (_, h, _, _, _)                   =  h

fn :: ht u3 (String String Int String String) => Int
      ht u3 (_, _, p, _, _)                   =  p

fn :: ht u4 (String String Int String String) => String
      ht u4 (_, _, _, pt, _)                  =  pt

fn :: ht u5 (String String Int String String) => String
      ht u5 (_, _, _, _, q)                   =  q

-- @implements FR-HTTP-001
-- @implements API-HTTP-001
fn :: uri scheme String => String
      uri scheme raw    =  ht u1 (uri parse raw)

-- @implements FR-HTTP-001
-- @implements API-HTTP-001
fn :: uri host String => String
      uri host raw    =  ht u2 (uri parse raw)

-- @implements FR-HTTP-001
-- @implements API-HTTP-001
fn :: uri port String => Int
      uri port raw    =  ht u3 (uri parse raw)

-- @implements FR-HTTP-001
-- @implements API-HTTP-001
fn :: uri path String => String
      uri path raw    =  ht u4 (uri parse raw)

-- @implements FR-HTTP-001
-- @implements API-HTTP-001
fn :: uri query String => String
      uri query raw    =  ht u5 (uri parse raw)

-- ── HTTP/1.1 Status Reason Phrases & Header Inspection ───────

-- @implements FR-HTTP-001
-- @implements API-HTTP-001
fn :: http status text Int  => String
      http status text code =
        | code == 200 = "OK"
        | code == 201 = "Created"
        | code == 202 = "Accepted"
        | code == 204 = "No Content"
        | code == 301 = "Moved Permanently"
        | code == 302 = "Found"
        | code == 304 = "Not Modified"
        | code == 400 = "Bad Request"
        | code == 401 = "Unauthorized"
        | code == 403 = "Forbidden"
        | code == 404 = "Not Found"
        | code == 405 = "Method Not Allowed"
        | code == 409 = "Conflict"
        | code == 429 = "Too Many Requests"
        | code == 500 = "Internal Server Error"
        | code == 502 = "Bad Gateway"
        | code == 503 = "Service Unavailable"
        | otherwise   = "Unknown"

fn :: ht pair key (String String) => String
      ht pair key (k, _)          =  k

fn :: ht pair val (String String) => String
      ht pair val (_, v)          =  v

fn :: ht hdr get lower [String String] String => String
      ht hdr get lower [] _ = ""
      ht hdr get lower (pair:rest) lkey =
        | (ht to lower (ht pair key pair)) == lkey = ht pair val pair
        | otherwise                                = ht hdr get lower rest lkey

-- @implements FR-HTTP-001
-- @implements API-HTTP-001
fn :: http header get [String String] String => String
      http header get headers         name   =  ht hdr get lower headers (ht to lower name)

fn :: ht extract bearer String => String
      ht extract bearer auth   =
        | (str len auth) <= 7                             = ""
        | (ht to lower (str slice auth 0 7)) == "bearer " = ht trim (str slice auth 7 (str len auth))
        | otherwise                                       = ""

-- @implements FR-HTTP-001
-- @implements API-HTTP-001
fn :: http bearer token [String String] => String
      http bearer token headers         =  ht extract bearer (http header get headers "Authorization")

-- ── HTTP/1.1 Request & Response Formatting & Parsing ─────────

fn :: ht fmt headers [String String] => String
      ht fmt headers []              =  ""
      ht fmt headers (pair:rest)     =
        k = ht strip crlf (ht pair key pair)
        v = ht strip crlf (ht pair val pair)
        k + ": " + v + "\r\n" + (ht fmt headers rest)

fn :: ht auto cl [String String] String => String
      ht auto cl headers         body   =
        | (str len body) == 0                                  = ""
        | (str len (http header get headers "Content-Length")) > 0 = ""
        | otherwise                                            = "Content-Length: " + (int to str (str len body)) + "\r\n"

-- @implements FR-HTTP-001
-- @implements API-HTTP-001
-- @mitigates VUL-INPUT-001
fn :: http build request String String [String String] String => String
      http build request method path headers body =
        m  = ht strip crlf method
        p  = ht strip crlf path
        cl = ht auto cl headers body
        m + " " + p + " HTTP/1.1\r\n" + (ht fmt headers headers) + cl + "\r\n" + body

-- @implements FR-HTTP-001
-- @implements API-HTTP-001
-- @mitigates VUL-INPUT-001
fn :: http build response Int [String String] String => String
      http build response code headers body =
        reason = http status text code
        cl     = ht auto cl headers body
        "HTTP/1.1 " + (int to str code) + " " + reason + "\r\n" + (ht fmt headers headers) + cl + "\r\n" + body

fn :: ht split lines loop String Int Int Int => [String]
      ht split lines loop s start idx len =
        | idx >= len                = [(ht strip crlf (str slice s start len))]
        | (str char at s idx) == 10 = [(ht strip crlf (str slice s start idx))] :: (ht split lines loop s (idx + 1) (idx + 1) len)
        | otherwise                 = ht split lines loop s start (idx + 1) len

fn :: ht parse hdr line String Int => [String String]
      ht parse hdr line line cidx =
        | cidx <= 0 = []
        | otherwise =
          k = ht trim (str slice line 0 cidx)
          v = ht trim (str slice line (cidx + 1) (str len line))
          [(k, v)]

fn :: ht parse hdr lines [String] => [String String]
      ht parse hdr lines []       =  []
      ht parse hdr lines (l:rest) =
        | (str len l) == 0 = ht parse hdr lines rest
        | otherwise        = (ht parse hdr line l (ht index of l ":")) :: (ht parse hdr lines rest)

fn :: ht split head body String Int Int => String String
      ht split head body raw crlf_idx lf_idx =
        | crlf_idx >= 0 = (str slice raw 0 crlf_idx, str slice raw (crlf_idx + 4) (str len raw))
        | lf_idx >= 0   = (str slice raw 0 lf_idx, str slice raw (lf_idx + 2) (str len raw))
        | otherwise     = (raw, "")

fn :: ht parse req rem String String Int => String String
      ht parse req rem method rem sp2 =
        | sp2 < 0   = (method, rem)
        | otherwise = (method, str slice rem 0 sp2)

fn :: ht parse req line String Int => String String
      ht parse req line line sp1 =
        | sp1 <= 0 = ("", "")
        | otherwise =
          method = str slice line 0 sp1
          rem    = str slice line (sp1 + 1) (str len line)
          ht parse req rem method rem (ht index of rem " ")

fn :: ht parse req parts [String] String => String String String
      ht parse req parts [] body = ("", "", body)
      ht parse req parts (f:_) body =
        mp = ht parse req line f (ht index of f " ")
        (ht pair key mp, ht pair val mp, body)

fn :: ht parse hdr parts [String] => [String String]
      ht parse hdr parts []       =  []
      ht parse hdr parts (_:rest) =  ht parse hdr lines rest

-- @implements FR-HTTP-001
-- @implements API-HTTP-001
-- @mitigates VUL-INPUT-001
fn :: http parse headers String => [String String]
      http parse headers raw    =
        hb    = ht split head body raw (ht index of raw "\r\n\r\n") (ht index of raw "\n\n")
        head  = ht pair key hb
        lines = ht split lines loop head 0 0 (str len head)
        ht parse hdr parts lines

-- @implements FR-HTTP-001
-- @implements API-HTTP-001
-- @mitigates VUL-INPUT-001
fn :: http parse request String => String String String
      http parse request raw    =
        hb    = ht split head body raw (ht index of raw "\r\n\r\n") (ht index of raw "\n\n")
        head  = ht pair key hb
        body  = ht pair val hb
        lines = ht split lines loop head 0 0 (str len head)
        ht parse req parts lines body

fn :: ht parse status rem String Int => Int String
      ht parse status rem rem sp2 =
        | sp2 < 0   = (ht parse int or rem 0, "")
        | otherwise = (ht parse int or (str slice rem 0 sp2) 0, str slice rem (sp2 + 1) (str len rem))

fn :: ht parse status line String Int => Int String
      ht parse status line line sp1 =
        | sp1 <= 0 = (0, "")
        | otherwise =
          rem = str slice line (sp1 + 1) (str len line)
          ht parse status rem rem (ht index of rem " ")

fn :: ht st code (Int String) => Int
      ht st code (c, _)       =  c

fn :: ht st text (Int String) => String
      ht st text (_, t)       =  t

fn :: ht parse resp parts [String] String => Int String String
      ht parse resp parts [] body = (0, "", body)
      ht parse resp parts (f:_) body =
        st = ht parse status line f (ht index of f " ")
        (ht st code st, ht st text st, body)

-- @implements FR-HTTP-001
-- @implements API-HTTP-001
-- @mitigates VUL-INPUT-001
fn :: http parse response String => Int String String
      http parse response raw    =
        hb    = ht split head body raw (ht index of raw "\r\n\r\n") (ht index of raw "\n\n")
        head  = ht pair key hb
        body  = ht pair val hb
        lines = ht split lines loop head 0 0 (str len head)
        ht parse resp parts lines body

-- ── Live Kernel TCP HTTP/1.1 Client (`http_request_tcp`, `http_get`, `http_post`) ──

fn :: ht ensure hdr [String String] String String => [String String]
      ht ensure hdr headers key val =
        | (str len (http header get headers key)) > 0 = headers
        | otherwise                                   = headers :: [(key, val)]

fn :: ht read tcp step Int Int String (Int String) => String
      ht read tcp step fd timeout_ms acc (rc, chunk) =
        | rc != 0   = acc
        | otherwise = ht read tcp loop fd timeout_ms (acc + chunk)

fn :: ht read tcp loop Int Int String => String
      ht read tcp loop fd timeout_ms acc =
        ht read tcp step fd timeout_ms acc (sys recv fd 16384 timeout_ms)

fn :: ht resp code (Int String String) => Int
      ht resp code (c, _, _)           =  c

fn :: ht resp body (Int String String) => String
      ht resp body (_, _, b)           =  b

fn :: ht finish tcp resp String => Int Int String
      ht finish tcp resp raw    =
        | (str len raw) == 0 = (0 - 1, 0, "")
        | otherwise =
          pr   = http parse response raw
          code = ht resp code pr
          (0, code, raw)

fn :: ht send read step Int Int (Int Int) => Int Int String
      ht send read step cfd timeout_ms (s_rc, _) =
        | s_rc != 0 =
          _ = sys close cfd
          (s_rc, 0, "")
        | otherwise =
          raw = ht read tcp loop cfd timeout_ms ""
          _   = sys close cfd
          ht finish tcp resp raw

fn :: ht connect send tcp Int Int String Int => Int Int String
      ht connect send tcp c_rc cfd wire timeout_ms =
        | c_rc != 0 = (c_rc, 0, "")
        | otherwise = ht send read step cfd timeout_ms (sys send cfd wire timeout_ms)

-- @implements FR-HTTP-001
-- @implements API-HTTP-001
-- @mitigates VUL-INPUT-001
fn :: http request tcp String Int String String [String String] String Int => Int Int String
      http request tcp host port method path headers body timeout_ms =
        c_res = sys tcp connect host port timeout_ms
        hdrs1 = ht ensure hdr headers "Host" host
        hdrs2 = ht ensure hdr hdrs1 "Connection" "close"
        wire  = http build request method path hdrs2 body
        ht connect send tcp (sock rc c_res) (sock fd c_res) wire timeout_ms

fn :: ht pick path String => String
      ht pick path p      =
        | (str len p) == 0 = "/"
        | otherwise        = p

fn :: ht build target path String String => String
      ht build target path p q =
        | (str len q) == 0 = ht pick path p
        | otherwise        = (ht pick path p) + "?" + q

fn :: ht exec url req (String String Int String String) String [String String] String Int => Int Int String
      ht exec url req (scheme, host, port, p, q) method headers body timeout_ms =
        | scheme != "http" or (str len host) == 0 or port <= 0 = (0 - 7, 0, "")
        | otherwise                                            = http request tcp host port method (ht build target path p q) headers body timeout_ms

-- @implements FR-HTTP-001
-- @implements API-HTTP-001
-- @mitigates VUL-INPUT-001
fn :: http get String Int        => Int Int String
      http get url    timeout_ms =
        ht exec url req (uri parse url) "GET" [] "" timeout_ms

-- @implements FR-HTTP-001
-- @implements API-HTTP-001
-- @mitigates VUL-INPUT-001
fn :: http post String String String Int => Int Int String
      http post url content_type body timeout_ms =
        ht exec url req (uri parse url) "POST" [("Content-Type", content_type)] body timeout_ms

-- @implements FR-HTTP-001
-- @implements API-HTTP-001
fn :: http resp rc (Int Int String) => Int
      http resp rc (rc, _, _)       =  rc

-- @implements FR-HTTP-001
-- @implements API-HTTP-001
fn :: http resp status (Int Int String) => Int
      http resp status (_, st, _)       =  st

-- @implements FR-HTTP-001
-- @implements API-HTTP-001
fn :: http resp headers (Int Int String) => [String String]
      http resp headers (_, _, raw)      =  http parse headers raw

-- @implements FR-HTTP-001
-- @implements API-HTTP-001
fn :: http resp body (Int Int String) => String
      http resp body (_, _, raw)      =  ht resp body (http parse response raw)
