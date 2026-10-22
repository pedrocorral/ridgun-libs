-- ============================================================
-- src/test/ridgun/test_http.rg
-- Automated test suite for http.rg (TS-HTTP-001)
-- @tests TS-HTTP-001
-- ============================================================

import test
import socket
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

-- @tests TS-HTTP-001
fn :: test http11 live tcp client and server => ()
      test http11 live tcp client and server =
        -- Spin up a real kernel TCP listener on port 0, connect a client, send HTTP request, respond, and read back
        l_res  = sys tcp listen "127.0.0.1" 0 8
        _      = assert_int_equals (sock rc l_res) 0 "http server listen ok"
        lfd    = sock fd l_res
        port   = sys local port lfd
        _      = assert_true (port > 0) "http server ephemeral port > 0"
        c_res  = sys tcp connect "localhost" port 500
        _      = assert_int_equals (sock rc c_res) 0 "http client connect ok"
        cfd    = sock fd c_res
        a_res  = sys accept lfd 500
        _      = assert_int_equals (sock accept rc a_res) 0 "http server accept ok"
        sfd    = sock accept fd a_res
        req_w  = http build request "GET" "/v1/ping?echo=1" [("Host", "localhost"), ("Connection", "close")] ""
        _      = assert_int_equals (sock rc (sys send cfd req_w 500)) 0 "http client send request"
        srv_rx = sock recv data (sys recv sfd 4096 500)
        s_req  = http parse request srv_rx
        _      = assert_str_eq (req method s_req) "GET" "server parsed GET"
        _      = assert_str_eq (req path s_req) "/v1/ping?echo=1" "server parsed path"
        resp_w = http build response 200 [("Content-Type", "application/json"), ("Connection", "close")] "{\"pong\":true}"
        _      = assert_int_equals (sock rc (sys send sfd resp_w 500)) 0 "http server send response"
        _      = assert_int_equals (sys_close sfd) 0 "http server close sfd"
        cli_rx = sock recv data (sys recv cfd 4096 500)
        c_resp = http parse response cli_rx
        c_hdrs = http parse headers cli_rx
        _      = assert_int_equals (resp code c_resp) 200 "client parsed 200"
        _      = assert_str_eq (http header get c_hdrs "content-type") "application/json" "client parsed header"
        _      = assert_str_eq (resp body c_resp) "{\"pong\":true}" "client parsed body"
        _      = assert_int_equals (sys_close cfd) 0 "http client close cfd"
        _      = assert_int_equals (sys_close lfd) 0 "http server close lfd"
        -- Verify http_get / http_post error handling on invalid scheme or refused port
        bad_g  = http get "ftp://localhost/file" 100
        _      = assert_int_equals (http resp rc bad_g) (0 - 7) "http_get non-http scheme -> -7"
        ref_p  = http post "http://127.0.0.1:39998/api" "application/json" "{}" 100
        _      = assert_int_equals (http resp rc ref_p) (0 - 3) "http_post refused port -> -3"
        -- Verify http_get against a real external background TCP responder over kernel loopback
        l_bg   = sys tcp listen "127.0.0.1" 0 8
        lfd_bg = sock fd l_bg
        p_bg   = sys local port lfd_bg
        _      = sys_close lfd_bg
        _      = shell_exec "python3 -c \"import socket; s=socket.socket(); s.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1); s.bind(('127.0.0.1',{p_bg})); s.listen(1); c,_=s.accept(); c.recv(1024); c.sendall(b'HTTP/1.1 200 OK\\r\\nContent-Type: text/plain\\r\\nContent-Length: 7\\r\\nConnection: close\\r\\n\\r\\nlive-ok'); c.close(); s.close()\" >/dev/null 2>&1 &"
        _      = sys_sleep_ms 80
        g_live = http get "http://localhost:{p_bg}/status?check=1" 500
        _      = assert_int_equals (http resp rc g_live) 0 "http_get live external TCP server rc == 0"
        _      = assert_int_equals (http resp status g_live) 200 "http_get live status == 200"
        _      = assert_str_eq (http header get (http resp headers g_live) "content-type") "text/plain" "http_get live header"
        _      = assert_str_eq (http resp body g_live) "live-ok" "http_get live body == live-ok"
        ()

fn :: main => ()
      main =
        _ = test uri parsing
        _ = test http11 request and response
        _ = test http11 live tcp client and server
        echo "[PASS] test_http: TS-HTTP-001 passed"
