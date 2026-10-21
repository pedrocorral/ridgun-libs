---
id: FR-CODEC-001
title: Provide pure-Ridgun Hex, Base64/Base64url, URL percent-encoding, query strings, and lightweight JSON formatting and key extraction
type: functional
status: implemented
priority: must
domain: CODEC
depends_on: []
related: [ADR-0002, VUL-INPUT-001]
tests: [TS-CODEC-001]
---
# FR-CODEC-001 — Provide pure-Ridgun Hex, Base64/Base64url, URL percent-encoding, query strings, and lightweight JSON formatting and key extraction

## Statement
The `codec` library SHALL provide pure-Ridgun RFC 4648 Hex (`hex encode`, `hex decode`, `is valid hex`), Standard Base64 with `=` padding (`base64 encode`, `base64 decode`, `is valid base64`), and URL-safe Base64url without padding (`base64url encode`, `base64url decode`), RFC 3986 URL percent-encoding (`url encode`, `url decode`, `query string encode`, `query string decode`), and RFC 8259 lightweight JSON formatting and field extraction (`json escape`, `json unescape`, `json quote`, `json int`, `json bool`, `json null`, `json array`, `json object`, `json get str`, `json get int`, `json get bool`).

## Rationale
Networking services (`socket.rg`), cryptographic payloads (`crypto.rg`), and configuration/IPC protocols require standardized text encodings and lightweight JSON serialization without external C libraries.

## Acceptance criteria
- AC1: Given arbitrary strings, when `hex encode`/`hex decode`, `base64 encode`/`base64 decode`, and `base64url encode`/`base64url decode` are called, then they match RFC 4648 test vectors (`""`, `"f"`, `"fo"`, `"foo"`, `"foob"`, `"fooba"`, `"foobar"`) and reject invalid hex/Base64 inputs cleanly (returning `""` on malformed input and `False` on `is valid hex`/`is valid base64`).
- AC2: Given strings with reserved characters and key-value lists `[(String, String)]`, when `url encode`, `url decode`, `query string encode`, and `query string decode` are called, then unreserved RFC 3986 characters (`A-Z`, `a-z`, `0-9`, `-`, `_`, `.`, `~`) remain literal, all other bytes are percent-encoded as `%XX`, and `query string decode (query string encode pairs)` round-trips all key-value pairs.
- AC3: Given strings, primitives, and `[(String, String)]` fields, when `json escape`, `json unescape`, `json quote`, `json object`, `json array`, `json get str`, `json get int`, and `json get bool` are called, then special characters (`"`, `\`, `\n`, `\r`, `\t`) are properly escaped/unescaped, valid JSON objects/arrays are produced, and top-level string/integer/boolean fields are accurately extracted (returning fallback defaults when a key is absent).

## Actors & permissions
- Any Ridgun module importing `codec`.

## Constraints & edge cases
- `hex decode` accepts both uppercase (`A-F`) and lowercase (`a-f`) hex digits and rejects odd-length strings or non-hex characters by returning `""`.
- `url decode` decodes both `%XX` and `+` (as space `' '` in query strings) and safely preserves literal `%` if not followed by 2 valid hex digits.

## Data & privacy
- Pure in-memory string and byte transformations.

## Security & observability notes
- Mitigates `VUL-INPUT-001` by validating hex/Base64 alphabets and escaping JSON control characters (`"`, `\`, `\n`, `\r`, `\t`) to prevent JSON injection.

## Out of scope
- Full recursive AST DOM parser for deeply nested arbitrary JSON schemas.
