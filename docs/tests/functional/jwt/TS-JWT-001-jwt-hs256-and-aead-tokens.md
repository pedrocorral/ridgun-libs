---
id: TS-JWT-001
title: Verify RFC 7519 HS256 JWT and ChaCha20-Poly1305 encrypted token signing, constant-time verification, and claim validation
level: unit
covers: [FR-JWT-001, API-JWT-001]
status: automated
automated_in: ["src/test/ridgun/test jwt.ridgun"]
---
# TS-JWT-001 — Verify RFC 7519 HS256 JWT and ChaCha20-Poly1305 encrypted token signing, constant-time verification, and claim validation

## Preconditions / fixtures
- Pure-Ridgun `jwt` and `test` modules (`src/main/ridgun/lib/jwt.ridgun`, `src/main/ridgun/lib/test.ridgun`).

## Steps / inputs
1. Sign payloads and `JwtClaims` (`iss`, `sub`, `exp`, `nbf`) with `jwt sign hs256` and `jwt sign claims`; verify `jwt decode payload` and `jwt verify hs256`.
2. Test `jwt verify claims` with valid `now`, expired `now >= exp`, premature `now < nbf`, wrong secret, tampered payload, and `alg: none` tokens.
3. Seal and open confidential tokens via `jwt seal aead` and `jwt open aead` and verify tampered ciphertexts are rejected.
4. Encode the bytes `[0, 128, 255]` (`Tensor[U8]`, ADR-0010) with `jwt b64url enc bytes` and decode them back; check RFC 4648 vectors; sign, verify and decode a UTF-8 payload, and seal and open a UTF-8 plaintext.
5. Standard vectors: RFC 4231 test case 2 through `jwt hmac sha256 b64url`; the RFC 7515 A.1 token verifies with its key; sealing the RFC 8439 §2.8.2 plaintext with its key and nonce gives the RFC ciphertext, and the token equals `crypto`'s `aead seal` with AAD `RGAEAD2.<nonce>`; an `RGAEAD1` token is rejected.

## Expected results (map to acceptance criteria)
- AC1 → `jwt sign*` produces valid 3-part Base64url `HS256` tokens.
- AC2 → `jwt verify*` accepts valid unexpired tokens and rejects tampered, expired, or wrong-secret tokens.
- AC3 → `jwt seal aead` and `jwt open aead` encrypt, authenticate, and decrypt payloads accurately.
- AC1, AC2, AC3 → bytes 0, 128 and 255 and UTF-8 text round-trip byte for byte.
- AC2, AC3 → step 5 matches RFC 4231, RFC 7515 A.1 and RFC 8439 (ADR-0011).

## Not covered here (to avoid duplication)
- Low-level SHA-256 and ChaCha20-Poly1305 test vectors (`TS-CRYPTO-003`, `TS-CRYPTO-004`).
