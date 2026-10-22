-- ============================================================
-- src/test/ridgun/test_http.rg
-- Automated test suite for http.rg (TS-HTTP-001)
-- @tests TS-HTTP-001
-- ============================================================

import test
import http

fn :: req method (String, String, String) => String
      req method (m, _, _)                =  m

fn :: req path (String, String, String) => String
      req path (_, p, _)                =  p

fn :: req body (String, String, String) => String
      req body (_, _, b)                =  b

fn :: resp code (Int, String, String) => Int
      resp code (c, _, _)             =  c

fn :: resp reason (Int, String, String) => String
      resp reason (_, r, _)             =  r

fn :: resp body (Int, String, String) => String
      resp body (_, _, b)             =  b

-- @tests TS-HTTP-001
fn :: test uri parsing => ()
      test uri parsing =
        u1 = "https://api.example.com:8443/v1/users?active=1&role=admin"
        _  = assert_str_eq (uri scheme u1) "https" "uri_scheme https"
        _  = assert_str_eq (uri host u1) "api.example.com" "uri_host"
        _  = assert_int_equals (uri port u1) 8443 "uri_port 8443"
        _  = assert_str_eq (uri path u1) "/v1/users" "uri_path"
        _  = assert_str_eq (uri query u1) "active=1&role=admin" "uri_query"
        u2 = "http://localhost/health"
        _  = assert_str_eq (uri scheme u2) "http" "uri_scheme http"
        _  = assert_str_eq (uri host u2) "localhost" "uri_host localhost"
        _  = assert_int_equals (uri port u2) 80 "default http port 80"
        _  = assert_str_eq (uri path u2) "/health" "uri_path /health"
        _  = assert_str_eq (uri query u2) "" "uri_query empty"
        ()

-- @tests TS-HTTP-001
fn :: test http11 request and response => ()
      test http11 request and response =
        hdrs    = [("Host", "api.example.com"), ("Authorization", "Bearer tok_xyz_987"), ("X-Injected", "safe\r\nEvil: 1")]
        raw_req = http build request "POST" "/v1/login" hdrs "{\"user\":\"alice\"}"
        parsed  = http parse request raw_req
        _       = assert_str_eq (req method parsed) "POST" "req method POST"
        _       = assert_str_eq (req path parsed) "/v1/login" "req path /v1/login"
        _       = assert_str_eq (req body parsed) "{\"user\":\"alice\"}" "req body"
        phdrs   = http parse headers raw_req
        _       = assert_str_eq (http header get phdrs "host") "api.example.com" "case-insensitive host header"
        _       = assert_str_eq (http header get phdrs "content-length") "16" "auto Content-Length 16"
        _       = assert_str_eq (http bearer token phdrs) "tok_xyz_987" "http_bearer_token"
        _       = assert_str_eq (http header get phdrs "Evil") "" "CRLF injection prevented"

        _        = assert_str_eq (http status text 200) "OK" "status 200 OK"
        _        = assert_str_eq (http status text 404) "Not Found" "status 404 Not Found"
        raw_resp = http build response 201 [("Content-Type", "application/json")] "{\"id\":42}"
        presp    = http parse response raw_resp
        rhdrs    = http parse headers raw_resp
        _        = assert_int_equals (resp code presp) 201 "resp code 201"
        _        = assert_str_eq (resp reason presp) "Created" "resp reason Created"
        _        = assert_str_eq (http header get rhdrs "content-type") "application/json" "resp Content-Type"
        _        = assert_str_eq (resp body presp) "{\"id\":42}" "resp body"
        ()

fn :: main => ()
      main =
        _ = test uri parsing
        _ = test http11 request and response
        echo "[PASS] test_http: TS-HTTP-001 passed"
