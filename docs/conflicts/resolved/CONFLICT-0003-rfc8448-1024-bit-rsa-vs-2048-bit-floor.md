---
id: CONFLICT-0003
title: RFC 8448 CertificateVerify uses a 1024-bit RSA key, but RSA verification must reject keys under 2048 bits
status: resolved            # open | resolved
date: 2026-11-06
affects: [FR-TLS-001, TS-TLS-001, FR-CRYPTO-006, TS-CRYPTO-006, src/main/ridgun/lib/tls.rg, src/main/ridgun/lib/crypto.rg]
adr: ADR-0005
---
# CONFLICT-0003 — RFC 8448 CertificateVerify uses a 1024-bit RSA key, but RSA verification must reject keys under 2048 bits

## Conflict
- `FR-TLS-001` AC1: "Given the RFC 8448 §3 TLS 1.3 1-RTT example trace, when ... `CertificateVerify` RSA-PSS verification ... are executed, then every intermediate secret, key, IV, and record matches RFC 8448 §3 bit-for-bit."
- `FR-CRYPTO-006` AC5: `rsa verify pkcs1` and `rsa verify pss` "reject any key smaller than 2048 bits (`str len n_be < 256`)".
- `TS-CRYPTO-006` case 5 says "RFC 8448 2048-bit RSA-PSS (`rsa_pss_rsae_sha256`)".
- RFC 8448 §2 gives the server RSA modulus as 128 bytes (1024 bits). Source: https://www.rfc-editor.org/rfc/rfc8448.txt, section 2.
- `src/main/ridgun/lib/crypto.rg` (`rsa verify pss inner`) returns `False` when the modulus is under 256 bytes.

| Requirement says | Code / other spec does | Impact if we follow the requirement |
|---|---|---|
| `FR-TLS-001` AC1: verify the RFC 8448 `CertificateVerify` RSA-PSS signature | `FR-CRYPTO-006` AC5 and `crypto.rg` reject the 1024-bit RFC 8448 key | One of the two ACs must break, or a second RSA path that accepts 1024-bit keys must exist |
| `TS-CRYPTO-006` case 5: "RFC 8448 2048-bit RSA-PSS" | The RFC 8448 key is 1024-bit | The test-spec text is factually wrong |

## Options and consequences
- A. Change code: add a crypto function that verifies RSA-PSS with a caller-given minimum key size, and use it only in `tls13 rfc8448 self test`. Cost: one small function. Risk: a weaker RSA path exists in the lib and another caller could use it.
- B. Change requirement (ADR): `FR-TLS-001` AC1 checks every RFC 8448 secret, key, IV, record and `Finished` value, and checks that the 1024-bit `CertificateVerify` is **rejected** by the 2048-bit floor. RSA-PSS correctness stays covered by the 2048-bit vectors in `TS-CRYPTO-006`. Fix the `TS-CRYPTO-006` wording. Cost: doc edits and an ADR. Risk: none for security; the RFC 8448 signature bytes are not checked as valid.
- C. Split: not useful here.

## Agent recommendation
Option B. It keeps exactly one RSA verification path with the 2048-bit floor, which matches `FR-TLS-001` AC4 (no path that weakens verification).

## Human decision
Option B, chosen by the user on 2026-11-06.

## Resolution evidence (ADR, commits, tests)
- `ADR-0005-rfc8448-self-test-keeps-2048-bit-rsa-floor.md` (accepted).
- `FR-TLS-001` AC1, `TS-TLS-001` case 1 and `TS-CRYPTO-006` case 5 amended.
- `tls13 rfc8448 self test` asserts the rejection (see `TASK-0043` verification log).
