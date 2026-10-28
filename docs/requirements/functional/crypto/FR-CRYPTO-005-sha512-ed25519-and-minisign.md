---
id: FR-CRYPTO-005
title: Provide FIPS 180-4 SHA-512, RFC 8032 §5.1 pure Ed25519 signatures, and Minisign public-key and signature formats
type: functional
status: implemented
priority: must
domain: CRYPTO
depends_on: [FR-CRYPTO-003, FR-CRYPTO-004]
related: [ADR-0002, VUL-AUTHN-001, VUL-INPUT-001]
tests: [TS-CRYPTO-005]
---
# FR-CRYPTO-005 — Provide FIPS 180-4 SHA-512, RFC 8032 §5.1 pure Ed25519 signatures, and Minisign public-key and signature formats

## Statement
The `crypto` library (`src/main/ridgun/lib/crypto.rg`) SHALL provide 100% pure-Ridgun FIPS 180-4 SHA-512 (`sha512 bytes String => String` and `sha512 hex String => String`), RFC 8032 §5.1 pure Ed25519 digital signatures (`ed25519 public key String => String`, `ed25519 sign String String => String`, and `ed25519 verify String String String => Bool`), and Minisign public-key and `.minisig` signature encoding and verification (`minisign encode pubkey String String => String`, `minisign decode pubkey String => String String`, `minisign sign String String String String String => String`, and `minisign verify String String String => Bool`).

## Rationale
`www-ridgun` (`tools/publish-release.sh`, install instructions) and `omni` need to sign and verify toolchain and library releases (`SHA256SUMS`) against an offline Ed25519 key so that even a compromised download server cannot forge a release checksum (`www-ridgun VUL-DATA-003`). Supporting both raw RFC 8032 Ed25519 and standard Minisign `.minisig` files allows signatures to be verified both by pure-Ridgun tools (`omni`) and by the standard `minisign` CLI.

## Acceptance criteria
- AC1: Given an arbitrary byte string `msg` (`0x00..0xFF`), when `sha512 bytes msg` and `sha512 hex msg` are called, then `sha512 bytes` returns the 64-byte FIPS 180-4 SHA-512 raw digest (`str len == 64`) and `sha512 hex` returns the 128-character lowercase hexadecimal digest, matching the FIPS 180-4 test vectors for `""`, `"abc"`, the 448-bit message, the 896-bit message, and one million `"a"` characters.
- AC2: Given a 32-byte secret `seed` and an arbitrary byte string `msg`, when `ed25519 public key seed` and `ed25519 sign seed msg` are called, then `ed25519 public key` returns the 32-byte compressed Twisted Edwards public key `A` (`str len == 32`) using constant-time scalar multiplication without branching on secret scalar bits, and `ed25519 sign` returns the 64-byte RFC 8032 §5.1 signature `R || S` (`str len == 64`), matching all five RFC 8032 §7.1 test vectors (empty message, 1-byte `0x72`, 2-byte `0xaf82`, 1023-byte message, and `SHA-1("abc")`) bit-for-bit; if `str len seed != 32`, both functions return `""`.
- AC3: Given a `pubkey` (32 B), `msg`, and `sig` (64 B), when `ed25519 verify pubkey msg sig` is called, then it returns `True` if and only if `pubkey` and `R` decode to valid points on $-x^2 + y^2 \equiv 1 - (121665/121666) x^2 y^2 \pmod{2^{255}-19}$ with canonical $y < 2^{255}-19$, $0 \le S < L = 2^{252} + 27742317777372353535851937790883648493$ (rejecting non-canonical $S \ge L$), and $[8][S]B = [8]R + [8][k]A$; and returns `False` without crashing on any flipped bit in `msg`, `sig`, or `pubkey`, on $S \ge L$, on non-curve points, or on wrong input lengths.
- AC4: Given a 32-byte `seed`, 8-byte `key_id`, `msg`, `untrusted_comment`, and `trusted_comment`, when `minisign encode pubkey key_id (ed25519 public key seed)` and `minisign sign seed key_id msg untrusted_comment trusted_comment` are called, then they produce standard Minisign base64 public-key text (`untrusted comment: ...\nRW...`) and 4-line `.minisig` signature text (`Ed` pure Ed25519 algorithm + `trusted comment: ...` + global Ed25519 signature over `sig || trusted_comment`), and `minisign verify pubkey_text msg minisig_text` verifies both the payload signature, key ID, and trusted-comment global signature (returning `False` on any tampering).

## Actors & permissions
- Any Ridgun program or lib (`omni`, `www-ridgun`, `jwt`, etc.) importing `crypto`.

## Constraints & edge cases
- Signing or verifying a message must complete in well under 1 second on x86-64.
- Secret scalar multiplication in `ed25519 public key` and `ed25519 sign` must use arithmetic constant-time conditional swap (`cswap`) without branching on secret scalar bits.
- `ed25519 verify` and `minisign verify` must never crash or raise an unhandled error on malformed, truncated, or adversarial inputs.

## Data & privacy
- Secret 32-byte seeds and expanded scalar clamping stay local to the function scope and are reclaimed deterministically under `RMM2`.

## Security & observability notes
- Mitigates `VUL-AUTHN-001` (RFC 8032 §5.1 strict $S < L$ non-malleability and constant-time secret scalar ladder) and `VUL-INPUT-001` (strict length and canonical field/point decoding).

## Out of scope
- Ed25519ctx and Ed25519ph (prehashed SHA-512) variants from RFC 8032 §5.1 (Minisign legacy `"ED"` prehashed mode is rejected in favor of `"Ed"` pure Ed25519).
