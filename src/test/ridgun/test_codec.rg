-- ============================================================
-- src/test/ridgun/test_codec.rg
-- Automated test suite for codec.rg (TS-CODEC-001)
-- @tests TS-CODEC-001
-- ============================================================

import test
import posix
import codec

fn :: rnd snd (Int, String) => String
      rnd snd (_, s)        =  s

fn :: check binary roundtrip loop Int => ()
      check binary roundtrip loop rem =
        | rem <= 0  = ()
        | otherwise =
          b = rnd snd (sys random bytes 32)
          _ = assert_int_equals (str_len b) 32 "random 32 byte length"
          _ = assert_str_eq (base64 decode (base64 encode b)) b "base64 binary roundtrip"
          _ = assert_str_eq (base64url decode (base64url encode b)) b "base64url binary roundtrip"
          _ = assert_str_eq (hex decode (hex encode b)) b "hex binary roundtrip"
          check binary roundtrip loop (rem - 1)

-- @tests TS-CODEC-001
fn :: test rfc4648 hex and base64 => ()
      test rfc4648 hex and base64 =
        -- 1. Hexadecimal RFC 4648 test vectors & negative validation
        _ = assert_str_eq (hex encode "") "" "hex_encode empty"
        _ = assert_str_eq (hex encode "foobar") "666f6f626172" "hex_encode foobar"
        _ = assert_str_eq (hex decode "666f6f626172") "foobar" "hex_decode lowercase"
        _ = assert_str_eq (hex decode "666F6F626172") "foobar" "hex_decode uppercase"
        _ = assert_true (is valid hex "deadBEEF09") "is_valid_hex valid"
        _ = assert_false (is valid hex "abc") "is_valid_hex odd length"
        _ = assert_false (is valid hex "deadZZ") "is_valid_hex invalid chars"
        _ = assert_str_eq (hex decode "abc") "" "hex_decode odd -> empty"

        -- 2. Base64 & Base64url RFC 4648 test vectors
        _ = assert_str_eq (base64 encode "") "" "b64 empty"
        _ = assert_str_eq (base64 encode "f") "Zg==" "b64 f"
        _ = assert_str_eq (base64 encode "fo") "Zm8=" "b64 fo"
        _ = assert_str_eq (base64 encode "foo") "Zm9v" "b64 foo"
        _ = assert_str_eq (base64 encode "foob") "Zm9vYg==" "b64 foob"
        _ = assert_str_eq (base64 encode "fooba") "Zm9vYmE=" "b64 fooba"
        _ = assert_str_eq (base64 encode "foobar") "Zm9vYmFy" "b64 foobar"
        _ = assert_str_eq (base64 decode "Zg==") "f" "b64 dec f"
        _ = assert_str_eq (base64 decode "Zm8=") "fo" "b64 dec fo"
        _ = assert_str_eq (base64 decode "Zm9v") "foo" "b64 dec foo"
        _ = assert_str_eq (base64 decode "Zm9vYg==") "foob" "b64 dec foob"
        _ = assert_str_eq (base64 decode "Zm9vYmE=") "fooba" "b64 dec fooba"
        _ = assert_str_eq (base64 decode "Zm9vYmFy") "foobar" "b64 dec foobar"
        _ = assert_str_eq (base64url encode "foob") "Zm9vYg" "b64url nopad"
        _ = assert_str_eq (base64url decode "Zm9vYg") "foob" "b64url dec"
        _ = assert_false (is valid base64 "A") "invalid base64 len%4==1"
        _ = assert_false (is valid base64 "Zm$v") "invalid base64 char"
        _ = assert_str_eq (base64 decode "Zm$v") "" "invalid base64 -> empty"

        -- 3. LIB-8: Binary-safe decoding for raw octets >= 0x80 and 0x00
        raw4 = hex decode "c800ff41"
        _    = assert_int_equals (str_len raw4) 4 "str_len (hex_decode c800ff41) == 4"
        _    = assert_int_equals (str_char_at raw4 0) 200 "raw4[0] == 0xc8"
        _    = assert_int_equals (str_char_at raw4 1) 0 "raw4[1] == 0x00"
        _    = assert_int_equals (str_char_at raw4 2) 255 "raw4[2] == 0xff"
        _    = assert_int_equals (str_char_at raw4 3) 65 "raw4[3] == 0x41"
        _    = assert_str_eq (hex encode raw4) "c800ff41" "hex_encode raw4 == c800ff41"
        _    = check binary roundtrip loop 10
        ()

-- @tests TS-CODEC-001
fn :: test rfc3986 url and query strings => ()
      test rfc3986 url and query strings =
        raw = "hello world&x=1+2%"
        enc = url encode raw
        _   = assert_str_eq enc "hello%20world%26x%3D1%2B2%25" "url_encode"
        _   = assert_str_eq (url decode enc) raw "url_decode roundtrip"
        _   = assert_str_eq (url decode "a+b%20c") "a b c" "url_decode plus as space"
        qs  = query string encode [("q", "ridgun libs"), ("page", "2")]
        _   = assert_str_eq qs "q=ridgun%20libs&page=2" "query_string_encode"
        dec = query string decode ("?" + qs)
        _   = assert eq dec [("q", "ridgun libs"), ("page", "2")]
        ()

-- @tests TS-CODEC-001
fn :: test rfc8259 lightweight json => ()
      test rfc8259 lightweight json =
        esc = json escape "line1\n\"quoted\"\\tab\t"
        _   = assert_str_eq esc "line1\\n\\\"quoted\\\"\\\\tab\\t" "json_escape"
        _   = assert_str_eq (json unescape esc) "line1\n\"quoted\"\\tab\t" "json_unescape"
        doc = json object [("service", json quote "solstice"), ("port", json int 8443), ("tls", json bool True), ("extra", json null)]
        _   = assert_str_eq doc "{\"service\":\"solstice\",\"port\":8443,\"tls\":true,\"extra\":null}" "json_object"
        _   = assert_str_eq (json get str doc "service") "solstice" "json_get_str"
        _   = assert_str_eq (json get str doc "missing") "" "json_get_str missing"
        _   = assert_int_equals (json get int doc "port" 80) 8443 "json_get_int"
        _   = assert_int_equals (json get int doc "missing" 80) 80 "json_get_int fallback"
        _   = assert_int_equals (json get int doc "service" 80) 80 "json_get_int non-int fallback"
        _   = assert_true (json get bool doc "tls" False) "json_get_bool"
        _   = assert_false (json get bool doc "missing" False) "json_get_bool fallback"
        arr = json array [json int 1, json int 2, json quote "three"]
        _   = assert_str_eq arr "[1,2,\"three\"]" "json_array"
        s_o = json str object [("k1", "v1"), ("k2", "v\"2")]
        _   = assert_str_eq (json get str s_o "k2") "v\"2" "json_str_object escaped roundtrip"
        ()

fn :: main => ()
      main =
        _ = test rfc4648 hex and base64
        _ = test rfc3986 url and query strings
        _ = test rfc8259 lightweight json
        echo "[PASS] test_codec: TS-CODEC-001 passed"
