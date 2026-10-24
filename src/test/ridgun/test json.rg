-- ============================================================
-- src/test/ridgun/test json.rg
-- Comprehensive test suite for json.rg inspired by serde_json & JSONTestSuite (RFC 8259)
-- Covers RG-076 (\uXXXX + UTF-16 surrogates), RG-077 (duplicate keys), RG-078 (depth/size limits)
-- @tests TS-JSON-001
-- ============================================================

import test
import json

fn :: is_json_ok JsonRes     => Bool
      is_json_ok (JsonOk _)  =  True
      is_json_ok (JsonErr _) =  False

fn :: unwrap_json JsonRes      => JsonVal
      unwrap_json (JsonOk val) =  val
      unwrap_json (JsonErr _)  =  JsonNull

fn :: is_json_null JsonVal  => Bool
      is_json_null JsonNull =  True
      is_json_null _        =  False

fn :: repeat_str String Int => String
      repeat_str _      0   =  ""
      repeat_str s      n
        | n <= 0 = ""
        | otherwise = s + (repeat_str s (n - 1))

fn :: nested_brackets Int => String
      nested_brackets n
        | n <= 0 = "0"
        | otherwise = "[" + (nested_brackets (n - 1)) + "]"

-- 1. Nested RFC 8259 objects, arrays, primitives, and compact/pretty round-trip
-- @tests TS-JSON-001
fn :: test json parse stringify and pretty => ()
      test json parse stringify and pretty =
        lb = char_from_code 123
        rb = char_from_code 125
        raw = lb + "\"user\":" + lb + "\"name\":\"Ada \\\"Lovelace\\\"\",\"age\":36,\"active\":true,\"roles\":[\"admin\",\"math\"],\"meta\":null" + rb + rb
        res = json parse raw
        _ = assert true (is_json_ok res) "AC1: json parse nested object and array"
        val = unwrap_json res

        compact = json stringify val
        _ = assert str eq compact raw "AC1: json stringify lossless round-trip"

        pretty_s = json pretty val 2
        res2 = json parse pretty_s
        _ = assert true (is_json_ok res2) "AC1: json pretty output parses back cleanly"
        _ = assert str eq (json stringify (unwrap_json res2)) raw "AC1: json pretty round-trip equality"
        ()

-- 2. Empty containers, primitive roots, negative integers, and escaped characters (serde_json vectors)
-- @tests TS-JSON-001
fn :: test json primitives escapes and empty containers => ()
      test json primitives escapes and empty containers =
        lb = char_from_code 123
        rb = char_from_code 125
        bs = char_from_code 92
        nl = char_from_code 10
        tab = char_from_code 9
        _ = assert str eq (json stringify (unwrap_json (json parse (lb + rb)))) (lb + rb) "AC1: empty object {}"
        _ = assert str eq (json stringify (unwrap_json (json parse "[]"))) "[]" "AC1: empty array []"
        _ = assert str eq (json stringify (unwrap_json (json parse ("  " + lb + "  " + rb + "  ")))) (lb + rb) "AC1: whitespace-padded empty object"
        _ = assert true (is_json_null (unwrap_json (json parse "null"))) "AC1: root null literal"
        _ = assert str eq (json stringify (unwrap_json (json parse "true"))) "true" "AC1: root true literal"
        _ = assert str eq (json stringify (unwrap_json (json parse "false"))) "false" "AC1: root false literal"
        _ = assert str eq (json stringify (unwrap_json (json parse "0"))) "0" "AC1: root zero integer"
        _ = assert str eq (json stringify (unwrap_json (json parse "-42000"))) "-42000" "AC1: root negative integer"

        esc_json = lb + "\"msg\":\"line1" + bs + "nline2" + bs + "t" + bs + bs + "slash\"" + rb
        esc_val = unwrap_json (json parse esc_json)
        _ = assert str eq (json get str esc_val "msg" "") ("line1" + nl + "line2" + tab + bs + "slash") "AC1: unescape \\n, \\t, \\\\ in JSON strings"
        _ = assert str eq (json stringify esc_val) esc_json "AC1: re-escape \\n, \\t, \\\\ on stringify"
        ()

