-- ============================================================
-- src/main/ridgun/lib/json.rg
-- Pure-Ridgun Recursive RFC 8259 JSON AST Parser, Serializer, Pretty-Printer & Dot-Path Query Library (JSON)
-- @implements FR-JSON-001
-- @implements API-JSON-001
-- @implements DM-Json
-- @mitigates VUL-INPUT-001
-- ============================================================

type JsonField = JsonField String JsonVal

type JsonVal = JsonNull | JsonBool Bool | JsonInt Int | JsonStr String | JsonArr [JsonVal] | JsonObj [JsonField]

type JsonRes = JsonOk JsonVal | JsonErr String

type JsonStep = JStepOk JsonVal Int | JStepErr String

type JsonArrStep = JArrOk [JsonVal] Int | JArrErr String

type JsonObjStep = JObjOk [JsonField] Int | JObjErr String

type JsonStrStep = JStrOk String Int | JStrErr String

-- ── Whitespace, Raw Byte & Character Helpers ─────────────────

fn :: j_is_ws Int => Bool
      j_is_ws c   =  c == 32 OR c == 9 OR c == 10 OR c == 13

fn :: j_is_digit Int => Bool
      j_is_digit c   =  c >= 48 AND c <= 57

fn :: j_skip_ws String Int Int => Int
      j_skip_ws s      pos len
        | pos >= len = len
        | j_is_ws (str_char_at s pos) = j_skip_ws s (pos + 1) len
        | otherwise = pos

fn :: j_spaces Int => String
      j_spaces n
        | n <= 0 = ""
        | otherwise = " " + (j_spaces (n - 1))

fn :: j_raw_byte_ub Int => String
      j_raw_byte_ub ub
        | ub >= 1 AND ub <= 127 = char_from_code ub
        | otherwise =
          efd = sys_call 290 (256 + ub) 526336 0 0 0 0
          s   = sys_read_fd efd 8
          _   = sys_close efd
          str_slice s 0 1

fn :: j_raw_byte Int => String
      j_raw_byte b   =  j_raw_byte_ub (((b % 256) + 256) % 256)

-- ── RFC 8259 §7 Unicode Escape (\uXXXX + UTF-16 Surrogates) & String Escaping ──

fn :: j_hex_digit Int => Int
      j_hex_digit c
        | c >= 48 AND c <= 57  = c - 48
        | c >= 97 AND c <= 102 = (c - 97) + 10
        | c >= 65 AND c <= 70  = (c - 65) + 10
        | otherwise            = 0 - 1

fn :: j_combine_hex4 Int Int Int Int => Int
      j_combine_hex4 d0 d1 d2 d3
        | d0 < 0 OR d1 < 0 OR d2 < 0 OR d3 < 0 = 0 - 1
        | otherwise = (((d0 * 16) + d1) * 256) + (d2 * 16) + d3

fn :: j_parse_hex4 String Int Int => Int
      j_parse_hex4 s      pos len
        | (pos + 4) > len = 0 - 1
        | otherwise =
          j_combine_hex4 (j_hex_digit (str_char_at s pos)) (j_hex_digit (str_char_at s (pos + 1))) (j_hex_digit (str_char_at s (pos + 2))) (j_hex_digit (str_char_at s (pos + 3)))

fn :: j_utf8_from_cp Int => String
      j_utf8_from_cp cp
        | cp <= 127 = j_raw_byte cp
        | cp <= 2047 =
          b0 = 192 + (cp / 64)
          b1 = 128 + (cp % 64)
          (j_raw_byte b0) + (j_raw_byte b1)
        | cp <= 65535 =
          b0 = 224 + (cp / 4096)
          b1 = 128 + ((cp / 64) % 64)
          b2 = 128 + (cp % 64)
          (j_raw_byte b0) + (j_raw_byte b1) + (j_raw_byte b2)
        | otherwise =
          b0 = 240 + (cp / 262144)
          b1 = 128 + ((cp / 4096) % 64)
          b2 = 128 + ((cp / 64) % 64)
          b3 = 128 + (cp % 64)
          (j_raw_byte b0) + (j_raw_byte b1) + (j_raw_byte b2) + (j_raw_byte b3)

