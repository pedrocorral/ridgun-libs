---
id: TS-CODEC-001
title: Verify RFC 4648 Hex/Base64/Base64url, RFC 3986 URL/query-string encoding, and RFC 8259 JSON formatting and extraction
level: unit
covers: [FR-CODEC-001, API-CODEC-001]
status: automated
automated_in: [src/test/ridgun/test codec.rg]
---
# TS-CODEC-001 — Verify RFC 4648 Hex/Base64/Base64url, RFC 3986 URL/query-string encoding, and RFC 8259 JSON formatting and extraction

## Preconditions / fixtures
- Pure-Ridgun `codec` module (`src/main/ridgun/lib/codec.rg`).

## Steps / inputs
1. Verify RFC 4648 test vectors (`""`, `"f"`, `"fo"`, `"foo"`, `"foob"`, `"fooba"`, `"foobar"`) for `hex encode`/`hex decode`, `base64 encode`/`base64 decode`, and `base64url encode`/`base64url decode`, plus invalid input rejection (`is valid hex`, `is valid base64`).
2. Verify `url encode`, `url decode`, `query string encode`, and `query string decode` on reserved characters (`"hello world&x=1+2%"`) and multi-pair query strings.
3. Verify `json escape`, `json unescape`, `json quote`, `json object`, `json str object`, `json array`, `json get str`, `json get int`, and `json get bool` across valid and missing keys.

## Expected results (map to acceptance criteria)
- AC1 → All RFC 4648 Hex, Base64, and Base64url vectors match bit-for-bit and invalid inputs return `""`/`False`.
- AC2 → URL percent-encoding and query-string encoding/decoding round-trip all characters and pairs accurately.
- AC3 → JSON escaping, formatting, and field extraction (`json get str`, `json get int`, `json get bool`) return exact values and fallback defaults on missing keys.

## Not covered here (to avoid duplication)
- Raw binary `byte_str` (`0..255`) lookup tables are covered in `TS-CRYPTO-003`.