-- 3. Deep multi-level dot-path queries, array indexing, field updates, and fallbacks
-- @tests TS-JSON-001
fn :: test json dot path queries and updates => ()
      test json dot path queries and updates =
        lb = char_from_code 123
        rb = char_from_code 125
        raw = lb + "\"user\":" + lb + "\"name\":\"Ada\",\"age\":36,\"active\":true,\"roles\":[\"admin\",\"math\"],\"matrix\":[[10,20],[30,40]]" + rb + ",\"count\":-7,\"disabled\":false" + rb
        val = unwrap_json (json parse raw)

        _ = assert str eq (json get str val "user.name" "") "Ada" "AC2: json get str dot path"
        _ = assert int equals (json get int val "user.age" 0) 36 "AC2: json get int dot path"
        _ = assert int equals (json get int val "count" 0) (-7) "AC2: json get int negative"
        _ = assert true (json get bool val "user.active" False) "AC2: json get bool true"
        _ = assert false (json get bool val "disabled" True) "AC2: json get bool false"
        _ = assert str eq (json get str val "user.roles.0" "") "admin" "AC2: json get str array index 0"
        _ = assert str eq (json get str val "user.roles.1" "") "math" "AC2: json get str array index 1"
        _ = assert int equals (json get int val "user.matrix.1.0" 0) 30 "AC2: nested 2D array index user.matrix.1.0"
        _ = assert int equals (json get int val "user.matrix.1.1" 0) 40 "AC2: nested 2D array index user.matrix.1.1"
        _ = assert str eq (json get str val "user.roles.99" "oob") "oob" "AC2: out-of-bounds array index fallback"
        _ = assert str eq (json get str val "user.missing.deep" "fallback") "fallback" "AC2: missing deep dot-path fallback"

        updated = json set field val "version" (JsonInt 2)
        _ = assert int equals (json get int updated "version" 0) 2 "AC2: json set field adds new key"
        overwritten = json set field updated "count" (JsonInt 99)
        _ = assert int equals (json get int overwritten "count" 0) 99 "AC2: json set field overwrites existing key"
        ()

-- 4. JSONTestSuite malformed / adversarial inputs rejection
-- @tests TS-JSON-001
fn :: test json malformed inputs => ()
      test json malformed inputs =
        lb = char_from_code 123
        rb = char_from_code 125
        _ = assert false (is_json_ok (json parse "")) "AC3: reject empty input"
        _ = assert false (is_json_ok (json parse "   ")) "AC3: reject whitespace-only input"
        _ = assert false (is_json_ok (json parse (lb + "\"unclosed\":1"))) "AC3: reject unclosed object"
        _ = assert false (is_json_ok (json parse "[1, 2, 3")) "AC3: reject unclosed array"
        _ = assert false (is_json_ok (json parse "\"unterminated string")) "AC3: reject unterminated string"
        _ = assert false (is_json_ok (json parse (lb + "unquoted: 1" + rb))) "AC3: reject unquoted object key"
        _ = assert false (is_json_ok (json parse (lb + "\"k\" 1" + rb))) "AC3: reject missing colon in object"
        _ = assert false (is_json_ok (json parse "[1, 2] trailing")) "AC3: reject trailing garbage token"
        _ = assert false (is_json_ok (json parse "tru")) "AC3: reject truncated boolean literal"
        _ = assert false (is_json_ok (json parse "nul")) "AC3: reject truncated null literal"
        ()

-- 5. RG-076: RFC 8259 §7 \uXXXX Unicode escapes & UTF-16 surrogate pairs
-- @tests TS-JSON-001
fn :: test rg076 unicode escapes and surrogates => ()
      test rg076 unicode escapes and surrogates =
        lb = char_from_code 123
        rb = char_from_code 125
        bs = char_from_code 92
        q  = char_from_code 34

        -- Solstice exact repro: {"title":"a\u00e9\"b"} -> "aé\"b" (UTF-8 C3 A9)
        repro_in  = lb + q + "title" + q + ":" + q + "a" + bs + "u00e9" + bs + q + "b" + q + rb
        repro_res = json parse repro_in
        _ = assert true (is_json_ok repro_res) "RG-076: parse \\u00e9 escape succeeds"
        repro_str = json get str (unwrap_json repro_res) "title" "-"
        _ = assert str eq repro_str ("aé" + q + "b") "RG-076: \\u00e9 decoded to UTF-8 é (C3 A9)"
        _ = assert int equals (str_len repro_str) 5 "RG-076: byte length of 'aé\"b' is 5"

        -- 1-byte (\u0041 -> 'A'), 2-byte (\u00E9 -> 'é'), 3-byte (\u20AC -> '€') BMP escapes
        bmp_in  = lb + q + "k" + q + ":" + q + bs + "u0041-" + bs + "u00E9-" + bs + "u20AC" + q + rb
        bmp_res = json parse bmp_in
        _ = assert true (is_json_ok bmp_res) "RG-076: BMP 1/2/3-byte \\uXXXX escapes parse"
        _ = assert str eq (json get str (unwrap_json bmp_res) "k" "") "A-é-€" "RG-076: BMP \\u0041, \\u00E9, \\u20AC decoded"

        -- Surrogate pair (\uD83D\uDE00 -> U+1F600 '😀', 4-byte UTF-8 F0 9F 98 80)
        emo_in  = lb + q + "emoji" + q + ":" + q + bs + "uD83D" + bs + "uDE00" + q + rb
        emo_res = json parse emo_in
        _ = assert true (is_json_ok emo_res) "RG-076: UTF-16 surrogate pair \\uD83D\\uDE00 parses"
        emo_str = json get str (unwrap_json emo_res) "emoji" ""
        _ = assert str eq emo_str "😀" "RG-076: surrogate pair decoded to 😀 (U+1F600)"
        _ = assert int equals (str_len emo_str) 4 "RG-076: 😀 is 4 UTF-8 bytes"

        -- Lone surrogates and malformed \uXXXX must return JsonErr (RFC 8259 §7)
        lone_hi   = lb + q + "bad" + q + ":" + q + bs + "uD83D" + q + rb
        lone_lo   = lb + q + "bad" + q + ":" + q + bs + "uDE00" + q + rb
        hi_non_lo = lb + q + "bad" + q + ":" + q + bs + "uD83D" + bs + "u0041" + q + rb
        hi_text   = lb + q + "bad" + q + ":" + q + bs + "uD83Dabc" + q + rb
        short_hex = lb + q + "bad" + q + ":" + q + bs + "u00e" + q + rb
        bad_hex   = lb + q + "bad" + q + ":" + q + bs + "u00g1" + q + rb
        _ = assert false (is_json_ok (json parse lone_hi)) "RG-076: reject lone high surrogate \\uD83D"
        _ = assert false (is_json_ok (json parse lone_lo)) "RG-076: reject lone low surrogate \\uDE00"
        _ = assert false (is_json_ok (json parse hi_non_lo)) "RG-076: reject high surrogate followed by non-surrogate \\u0041"
        _ = assert false (is_json_ok (json parse hi_text)) "RG-076: reject high surrogate followed by plain text"
        _ = assert false (is_json_ok (json parse short_hex)) "RG-076: reject truncated \\u00e escape"
        _ = assert false (is_json_ok (json parse bad_hex)) "RG-076: reject non-hex \\u00g1 escape"
        ()

