# decisions/ — Architecture Decision Records
Accepted ADRs are settled: do not re-open a decision ("should we switch to Mongo?") unless the user asks or a requirement makes it impossible; then write a superseding ADR. Read this when: asking "why is it like this?" or after any conflict ruling. Skip when: the ADR list does not touch your area (check `affects`).

| Path | What | Status |
|---|---|---|
| `ADR-0001-adopt-aix-and-choose-stack.md` | Adopt AIX; choose pure-Ridgun `stable` single-root library stack | accepted |
| `ADR-0002-adopt-solstice-and-posix-io-specs.md` | Adopt Solstice runtime requirements and POSIX/IO library specifications across `ridgun-libs` | accepted |
| `ADR-0003-solstice-2026-10-24-kdf-speed-kv-names-and-json-hardening.md` | Adopt Solstice 2026-10-24 KDF speed bounds, library-prefixed KV names, and RFC 8259 JSON hardening | accepted |
| `ADR-0004-x509cert-field-names-follow-the-crypto-contract.md` | `X509Cert` field names follow `API-CRYPTO-001` (`CONFLICT-0002`) | accepted |
| `ADR-0005-rfc8448-self-test-keeps-2048-bit-rsa-floor.md` | RFC 8448 self-test keeps the 2048-bit RSA floor (`CONFLICT-0003`) | accepted |
| `ADR-0006-tensor-bitwise-functions-use-bit-prefixed-names.md` | Tensor bitwise functions use bit-prefixed names (`CONFLICT-0004`) | accepted |
