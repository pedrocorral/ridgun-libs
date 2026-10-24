#!/usr/bin/env python3
"""Writes tests/test_json.rg. Two kinds of checks, named in each label:
  [contract] what docs/requirements/functional/json/FR-JSON-001 and API-JSON-001 promise;
  [RFC 8259] what RFC 8259 requires of any JSON parser or generator; Python's json module (strict) is the reference
             for which texts are valid. Where the contract departs from the RFC (numbers are Int only), the label says so."""
import json, os

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "test_json.rg")


def lit(s):
    """A Ridgun expression for these bytes: a string literal when printable, else bytes_from_list pieces."""
    b = s.encode() if isinstance(s, str) else s
    if all(32 <= c < 127 for c in b) or all(c >= 32 or c in (9, 10, 13) for c in b) and b"\x7f" not in b:
        t = b.decode("utf-8")
        return '"' + t.replace("\\", "\\\\").replace('"', '\\"').replace("{", "\\{").replace("}", "\\}").replace("\t", "\\t").replace("\n", "\\n").replace("\r", "\\r") + '"'
    return "(bytes_from_list [" + ", ".join(str(c) for c in b) + "])"


def lbl(s):
    return s.replace("\\", "\\\\").replace('"', '\\"').replace("{", "\\{").replace("}", "\\}")


def valid(text):
    try:
        json.loads(text, parse_constant=lambda c: (_ for _ in ()).throw(ValueError(c)))
        return True
    except ValueError:
        return False


checks = []
add = checks.append

# ── [RFC 8259] texts a parser must refuse (Python's strict json agrees for each) ──
REJECT = [("leading zero (§6)", "01"), ("negative leading zero (§6)", "-01"), ("leading zero in an array (§6)", "[01]"), ("plus sign (§6)", "+1"),
          ("fraction without integer part (§6)", ".5"), ("fraction without digits (§6)", "1."), ("exponent without digits (§6)", "1e"), ("hex number (§6)", "0x10"),
          ("NaN (§6)", "NaN"), ("Infinity (§6)", "Infinity"), ("trailing comma in an array (§5)", "[1,]"), ("trailing comma in an object (§4)", '{"a":1,}'),
          ("missing comma (§5)", "[1 2]"), ("missing colon (§4)", '{"a" 1}'), ("number as a key (§4)", '{1:2}'), ("single quotes (§7)", "'a'"),
          ("raw tab in a string (§7)", '"a\tb"'), ("raw line feed in a string (§7)", '"a\nb"'), ("raw NUL in a string (§7)", b'"a\x00b"'),
          ("invalid escape \\x (§7)", '"\\x41"'), ("short \\u escape (§7)", '"\\u12"'), ("unclosed array", "[1"), ("unclosed string", '"abc'),
          ("trailing data after the value (§2)", '{"a":1}}'), ("two values (§2)", "1 2"), ("empty text (§2)", ""), ("only whitespace (§2)", " \n "),
          ("vertical tab is not whitespace (§2)", "[\x0b1]"), ("no-break space is not whitespace (§2)", "[\u00a01]"), ("BOM-less garbage", "nul"), ("true in capitals", "True")]
for name, text in REJECT:
    t = text.decode("latin-1") if isinstance(text, bytes) else text
    assert not valid(t), name
    add('lt_false "[RFC 8259] refuses %s: %s" (json_t_ok (json_parse %s))' % (lbl(name), lbl(repr(t)), lit(text)))

# ── [RFC 8259] texts a parser must accept; the value is checked through json_stringify (compact, key order kept) ──
ACCEPT = [("negative zero", "-0", "0"), ("whitespace of all four kinds around a value", " \t\n\r[1] \r\n\t", "[1]"), ("empty containers", '[[],{},""]', '[[],{},""]'),
          ("top-level string", '"x"', '"x"'), ("top-level null", "null", "null"), ("nested", '{"a":[{"b":[true,false,null]}]}', '{"a":[{"b":[true,false,null]}]}'),
          ("escaped slash \\/ decodes to /", '"a\\/b"', '"a/b"'), ("largest 64-bit integer", "9223372036854775807", "9223372036854775807"),
          ("smallest 64-bit integer", "-9223372036854775808", "-9223372036854775808")]
for name, text, out in ACCEPT:
    assert valid(text), name
    add('lt_eq "[RFC 8259] accepts %s" (json_t_compact (json_parse %s)) %s' % (lbl(name), lit(text), lit(out)))