-- 6. RG-077: Reject duplicate object keys (RFC 8259 §4)
-- @tests TS-JSON-001
fn :: test rg077 duplicate object keys => ()
      test rg077 duplicate object keys =
        lb = char_from_code 123
        rb = char_from_code 125
        bs = char_from_code 92
        q  = char_from_code 34

        -- Solstice exact repro: {"title":"a","title":"b"} -> must be JsonErr
        dup_top = lb + "\"title\":\"a\",\"title\":\"b\"" + rb
        _ = assert false (is_json_ok (json parse dup_top)) "RG-077: reject duplicate top-level key 'title'"

        -- Duplicate key inside nested object -> must be JsonErr
        dup_nested = lb + "\"meta\":" + lb + "\"k\":1,\"k\":2" + rb + rb
        _ = assert false (is_json_ok (json parse dup_nested)) "RG-077: reject duplicate key in nested object"

        -- Duplicate key disguised via \uXXXX escape ({"a":1,"\u0061":2}) -> must be JsonErr
        dup_escaped = lb + q + "a" + q + ":1," + q + bs + "u0061" + q + ":2" + rb
        _ = assert false (is_json_ok (json parse dup_escaped)) "RG-077: reject duplicate key after \\u0061 unescaping"

        -- Same key name in distinct sibling/nested objects remains valid!
        distinct_scopes = lb + "\"meta\":" + lb + "\"title\":\"x\"" + rb + ",\"title\":\"y\"" + rb
        res_ok = json parse distinct_scopes
        _ = assert true (is_json_ok res_ok) "RG-077: allow same key name in different object scopes"
        _ = assert str eq (json get str (unwrap_json res_ok) "title" "-") "y" "RG-077: top-level key 'title' is 'y'"
        ()

-- 7. RG-078: Enforce maximum nesting depth and maximum input size
-- @tests TS-JSON-001
fn :: test rg078 depth and size limits => ()
      test rg078 depth and size limits =
        -- Default depth limit (64): 32 nested arrays succeed, 80 nested arrays fail
        ok_32   = nested_brackets 32
        deep_80 = nested_brackets 80
        _ = assert true (is_json_ok (json parse ok_32)) "RG-078: 32 nested arrays within default depth limit"
        _ = assert false (is_json_ok (json parse deep_80)) "RG-078: 80 nested arrays exceed default depth limit (64)"

        -- Custom per-endpoint limits via `json parse with limits`
        _ = assert true (is_json_ok (json parse with limits (nested_brackets 5) 5 1024)) "RG-078: depth 5 allowed when max_depth=5"
        _ = assert false (is_json_ok (json parse with limits (nested_brackets 6) 5 1024)) "RG-078: depth 6 rejected when max_depth=5"

        -- Input size limit via `json parse with limits`
        big_str = "\"" + (repeat_str "abcdefghij" 20) + "\""
        _ = assert true (is_json_ok (json parse with limits big_str 64 500)) "RG-078: 202-byte payload allowed when max_bytes=500"
        _ = assert false (is_json_ok (json parse with limits big_str 64 100)) "RG-078: 202-byte payload rejected when max_bytes=100"
        ()

-- @tests TS-JSON-001
fn :: main => ()
      main =
        _ = test json parse stringify and pretty
        _ = test json primitives escapes and empty containers
        _ = test json dot path queries and updates
        _ = test json malformed inputs
        _ = test rg076 unicode escapes and surrogates
        _ = test rg077 duplicate object keys
        _ = test rg078 depth and size limits
        echo "[PASS] test json: TS-JSON-001 (including RG-076, RG-077, RG-078) passed"
