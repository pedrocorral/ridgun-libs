-- ============================================================
-- src/test/ridgun/test json.rg
-- Automated test suite for the Recursive RFC 8259 JSON AST & Path Query Library (`json.rg`)
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

-- @tests TS-JSON-001
fn :: test json dot path queries and updates => ()
      test json dot path queries and updates =
        lb = char_from_code 123
        rb = char_from_code 125
        raw = lb + "\"user\":" + lb + "\"name\":\"Ada\",\"age\":36,\"active\":true,\"roles\":[\"admin\",\"math\"]" + rb + ",\"count\":-7" + rb
        val = unwrap_json (json parse raw)

        _ = assert str eq (json get str val "user.name" "") "Ada" "AC2: json get str dot path"
        _ = assert int equals (json get int val "user.age" 0) 36 "AC2: json get int dot path"
        _ = assert int equals (json get int val "count" 0) (-7) "AC2: json get int negative"
        _ = assert true (json get bool val "user.active" False) "AC2: json get bool dot path"
        _ = assert str eq (json get str val "user.roles.1" "") "math" "AC2: json get str array index in dot path"
        _ = assert str eq (json get str val "user.missing" "fallback") "fallback" "AC2: json get str fallback on missing key"

        updated = json set field val "version" (JsonInt 2)
        _ = assert int equals (json get int updated "version" 0) 2 "AC2: json set field"
        ()

-- @tests TS-JSON-001
fn :: test json malformed inputs => ()
      test json malformed inputs =
        lb = char_from_code 123
        _ = assert false (is_json_ok (json parse (lb + "\"unclosed\":1"))) "AC3: reject unclosed object"
        _ = assert false (is_json_ok (json parse "\"unterminated")) "AC3: reject unterminated string"
        _ = assert false (is_json_ok (json parse "[1, 2] trailing")) "AC3: reject trailing garbage"
        ()

-- @tests TS-JSON-001
fn :: main => ()
      main =
        _ = test json parse stringify and pretty
        _ = test json dot path queries and updates
        _ = test json malformed inputs
        echo "[PASS] test json: TS-JSON-001 passed"
