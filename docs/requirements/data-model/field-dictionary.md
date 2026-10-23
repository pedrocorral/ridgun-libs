---
id: DATA-FIELD-DICTIONARY
title: Canonical field dictionary
status: approved
---
# Canonical field dictionary

**The only field names that exist.** Every name used in a `DM-*`, an `API-*`, `shared/` schemas, ORM mappings and DTOs must appear here with the same spelling and type. No synonyms (`customer_id` vs `client_id`), no per-layer renames. Add a row before using a name; `aix docs validate` warns on API/DM field names missing from this table.

Conventions: `snake_case`; ids end in `_id`; timestamps end in `_at` (UTC ISO-8601); booleans start with `is_`/`has_`; money as `<name>_minor` + `<name>_currency`; counts end in `_count`.

| Field | Type | Meaning | Owner (DM) | Also used by (API/others) |
|---|---|---|---|---|
| sock_id | Int | Socket handle identifier | SOCK | `socket.rg` |
| family | String | Socket address family (`inet`, `inet6`, `unix`) | SOCK | `socket.rg` |
| sock_type | String | Socket transport type (`stream`, `dgram`) | SOCK | `socket.rg` |
| host | String | IPv4/IPv6 address or hostname | SOCK | `socket.rg` |
| port | Int | TCP/UDP port number (`0..65535`) | SOCK | `socket.rg` |
| path | String | Filesystem path for `AF_UNIX` socket or file operation | SOCK | `socket.rg`, `posix.rg`, `io.rg` |
| timeout_ms | Int | Read/write/connect/poll/process timeout in milliseconds (`-1` infinite, `0` non-blocking, `>0` deadline) | SOCK | `socket.rg`, `posix.rg`, `io.rg` |
| reuse_addr | Bool | `SO_REUSEADDR` option flag | SOCK | `socket.rg` |
| keep_alive | Bool | `SO_KEEPALIVE` option flag | SOCK | `socket.rg` |
| non_blocking | Bool | Non-blocking descriptor/socket mode flag | SOCK | `socket.rg`, `posix.rg` |
| tcp_nodelay | Bool | `TCP_NODELAY` Nagle algorithm disable flag | SOCK | `socket.rg` |
| broadcast | Bool | `SO_BROADCAST` UDP broadcast permission flag | SOCK | `socket.rg` |
| rcvbuf | Int | `SO_RCVBUF` receive buffer size in bytes | SOCK | `socket.rg` |
| sndbuf | Int | `SO_SNDBUF` send buffer size in bytes | SOCK | `socket.rg` |
| is_open | Bool | Whether the socket or file descriptor handle is open | SOCK | `socket.rg`, `posix.rg` |
| is_listening | Bool | Whether the socket handle is in listening mode | SOCK | `socket.rg` |
| is_connected | Bool | Whether the socket handle is connected | SOCK | `socket.rg` |
| can_read | Bool | Whether the socket receive half is open (`SHUT_RD` not set) | SOCK | `socket.rg` |
| can_write | Bool | Whether the socket send half is open (`SHUT_WR` not set) | SOCK | `socket.rg` |
| readable | Bool | Poll readiness flag indicating bytes or connections are ready to read | SOCK | `socket.rg`, `posix.rg` |
| writable | Bool | Poll readiness flag indicating the descriptor can accept writes | SOCK | `socket.rg`, `posix.rg` |
| has_error | Bool | Poll readiness flag indicating the descriptor is closed or in error state | SOCK | `socket.rg`, `posix.rg` |
| status_code | Int | Solstice negative error code or `0` on success (`0`, `-1`..`-12`, `-99`) | SOCK | `socket.rg`, `crypto.rg`, `posix.rg`, `io.rg` |
| m_cost | Int | Argon2 memory cost in KiB (`>= 8 * lanes`) | CRYPTO | `argon2id.rg`, `crypto.rg` |
| t_cost | Int | Argon2 time cost / number of passes (`>= 1`) | CRYPTO | `argon2id.rg`, `crypto.rg` |
| lanes | Int | Argon2 degree of parallelism (`1..255`) | CRYPTO | `argon2id.rg`, `crypto.rg` |
| tag_len | Int | Output tag length in bytes (`4..64`) | CRYPTO | `argon2id.rg`, `crypto.rg` |
| version | Int | Argon2 version number (`19` = `0x13`) | CRYPTO | `argon2id.rg`, `crypto.rg` |
| salt_b64 | String | Unpadded Base64 salt extracted from a PHC string | CRYPTO | `argon2id.rg`, `crypto.rg` |
| tag_b64 | String | Unpadded Base64 tag extracted from a PHC string | CRYPTO | `argon2id.rg`, `crypto.rg` |
| key_bytes | String | Raw 32-byte symmetric key or HMAC key | CRYPTO | `crypto.rg` |
| nonce_bytes | String | Raw 12-byte RFC 8439 ChaCha20-Poly1305 nonce | CRYPTO | `crypto.rg` |
| aad_bytes | String | Additional authenticated data (AAD) for AEAD encryption | CRYPTO | `crypto.rg` |
| fd | Int | POSIX file, pipe, signal, or socket descriptor (`>= 0`) | POSIX | `posix.rg`, `io.rg`, `socket.rg` |
| events | Int | Poll event bitmask (`POLLIN = 1`, `POLLOUT = 4`, `POLLERR = 8`) | POSIX | `posix.rg`, `io.rg` |
| sig_num | Int | POSIX signal number (`SIGINT = 2`, `SIGKILL = 9`, `SIGTERM = 15`, etc.) | POSIX | `posix.rg`, `io.rg` |
| pid | Int | Operating system process identifier | POSIX | `posix.rg`, `io.rg` |
| exit_code | Int | Process exit status code (`0..255`) | POSIX | `posix.rg`, `io.rg` |
| errno_code | Int | Positive POSIX `errno` value returned by kernel syscall failure | POSIX | `posix.rg`, `io.rg` |
| max_bytes | Int | Upper bound on bytes read in a single descriptor/socket read operation | IO | `io.rg`, `socket.rg`, `posix.rg` |
| agent_state | String | Lifecycle or reply state of a Ridgun agent (`running`, `stopped`, `timeout`, `error`) | AGENT | `agent.rg` |
| item_count | Int | Number of entries or messages held by a stateful agent | AGENT | `agent.rg` |
| row_count | Int | Number of rows `r` in a 2D typed tensor (`>= 0`) | TENSOR | `tensor.rg`, `crypto.rg` |
| col_count | Int | Number of columns `c` in a 2D typed tensor (`>= 0`) | TENSOR | `tensor.rg`, `crypto.rg` |
| row_idx | Int | Zero-based row subscript index (`0..row_count-1`) | TENSOR | `tensor.rg`, `crypto.rg` |
| col_idx | Int | Zero-based column subscript index (`0..col_count-1`) | TENSOR | `tensor.rg`, `crypto.rg` |
| indent_width | Int | Spaces per structural indentation level (`>= 1`, default `2`) | FMT | `fmt.rg` |
| max_align_params | Int | Maximum parameter count eligible for 2D tabular column alignment (`>= 0`, default `4`) | FMT | `fmt.rg` |
| max_line_width | Int | Maximum line width in columns for 2D signature/clause alignment (`>= 20`, default `80`) | FMT | `fmt.rg` |
| is_aligned | Bool | Whether 2D tabular signature, clause, and `where` alignment is enabled | FMT | `fmt.rg` |
| target_format | String | Output format identifier (`plain`, `tty`, `truecolor`, `html_inline`, `html_css`, `markdown`, `pango`, `latex`, `rtf`) | FMT | `fmt.rg` |
| color_theme | String | Syntax highlighting theme identifier (`none`, `dark`, `light`) | FMT | `fmt.rg` |
| json_kind | String | Discriminator of a parsed `JsonVal` node (`null`, `bool`, `int`, `str`, `arr`, `obj`) | JSON | `json.rg` |
| dot_path | String | Dot-separated object/array query path (`a.b.0`) | JSON | `json.rg` |
| delimiter_char | String | Single-character field delimiter for tabular parsing (`,` for CSV, `\t` for TSV) | CSV | `csv.rg` |
| has_headers | Bool | Whether the first row of a CSV/TSV document defines column header names | CSV | `csv.rg` |
| section_name | String | Section header name `[section]` in an INI configuration document | INI | `ini.rg` |
| pattern_str | String | Regular expression pattern string compiled into a Thompson NFA | REGEX | `regex.rg` |
| match_start | Int | Zero-based inclusive start byte offset of a regex match (`>= 0`) | REGEX | `regex.rg` |
| match_end | Int | Zero-based exclusive end byte offset of a regex match (`>= match_start`) | REGEX | `regex.rg` |
| tree_height | Int | Height of a balanced binary search tree node (`>= 0`) | BTREE | `btree.rg` |
| priority_score | Int | Numeric priority key in a `MinHeap` priority queue | BTREE | `btree.rg` |
| issuer | String | JWT `iss` (issuer) claim string | JWT | `jwt.rg` |
| subject | String | JWT `sub` (subject) claim string | JWT | `jwt.rg` |
| expires_at | Int | JWT `exp` expiration timestamp in UTC epoch seconds | JWT | `jwt.rg` |
| not_before_at | Int | JWT `nbf` not-before timestamp in UTC epoch seconds | JWT | `jwt.rg` |
| ws_opcode | Int | RFC 6455 WebSocket frame opcode (`1` text, `2` binary, `8` close, `9` ping, `10` pong) | WS | `ws.rg` |
| is_fin | Bool | RFC 6455 WebSocket `FIN` bit indicating the final fragment of a message | WS | `ws.rg` |
| is_masked | Bool | RFC 6455 WebSocket `MASK` bit indicating a 4-byte XOR masking key is present | WS | `ws.rg` |
| norm_value | Real | Computed matrix or vector norm ($L_1$, $L_2$, or $L_\infty$) | LINALG | `linalg.rg` |
| diff_op | String | Line diff edit operation kind (`equal`, `insert`, `delete`) | DIFF | `diff.rg` |
| old_line_no | Int | 1-based line number in the original document (`>= 0`) | DIFF | `diff.rg` |
| new_line_no | Int | 1-based line number in the modified document (`>= 0`) | DIFF | `diff.rg` |
| escape_mode | String | Template variable auto-escaping mode (`none`, `html`, `latex`) | TMPL | `template.rg` |
