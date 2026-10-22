---
id: FR-HTTP-001
title: Provide pure-Ridgun RFC 3986 URI parsing and RFC 9112 HTTP/1.1 request and response building, parsing, and header lookup
type: functional
status: implemented
priority: must
domain: HTTP
depends_on: []
related: [ADR-0002, VUL-INPUT-001]
tests: [TS-HTTP-001]
---
# FR-HTTP-001 — Provide pure-Ridgun RFC 3986 URI parsing and RFC 9112 HTTP/1.1 request and response building, parsing, and header lookup

## Statement
The `http` library SHALL provide pure-Ridgun RFC 3986 URI parsing (`uri parse`, `uri scheme`, `uri host`, `uri port`, `uri path`, `uri query`) and RFC 9112 HTTP/1.1 message construction, parsing, and inspection (`http status text`, `http build request`, `http build response`, `http parse request`, `http parse response`, `http parse headers`, `http header get`, `http bearer token`).

## Rationale
Web servers (`Solstice`), REST clients, and IPC services over `socket.rg` require deterministic HTTP/1.1 wire-format request/response serialization, case-insensitive header lookup, and URI decomposition without external C HTTP parsers.

## Acceptance criteria
- AC1: Given an RFC 3986 URL (`"https://api.example.com:8443/v1/users?active=1"` or `"http://localhost/health"`), when `uri parse` and its accessors are called, then they extract `scheme` (`"https"`), `host` (`"api.example.com"`), `port` (`8443`, or default `80`/`443`), `path` (`"/v1/users"`), and `query` (`"active=1"`).
- AC2: Given HTTP method, target path, headers `[(String, String)]`, and body, when `http build request`, `http parse request`, and `http parse headers` are called, then `http build request` formats a valid CRLF-delimited `HTTP/1.1` wire message (automatically sanitizing CR/LF in header names/values and computing `Content-Length` when body is non-empty), `http parse request` recovers `(method, path, body)`, and `http parse headers` recovers `[(String, String)]`.
- AC3: Given HTTP status code, headers, and body, when `http status text`, `http build response`, `http parse response`, `http parse headers`, `http header get`, and `http bearer token` are called, then `http parse response` recovers `(status_code, reason, body)`, `http header get` matches header names case-insensitively, and `http bearer token` extracts the token after `"Bearer "`.

## Actors & permissions
- Any Ridgun module importing `http`.

## Constraints & edge cases
- Header names/values passed to `http build request` or `http build response` have `\r` and `\n` stripped to prevent HTTP header/response splitting (`CRLF` injection).

## Data & privacy
- Pure in-memory protocol framing and parsing.

## Security & observability notes
- Mitigates `VUL-INPUT-001` by stripping `\r` and `\n` from HTTP header values (preventing CRLF response splitting) and validating status codes.

## Out of scope
- HTTP/2 binary HPACK framing.
