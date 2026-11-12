---
id: DM-Tls
title: TLS Configuration, Connection State, and Typed Error Model
status: approved
domain: TLS
implements: [FR-TLS-001]
verified_by: [TS-TLS-001]
---
# DM-Tls — TLS Configuration, Connection State, and Typed Error Model

## Overview
Defines the configuration (`TlsConfig`), active encrypted session (`TlsConn`), and typed failure reason (`TlsError`, `TlsResult`) ADTs in `src/main/ridgun/lib/tls.rg`.

## Algebraic Data Types
- `TlsConfig`: `root_certs_path`, `root_certs_pem`, `alpn_protocols`, `min_version`, `max_version`, `timeout_ms`, `verify_time_sec`.
- `TlsConn`: `fd`, `server_name`, `tls_version`, `cipher_suite`, `selected_alpn`, `c_key`, `c_iv`, `s_key`, `s_iv`, `io_timeout_ms` (the I/O timeout of every send and receive), `state` (`Tensor[U64 * 16]` holding sequence numbers and flags), `rx_buf` (`Tensor[U64 * 65536]` holding buffered decrypted bytes).
- `TlsError`: `TlsCertExpired String | TlsHostnameMismatch String | TlsInvalidChain String | TlsUnsupportedVersion String | TlsServerAlert Int String | TlsTimeout String | TlsIoError String`.
- `TlsResult`: `TlsOk TlsConn | TlsErr TlsError`.
