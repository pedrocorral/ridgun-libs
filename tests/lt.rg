-- lt.rg — Checks for the acceptance tests in this folder. Unlike `test`'s assert_* (which stop at the first
-- failure), each check prints a failure and returns False, so one run shows every failure; lt_done prints the
-- tally and exits with 1 when anything failed. Values are shown with their length, and byte strings as hex,
-- so a failure says what came back, not only that something did.

import test
import str
import crypto

-- How a value is shown in a failure: as text when every byte is printable ASCII, UTF-8 or a line break; as hex
-- otherwise. Long values are cut; the length shown is always the real one.
fn :: lt show String => String
      lt show v =
        | lt_printable v 0  = "\"" + (lt_cut v) + "\" (" + (int_to_str (str_len v)) + " bytes)"
        | otherwise         = "hex " + (lt_cut (bytes_to_hex_str v)) + " (" + (int_to_str (str_len v)) + " bytes)"

fn :: lt cut String => String
      lt cut v =
        | (str_len v) > 240 = (str_slice v 0 240) + "…"
        | otherwise         = v

-- Bytes 0x20–0x7E, tab, line feed, or >= 0x80 (UTF-8 text); 0x00–0x1F otherwise and 0x7F count as binary.
fn :: lt printable String Int => Bool
      lt printable v i =
        | i >= (str_len v)                                   = True
        | lt_text_byte (((str_char_at v i) % 256 + 256) % 256) = lt_printable v (i + 1)
        | otherwise                                          = False

fn :: lt text byte Int => Bool
      lt text byte b =  (b >= 32 and b != 127) or b == 9 or b == 10

fn :: lt report Bool String String String => Bool
      lt report True  _     _      _        =  True
      lt report False label actual expected =
        _ = echo ("FAIL " + label + "\n       got:      " + actual + "\n       expected: " + expected)
        False

-- Text equality.
fn :: lt eq String String String => Bool
      lt eq label actual expected =  lt_report (actual == expected) label (lt_show actual) (lt_show expected)

-- Byte equality, shown as hex: for results that may hold bytes 0x00 or >= 0x80.
fn :: lt hex String String String => Bool
      lt hex label actual expected_hex =  lt_report ((bytes_to_hex_str actual) == expected_hex) label (bytes_to_hex_str actual) expected_hex

fn :: lt int String Int Int => Bool
      lt int label actual expected =  lt_report (actual == expected) label (int_to_str actual) (int_to_str expected)

fn :: lt true String Bool => Bool
      lt true label ok =  lt_report ok label "False" "True"

fn :: lt false String Bool => Bool
      lt false label ok =  lt_report (not ok) label "True" "False"

-- Linear time: the big input is `factor` times the small one, so a linear implementation takes about `factor`
-- times as long and a quadratic one about factor². Fails above factor * 2 (noise allowance), and when the big
-- input takes longer than `limit_ms`. Times under 20 ms are too small to compare and count as linear.
fn :: lt linear String Int Int Int Int => Bool
      lt linear label small_ms big_ms factor limit_ms =  lt_report ((big_ms <= limit_ms) and (big_ms < 20 or big_ms <= (small_ms * factor * 2) + 20)) label ((int_to_str small_ms) + " ms → " + (int_to_str big_ms) + " ms for " + (int_to_str factor) + "× the input") ("at most " + (int_to_str (factor * 2)) + "× (linear), and under " + (int_to_str limit_ms) + " ms")

fn :: lt count false [Bool] Int => Int
      lt count false []     n =  n
      lt count false (b:bs) n =
        | b         = lt_count_false bs n
        | otherwise = lt_count_false bs (n + 1)

fn :: lt count [Bool] Int => Int
      lt count []     n =  n
      lt count (_:bs) n =  lt_count bs (n + 1)

-- The tally; exits with 1 when any check failed.
fn :: lt done String [Bool] => ()
      lt done name results =  lt_finish name (lt_count results 0) (lt_count_false results 0)

fn :: lt finish String Int Int => ()
      lt finish name total failed =
        | failed == 0 = echo ("ok   " + name + ": " + (int_to_str total) + " checks")
        | otherwise   = fail_test (name + ": " + (int_to_str failed) + " of " + (int_to_str total) + " checks failed")
