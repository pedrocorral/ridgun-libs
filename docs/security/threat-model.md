---
id: SEC-THREAT-MODEL
title: Threat model
status: approved
---
# Threat model

## Assets (what we protect)
- **Password, Key, Nonce & Tag Material (`CRYPTO`)**: Plaintext passwords, salts, PBKDF2/Argon2id derived keys, ChaCha20 32-byte keys, 12-byte nonces, Poly1305/HMAC authentication tags, and PHC encoded strings processed by `argon2id` and `crypto`.
- **Socket & File Descriptors (`SOCK`, `POSIX`, `IO`)**: Local and remote TCP/UDP/Unix socket descriptors, file-backed Unix socket paths, OS pipes, watched signal descriptors, and payload buffers.
- **Kernel Entropy & Process Lifecycle (`POSIX`, `IO`)**: CSPRNG byte streams (`sys_random_bytes`), monotonic timeout deadlines, and spawned external command processes (`io exec timeout`).

## Actors (who might attack, incl. insiders and automated agents)
- **Remote Network Peer**: Sends malformed frames, oversized payloads, tampered AEAD ciphertexts/tags, or stalls connections to exhaust descriptors/threads.
- **Offline / Timing Side-Channel Attacker**: Attempts password cracking against Argon2id/PBKDF2 hashes or timing side-channel attacks against HMAC, Poly1305, or Argon2id tag verification.
- **Untrusted Caller Input**: Passes unsafe hostnames, Unix socket paths (`..`), null bytes, negative byte counts, or out-of-range cryptographic parameters (`m_cost`, `t_cost`, `lanes`, `tag_len`, key/nonce lengths).

## Trust boundaries & data flows
- Caller application → `socket.ridgun` public API → OS socket/IPC boundary (validates address, port `1..65535`, Unix path safety, and `sys poll` timeout bounds before any OS operation).
- Caller application → `argon2id.ridgun` & `crypto.ridgun` public API (validates RFC 9106 / RFC 8439 parameter and key/nonce lengths and performs constant-time byte/tag comparison via `ct_equal` / `constant time eq`).
- Caller application → `posix.ridgun` & `io.ridgun` public API → Linux kernel (`sys open`, `sys poll`, `sys read fd`, `sys write fd`, `sys kill`, `sys call`).

## Component tags
- `src/main/ridgun/lib/socket.ridgun`: `internet-facing`
- `src/main/ridgun/lib/argon2id.ridgun`: `internal`
- `src/main/ridgun/lib/crypto.ridgun`: `internal`
- `src/main/ridgun/lib/posix.ridgun`: `internal`
- `src/main/ridgun/lib/io.ridgun`: `internal`
- `src/main/ridgun/lib/str.ridgun`: `internal`
- `src/main/ridgun/lib/test.ridgun`: `internal`

## Assumptions & accepted risks (link ADRs)
- Pure-Ridgun (`v0.9.3`) library stack (`ADR-0001`, `ADR-0002`).
