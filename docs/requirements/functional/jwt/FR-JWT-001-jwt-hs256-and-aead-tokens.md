---
id: FR-JWT-001
title: Provide RFC 7519 HS256 JWT and ChaCha20-Poly1305 encrypted token signing, constant-time verification, and claim validation
type: functional
status: implemented
priority: must
domain: JWT
depends_on: []
related: [ADR-0002, DM-Jwt, API-JWT-001, VUL-AUTHN-001, VUL-INPUT-001]
tests: [TS-JWT-001]
---
# FR-JWT-001 — Provide RFC 7519 HS256 JWT and ChaCha20-Poly1305 encrypted token signing, constant-time verification, and claim validation

## Statement
The `jwt` library SHALL provide RFC 7519 `HS256` (`HMAC-SHA256`) JSON Web Token creation (`jwt sign hs256`, `jwt sign claims`), constant-time signature verification and claim validation (`jwt verify hs256`, `jwt verify claims`), unverified header/payload inspection (`jwt decode payload`), and ChaCha20-Poly1305 AEAD encrypted token sealing and opening (`jwt seal aead`, `jwt open aead`).

## Rationale
HTTP services and distributed agents require standard stateless authentication tokens (`HS256` JWT) and confidential AEAD-sealed tokens with strict algorithm enforcement and constant-time MAC verification.

## Acceptance criteria
- AC1: Given a secret key and payload/claims (`iss`, `sub`, `exp`, `nbf`), when `jwt sign hs256` or `jwt sign claims` is called, then it produces a 3-part Base64url `header.payload.signature` token whose header is `{"alg":"HS256","typ":"JWT"}`.
- AC2: Given a signed token, secret key, and current timestamp `now`, when `jwt verify hs256` or `jwt verify claims` is called, then it verifies the `HS256` header, checks the HMAC-SHA256 signature in constant time, enforces `nbf <= now < exp`, and rejects tampered tokens, wrong secrets, expired tokens, or `alg: none`.
- AC3: Given a 32-byte key, 12-byte nonce, and payload, when `jwt seal aead` and `jwt open aead` are called, then the payload is encrypted and authenticated with RFC 8439 ChaCha20-Poly1305 and round-trips losslessly.

## Actors & permissions
- Any Ridgun program or lib importing `jwt`.

## Constraints & edge cases
- Rejects any token that does not have exactly 3 `.`-separated non-empty Base64url segments or whose `alg` is not `"HS256"`.

## Data & privacy
- Secret keys are never logged or embedded in error strings.

## Security & observability notes
- Mitigates `VUL-AUTHN-001` (algorithm confusion and timing side channels) and `VUL-INPUT-001`.

## Out of scope
- RSA/ECDSA asymmetric key pairs.
