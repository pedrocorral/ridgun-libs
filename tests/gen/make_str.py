#!/usr/bin/env python3
"""Writes tests/test_str.rg. Expected values follow str's contract (docs/requirements/functional/str/FR-STR-001,
API-STR-001): byte indexes, -1 when not found, 0 for an empty needle, trim strips only space \\t \\n \\r, replace is
left to right without overlaps and leaves s unchanged for an empty `old`, split keeps empty segments and gives [""]
for "", case changes touch ASCII letters only. Python applies those rules to the same bytes to give each value."""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rg_strict import strict

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "test_str.rg")


def rg(b):
    if isinstance(b, str):
        b = b.encode()
    if all(32 <= c < 127 and c not in (34, 92, 123, 125) for c in b):
        return '"' + b.decode() + '"'
    return "(bytes_from_list [" + ", ".join(str(c) for c in b) + "])"


def lst(items):
    return "".join("[" + x.decode("utf-8", "replace") + "]" for x in items)


checks = []
add = checks.append


def eq(label, expr, want):
    w = want.encode() if isinstance(want, str) else want
    if all(32 <= c < 127 or c >= 128 for c in w) and b"\\" not in w and b'"' not in w and b"{" not in w and b"}" not in w:
        try:
            add('lt_eq "%s" %s "%s"' % (label, expr, w.decode()))
            return
        except UnicodeDecodeError:
            pass
    add('lt_hex "%s" %s "%s"' % (label, expr, w.hex()))


# index of (bytes)
for label, h, n, want in [("needle at the start", "abc", "a", 0), ("needle at the end", "abc", "c", 2), ("first of two", "abab", "b", 1),
                          ("not found is -1", "abc", "x", -1), ("needle longer than the text is -1", "ab", "abc", -1), ("empty needle is 0", "abc", "", 0),
                          ("empty text, empty needle is 0", "", "", 0), ("empty text is -1", "", "a", -1),
                          ("byte index after a two-byte é", "café!", "!", 5), ("finds a multi-byte needle", "naïve", "ï", 2),
                          ("finds a NUL byte", b"ab\x00cd", b"\x00", 2), ("finds a byte >= 0x80 in binary data", b"\x01\x02\xff\x03", b"\xff", 2)]:
    add('lt_int "str_index_of: %s" (str_index_of %s %s) %s' % (label, rg(h), rg(n), f"(0 - {-want})" if want < 0 else want))

# trim
for label, s, want in [("spaces, tabs, CR and LF at both ends", "\t\n x y \r\n", "x y"), ("only whitespace gives \\\"\\\"", " \t\r\n ", ""),
                       ("inner whitespace stays", "a  \t b", "a  \t b"), ("NUL is not whitespace", b"\x00a\x00", b"\x00a\x00"),
                       ("a no-break space (C2 A0) is not ASCII whitespace", b"\xc2\xa0a\xc2\xa0", b"\xc2\xa0a\xc2\xa0"), ("UTF-8 text stays whole", " ñandú ", "ñandú")]:
    eq("str_trim: " + label, "(str_trim %s)" % rg(s), want)

# replace
for label, s, old, new, want in [("non-overlapping, left to right", "aaaa", "aa", "b", "bb"), ("odd count leaves the rest", "aaa", "aa", "b", "ba"),
                                 ("empty old leaves s unchanged", "abc", "", "x", "abc"), ("deleting", "a-b-c", "-", "", "abc"),
                                 ("new contains old: no rescan", "aaa", "a", "aa", "aaaaaa"), ("multi-byte old", "éxé", "é", "e", "exe"),
                                 ("NUL bytes are replaced too", b"a\x00b\x00", b"\x00", b"_", b"a_b_"), ("bytes >= 0x80 are kept around matches", b"\xff-\xfe", b"-", b"+", b"\xff+\xfe"),
                                 ("old longer than s", "ab", "abc", "x", "ab")]:
    eq("str_replace: " + label, "(str_replace %s %s %s)" % (rg(s), rg(old), rg(new)), want)

# split
for label, s, sep, want in [("keeps empty segments", "a,,b", ",", [b"a", b"", b"b"]), ("separators at both ends", ",a,", ",", [b"", b"a", b""]),
                            ("\\\"\\\" gives [\\\"\\\"] (FR-STR-001)", "", ",", [b""]), ("no separator gives the whole text", "abc", ",", [b"abc"]),
                            ("multi-byte separator", "a::b::", "::", [b"a", b"b", b""]), ("separator longer than the text", "ab", "abc", [b"ab"]),
                            ("UTF-8 separator", "aéb", "é", [b"a", b"b"]), ("UTF-8 text around an ASCII separator", "ñ,ü", ",", ["ñ".encode(), "ü".encode()])]:
    add('lt_eq "str_split: %s" (str_t_list (str_split %s %s)) "%s"' % (label, rg(s), rg(sep), lst(want).replace('"', '\\"')))
for s, sep in [("a,,b,", ","), (",", ","), ("", ","), ("x::y", "::"), ("café,thé", ",")]:
    add('lt_eq "str_join (str_split s sep) sep == s for %s" (str_join (str_split %s %s) %s) %s' % (rg(s).replace('"', '\\"'), rg(s), rg(sep), rg(sep), rg(s)))
