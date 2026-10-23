---
id: TS-HTTP-001
title: Verify RFC 3986 URI parsing, HTTP/1.1 request/response building and parsing, case-insensitive headers, and CRLF sanitization
level: unit
covers: [FR-HTTP-001, API-HTTP-001]
status: automated
automated_in: [src/test/ridgun/test http.rg]
---
# TS-HTTP-001 — Verify RFC 3986 URI parsing, HTTP/1.1 request/response building and parsing, case-insensitive headers, and CRLF sanitization

## Preconditions / fixtures
- Pure-Ridgun `http` module (`src/main/ridgun/lib/http.rg`).

## Steps / inputs
1. Call `uri parse`, `uri scheme`, `uri host`, `uri port`, `uri path`, and `uri query` on explicit-port and default-port HTTP/HTTPS URLs.
2. Call `http build request`, `http parse request`, `http header get`, and `http bearer token` on a `POST /v1/login` request with `Authorization: Bearer tok_123` and JSON body.
3. Call `http status text`, `http build response`, and `http parse response` on `200 OK` and `404 Not Found` responses, and verify CRLF injection characters in header values are stripped.

## Expected results (map to acceptance criteria)
- AC1 → URI components (`scheme`, `host`, `port`, `path`, `query`) are extracted accurately.
- AC2 → HTTP/1.1 requests round-trip method, path, headers, and body with CRLF sanitization.
- AC3 → HTTP/1.1 responses, status texts, case-insensitive headers, and Bearer tokens match expected values.

## Not covered here (to avoid duplication)
- Kernel TCP socket transport is covered in `TS-SOCK-004`.