fn :: j_escape_loop String Int Int String => String
      j_escape_loop s      pos len acc
        | pos >= len = acc
        | (str_char_at s pos) == 34 = j_escape_loop s (pos + 1) len (acc + (char_from_code 92) + (char_from_code 34))
        | (str_char_at s pos) == 92 = j_escape_loop s (pos + 1) len (acc + (char_from_code 92) + (char_from_code 92))
        | (str_char_at s pos) == 8 = j_escape_loop s (pos + 1) len (acc + (char_from_code 92) + "b")
        | (str_char_at s pos) == 12 = j_escape_loop s (pos + 1) len (acc + (char_from_code 92) + "f")
        | (str_char_at s pos) == 10 = j_escape_loop s (pos + 1) len (acc + (char_from_code 92) + "n")
        | (str_char_at s pos) == 13 = j_escape_loop s (pos + 1) len (acc + (char_from_code 92) + "r")
        | (str_char_at s pos) == 9 = j_escape_loop s (pos + 1) len (acc + (char_from_code 92) + "t")
        | otherwise = j_escape_loop s (pos + 1) len (acc + (str_slice s pos (pos + 1)))

fn :: j_escape_str String => String
      j_escape_str s      =  (char_from_code 34) + (j_escape_loop s 0 (str_len s) "") + (char_from_code 34)

fn :: j_unescape_simple Int => String
      j_unescape_simple 34  =  char_from_code 34
      j_unescape_simple 92  =  char_from_code 92
      j_unescape_simple 47  =  "/"
      j_unescape_simple 98  =  char_from_code 8
      j_unescape_simple 102 =  char_from_code 12
      j_unescape_simple 110 =  char_from_code 10
      j_unescape_simple 114 =  char_from_code 13
      j_unescape_simple 116 =  char_from_code 9
      j_unescape_simple _   =  ""

fn :: j_finish_surrogate String Int Int String Int Int => JsonStrStep
      j_finish_surrogate s pos len acc hi_u lo_u
        | lo_u < 56320 OR lo_u > 57343 = JStrErr "invalid low UTF-16 surrogate in JSON string"
        | otherwise =
          cp = 65536 + ((hi_u - 55296) * 1024) + (lo_u - 56320)
          j_parse_str_loop s (pos + 6) len (acc + (j_utf8_from_cp cp))

fn :: j_parse_u_surrogate String Int Int String Int => JsonStrStep
      j_parse_u_surrogate s pos len acc hi_u
        | (pos + 6) > len = JStrErr "unpaired high UTF-16 surrogate in JSON string"
        | (str_char_at s pos) != 92 OR (str_char_at s (pos + 1)) != 117 = JStrErr "unpaired high UTF-16 surrogate in JSON string"
        | otherwise = j_finish_surrogate s pos len acc hi_u (j_parse_hex4 s (pos + 2) len)

fn :: j_dispatch_u_escape String Int Int String Int => JsonStrStep
      j_dispatch_u_escape s pos len acc u
        | u < 0 = JStrErr "invalid \\uXXXX hex escape in JSON string"
        | u >= 56320 AND u <= 57343 = JStrErr "unpaired low UTF-16 surrogate in JSON string"
        | u >= 55296 AND u <= 56319 = j_parse_u_surrogate s (pos + 4) len acc u
        | otherwise = j_parse_str_loop s (pos + 4) len (acc + (j_utf8_from_cp u))

fn :: j_parse_u_escape String Int Int String => JsonStrStep
      j_parse_u_escape s pos len acc =
        j_dispatch_u_escape s pos len acc (j_parse_hex4 s pos len)

fn :: j_finish_simple_escape String Int Int String String => JsonStrStep
      j_finish_simple_escape s pos len acc rep
        | rep == "" = JStrErr "invalid escape sequence in JSON string"
        | otherwise = j_parse_str_loop s (pos + 1) len (acc + rep)

fn :: j_parse_escape_char String Int Int String Int => JsonStrStep
      j_parse_escape_char s pos len acc esc_c
        | esc_c == 117 = j_parse_u_escape s (pos + 1) len acc
        | otherwise = j_finish_simple_escape s pos len acc (j_unescape_simple esc_c)

fn :: j_parse_escape String Int Int String => JsonStrStep
      j_parse_escape s pos len acc =
        j_parse_escape_char s pos len acc (str_char_at s pos)

