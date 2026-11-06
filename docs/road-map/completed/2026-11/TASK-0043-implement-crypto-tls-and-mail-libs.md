---
id: TASK-0043
title: Implement FR-CRYPTO-006 primitives in crypto.rg and implement tls.rg and mail.rg libraries
status: completed
created: 2026-11-06
completed: 2026-11-06
requirements: [FR-CRYPTO-006, API-CRYPTO-001, FR-TLS-001, API-TLS-001, DM-Tls, FR-MAIL-001, API-MAIL-001, DM-Mail]
tests: [TS-CRYPTO-006, TS-TLS-001, TS-MAIL-001]
security: [VUL-AUTHN-001, VUL-INPUT-001, VUL-INJ-002, VUL-AUTHN-004, VUL-INPUT-003, VUL-INJ-003]
context_files:
  - src/main/ridgun/lib/crypto.rg
  - src/main/ridgun/lib/tls.rg
  - src/main/ridgun/lib/mail.rg
  - src/test/ridgun/test crypto.rg
  - src/test/ridgun/test tls.rg
  - src/test/ridgun/test mail.rg
  - docs/requirements/functional/crypto/FR-CRYPTO-006-x25519-aes128gcm-hkdf-sha384-p256-p384-rsa-and-x509.md
  - docs/requirements/functional/tls/FR-TLS-001-tls13-and-tls12-client-and-x509-verification.md
  - docs/requirements/functional/mail/FR-MAIL-001-rfc5322-composition-and-smtp-tls-client.md
