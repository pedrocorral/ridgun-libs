---
id: ADR-0005
title: RFC 8448 self-test keeps the 2048-bit RSA floor
status: accepted
date: 2026-11-06
supersedes: []
affects: [FR-TLS-001, TS-TLS-001, TS-CRYPTO-006, src/main/ridgun/lib/tls.ridgun]
---
# ADR-0005 — RFC 8448 self-test keeps the 2048-bit RSA floor

## Context
`CONFLICT-0003`: RFC 8448 §3 signs `CertificateVerify` with a 1024-bit RSA key (RFC 8448 §2).
`FR-CRYPTO-006` AC5 requires RSA verification to reject keys under 2048 bits.
`FR-TLS-001` AC1 required the RFC 8448 `CertificateVerify` to verify.
`TS-CRYPTO-006` called the RFC 8448 key "2048-bit", which is wrong.

## Options considered
1. Add a second RSA-PSS path with a caller-given minimum key size, used only by the self-test.
2. Keep one RSA path with the 2048-bit floor; the self-test expects the 1024-bit `CertificateVerify` to be rejected.

## Decision
Option 2, chosen by the user on 2026-11-06.
`crypto.ridgun` keeps exactly one RSA verification path, and it rejects keys under 2048 bits.
RSA-PSS correctness is proven by the 2048-bit vectors in `TS-CRYPTO-006`.

## Consequences
- Requirements to update: `FR-TLS-001` AC1 (the RFC 8448 `CertificateVerify` must be rejected by the 2048-bit floor; every other value must match).
- Tests to update: `TS-TLS-001` case 1; `TS-CRYPTO-006` case 5 wording (2048-bit RSA-PSS vectors are generated, not from RFC 8448).
- Code to update: `tls13 rfc8448 self test` in `tls.ridgun` asserts the rejection.