fn :: j_parse_str_loop String Int Int String => JsonStrStep
      j_parse_str_loop s      pos len acc
        | pos >= len = JStrErr "unterminated JSON string"
        | (str_char_at s pos) == 34 = JStrOk acc (pos + 1)
        | (str_char_at s pos) == 92 AND (pos + 1) >= len = JStrErr "unterminated escape in JSON string"
        | (str_char_at s pos) == 92 = j_parse_escape s (pos + 1) len acc
        | otherwise = j_parse_str_loop s (pos + 1) len (acc + (str_slice s pos (pos + 1)))

fn :: j_parse_string String Int Int => JsonStrStep
      j_parse_string s      pos len
        | pos >= len OR (str_char_at s pos) != 34 = JStrErr "expected JSON string"
        | otherwise = j_parse_str_loop s (pos + 1) len ""

-- ── Integer Literal Parsing ──────────────────────────────────

fn :: j_scan_digits String Int Int => Int
      j_scan_digits s      pos len
        | pos >= len = len
        | j_is_digit (str_char_at s pos) = j_scan_digits s (pos + 1) len
        | otherwise = pos

fn :: j_parse_number String Int Int => JsonStep
      j_parse_number s      pos len
        | (str_char_at s pos) == 45 = j_finish_neg_num s pos (j_scan_digits s (pos + 1) len)
        | otherwise = j_finish_pos_num s pos (j_scan_digits s pos len)

fn :: j_finish_neg_num String Int Int     => JsonStep
      j_finish_neg_num s      pos end_pos
        | end_pos <= (pos + 1) = JStepErr "invalid negative number"
        | otherwise = JStepOk (JsonInt (str_to_int (str_slice s pos end_pos))) end_pos

fn :: j_finish_pos_num String Int Int     => JsonStep
      j_finish_pos_num s      pos end_pos
        | end_pos <= pos = JStepErr "expected number"
        | otherwise = JStepOk (JsonInt (str_to_int (str_slice s pos end_pos))) end_pos

-- ── Recursive Value, Array & Object Parser (Bounded Depth & Unique Keys) ──

fn :: j_has_field [JsonField] String => Bool
      j_has_field []                  _   =  False
      j_has_field ((JsonField k _):fs) key
        | k == key = True
        | otherwise = j_has_field fs key

fn :: j_parse_val String Int Int Int => JsonStep
      j_parse_val s      pos len rem_depth =
        p = j_skip_ws s pos len
        j_parse_val_at s p len rem_depth

fn :: j_parse_val_at String Int Int Int => JsonStep
      j_parse_val_at s      p   len rem_depth
        | p >= len = JStepErr "unexpected end of JSON input"
        | (str_char_at s p) == 34 = j_wrap_str_step (j_parse_string s p len)
        | (str_char_at s p) == 91 =
          | rem_depth <= 0 = JStepErr "maximum JSON nesting depth exceeded"
          | otherwise = j_parse_arr_open s (p + 1) len (rem_depth - 1)
        | (str_char_at s p) == 123 =
          | rem_depth <= 0 = JStepErr "maximum JSON nesting depth exceeded"
          | otherwise = j_parse_obj_open s (p + 1) len (rem_depth - 1)
        | (p + 4) <= len AND (str_slice s p (p + 4)) == "true" = JStepOk (JsonBool True) (p + 4)
        | (p + 5) <= len AND (str_slice s p (p + 5)) == "false" = JStepOk (JsonBool False) (p + 5)
        | (p + 4) <= len AND (str_slice s p (p + 4)) == "null" = JStepOk JsonNull (p + 4)
        | (str_char_at s p) == 45 OR (j_is_digit (str_char_at s p)) = j_parse_number s p len
        | otherwise = JStepErr "unexpected token in JSON value"

fn :: j_wrap_str_step JsonStrStep   => JsonStep
      j_wrap_str_step (JStrOk val next_p) = JStepOk (JsonStr val) next_p
      j_wrap_str_step (JStrErr err) =  JStepErr err

fn :: j_parse_arr_open String Int Int Int => JsonStep
      j_parse_arr_open s      pos len rem_depth =
        p = j_skip_ws s pos len
        j_parse_arr_first s p len rem_depth