scope:
  - src/main/ridgun/lib/crypto.rg
  - src/main/ridgun/lib/tls.rg
  - src/main/ridgun/lib/mail.rg
  - src/test/ridgun/test crypto.rg
  - src/test/ridgun/test tls.rg
  - src/test/ridgun/test mail.rg
  - build.rg
  - docs/requirements/**
  - docs/tests/**
  - docs/security/**
owner: agent-001
claimed: 2026-11-06T19:17:49Z
claimed_by: claude claude@solarfall
policy:                     # empty = project default
---
# TASK-0043 — Implement FR-CRYPTO-006 primitives in crypto.rg and implement tls.rg and mail.rg libraries

## Goal (one sentence)
Implement `FR-CRYPTO-006` (SHA-384, HKDF, X25519, AES-128-GCM, ECDHE P-256, ECDSA P-256/P-384, RSA PKCS#1 v1.5/PSS verification, and ASN.1 DER / X.509 / PEM parsing) in `src/main/ridgun/lib/crypto.rg`, the `tls` client library (`src/main/ridgun/lib/tls.rg`, `FR-TLS-001`), and the `mail` RFC 5322 & SMTP over TLS library (`src/main/ridgun/lib/mail.rg`, `FR-MAIL-001`), along with their automated test suites and compiled library bundles.

## Plan
- [x] Create `FR-CRYPTO-006`, `FR-TLS-001`, `API-TLS-001`, `DM-Tls`, `FR-MAIL-001`, `API-MAIL-001`, `DM-Mail`, `TS-CRYPTO-006`, `TS-TLS-001`, and `TS-MAIL-001`.
- [x] Implement `FR-CRYPTO-006` in `src/main/ridgun/lib/crypto.rg` and verify `TS-CRYPTO-006` in `src/test/ridgun/test crypto.rg`.
- [x] Implement `src/main/ridgun/lib/tls.rg` (`FR-TLS-001`) and verify `TS-TLS-001` in `src/test/ridgun/test tls.rg` (RFC 8448 vectors, live servers, `badssl.com` rejection cases).
- [x] Implement `src/main/ridgun/lib/mail.rg` (`FR-MAIL-001`) and verify `TS-MAIL-001` in `src/test/ridgun/test mail.rg` (`mail render`, local Ridgun SMTP over TLS test server, STARTTLS/AUTH enforcement).
- [x] Update `build.rg`, build `.rglib` / `.rgc` / `.so` artifacts for `crypto`, `tls`, and `mail`, and run `aix docs validate`.
- [x] Apply the doc status flips and ADR-0005 amendments, then `aix docs coverage`.

## Progress log (append-only, newest last)
- 2026-11-06: Created requirements (`FR-CRYPTO-006`, `FR-TLS-001`, `FR-MAIL-001`), API contracts, data models, and test specifications (`TS-CRYPTO-006`, `TS-TLS-001`, `TS-MAIL-001`).
- 2026-11-06: (gemini, unlogged at the time) Implemented `FR-CRYPTO-006` in `crypto.rg` (~1 870 lines: SHA-384, HMAC-SHA-384, HKDF, X25519, AES-128-GCM, P-256/P-384, RSA PKCS#1 v1.5/PSS, PEM, ASN.1, X.509) and two `TS-CRYPTO-006` test functions.
- 2026-11-06: claude took over seat agent-001 (user confirmed gemini stopped). `CONFLICT-0002` (X509Cert field names vs `API-CRYPTO-001`) resolved by the user as option A → `ADR-0004`; code renamed to contract names.
- 2026-11-06: Added `TS-CRYPTO-006` gap tests (X25519 lengths, NIST GCM TC3/TC4, raw ECDSA, RSA SHA-384/512 + PSS-384, RSA/P-384/Ed25519 certs, CA-signed leaf).
- 2026-11-06: `CONFLICT-0003` (RFC 8448 1024-bit RSA vs 2048-bit floor) resolved by the user as option B → `ADR-0005`. Doc amendments to FR-TLS-001/TS-TLS-001/TS-CRYPTO-006 wait for write access to `docs/`.
- 2026-11-06: Moved stale untracked `src/main/ridgun/lib/crypto.rgc` / `crypto.rglib` (18:43 build) out of the source dir: they shadowed `crypto.rg` for `import crypto` from sibling libs.
- 2026-11-06: Implemented `tls.rg` (TLS 1.3 + 1.2 client, HRR, chain/expiry/hostname checks, RFC 8448 self-test) and `test tls.rg` (RFC 8448, PRF, chain unit cases, 7 local openssl s_server handshakes, 3 local failure cases, 8 live cases).
- 2026-11-06: Implemented `mail.rg` (RFC 5322 render with QP bodies, RFC 2047, dot-stuffing, SMTP over implicit TLS / mandatory STARTTLS, AUTH PLAIN/LOGIN only after TLS) and `test mail.rg` with a Ridgun SMTP + TLS 1.3 test server (Ed25519 cert).
- 2026-11-06: `build.rg` tasks include `tls` and `mail`; built bundles and `.so` for crypto, tls, mail. Added `VUL-AUTHN-004`, `VUL-INPUT-003`, `VUL-INJ-003` (`expected`) for the new attack surface; tls/mail markers point at them.
- 2026-11-06: Renamed files whose slugs held lowercase IDs (task file, ADR-0004, CONFLICT-0002) so `aix docs validate` passes.
- 2026-11-06: Applied doc status flips (FR → implemented, TS → automated) and ADR-0005 wording; fixed TS front matter (`verifies`/`test_files` → `covers`/`automated_in`) so the coverage matrix links them; coverage regenerated.

## Files changed (keep current)
- `src/main/ridgun/lib/crypto.rg`
- `src/test/ridgun/test crypto.rg`
- `src/main/ridgun/lib/tls.rg`
- `src/test/ridgun/test tls.rg`
- `src/main/ridgun/lib/mail.rg`
- `src/test/ridgun/test mail.rg`
- `build.rg`
- `docs/security/vulnerability-register.md`
- `src/test/ridgun/fixtures/tls/gen-certs.sh`
- `docs/requirements/decisions/ADR-0005-rfc8448-self-test-keeps-2048-bit-rsa-floor.md`
- `docs/conflicts/resolved/CONFLICT-0003-rfc8448-1024-bit-rsa-vs-2048-bit-floor.md`
- `docs/requirements/decisions/ADR-0004-x509cert-field-names-follow-the-crypto-contract.md`
- `docs/conflicts/resolved/CONFLICT-0002-x509cert-field-names-vs-the-crypto-contract.md`
- `docs/requirements/product/glossary.md`
- `docs/requirements/data-model/field-dictionary.md`
- `docs/requirements/functional/crypto/FR-CRYPTO-006-x25519-aes128gcm-hkdf-sha384-p256-p384-rsa-and-x509.md`
- `docs/requirements/functional/tls/FR-TLS-001-tls13-and-tls12-client-and-x509-verification.md`
- `docs/requirements/functional/mail/FR-MAIL-001-rfc5322-composition-and-smtp-tls-client.md`
- `docs/requirements/api/crypto/API-CRYPTO-001-crypto-and-argon2id-contract.md`
- `docs/requirements/api/tls/API-TLS-001-tls-module-contract.md`
- `docs/requirements/api/mail/API-MAIL-001-mail-module-contract.md`
- `docs/requirements/data-model/DM-Tls.md`
- `docs/requirements/data-model/DM-Mail.md`
- `docs/tests/functional/crypto/TS-CRYPTO-006-x25519-aes128gcm-hkdf-sha384-ecdsa-rsa-x509.md`
- `docs/tests/functional/tls/TS-TLS-001-tls13-rfc8448-live-handshake-and-badssl-rejection.md`
- `docs/tests/functional/mail/TS-MAIL-001-rfc5322-render-and-smtp-tls-client.md`

## Verification performed (command → result, newest last)
- `ridgunc check --strict src/main/ridgun/lib/crypto.rg` → 0 errors (545 functions).
- `ridgunc run "src/test/ridgun/test crypto.rg"` → `[PASS]` TS-CRYPTO-003/004/005/006, TS-PERF-001 (after ADR-0004 rename).
- `ridgunc run "src/test/ridgun/test crypto.rg"` → `[PASS]` with the new `test crypto006 edge cases and certs`.
- `ridgunc check --strict src/main/ridgun/lib/tls.rg` → 0 errors.
- `ridgunc run "src/test/ridgun/test tls.rg"` → `[PASS]` TS-TLS-001 (RFC 8448 28/28, local + live).
- `ridgunc run "src/test/ridgun/test mail.rg"` → `[PASS]` TS-MAIL-001 (render, 8 local SMTP scenarios, Gmail 587/465 → 530 without AUTH).
- `ridgunc run "src/test/ridgun/test socket.rg"` → all passed.
- `ridgunc run "src/test/ridgun/test tensor.rg"` → compile error `undefined function 'blocks'`; same failure on a clean `git archive HEAD` copy, so it predates this task.
- `ridgunc build --strict --so` for crypto, tls, mail → OK; `aix docs validate` → 0 errors, 0 warnings.
- `aix docs coverage` → FR-CRYPTO-006, FR-TLS-001, FR-MAIL-001, API-TLS-001, API-MAIL-001 all `ok`.

## Exact next actions
1. Once `docs/` is group-writable: run the pending doc edits (status flips FR-CRYPTO-006/FR-TLS-001/FR-MAIL-001 → implemented, TS-CRYPTO-006/TS-TLS-001/TS-MAIL-001 → automated, INDEX rows, ADR-0005 wording in FR-TLS-001, TS-TLS-001, TS-CRYPTO-006).
2. `aix docs coverage && aix docs validate`.
3. Commit (`feat(crypto,tls,mail): ...` with the IDs) after the user approves; then complete the task and release the seat.
4. Later: audit the new VUL rows (`security-audit`), which are `expected` until an audit report exists.

## Decisions / open questions
- All cryptographic and X.509/ASN.1/PEM primitives are placed in `crypto.rg` so `tls.rg` and any other lib can reuse them.
- `tls connect Socket` opens a kernel connection to the socket's `remote_addr`: the `socket.rg` `Socket` record is simulated and holds no kernel descriptor.
- Root lookup searches the PEM text for the base64 of the issuer name (3 alignments) and decodes only matching roots (full bundle decode costs ~2.6 s).
- ClientHello offers only an X25519 key share; servers that want P-256 get it through HelloRetryRequest (saves ~360 ms per handshake).
- Local TLS tests use `openssl s_server` as an independent peer with throwaway keys from `src/test/ridgun/fixtures/tls/gen-certs.sh`.

## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green
- [x] security entries updated  - [x] docs INDEX updated  - [x] coverage matrix regenerated
