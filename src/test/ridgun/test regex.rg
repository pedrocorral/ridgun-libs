-- ============================================================
-- src/test/ridgun/test regex.rg
-- Automated unit tests for regex.rg (Thompson NFA Regex Engine)
-- @tests TS-REGEX-001
-- ============================================================

import test
import regex

fn :: re_match_count [RegexMatch] => Int
      re_match_count []           =  0
      re_match_count (_:rest)     =  1 + (re_match_count rest)

fn :: re_match_at [RegexMatch] Int => RegexMatch
      re_match_at []           _   =  RegexMatch False (-1) (-1) ""
      re_match_at (m:_)        0   =  m
      re_match_at (_:rest)     idx =  re_match_at rest (idx - 1)

fn :: re_str_at [String] Int => String
      re_str_at []       _   =  ""
      re_str_at (s:_)    0   =  s
      re_str_at (_:rest) idx =  re_str_at rest (idx - 1)

fn :: re_str_count [String] => Int
      re_str_count []       =  0
      re_str_count (_:rest) =  1 + (re_str_count rest)

-- @tests TS-REGEX-001
fn :: test_regex_operators_and_classes => ()
      test_regex_operators_and_classes =
        _ = assert true (regex match 'a(b|c)+d?e*' "abcbdeee") "AC1: alternation group plus opt star"
        _ = assert false (regex match 'a(b|c)+d?e*' "ade") "AC1: plus requires at least one"
        _ = assert true (regex match '[a-z]+_[0-9]+' "ridgun_42") "AC1: char class ranges"
        _ = assert true (regex match '[^0-9]+' "hello_world") "AC1: negated char class"
        _ = assert false (regex match '[^0-9]+' "hello42") "AC1: negated char class rejects digits"
        _ = assert true (regex match '\w+\s+\d+' "agent   007") "AC1: shorthand escapes \\w \\s \\d"
        _ = assert true (regex match 'v\d+\.\d+\.\d+' "v0.9.15") "AC1: escaped dot literal"
        _ = assert false (regex match 'v\d+\.\d+\.\d+' "v0X9Y15") "AC1: escaped dot rejects non-dot"
        _ = assert true (regex is match '^hello' "hello world") "AC1: bol anchor matches start"
        _ = assert false (regex is match '^world' "hello world") "AC1: bol anchor rejects middle"
        _ = assert true (regex is match 'world$' "hello world") "AC1: eol anchor matches end"
        _ = assert false (regex match '(a+)+b' "aaaaaaaaaaaaaaaaaaaaaac") "AC1: linear-time NFA rejects ReDoS pattern"
        ()

-- @tests TS-REGEX-001
fn :: test_regex_find_replace_split => ()
      test_regex_find_replace_split =
        m1 = regex find '\d+' "item #42 and #99"
        _ = assert true (matched m1) "AC2: find matched"
        _ = assert int equals (match_start m1) 6 "AC2: find start"
        _ = assert int equals (match_end m1) 8 "AC2: find end"
        _ = assert str eq (text m1) "42" "AC2: find text"
        all_m = regex find all '\d+' "id=10, port=8080, ttl=60"
        _ = assert int equals (re_match_count all_m) 3 "AC2: find all count"
        _ = assert str eq (text (re_match_at all_m 1)) "8080" "AC2: find all second text"
        r1 = regex replace '\d+' "X" "v1.2.3"
        _ = assert str eq r1 "vX.2.3" "AC3: replace first"
        r2 = regex replace all '\d+' "X" "v1.2.3"
        _ = assert str eq r2 "vX.X.X" "AC3: replace all"
        parts = regex split '\s*,\s*' "alpha, beta ,  gamma,delta"
        _ = assert int equals (re_str_count parts) 4 "AC3: split count"
        _ = assert str eq (re_str_at parts 1) "beta" "AC3: split second element"
        _ = assert str eq (re_str_at parts 2) "gamma" "AC3: split third element"
        ()

-- @tests TS-REGEX-001
fn :: main => ()
      main =
        _ = test_regex_operators_and_classes
        _ = test_regex_find_replace_split
        echo "[PASS] test regex: TS-REGEX-001 passed"