fn :: j_parse_arr_first String Int Int Int => JsonStep
      j_parse_arr_first s      p   len rem_depth
        | p >= len = JStepErr "unterminated JSON array"
        | (str_char_at s p) == 93 = JStepOk (JsonArr []) (p + 1)
        | otherwise = j_finish_arr_step (j_parse_arr_items s p len rem_depth [])

fn :: j_finish_arr_step JsonArrStep   => JsonStep
      j_finish_arr_step (JArrOk items next_p) = JStepOk (JsonArr items) next_p
      j_finish_arr_step (JArrErr err) =  JStepErr err

fn :: j_parse_arr_items String Int Int Int [JsonVal] => JsonArrStep
      j_parse_arr_items s      pos len rem_depth acc =
        j_parse_arr_after_item s len rem_depth acc (j_parse_val s pos len rem_depth)

fn :: j_parse_arr_after_item String Int Int [JsonVal] JsonStep => JsonArrStep
      j_parse_arr_after_item _ _ _ _ (JStepErr err) = JArrErr err
      j_parse_arr_after_item s len rem_depth acc (JStepOk v next_p) =
        p = j_skip_ws s next_p len
        j_parse_arr_delim s p len rem_depth (acc :: [v])

fn :: j_parse_arr_delim String Int Int Int [JsonVal] => JsonArrStep
      j_parse_arr_delim s      p   len rem_depth acc
        | p >= len = JArrErr "unterminated JSON array"
        | (str_char_at s p) == 93 = JArrOk acc (p + 1)
        | (str_char_at s p) == 44 = j_parse_arr_items s (p + 1) len rem_depth acc
        | otherwise = JArrErr "expected ',' or ']' in JSON array"

fn :: j_parse_obj_open String Int Int Int => JsonStep
      j_parse_obj_open s      pos len rem_depth =
        p = j_skip_ws s pos len
        j_parse_obj_first s p len rem_depth

fn :: j_parse_obj_first String Int Int Int => JsonStep
      j_parse_obj_first s      p   len rem_depth
        | p >= len = JStepErr "unterminated JSON object"
        | (str_char_at s p) == 125 = JStepOk (JsonObj []) (p + 1)
        | otherwise = j_finish_obj_step (j_parse_obj_fields s p len rem_depth [])

fn :: j_finish_obj_step JsonObjStep   => JsonStep
      j_finish_obj_step (JObjOk fields next_p) = JStepOk (JsonObj fields) next_p
      j_finish_obj_step (JObjErr err) =  JStepErr err

fn :: j_parse_obj_fields String Int Int Int [JsonField] => JsonObjStep
      j_parse_obj_fields s      pos len rem_depth acc =
        p = j_skip_ws s pos len
        j_parse_obj_after_key s len rem_depth acc (j_parse_string s p len)

fn :: j_parse_obj_after_key String Int Int [JsonField] JsonStrStep   => JsonObjStep
      j_parse_obj_after_key _      _   _         _     (JStrErr err) =  JObjErr err
      j_parse_obj_after_key s      len rem_depth acc   (JStrOk key next_p)
        | j_has_field acc key = JObjErr ("duplicate JSON object key: " + key)
        | otherwise =
          p = j_skip_ws s next_p len
          j_parse_obj_colon s p len rem_depth key acc

fn :: j_parse_obj_colon String Int Int Int String [JsonField] => JsonObjStep
      j_parse_obj_colon s p len rem_depth key acc
        | p >= len OR (str_char_at s p) != 58 = JObjErr "expected ':' after JSON object key"
        | otherwise = j_parse_obj_after_val s len rem_depth key acc (j_parse_val s (p + 1) len rem_depth)

fn :: j_parse_obj_after_val String Int Int String [JsonField] JsonStep => JsonObjStep
      j_parse_obj_after_val _ _ _ _ _ (JStepErr err) = JObjErr err
      j_parse_obj_after_val s len rem_depth key acc (JStepOk v next_p) =
        p = j_skip_ws s next_p len
        j_parse_obj_delim s p len rem_depth (acc :: [JsonField key v])

fn :: j_parse_obj_delim String Int Int Int [JsonField] => JsonObjStep
      j_parse_obj_delim s      p   len rem_depth acc
        | p >= len = JObjErr "unterminated JSON object"
        | (str_char_at s p) == 125 = JObjOk acc (p + 1)
        | (str_char_at s p) == 44 = j_parse_obj_fields s (p + 1) len rem_depth acc
        | otherwise = JObjErr "expected ',' or '}' in JSON object"

