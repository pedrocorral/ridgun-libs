-- ============================================================
-- src/test/ridgun/test diff.rg
-- Comprehensive test suite for diff.rg inspired by Myers (1986), Python difflib, and Rust similar
-- @tests TS-DIFF-001
-- ============================================================

import test
import diff

fn :: count_edits [DiffEdit] => Int
      count_edits []         =  0
      count_edits (_:es)     =  1 + (count_edits es)

fn :: nth_edit [DiffEdit] Int => DiffEdit
      nth_edit []         _   =  DiffEdit "none" "" 0 0
      nth_edit (e:es)     idx
        | idx <= 0 = e
        | otherwise = nth_edit es (idx - 1)

-- 1. Empty, single-line, and identical inputs
-- @tests TS-DIFF-001
fn :: test_diff_empty_and_identical => ()
      test_diff_empty_and_identical =
        nl = char_from_code 10
        e_empty = diff text "" ""
        _ = assert int equals (count_edits e_empty) 0 "AC1: empty diff edit count"
        _ = assert false (diff has changes e_empty) "AC1: empty diff has no changes"
        _ = assert int equals (diff edit distance "" "") 0 "AC1: empty edit distance"
        _ = assert str eq (diff apply e_empty) "" "AC3: empty diff apply"
        same_doc = "alpha" + nl + "beta" + nl + "gamma"
        e_same = diff text same_doc same_doc
        _ = assert int equals (count_edits e_same) 3 "AC1: identical 3-line count"
        _ = assert false (diff has changes e_same) "AC1: identical has no changes"
        st_same = diff stats e_same
        _ = assert int equals (equal_count st_same) 3 "AC1: equal_count == 3"
        _ = assert int equals (insert_count st_same) 0 "AC1: insert_count == 0"
        _ = assert int equals (delete_count st_same) 0 "AC1: delete_count == 0"
        _ = assert int equals (diff edit distance same_doc same_doc) 0 "AC1: identical edit distance == 0"
        _ = assert str eq (diff apply e_same) same_doc "AC3: identical diff apply"
        ()

-- 2. Pure insertion from empty and pure deletion to empty
-- @tests TS-DIFF-001
fn :: test_diff_pure_insert_and_delete => ()
      test_diff_pure_insert_and_delete =
        nl = char_from_code 10
        target = "line1" + nl + "line2" + nl + "line3"
        e_ins = diff text "" target
        _ = assert true (diff has changes e_ins) "AC1: pure insert has changes"
        st_ins = diff stats e_ins
        _ = assert int equals (equal_count st_ins) 0 "AC1: pure insert equal_count"
        _ = assert int equals (insert_count st_ins) 3 "AC1: pure insert insert_count"
        _ = assert int equals (delete_count st_ins) 0 "AC1: pure insert delete_count"
        _ = assert int equals (diff edit distance "" target) 3 "AC1: pure insert edit distance"
        _ = assert str eq (diff apply e_ins) target "AC3: pure insert apply"
        ins0 = nth_edit e_ins 0
        ins2 = nth_edit e_ins 2
        _ = assert str eq (diff_op ins0) "insert" "AC1: ins0 op"
        _ = assert int equals (old_line_no ins0) 0 "AC1: ins0 old_line_no"
        _ = assert int equals (new_line_no ins0) 1 "AC1: ins0 new_line_no"
        _ = assert int equals (new_line_no ins2) 3 "AC1: ins2 new_line_no"
        e_del = diff text target ""
        _ = assert true (diff has changes e_del) "AC1: pure delete has changes"
        st_del = diff stats e_del
        _ = assert int equals (equal_count st_del) 0 "AC1: pure delete equal_count"
        _ = assert int equals (insert_count st_del) 0 "AC1: pure delete insert_count"
        _ = assert int equals (delete_count st_del) 3 "AC1: pure delete delete_count"
        _ = assert int equals (diff edit distance target "") 3 "AC1: pure delete edit distance"
        _ = assert str eq (diff apply e_del) "" "AC3: pure delete apply"
        del0 = nth_edit e_del 0
        del2 = nth_edit e_del 2
        _ = assert str eq (diff_op del0) "delete" "AC1: del0 op"
        _ = assert int equals (old_line_no del0) 1 "AC1: del0 old_line_no"
        _ = assert int equals (new_line_no del0) 0 "AC1: del0 new_line_no"
        _ = assert int equals (old_line_no del2) 3 "AC1: del2 old_line_no"
        ()

