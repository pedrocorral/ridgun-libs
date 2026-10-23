---
id: TS-JWT-001
title: Verify RFC 7519 HS256 JWT and ChaCha20-Poly1305 encrypted token signing, constant-time verification, and claim validation
level: unit
covers: [FR-JWT-001, API-JWT-001]
status: automated
automated_in: ["src/test/ridgun/test jwt.rg"]
---
# TS-JWT-001 — Verify RFC 7519 HS256 JWT and ChaCha20-Poly1305 encrypted token signing, constant-time verification, and claim validation

## Preconditions / fixtures
- Pure-Ridgun `jwt` and `test` modules (`src/main/ridgun/lib/jwt.rg`, `src/main/ridgun/lib/test.rg`).

## Steps / inputs
1. Sign payloads and `JwtClaims` (`iss`, `sub`, `exp`, `nbf`) with `jwt sign hs256` and `jwt sign claims`; verify `jwt decode payload` and `jwt verify hs256`.
2. Test `jwt verify claims` with valid `now`, expired `now >= exp`, premature `now < nbf`, wrong secret, tampered payload, and `alg: none` tokens.
3. Seal and open confidential tokens via `jwt seal aead` and `jwt open aead` and verify tampered ciphertexts are rejected.

## Expected results (map to acceptance criteria)
- AC1 → `jwt sign*` produces valid 3-part Base64url `HS256` tokens.
- AC2 → `jwt verify*` accepts valid unexpired tokens and rejects tampered, expired, or wrong-secret tokens.
- AC3 → `jwt seal aead` and `jwt open aead` encrypt, authenticate, and decrypt payloads accurately.

## Not covered here (to avoid duplication)
- Low-level SHA-256 and ChaCha20-Poly1305 test vectors (`TS-CRYPTO-003`, `TS-CRYPTO-004`).