fn :: j_check_eof String Int JsonStep       => JsonRes
      j_check_eof _      _   (JStepErr err) =  JsonErr err
      j_check_eof s      len (JStepOk val end_p) =
        p = j_skip_ws s end_p len
        j_check_eof_pos p len val

fn :: j_check_eof_pos Int Int JsonVal => JsonRes
      j_check_eof_pos p   len val
        | p == len = JsonOk val
        | otherwise = JsonErr "unexpected trailing characters after JSON value"

-- @implements FR-JSON-001
-- @implements API-JSON-001
-- @mitigates VUL-INPUT-001
fn :: json parse with limits String Int Int => JsonRes
      json parse with limits s max_depth max_bytes
        | max_depth < 1 = JsonErr "invalid JSON max_depth limit"
        | max_bytes < 1 = JsonErr "invalid JSON max_bytes limit"
        | (str_len s) > max_bytes = JsonErr "JSON input exceeds maximum allowed byte length"
        | otherwise = j_check_eof s (str_len s) (j_parse_val s 0 (str_len s) max_depth)

-- @implements FR-JSON-001
-- @implements API-JSON-001
-- @mitigates VUL-INPUT-001
fn :: json parse String => JsonRes
      json parse s      =  json parse with limits s 64 1048576

-- ── Serialization & Pretty-Printing ──────────────────────────

fn :: j_join_arr [JsonVal] => String
      j_join_arr []        =  ""
      j_join_arr (v:[])    =  json stringify v
      j_join_arr (v:vs)    =  (json stringify v) + "," + (j_join_arr vs)

fn :: j_join_obj [JsonField] => String
      j_join_obj []          =  ""
      j_join_obj ((JsonField k v):[]) = (j_escape_str k) + ":" + (json stringify v)
      j_join_obj ((JsonField k v):rest) = (j_escape_str k) + ":" + (json stringify v) + "," + (j_join_obj rest)

-- @implements FR-JSON-001
-- @implements API-JSON-001
fn :: json stringify JsonVal          => String
      json stringify JsonNull         =  "null"
      json stringify (JsonBool True)  =  "true"
      json stringify (JsonBool False) =  "false"
      json stringify (JsonInt n)      =  int_to_str n
      json stringify (JsonStr s)      =  j_escape_str s
      json stringify (JsonArr items)  =  "[" + (j_join_arr items) + "]"
      json stringify (JsonObj fields) =  (char_from_code 123) + (j_join_obj fields) + (char_from_code 125)

fn :: j_pretty_arr [JsonVal] Int Int => String
      j_pretty_arr []        _   _   =  ""
      j_pretty_arr (v:[])    ind cur =  (j_spaces (cur + ind)) + (j_pretty_val v ind (cur + ind))
      j_pretty_arr (v:vs)    ind cur =  (j_spaces (cur + ind)) + (j_pretty_val v ind (cur + ind)) + "," + (char_from_code 10) + (j_pretty_arr vs ind cur)

fn :: j_pretty_obj [JsonField] Int Int => String
      j_pretty_obj []          _   _   =  ""
      j_pretty_obj ((JsonField k v):[]) ind cur =
        (j_spaces (cur + ind)) + (j_escape_str k) + ": " + (j_pretty_val v ind (cur + ind))
      j_pretty_obj ((JsonField k v):rest) ind cur =
        (j_spaces (cur + ind)) + (j_escape_str k) + ": " + (j_pretty_val v ind (cur + ind)) + "," + (char_from_code 10) + (j_pretty_obj rest ind cur)

fn :: j_pretty_val JsonVal          Int Int => String
      j_pretty_val (JsonArr [])     _   _   =  "[]"
      j_pretty_val (JsonArr items)  ind cur =
        nl = char_from_code 10
        "[" + nl + (j_pretty_arr items ind cur) + nl + (j_spaces cur) + "]"
      j_pretty_val (JsonObj [])     _   _   =  (char_from_code 123) + (char_from_code 125)
      j_pretty_val (JsonObj fields) ind cur =
        nl = char_from_code 10
        (char_from_code 123) + nl + (j_pretty_obj fields ind cur) + nl + (j_spaces cur) + (char_from_code 125)
      j_pretty_val v                _   _   =  json stringify v

