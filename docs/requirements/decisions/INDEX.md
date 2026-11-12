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
| `ADR-0007-libs-reach-the-kernel-only-through-the-posix-bridge.md` | Libs reach the kernel only through the posix per-architecture bridge | accepted |
| `ADR-0008-linalg-computes-with-real.md` | linalg computes with Real, not with integers in Real tensors | accepted |
| `ADR-0009-hashmap-is-updated-in-place.md` | hashmap is updated in place and lists keys in insertion order | accepted |
| `ADR-0010-bytes-are-tensor-u8.md` | Byte sequences in libs are Tensor[U8], not lists of Int or memfd buffers | accepted |
| `ADR-0011-jwt-uses-the-standard-hmac-and-aead.md` | jwt uses the crypto lib's HMAC-SHA256 and ChaCha20-Poly1305 | accepted |
| `ADR-0012-generic-list-helpers-come-from-the-prelude.md` | Generic list helpers and str join come from the compiler prelude | accepted |
| `ADR-0013-x86-64-uses-the-runtime-net-and-file-operations.md` | On x86-64, socket and posix use the runtime's net and file operations | accepted |
