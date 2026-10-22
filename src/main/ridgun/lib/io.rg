-- ============================================================
-- src/main/ridgun/lib/io.rg
-- Pure-Ridgun High-Level Timeout-Bounded I/O, Metadata & Streams Library (IO)
-- @implements FR-IO-001
-- @implements FR-IO-002
-- @implements NFR-PERF-001
-- @implements API-IO-001
-- @implements DM-IoResult
-- @mitigates VUL-INJ-002
-- @mitigates VUL-INPUT-001
-- ============================================================

import posix

-- ── Extensible I/O Error & Result Sum Types (§5.1) ───────────

-- @implements FR-IO-001
-- @implements DM-IoResult
type IoError = Timeout Int | Eof | SysErr Int String | NotFound String

-- @implements FR-IO-001
-- @implements DM-IoResult
type IoResult = String | Int | Timeout Int | Eof | SysErr Int String | NotFound String | IoErr IoError | IoOk String | IoTimeout | IoEof | IoError Int

-- @implements FR-IO-001
-- @implements API-IO-001
fn :: format io error IoError            => String
      format io error (Timeout ms)       =  "timeout after {ms} ms"
      format io error Eof                =  "unexpected end of file"
      format io error (SysErr c op_name) =  "syscall error {c} in {op_name}"
      format io error (NotFound path)    =  "file not found: {path}"
      format io error _                  =  "unknown io error"

fn :: format io result IoResult           => String
      format io result (String s)         =  "ok:str:{s}"
      format io result (IoOk s)           =  "ok:str:{s}"
      format io result (Int n)            =  "ok:int:{n}"
      format io result (Timeout ms)       =  "err:timeout after {ms} ms"
      format io result IoTimeout          =  "err:timeout"
      format io result Eof                =  "err:unexpected end of file"
      format io result IoEof              =  "err:unexpected end of file"
      format io result (IoError c)        =  "err:io error {c}"
      format io result (SysErr c op_name) =  "err:syscall error {c} in {op_name}"
      format io result (NotFound path)    =  "err:file not found: {path}"
      format io result (IoErr err)        =  "err:{format_io_error err}"
      format io result _                  =  "err:unknown io error"

-- ── Timeout-Bounded Descriptor Read & Write (§5.2) ───────────

fn :: map read bytes String => IoResult
      map read bytes data   =
        | (str_len data) == 0 = Eof
        | otherwise           = String data

-- @implements FR-IO-001
-- @implements API-IO-001
fn :: read fd after poll PollStatus Int Int Int => IoResult
      read fd after poll (PollReady _) fd max_bytes _ = map read bytes (posix read fd max_bytes)
      read fd after poll PollTimeout _ _ timeout_ms = Timeout timeout_ms
      read fd after poll (PollError code) _ _ _ = SysErr code "poll"

-- @implements FR-IO-001
-- @implements NFR-PERF-001
-- @implements API-IO-001
-- @mitigates VUL-INPUT-001
fn :: read fd Int Int       Int        => IoResult
      read fd fd  max_bytes timeout_ms =
        | fd < 0         = SysErr 9 "read"
        | max_bytes <= 0 = SysErr 22 "read"
        | otherwise      =
          status = wait fd fd poll_in timeout_ms
          read fd after poll status fd max_bytes timeout_ms

-- @implements FR-IO-001
-- @implements NFR-PERF-001
-- @implements API-IO-001
op :: read fd Int max Int       timeout Int        => IoResult
      read fd fd  max max_bytes timeout timeout_ms =
        read fd fd max_bytes timeout_ms

fn :: map write rc Int => IoResult
      map write rc rc  =
        | rc < 0    = SysErr (0 - rc) "write"
        | otherwise = Int rc

-- @implements FR-IO-001
-- @implements API-IO-001
fn :: write fd after poll PollStatus Int String Int => IoResult
      write fd after poll (PollReady _) fd data _ = map write rc (posix write fd data)
      write fd after poll PollTimeout _ _ timeout_ms = Timeout timeout_ms
      write fd after poll (PollError code) _ _ _ = SysErr code "poll"