-- @implements FR-JSON-001
-- @implements API-JSON-001
fn :: json pretty JsonVal Int => String
      json pretty val     ind =  j_pretty_val val ind 0

-- ── Dot-Path Queries & Field Updates ─────────────────────────

fn :: j_find_field [JsonField] String => JsonVal
      j_find_field []          _      =  JsonNull
      j_find_field ((JsonField k v):fs) key
        | k == key = v
        | otherwise = j_find_field fs key

-- @implements FR-JSON-001
-- @implements API-JSON-001
fn :: json get field JsonVal          String => JsonVal
      json get field (JsonObj fields) key    =  j_find_field fields key
      json get field _                _      =  JsonNull

fn :: j_nth_val [JsonVal] Int => JsonVal
      j_nth_val []        _   =  JsonNull
      j_nth_val (v:vs)    idx
        | idx < 0 = JsonNull
        | idx == 0 = v
        | otherwise = j_nth_val vs (idx - 1)

-- @implements FR-JSON-001
-- @implements API-JSON-001
fn :: json get index JsonVal         Int => JsonVal
      json get index (JsonArr items) idx =  j_nth_val items idx
      json get index _               _   =  JsonNull

fn :: j_split_dots_loop String Int Int Int [String] => [String]
      j_split_dots_loop s pos len start acc
        | pos >= len = acc :: [str_slice s start len]
        | (str_char_at s pos) == 46 = j_split_dots_loop s (pos + 1) len (pos + 1) (acc :: [str_slice s start pos])
        | otherwise = j_split_dots_loop s (pos + 1) len start acc

fn :: j_step_path JsonVal          String => JsonVal
      j_step_path (JsonObj fields) seg    =  j_find_field fields seg
      j_step_path (JsonArr items)  seg
        | seg != "" AND (j_scan_digits seg 0 (str_len seg)) == (str_len seg) = j_nth_val items (str_to_int seg)
        | otherwise = JsonNull
      j_step_path _                _      =  JsonNull

fn :: j_walk_path JsonVal [String]   => JsonVal
      j_walk_path val     []         =  val
      j_walk_path val     ("":rest)  =  j_walk_path val rest
      j_walk_path val     (seg:rest) =  j_walk_path (j_step_path val seg) rest

-- @implements FR-JSON-001
-- @implements API-JSON-001
fn :: json get path JsonVal String   => JsonVal
      json get path val     ""       =  val
      json get path val     dot_path =  j_walk_path val (j_split_dots_loop dot_path 0 (str_len dot_path) 0 [])

-- @implements FR-JSON-001
-- @implements API-JSON-001
fn :: json get str JsonVal String String => String
      json get str val dot_path fallback = j_unwrap_str (json get path val dot_path) fallback

fn :: j_unwrap_str JsonVal     String   => String
      j_unwrap_str (JsonStr s) _        =  s
      j_unwrap_str _           fallback =  fallback

-- @implements FR-JSON-001
-- @implements API-JSON-001
fn :: json get int JsonVal String Int => Int
      json get int val dot_path fallback = j_unwrap_int (json get path val dot_path) fallback

fn :: j_unwrap_int JsonVal     Int      => Int
      j_unwrap_int (JsonInt n) _        =  n
      j_unwrap_int _           fallback =  fallback

-- @implements FR-JSON-001
-- @implements API-JSON-001
fn :: json get bool JsonVal String Bool => Bool
      json get bool val dot_path fallback = j_unwrap_bool (json get path val dot_path) fallback

fn :: j_unwrap_bool JsonVal      Bool     => Bool
      j_unwrap_bool (JsonBool b) _        =  b
      j_unwrap_bool _            fallback =  fallback

fn :: j_put_field [JsonField] String JsonVal => [JsonField]
      j_put_field []          key    new_val =  [JsonField key new_val]
      j_put_field ((JsonField k v):fs) key new_val
        | k == key = [JsonField key new_val] :: fs
        | otherwise = [JsonField k v] :: (j_put_field fs key new_val)

-- @implements FR-JSON-001
-- @implements API-JSON-001
fn :: json set field JsonVal String JsonVal => JsonVal
      json set field (JsonObj fields) key new_val = JsonObj (j_put_field fields key new_val)
      json set field _ key new_val = JsonObj [JsonField key new_val]
