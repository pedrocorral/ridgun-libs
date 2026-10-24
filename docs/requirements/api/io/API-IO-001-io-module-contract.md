---
id: API-IO-001
title: Public lib contract for io (io.rglib / libio.so)
status: approved
implements: [FR-IO-001, FR-IO-002]
auth: none
---
# API-IO-001 — Public lib contract for `io` (`io.rg`)

## Request
- Imported via `import io` (imports `posix`).
- Inputs (see `DM-IoResult`): `fd` (`Int`), `max_bytes` (`Int`), `timeout_ms` (`Int`), `path` (`String`).
- Extensible Error & Result Types (`ridgun_posix_io_library_spec.md` §5.1):
  - `type IoError = Timeout Int | Eof | SysErr Int String | NotFound String`
  - `type IoResult = String | Int | IoError`
  - `format io error IoError => String`
- Timeout-Bounded Descriptor & Process Operations (§5.2):
  - `read fd Int max Int timeout Int => IoResult`
  - `read fd after poll PollStatus Int Int Int => IoResult`
  - `write fd Int data String timeout Int => IoResult`
  - `write fd after poll PollStatus Int String Int => IoResult`
  - `io exec timeout String Int => IoResult` / `exec with timeout String Int => IoResult`
- High-Level File, Metadata & Stream Operations (`RG-010`):
  - `read_file String => String`, `write_file String String => Int`, `append_file String String => Int`
  - `read_bytes String => [Int]`, `write_bytes String [Int] => Int`, `list_dir String => [String]`
  - `file_exists String => Bool`, `is_file String => Bool`, `is_dir String => Bool`, `is_symlink String => Bool`
  - `file_size String => Int`, `file_mtime String => Int`, `file_mode String => Int`
  - `io read file safe String => IoResult`, `io read lines String => [String]`, `io write lines String [String] => Int`

## Responses
| Code | When | Body |
|---|---|---|
| `String` / `Int` | Read or write succeeded | Payload `String` or bytes written `Int` |
| `Timeout ms` | Descriptor or command exceeded `timeout_ms` | `Timeout ms` (`"timeout after {ms} ms"`) |
| `Eof` | Descriptor reached end-of-file (`0` bytes read after `PollReady`) | `Eof` (`"unexpected end of file"`) |
| `SysErr code op` | Underlying syscall / poll returned an error | `SysErr code op` (`"syscall error {code} in {op}"`) |
| `NotFound path` | Target file path does not exist | `NotFound path` (`"file not found: {path}"`) |

## Rules
- `read fd` and `write fd` always poll descriptor readiness via `wait fd` before invoking `sys read fd` / `sys write fd`.
- `is_symlink` inspects link metadata (`lstat`) without following the target link.