add('lt_eq "str_join [] gives \\"\\"" (str_join [] ",") ""')
add('lt_eq "str_join of one item adds no separator" (str_join ["a"] ",") "a"')
add('lt_eq "str_join keeps empty items" (str_join ["", "", ""] ",") ",,"')

# case (ASCII letters only; every other byte unchanged)
upper = bytes((c - 32 if 97 <= c <= 122 else c) for c in range(256))
lower = bytes((c + 32 if 65 <= c <= 90 else c) for c in range(256))
add('lt_hex "str_to_upper of every byte 0..255 changes only a-z" (str_to_upper (bytes_from_list (str_t_range 0 256 []))) "%s"' % upper.hex())
add('lt_hex "str_to_lower of every byte 0..255 changes only A-Z" (str_to_lower (bytes_from_list (str_t_range 0 256 []))) "%s"' % lower.hex())
eq("str_to_upper leaves UTF-8 letters as they are", '(str_to_upper "ñandú é")', "ñANDú é")

# repeat and pad
for label, s, n, want in [("3 times", "ab", 3, "ababab"), ("0 times", "ab", 0, ""), ("negative count", "ab", -2, ""), ("empty text", "", 5, ""), ("bytes >= 0x80", b"\xff", 3, b"\xff\xff\xff")]:
    eq("str_repeat: " + label, "(str_repeat %s %s)" % (rg(s), f"(0 - {-n})" if n < 0 else n), want)
eq("str_pad_left to width 3 with 0", '(str_pad_left "7" 3 "0")', "007")
eq("str_pad_right to width 4 with .", '(str_pad_right "ab" 4 ".")', "ab..")
eq("str_pad_left: width not above the length leaves it", '(str_pad_left "abcd" 2 "0")', "abcd")

# time: linear in the input, and under 0.5 s for 200 KB (str_replace and str_to_lower took 7.9 s, RG-082; after c65ce80
# they take 0-60 ms, but str_split regressed to 1.5 s in the bundle of 22:59, RG-091, which a 2 s limit let through)
TIMED = [("str_replace (nothing to replace)", 'str_replace small "\\r\\n" "\\n"', 'str_replace big "\\r\\n" "\\n"'),
         ("str_to_lower", "str_to_lower small", "str_to_lower big"),
         ("str_to_upper", "str_to_upper small", "str_to_upper big"),
         ("str_join (2 000 then 20 000 parts)", 'str_join small_parts "\\n"', 'str_join big_parts "\\n"'),
         ("str_split", 'str_t_count (str_split small "\\n")', 'str_t_count (str_split big "\\n")'),
         ("str_index_of (not found)", 'int_to_str (str_index_of small "zzz")', 'int_to_str (str_index_of big "zzz")'),
         ("str_trim", "str_trim (\"  \" + small + \"  \")", "str_trim (\"  \" + big + \"  \")")]
timing = []
for i, (label, a, b) in enumerate(TIMED):
    timing.append(f'''        s{i} = sys_monotonic_ms
        _ = str_len ({a})
        m{i} = sys_monotonic_ms
        _ = str_len ({b})
        e{i} = sys_monotonic_ms
        t{i} = lt_linear "{label}: 20 KB then 200 KB in linear time, 200 KB under 0.5 s" (m{i} - s{i}) (e{i} - m{i}) 10 500''')

body = "\n".join(f"        c{i} = {c}" for i, c in enumerate(checks))
names = ", ".join([f"c{i}" for i in range(len(checks))] + [f"t{i}" for i in range(len(TIMED))])
src = f'''-- test_str.rg — str against its contract (FR-STR-001, API-STR-001) with bytes the library's own tests don't use:
-- NUL, bytes >= 0x80 and UTF-8 text, round trips, and time in the size of the input.
-- Generated by tests/gen/make_str.py. Lists are shown as "[a][b]…", so lost or extra empty items show.

import test
import str
import posix
import crypto
import lt

fn :: str_t_range Int Int [Int] => [Int]
      str_t_range i n acc =
        | i >= n    = acc
        | otherwise = str_t_range (i + 1) n (acc :: [i])

fn :: str_t_list [String] => String
      str_t_list []     =  ""
      str_t_list (x:xs) =  "[" + x + "]" + (str_t_list xs)

fn :: str_t_count [String] => String
      str_t_count xs =  int_to_str (str_t_len xs 0)

fn :: str_t_len [String] Int => Int
      str_t_len []     n =  n
      str_t_len (_:xs) n =  str_t_len xs (n + 1)

-- Built from lines, without str_repeat or str_join, so the setup doesn't depend on what is measured.
fn :: str_t_lines Int [String] => [String]
      str_t_lines n acc =
        | n <= 0    = acc
        | otherwise = str_t_lines (n - 1) (acc :: ["Some TEXT with Code, café & a [Link](https://example.org)."])

fn :: str_t_glue [String] String => String
      str_t_glue []     acc =  acc
      str_t_glue (x:xs) acc =  str_t_glue xs (acc + x + "\\n")

fn :: main => ()
      main =
{body}
        small_parts = str_t_lines 340 []
        big_parts = str_t_lines 3400 []
        small = str_t_glue small_parts ""
        big = str_t_glue big_parts ""
{chr(10).join(timing)}
        lt_done "str" [{names}]
'''
open(OUT, "w").write(strict(src))
print(f"wrote {OUT}: {len(checks) + len(TIMED)} checks")