-- @implements FR-IO-001
-- @implements NFR-PERF-001
-- @implements API-IO-001
fn :: write fd Int String Int        => IoResult
      write fd fd  data   timeout_ms =
        | fd < 0    = SysErr 9 "write"
        | otherwise =
          status = wait fd fd poll_out timeout_ms
          write fd after poll status fd data timeout_ms

-- @implements FR-IO-001
-- @implements NFR-PERF-001
-- @implements API-IO-001
op :: write fd Int data String  timeout Int        => IoResult
      write fd fd  data payload timeout timeout_ms =
        write fd fd payload timeout_ms

-- ── Timeout-Bounded Command Execution (§5.2) ─────────────────

fn :: has null char String Int Int => Bool
      has null char s idx slen =
        | idx >= slen              = False
        | (str_char_at s idx) == 0 = True
        | otherwise                = has null char s (idx + 1) slen

fn :: pad ms three Int => String
      pad ms three rem =
        | rem < 10  = "00{rem}"
        | rem < 100 = "0{rem}"
        | otherwise = "{rem}"

fn :: format timeout sec Int => String
      format timeout sec ms  =
        secs = ms / 1000
        rem  = ms % 1000
        p    = pad ms three rem
        "{secs}.{p}s"

fn :: map exec rc Int Int        => IoResult
      map exec rc rc  timeout_ms =
        | rc == 124 or rc == 137 = Timeout timeout_ms
        | rc < 0                 = SysErr (0 - rc) "exec"
        | otherwise              = Int rc

-- @implements FR-IO-001
-- @implements NFR-PERF-001
-- @implements API-IO-001
-- @mitigates VUL-INJ-002
fn :: io exec timeout String Int        => IoResult
      io exec timeout cmd    timeout_ms =
        | (str_len cmd) == 0 or (has null char cmd 0 (str_len cmd)) = SysErr 22 "exec"
        | timeout_ms <= 0                                           = Timeout timeout_ms
        | otherwise                                                 =
          tspec = format timeout sec timeout_ms
          rc    = shell_exec "timeout -k 0.01s {tspec} sh -c \"{cmd}\" >/dev/null 2>&1"
          map exec rc rc timeout_ms

-- @implements FR-IO-001
-- @implements API-IO-001
fn :: exec with timeout String Int        => IoResult
      exec with timeout cmd    timeout_ms =
        io exec timeout cmd timeout_ms

-- ── RG-010 File Operations & Metadata Predicates ─────────────

fn :: read existing or empty String => String
      read existing or empty path   =
        | lstat exists (file_lstat path) = read_file path
        | otherwise                      = ""

-- @implements FR-IO-002
-- @implements API-IO-001
fn :: append file String String => Int
      append file path   data   =
        | not (is safe posix path path) = 0 - 22
        | otherwise                     =
          prev = read existing or empty path
          _    = write_file path (prev + data)
          0

-- @implements FR-IO-002
-- @implements API-IO-001
fn :: file exists String => Bool
      file exists path   =
        | not (is safe posix path path) = False
        | otherwise                     = lstat exists (file_lstat path)

-- @implements FR-IO-002
-- @implements API-IO-001
fn :: is file String => Bool
      is file path   =
        | not (is safe posix path path) = False
        | otherwise                     =
          st = file_lstat path
          (lstat exists st) and ((lstat kind st) == "file")

-- @implements FR-IO-002
-- @implements API-IO-001
fn :: is dir String => Bool
      is dir path   =
        | not (is safe posix path path) = False
        | otherwise                     =
          st = file_lstat path
          (lstat exists st) and ((lstat kind st) == "dir")

-- @implements FR-IO-002
-- @implements API-IO-001
fn :: is symlink String => Bool
      is symlink path   =
        | not (is safe posix path path) = False
        | otherwise                     =
          st   = file_lstat path
          kind = lstat kind st
          tlen = str_len (lstat symlink target st)
          (lstat exists st) and (kind == "symlink" or kind == "link" or tlen > 0)

