#!/usr/bin/env python3
"""Writes tests/test_codec.rg. Expected values come from codec's own contract (docs/requirements/functional/codec/
FR-CODEC-001, API-CODEC-001) and from independent references: RFC 4648 §10 vectors, Python's base64/binascii, and
RFC 3986 §2.3 (unreserved = A-Z a-z 0-9 - . _ ~) applied by Python. Re-run it to re-derive them."""
import base64, os

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "test_codec.rg")
UNRESERVED = set(b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")


def pct(b):
    return "".join(chr(c) if c in UNRESERVED else "%%%02X" % c for c in b)


def q(s):
    return s.replace("\\", "\\\\").replace('"', '\\"').replace("{", "\\{").replace("}", "\\}")


checks = []
add = checks.append
ALL = "(bytes_from_list (codec_t_range 0 256 []))"

# ── URL encoding (FR-CODEC-001: only A-Z a-z 0-9 - _ . ~ stay; everything else %XX; "+" decodes to space) ──
add('lt_eq "url_encode of every byte 0..255: RFC 3986 unreserved stay, the rest %%XX uppercase" (url_encode %s) "%s"' % (ALL, pct(bytes(range(256)))))
add('lt_hex "url_decode (url_encode b) == b for every byte 0..255 (NUL and >= 0x80 included)" (url_decode (url_encode %s)) "%s"' % (ALL, bytes(range(256)).hex()))
add('lt_eq "url_encode: space is %20, not +" (url_encode "a b") "a%20b"')
add('lt_eq "url_encode: + and % are encoded" (url_encode "1+1=2%") "1%2B1%3D2%25"')
add('lt_eq "url_encode: UTF-8 é is %C3%A9" (url_encode "é") "%C3%A9"')
add('lt_eq "url_encode: \\"\\" gives \\"\\"" (url_encode "") ""')
add('lt_eq "url_decode: + is a space" (url_decode "a+b") "a b"')
add('lt_eq "url_decode: lowercase hex %2b" (url_decode "%2b%2B") "++"')
add('lt_eq "url_decode: %zz is kept as it is" (url_decode "100%zz") "100%zz"')
add('lt_eq "url_decode: a truncated %4 is kept" (url_decode "x%4") "x%4"')
add('lt_eq "url_decode: a lone % at the end is kept" (url_decode "50%") "50%"')
add('lt_hex "url_decode: %00 is one NUL byte" (url_decode "a%00b") "610062"')
add('lt_hex "url_decode: %C3%A9 is the two bytes of é" (url_decode "%C3%A9") "c3a9"')
add('lt_hex "url_decode: %FF alone is the byte 0xFF" (url_decode "%FF") "ff"')

# ── Query strings (FR-CODEC-001: decode(encode pairs) round-trips; code: one leading ?, empty items skipped, missing = gives "", split at the first =, duplicates kept) ──
for name, qs, want in [("two pairs", "a=1&b=2", [("a", "1"), ("b", "2")]), ("a leading ? is dropped", "?a=1", [("a", "1")]),
                       ("a key without = has the value \\\"\\\"", "flag&x=1", [("flag", ""), ("x", "1")]), ("empty items are skipped", "a=1&&b=2&", [("a", "1"), ("b", "2")]),
                       ("only the first = splits", "a=b=c", [("a", "b=c")]), ("duplicate keys are kept in order", "k=1&k=2", [("k", "1"), ("k", "2")]),
                       ("keys and values are decoded (+ is a space, %26 is &)", "na+me=a%26b+c", [("na me", "a&b c")]), ("\\\"\\\" gives no pairs", "", []), ("\\\"?\\\" gives no pairs", "?", [])]:
    add('lt_eq "query_string_decode: %s" (codec_t_pairs (query_string_decode "%s")) "%s"' % (name, qs, "".join(f"[{q(k)}][{q(v)}]" for k, v in want)))
add('lt_eq "query_string_decode (query_string_encode pairs) gives the pairs back, with = & + %% é and \\"\\" in them" (codec_t_pairs (query_string_decode (query_string_encode codec_t_tricky_pairs))) "%s"' % q("[a=b][x&y][1+1][50% é][][empty key][e][]"))

# ── Hex (FR-CODEC-001: decode accepts both cases; odd length or a non-hex character gives ""; code: encode is lowercase) ──
add('lt_eq "hex_encode of every byte 0..255 (lowercase)" (hex_encode %s) "%s"' % (ALL, bytes(range(256)).hex()))
add('lt_hex "hex_decode accepts mixed case" (hex_decode "DEADbeef00") "deadbeef00"')
add('lt_hex "hex_decode (hex_encode b) == b for every byte" (hex_decode (hex_encode %s)) "%s"' % (ALL, bytes(range(256)).hex()))
add('lt_eq "hex_decode of an odd length gives \\"\\"" (hex_decode "abc") ""')
add('lt_eq "hex_decode with a non-hex character gives \\"\\"" (hex_decode "0g") ""')
add('lt_false "is_valid_hex refuses \\"0x10\\"" (is_valid_hex "0x10")')

# ── Base64 (RFC 4648 §4, §5, §10; FR-CODEC-001: standard with = padding, base64url without; invalid input gives "") ──
for s in [b"", b"f", b"fo", b"foo", b"foob", b"fooba", b"foobar"]:
    add('lt_eq "base64_encode RFC 4648 §10: %s" (base64_encode "%s") "%s"' % (s.decode() or "empty", s.decode(), base64.b64encode(s).decode()))
    add('lt_eq "base64_decode RFC 4648 §10: %s" (base64_decode "%s") "%s"' % (base64.b64encode(s).decode() or "empty", base64.b64encode(s).decode(), s.decode()))
    add('lt_eq "base64url_encode (no padding): %s" (base64url_encode "%s") "%s"' % (s.decode() or "empty", s.decode(), base64.urlsafe_b64encode(s).decode().rstrip("=")))
add('lt_eq "base64_encode of every byte 0..255" (base64_encode %s) "%s"' % (ALL, base64.b64encode(bytes(range(256))).decode()))
add('lt_hex "base64_decode (base64_encode b) == b for every byte" (base64_decode (base64_encode %s)) "%s"' % (ALL, bytes(range(256)).hex()))
add('lt_eq "base64_encode of fb ff bf uses + and /" (base64_encode (bytes_from_list [251, 255, 191])) "+/+/"')
add('lt_eq "base64url_encode of fb ff bf uses - and _ (RFC 4648 §5)" (base64url_encode (bytes_from_list [251, 255, 191])) "-_-_"')
add('lt_hex "base64url_decode \\"-_-_\\"" (base64url_decode "-_-_") "fbffbf"')
add('lt_eq "base64_decode without padding (\\"Zg\\")" (base64_decode "Zg") "f"')
add('lt_eq "base64_decode: a character outside the alphabet gives \\"\\"" (base64_decode "Zm9v!") ""')
add('lt_eq "base64_decode: one leftover character (length % 4 == 1) gives \\"\\"" (base64_decode "Zm9vY") ""')
add('lt_eq "base64_decode: = in the middle gives \\"\\"" (base64_decode "Zg==Zg==") ""')
add('lt_eq "base64_decode: whitespace gives \\"\\"" (base64_decode "Zm9v YmFy") ""')
add('lt_false "is_valid_base64 refuses \\"Zm9v!\\"" (is_valid_base64 "Zm9v!")')

# ── Lightweight JSON helpers (FR-CODEC-001 cites RFC 8259) ──
add('lt_true "json_escape leaves no raw control byte 0x00-0x1F (RFC 8259 §7: they MUST be escaped)" (codec_t_no_controls (json_escape (bytes_from_list (codec_t_range 0 32 []))))')
add('lt_hex "json_unescape (json_escape s) == s for every byte 0x01..0x7F" (json_unescape (json_escape (bytes_from_list (codec_t_range 1 128 [])))) "%s"' % bytes(range(1, 128)).hex())
add('lt_eq "json_quote escapes quote and backslash" (json_quote "a\\"b\\\\c") "\\"a\\\\\\"b\\\\\\\\c\\""')

# ── Time: linear in the input (url_encode / url_decode / query_string_decode took 16.4 s / 10.6 s / 10.6 s for 200 KB, Solstice register RG-083) ──
TIMED = [("url_encode", "url_encode"), ("url_decode", "url_decode"), ("query_string_decode", "codec_t_qs_len")]

body = "\n".join(f"        c{i} = {c}" for i, c in enumerate(checks))
names = ", ".join(f"c{i}" for i in range(len(checks)))
timing = []
for i, (label, fn) in enumerate(TIMED):
    timing.append(f'''        s{i} = sys_monotonic_ms
        _ = codec_t_touch ({fn} small_{label})
        m{i} = sys_monotonic_ms
        _ = codec_t_touch ({fn} big_{label})
        e{i} = sys_monotonic_ms
        t{i} = lt_linear "{label}: 20 KB then 200 KB in linear time, 200 KB under 2 s" (m{i} - s{i}) (e{i} - m{i}) 10 2000''')
setup = '''        small_url_encode = str_repeat "Some text & more: a=1+2 café.\\n" 650
        big_url_encode = str_repeat "Some text & more: a=1+2 café.\\n" 6500
        small_url_decode = url_encode small_url_encode
        big_url_decode = url_encode big_url_encode
        small_query_string_decode = "title=x&body=" + small_url_decode
        big_query_string_decode = "title=x&body=" + big_url_decode'''
tnames = ", ".join(f"t{i}" for i in range(len(TIMED)))

src = f'''-- test_codec.rg — codec against its contract (FR-CODEC-001, API-CODEC-001) and RFC 3986 / RFC 4648 / RFC 8259.
-- Generated by tests/gen/make_codec.py, which says where each expected value comes from. Binary inputs are built
-- with crypto's bytes_from_list, never with codec itself.

import test
import str
import posix
import crypto
import codec
import lt

fn :: codec_t_range Int Int [Int] => [Int]
      codec_t_range i n acc =
        | i >= n    = acc
        | otherwise = codec_t_range (i + 1) n (acc :: [i])

-- Pairs as "[k][v]…", so a wrong split, a lost pair or a wrong order all show.
fn :: codec_t_pairs [String String] => String
      codec_t_pairs []          =  ""
      codec_t_pairs ((k, v):ps) =  "[" + k + "][" + v + "]" + (codec_t_pairs ps)

fn :: codec_t_tricky_pairs => [String String]
      codec_t_tricky_pairs =  [("a=b", "x&y"), ("1+1", "50% é"), ("", "empty key"), ("e", "")]

fn :: codec_t_no_controls String => Bool
      codec_t_no_controls s =  codec_t_no_controls_from s 0

fn :: codec_t_no_controls_from String Int => Bool
      codec_t_no_controls_from s i =
        | i >= (str_len s)                                    = True
        | (((str_char_at s i) % 256 + 256) % 256) < 32        = False
        | otherwise                                           = codec_t_no_controls_from s (i + 1)

fn :: codec_t_qs_len String => String
      codec_t_qs_len qs =  int_to_str (codec_t_count (query_string_decode qs) 0)

fn :: codec_t_count [String String] Int => Int
      codec_t_count []     n =  n
      codec_t_count (_:ps) n =  codec_t_count ps (n + 1)

-- Uses a result so the work can't be skipped.
fn :: codec_t_touch String => Int
      codec_t_touch s =  str_len s

fn :: main => ()
      main =
{body}
{setup}
{chr(10).join(timing)}
        lt_done "codec" [{names}, {tnames}]
'''
open(OUT, "w").write(src)
print(f"wrote {OUT}: {len(checks) + len(TIMED)} checks")