for name, text in [("a fraction 1.5", "1.5"), ("an exponent 1e5", "1e5"), ("a negative fraction with exponent -1.5E-3", "-1.5E-3")]:
    assert valid(text)
    add('lt_true "[RFC 8259 §6] accepts %s (FR-JSON-001 says Int only: browsers and APIs send these)" (json_t_ok (json_parse %s))' % (lbl(name), lit(text)))
add('lt_true "[RFC 8259 §6] 9223372036854775808 (above Int) is refused or kept exactly, never wrapped" (json_t_exact_or_refused "9223372036854775808")')
add('lt_true "[RFC 8259 §6] 99999999999999999999999 is refused or kept exactly, never wrapped" (json_t_exact_or_refused "99999999999999999999999")')

# ── [contract] escapes decode to bytes (API-JSON-001; RFC 8259 §7) ──
add('lt_hex "[contract] \\\\b \\\\f \\\\n \\\\r \\\\t \\\\\\" \\\\\\\\ \\\\/ decode to their bytes" (json_t_strval (json_parse %s)) "%s"' % (lit('"\\b\\f\\n\\r\\t\\"\\\\\\/"'), json.loads('"\\b\\f\\n\\r\\t\\"\\\\\\/"').encode().hex()))
add('lt_hex "[contract] \\\\u0000 decodes to one NUL byte" (json_t_strval (json_parse %s)) "00"' % lit('"\\u0000"'))
add('lt_hex "[contract] \\\\u00e9 \\\\u20ac \\\\ud83d\\\\ude00 decode to UTF-8" (json_t_strval (json_parse %s)) "%s"' % (lit('"\\u00e9\\u20ac\\ud83d\\ude00"'), "é€😀".encode().hex()))

# ── [RFC 8259 §7] json_stringify escapes every control byte, and parse(stringify v) == v ──
ctl = bytes(range(0, 32)) + b'"\\/' + "é😀".encode()
add('lt_true "[RFC 8259 §7] json_stringify leaves no raw control byte 0x00-0x1F in a string" (json_t_no_controls (json_stringify (JsonStr %s)))' % lit(ctl))
add('lt_hex "[RFC 8259 §7] parse (stringify s) gives s back for every control byte, quote, backslash, slash and UTF-8" (json_t_strval (json_parse (json_stringify (JsonStr %s)))) "%s"' % (lit(ctl), ctl.hex()))

# ── [contract] getters, set, path, limits (FR-JSON-001, API-JSON-001) ──
doc = '{"s":"x","n":5,"b":true,"z":null,"a":[10,{"k":"v"}],"o":{"p":{"q":7}}}'
add('lt_eq "[contract] json_get_str of a number field gives the fallback" (json_get_str (json_t_val %s) "n" "fb") "fb"' % lit(doc))
add('lt_int "[contract] json_get_int of a string field gives the fallback" (json_get_int (json_t_val %s) "s" 42) 42' % lit(doc))
add('lt_false "[contract] json_get_bool of null gives the fallback" (json_get_bool (json_t_val %s) "z" False)' % lit(doc))
add('lt_eq "[contract] json_get_str of a missing field gives the fallback" (json_get_str (json_t_val %s) "missing" "fb") "fb"' % lit(doc))
add('lt_eq "[contract] json_get_path a.1.k" (json_stringify (json_get_path (json_t_val %s) "a.1.k")) "\\"v\\""' % lit(doc))
add('lt_eq "[contract] json_get_path o.p.q" (json_stringify (json_get_path (json_t_val %s) "o.p.q")) "7"' % lit(doc))
add('lt_eq "[contract] json_get_path a.9 (out of range) is null" (json_stringify (json_get_path (json_t_val %s) "a.9")) "null"' % lit(doc))
add('lt_eq "[contract] json_set_field replaces in place, keeping key order" (json_stringify (json_set_field (json_t_val %s) "a" (JsonInt 1))) %s' % (lit('{"a":0,"b":1}'), lit('{"a":1,"b":1}')))
add('lt_eq "[contract] json_set_field appends a new key at the end" (json_stringify (json_set_field (json_t_val %s) "c" JsonNull)) %s' % (lit('{"a":0}'), lit('{"a":0,"c":null}')))
add('lt_eq "[contract] json_set_field on a non-object gives a one-field object" (json_stringify (json_set_field (JsonInt 3) "k" (JsonBool True))) %s' % lit('{"k":true}'))
add('lt_true "[contract] json_parse_with_limits: exactly max_bytes is accepted" (json_t_ok (json_parse_with_limits "[1,2]" 64 5))')
add('lt_false "[contract] json_parse_with_limits: one byte over max_bytes is refused" (json_t_ok (json_parse_with_limits "[1,2] " 64 5))')
add('lt_false "[contract] json_parse_with_limits: depth 3 with max_depth 2 is refused" (json_t_ok (json_parse_with_limits "[[[1]]]" 2 100))')
add('lt_true "[contract] json_parse_with_limits: depth 2 with max_depth 2 is accepted" (json_t_ok (json_parse_with_limits "[[1]]" 2 100))')
add('lt_false "[contract] 100 000 nested arrays are refused (default depth 64) without exhausting the stack" (json_t_ok (json_parse (json_t_nest 100000))))')