-- 3. Classic Myers (1986) paper benchmark: ABCABBA -> CBABAC (LCS length = 4, edit distance = 5)
-- @tests TS-DIFF-001
fn :: test_diff_myers_classic_vector => ()
      test_diff_myers_classic_vector =
        nl = char_from_code 10
        old_lines = ["A", "B", "C", "A", "B", "B", "A"]
        new_lines = ["C", "B", "A", "B", "A", "C"]
        edits = diff lines old_lines new_lines
        st = diff stats edits
        _ = assert int equals (equal_count st) 4 "AC1: Myers LCS length 4"
        _ = assert int equals (delete_count st) 3 "AC1: Myers delete count 3"
        _ = assert int equals (insert_count st) 2 "AC1: Myers insert count 2"
        old_s = "A" + nl + "B" + nl + "C" + nl + "A" + nl + "B" + nl + "B" + nl + "A"
        new_s = "C" + nl + "B" + nl + "A" + nl + "B" + nl + "A" + nl + "C"
        _ = assert int equals (diff edit distance old_s new_s) 5 "AC1: Myers edit distance 5"
        _ = assert str eq (diff apply edits) new_s "AC3: Myers apply reproduces CBABAC"
        ()

-- 4. Multi-line code refactoring diff, line numbering, and lossless apply
-- @tests TS-DIFF-001
fn :: test_diff_code_hunks_and_line_numbers => ()
      test_diff_code_hunks_and_line_numbers =
        nl = char_from_code 10
        old_code = "fn :: add Int Int => Int" + nl + "      add a b = a + b" + nl + "" + nl + "fn :: sub Int Int => Int" + nl + "      sub a b = a - b"
        new_code = "fn :: add Int Int => Int" + nl + "      add x y = x + y" + nl + "" + nl + "fn :: mul Int Int => Int" + nl + "      mul a b = a * b" + nl + "" + nl + "fn :: sub Int Int => Int" + nl + "      sub a b = a - b"
        edits = diff text old_code new_code
        _ = assert true (diff has changes edits) "AC1: code refactoring has changes"
        _ = assert str eq (diff apply edits) new_code "AC3: code refactoring lossless apply"
        e0 = nth_edit edits 0
        _ = assert str eq (diff_op e0) "equal" "AC1: line 1 equal"
        _ = assert int equals (old_line_no e0) 1 "AC1: line 1 old_line_no"
        _ = assert int equals (new_line_no e0) 1 "AC1: line 1 new_line_no"
        e1 = nth_edit edits 1
        _ = assert str eq (diff_op e1) "delete" "AC1: line 2 deleted"
        _ = assert str eq (line_text e1) "      add a b = a + b" "AC1: deleted line text"
        _ = assert int equals (old_line_no e1) 2 "AC1: deleted old_line_no"
        _ = assert int equals (new_line_no e1) 0 "AC1: deleted new_line_no"
        e2 = nth_edit edits 2
        _ = assert str eq (diff_op e2) "insert" "AC1: line 2 inserted"
        _ = assert str eq (line_text e2) "      add x y = x + y" "AC1: inserted line text"
        _ = assert int equals (old_line_no e2) 0 "AC1: inserted old_line_no"
        _ = assert int equals (new_line_no e2) 2 "AC1: inserted new_line_no"
        ()

-- 5. Unified Diff formatting verification (headers, @@ hunk coordinates, prefix markers)
-- @tests TS-DIFF-001
fn :: test_diff_unified_formatting => ()
      test_diff_unified_formatting =
        nl = char_from_code 10
        old_s = "one" + nl + "two" + nl + "three"
        new_s = "one" + nl + "TWO" + nl + "three" + nl + "four"
        uni = diff unified "a/sample.txt" "b/sample.txt" old_s new_s
        expected = "--- a/sample.txt" + nl + "+++ b/sample.txt" + nl + "@@ -1,3 +1,4 @@" + nl + " one" + nl + "-two" + nl + "+TWO" + nl + " three" + nl + "+four" + nl
        _ = assert str eq uni expected "AC2: unified diff output matches standard header and hunk format"
        uni_empty = diff unified "a/empty" "b/empty" "" ""
        _ = assert str eq uni_empty ("--- a/empty" + nl + "+++ b/empty" + nl + "@@ -0,0 +0,0 @@" + nl) "AC2: unified diff empty files"
        ()

-- 6. Duplicate/repetitive lines & boundary shifts (Python difflib / Rust similar edge cases)
-- @tests TS-DIFF-001
fn :: test_diff_repetitive_lines => ()
      test_diff_repetitive_lines =
        nl = char_from_code 10
        old_rep = "x" + nl + "x" + nl + "y" + nl + "x" + nl + "x"
        new_rep = "x" + nl + "y" + nl + "y" + nl + "x"
        edits = diff text old_rep new_rep
        st = diff stats edits
        _ = assert int equals (equal_count st) 3 "AC1: repetitive LCS equal_count"
        _ = assert int equals (delete_count st) 2 "AC1: repetitive LCS delete_count"
        _ = assert int equals (insert_count st) 1 "AC1: repetitive LCS insert_count"
        _ = assert str eq (diff apply edits) new_rep "AC3: repetitive lines apply"
        ()

-- @tests TS-DIFF-001
fn :: main => ()
      main =
        _ = test_diff_empty_and_identical
        _ = test_diff_pure_insert_and_delete
        _ = test_diff_myers_classic_vector
        _ = test_diff_code_hunks_and_line_numbers
        _ = test_diff_unified_formatting
        _ = test_diff_repetitive_lines
        echo "[PASS] test diff: TS-DIFF-001 passed"
