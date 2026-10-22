---
id: API-HTTP-001
title: Public module contract for http (http.rglib / libhttp.so)
status: approved
implements: [FR-HTTP-001]
auth: none
---
# API-HTTP-001 — Public module contract for `http` (`http.rg`)

## Request
- Imported via `import http`.
- URI Parsing:
  - `uri parse String => (String, String, Int, String, String)` (`(scheme, host, port, path, query)`)
  - `uri scheme String => String`, `uri host String => String`, `uri port String => Int`, `uri path String => String`, `uri query String => String`
- HTTP/1.1 Requests, Responses, Headers & Live TCP Client:
  - `http status text Int => String`
  - `http build request String String [(String, String)] String => String`
  - `http parse request String => (String, String, String)` (`(method, path, body)`)
  - `http build response Int [(String, String)] String => String`
  - `http parse response String => (Int, String, String)` (`(status_code, reason, body)`)
  - `http parse headers String => [(String, String)]`
  - `http header get [(String, String)] String => String`, `http bearer token [(String, String)] => String`
  - `http request tcp String Int String String [(String, String)] String Int => (Int, Int, String)` (`(rc, status_code, raw_response)`)
  - `http get String Int => (Int, Int, String)`, `http post String String String Int => (Int, Int, String)`
  - `http resp rc (Int, Int, String) => Int`, `http resp status (Int, Int, String) => Int`, `http resp headers (Int, Int, String) => [(String, String)]`, `http resp body (Int, Int, String) => String`

## Responses
| Code | When | Body |
|---|---|---|
| `String` / `Tuple` | URI or HTTP/1.1 wire message processed | Formatted wire string or parsed components |

## Rules
- All header lookups in `http header get` are ASCII case-insensitive; CR/LF characters are stripped from outbound header values.
