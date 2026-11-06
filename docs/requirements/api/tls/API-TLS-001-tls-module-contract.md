---
id: API-TLS-001
title: Public API Contract for tls.rg
status: approved
domain: TLS
implements: [FR-TLS-001]
verified_by: [TS-TLS-001]
---
# API-TLS-001 — Public API Contract for `tls.rg`

## Module
`src/main/ridgun/lib/tls.rg` (`module :: tls`)

## Types
- `type TlsConfig = root_certs_path: String, root_certs_pem: String, alpn_protocols: [String], min_version: Int, max_version: Int, timeout_ms: Int, verify_time_sec: Int`
- `type TlsConn = fd: Int, server_name: String, tls_version: Int, cipher_suite: Int, selected_alpn: String, c_key: String, c_iv: String, s_key: String, s_iv: String, timeout_ms: Int, state: Tensor[U64 * 16], rx_buf: Tensor[U64 * 65536]`
- `type TlsError = TlsCertExpired String | TlsHostnameMismatch String | TlsInvalidChain String | TlsUnsupportedVersion String | TlsServerAlert Int String | TlsTimeout String | TlsIoError String`
- `type TlsResult = TlsOk TlsConn | TlsErr TlsError`

## Public Functions
- `fn :: tls defaults => TlsConfig`
- `fn :: tls with roots TlsConfig String => TlsConfig`
- `fn :: tls with root pem TlsConfig String => TlsConfig`
- `fn :: tls with alpn TlsConfig [String] => TlsConfig`
- `fn :: tls with timeout TlsConfig Int => TlsConfig`
- `fn :: tls with verify time TlsConfig Int => TlsConfig`
- `fn :: tls connect Socket String TlsConfig => TlsResult`
- `fn :: tls connect fd Int String TlsConfig => TlsResult`
- `fn :: tls connect host String Int TlsConfig => TlsResult`
- `fn :: tls send TlsConn String => Int`
- `fn :: tls recv TlsConn Int => String`
- `fn :: tls close TlsConn => ()`
- `fn :: tls is ok TlsResult => Bool`
- `fn :: tls unwrap TlsResult => TlsConn`
- `fn :: tls error kind TlsResult => String`
- `fn :: tls error reason TlsResult => String`
- `fn :: tls verify chain [String] String TlsConfig => Bool TlsError`
- `fn :: tls13 rfc8448 self test => Bool`