body = "\n".join(f"        c{i} = {c}" for i, c in enumerate(checks))
names = ", ".join([f"c{i}" for i in range(len(checks))] + ["t0", "t1"])
src = f'''-- test_json.rg — json against its contract (FR-JSON-001, API-JSON-001) and RFC 8259.
-- Generated by tests/gen/make_json.py: labels say [contract] or [RFC 8259 §n]; Python's strict json module confirms
-- each text is valid or invalid JSON. Where the contract departs from the RFC, the label says so.

import test
import str
import posix
import crypto
import json
import lt

fn :: json_t_ok JsonRes => Bool
      json_t_ok (JsonOk _)  =  True
      json_t_ok (JsonErr _) =  False

-- The value as compact JSON, or "ERR: …" when parsing failed.
fn :: json_t_compact JsonRes => String
      json_t_compact (JsonOk v)  =  json_stringify v
      json_t_compact (JsonErr e) =  "ERR: " + e

fn :: json_t_val String => JsonVal
      json_t_val s =  json_t_val_of (json_parse s)

fn :: json_t_val_of JsonRes => JsonVal
      json_t_val_of (JsonOk v)  =  v
      json_t_val_of (JsonErr _) =  JsonNull

-- The string inside a parsed top-level string, or "ERR" (shown as hex 455252).
fn :: json_t_strval JsonRes => String
      json_t_strval (JsonOk (JsonStr s)) =  s
      json_t_strval _                    =  "ERR"

fn :: json_t_exact_or_refused String => Bool
      json_t_exact_or_refused text =  json_t_exact_of text (json_parse text)

fn :: json_t_exact_of String JsonRes => Bool
      json_t_exact_of text (JsonOk v)  =  (json_stringify v) == text
      json_t_exact_of _    (JsonErr _) =  True

fn :: json_t_no_controls String => Bool
      json_t_no_controls s =  json_t_no_controls_from s 0

fn :: json_t_no_controls_from String Int => Bool
      json_t_no_controls_from s i =
        | i >= (str_len s)                                = True
        | (((str_char_at s i) % 256 + 256) % 256) < 32    = False
        | otherwise                                       = json_t_no_controls_from s (i + 1)

fn :: json_t_brackets Int String String => String
      json_t_brackets n acc ch =
        | n <= 0    = acc
        | otherwise = json_t_brackets (n - 1) (acc + ch) ch

fn :: json_t_nest Int => String
      json_t_nest n =  (json_t_brackets n "" "[") + (json_t_brackets n "" "]")

-- An array of n strings, for timing: ["item 0 é","item 1 é",…]
fn :: json_t_items Int Int [String] => [String]
      json_t_items i n acc =
        | i >= n    = acc
        | otherwise = json_t_items (i + 1) n (acc :: ["\\"item " + (int_to_str i) + " \\\\\\" é\\""])

fn :: json_t_array Int => String
      json_t_array n =  "[" + (str_join (json_t_items 0 n []) ",") + "]"

fn :: main => ()
      main =
{body}
        small = json_t_array 1500
        big = json_t_array 15000
        s0 = sys_monotonic_ms
        _ = json_t_ok (json_parse_with_limits small 64 10000000)
        m0 = sys_monotonic_ms
        _ = json_t_ok (json_parse_with_limits big 64 10000000)
        e0 = sys_monotonic_ms
        t0 = lt_linear "json_parse: 20 KB then 200 KB in linear time, 200 KB under 2 s" (m0 - s0) (e0 - m0) 10 2000
        vs = json_t_val small
        vb = json_t_val big
        s1 = sys_monotonic_ms
        _ = str_len (json_stringify vs)
        m1 = sys_monotonic_ms
        _ = str_len (json_stringify vb)
        e1 = sys_monotonic_ms
        t1 = lt_linear "json_stringify: 20 KB then 200 KB in linear time, 200 KB under 2 s" (m1 - s1) (e1 - m1) 10 2000
        lt_done "json" [{names}]
'''
open(OUT, "w").write(src)
print(f"wrote {OUT}: {len(checks) + 2} checks")