fn :: extract size (Bool String Int Int Int String String Int String) => Int
      extract size st                                                 =
        | not (lstat exists st) = 0 - 1
        | otherwise             = lstat size st

-- @implements FR-IO-002
-- @implements API-IO-001
fn :: file size String => Int
      file size path   =
        | not (is safe posix path path) = 0 - 1
        | otherwise                     = extract size (file_lstat path)

fn :: extract mtime (Bool String Int Int Int String String Int String) => Int
      extract mtime st                                                 =
        | not (lstat exists st) = 0 - 1
        | otherwise             = lstat mtime sec st

-- @implements FR-IO-002
-- @implements API-IO-001
fn :: file mtime String => Int
      file mtime path   =
        | not (is safe posix path path) = 0 - 1
        | otherwise                     = extract mtime (file_lstat path)

fn :: extract mode (Bool String Int Int Int String String Int String) => Int
      extract mode st                                                 =
        | not (lstat exists st) = 0 - 1
        | otherwise             = lstat mode st

-- @implements FR-IO-002
-- @implements API-IO-001
fn :: file mode String => Int
      file mode path   =
        | not (is safe posix path path) = 0 - 1
        | otherwise                     = extract mode (file_lstat path)

-- ── Safe File Read & Line-Stream Helpers ─────────────────────

-- @implements FR-IO-002
-- @implements API-IO-001
-- @mitigates VUL-INPUT-001
fn :: io read file safe String => IoResult
      io read file safe path   =
        | not (is safe posix path path)        = SysErr 22 "read_file"
        | not (lstat exists (file_lstat path)) = NotFound path
        | otherwise                            = String (read_file path)

fn :: split lines loop String Int Int Int => [String]
      split lines loop s idx start slen =
        | idx >= slen =
          | start == slen = []
          | otherwise     = [str_slice s start slen] |.
        | (str_char_at s idx) == 10 =
          line = str_slice s start idx
          [line] :: (split lines loop s (idx + 1) (idx + 1) slen)
        | otherwise =
          split lines loop s (idx + 1) start slen

fn :: split non empty lines String Int => [String]
      split non empty lines raw rlen =
        | rlen == 0 = []
        | otherwise = split lines loop raw 0 0 rlen

-- @implements FR-IO-002
-- @implements API-IO-001
fn :: io read lines String => [String]
      io read lines path   =
        | not (is safe posix path path)        = []
        | not (lstat exists (file_lstat path)) = []
        | otherwise                            =
          raw = read_file path
          split non empty lines raw (str_len raw)

fn :: str list is empty [String] => Bool
      str list is empty []       =  True
      str list is empty (_:_)    =  False

fn :: join lines nl [String]    => String
      join lines nl []          =  ""
      join lines nl (line:rest) =
        | str list is empty rest = line + "\n"
        | otherwise              = line + "\n" + (join lines nl rest)

-- @implements FR-IO-002
-- @implements API-IO-001
fn :: io write lines String [String] => Int
      io write lines path   lines    =
        | not (is safe posix path path) = 0 - 22
        | otherwise                     =
          _ = write_file path (join lines nl lines)
          0

-- ── Ridgun v0.9.5 PAL & Ambient Deadline `io read with timeout` (§3.1) ────

fn :: io wrap chunk String => IoResult
      io wrap chunk ""     =  IoEof
      io wrap chunk s      =  IoOk s

fn :: io read after poll Int Int => IoResult
      io read after poll fd ev =
        | ev == 0 =
          _ = sys close fd
          IoTimeout
        | ev < 0 =
          _ = sys close fd
          IoError ev
        | otherwise =
          chunk = sys read fd fd 65536
          _     = sys close fd
          io wrap chunk chunk

fn :: io read poll step Int => IoResult
      io read poll step fd  =
        | fd < 0    = IoError fd
        | otherwise =
          ev = sys poll fd 1 (0 - 1)
          io read after poll fd ev

-- @implements FR-IO-001
-- @implements API-IO-001
fn :: io read with timeout String Int => IoResult
      io read with timeout path wait_ms =
        with timeout wait_ms do
          fd = sys open path 2048 0
          io read poll step fd
