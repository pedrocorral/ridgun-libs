-- ============================================================
-- src/test/ridgun/test list.rg
-- Comprehensive test suite for list.rg inspired by Rust std::slice & Haskell Data.List
-- @tests TS-LIST-001
-- ============================================================

import test
import list

-- 1. Indexing, slicing (`take`, `drop`, `slice`), reversal, ranges, search, and deduplication on [Int] & [String]
-- @tests TS-LIST-001
fn :: test list indexing slicing and ranges => ()
      test list indexing slicing and ranges =
        xs = [10, 20, 30, 40, 50]
        ss = ["aa", "bb", "cc", "dd"]
        _ = assert int equals (list len xs) 5 "AC1: list_len 5"
        _ = assert int equals (list str len ss) 4 "AC1: list_str_len 4"
        _ = assert true (list is empty []) "AC1: list_is_empty []"
        _ = assert false (list is empty xs) "AC1: list_is_empty non-empty"
        _ = assert true (list str is empty []) "AC1: list_str_is_empty []"
        _ = assert false (list str is empty ss) "AC1: list_str_is_empty non-empty"

        _ = assert int equals (list nth xs 0) 10 "AC1: list_nth 0"
        _ = assert int equals (list nth xs 4) 50 "AC1: list_nth 4"
        _ = assert int equals (list nth or xs 99 (0 - 1)) (0 - 1) "AC1: list_nth_or out of bounds"
        _ = assert int equals (list nth or xs (0 - 1) (0 - 1)) (0 - 1) "AC1: list_nth_or negative"
        _ = assert str eq (list str nth ss 2) "cc" "AC1: list_str_nth 2"
        _ = assert str eq (list str nth or ss 99 "oob") "oob" "AC1: list_str_nth_or out of bounds"
        _ = assert int equals (list head xs 0) 10 "AC1: list_head"
        _ = assert int equals (list head [] 99) 99 "AC1: list_head empty fallback"
        _ = assert int equals (list last xs 0) 50 "AC1: list_last"
        _ = assert int equals (list last [] 99) 99 "AC1: list_last empty fallback"

        _ = assert eq (list take xs 3) [10, 20, 30]
        _ = assert eq (list take xs 0) []
        _ = assert eq (list take xs (0 - 2)) []
        _ = assert eq (list take xs 99) [10, 20, 30, 40, 50]
        _ = assert eq (list drop xs 3) [40, 50]
        _ = assert eq (list drop xs 0) xs
        _ = assert eq (list drop xs 99) []
        _ = assert eq (list slice xs 1 4) [20, 30, 40]
        _ = assert eq (list slice xs (0 - 3) 2) [10, 20]
        _ = assert eq (list slice xs 4 2) []
        _ = assert eq (list str slice ss 1 3) ["bb", "cc"]

        _ = assert eq (list reverse xs) [50, 40, 30, 20, 10]
        _ = assert eq (list str reverse ss) ["dd", "cc", "bb", "aa"]

        _ = assert eq (list range 1 5) [1, 2, 3, 4, 5]
        _ = assert eq (list range 3 3) [3]
        _ = assert eq (list range 5 1) []
        _ = assert eq (list range step 0 6 2) [0, 2, 4, 6]
        _ = assert eq (list range step 6 0 (0 - 2)) [6, 4, 2, 0]
        _ = assert eq (list range step 1 5 0) []
        _ = assert eq (list replicate 3 7) [7, 7, 7]
        _ = assert eq (list replicate 0 7) []

        _ = assert true (list contains xs 30) "AC1: list_contains 30"
        _ = assert false (list contains xs 99) "AC1: list_contains 99"
        _ = assert true (list str contains ss "cc") "AC1: list_str_contains cc"
        _ = assert false (list str contains ss "zz") "AC1: list_str_contains zz"
        _ = assert int equals (list index of xs 30) 2 "AC1: list_index_of 30"
        _ = assert int equals (list index of xs 99) (0 - 1) "AC1: list_index_of missing"
        _ = assert int equals (list str index of ss "dd") 3 "AC1: list_str_index_of dd"
        _ = assert int equals (list count [1, 2, 1, 3, 1] 1) 3 "AC1: list_count"
        _ = assert int equals (list str count ["a", "b", "a"] "a") 2 "AC1: list_str_count"
        _ = assert eq (list dedup [3, 1, 3, 2, 1, 3]) [3, 1, 2]
        _ = assert eq (list str dedup ["b", "a", "b", "c", "a"]) ["b", "a", "c"]
        ()

-- 2. Deterministic O(N log N) mergesort on ascending, descending, duplicate, negative, and prefix-sharing inputs
-- @tests TS-LIST-001
fn :: test list mergesort => ()
      test list mergesort =
        unsorted = [42, 7, 19, 7, 0, (0 - 5), 100, 3, (0 - 50)]
        sorted = list sort unsorted
        _ = assert eq sorted [(0 - 50), (0 - 5), 0, 3, 7, 7, 19, 42, 100]
        _ = assert true (list is sorted sorted) "AC2: list_is_sorted after sort"
        _ = assert false (list is sorted unsorted) "AC2: list_is_sorted false on unsorted"
        _ = assert true (list is sorted []) "AC2: empty list is sorted"
        _ = assert true (list is sorted [1]) "AC2: singleton list is sorted"
        _ = assert eq (list sort []) []
        _ = assert eq (list sort [1]) [1]
        _ = assert eq (list sort [5, 4, 3, 2, 1]) [1, 2, 3, 4, 5]
        s_strs = list str sort ["delta", "alpha", "charlie", "bravo", "alpha", "al", ""]
        _ = assert eq s_strs ["", "al", "alpha", "alpha", "bravo", "charlie", "delta"]
        ()

-- 3. Associative key-value map (`kv_*`) CRUD, order preservation, and multi-key merge
-- @tests TS-LIST-001
fn :: test kv associative map => ()
      test kv associative map =
        m0 = kv empty
        _ = assert int equals (kv len m0) 0 "AC3: kv_empty len 0"
        m1 = kv put m0 "host" "127.0.0.1"
        m2 = kv put m1 "port" "8080"
        m3 = kv put m2 "port" "9090"
        _ = assert int equals (kv len m3) 2 "AC3: kv_put updates in-place without duplicating key"
        _ = assert true (kv has m3 "host") "AC3: kv_has host"
        _ = assert false (kv has m3 "missing") "AC3: kv_has missing"
        _ = assert str eq (kv get m3 "port") "9090" "AC3: kv_get updated port"
        _ = assert str eq (kv get m3 "missing") "" "AC3: kv_get missing returns empty"
        _ = assert str eq (kv get or m3 "mode" "prod") "prod" "AC3: kv_get_or default"
        _ = assert eq (kv keys m3) ["host", "port"]
        _ = assert eq (kv values m3) ["127.0.0.1", "9090"]
        m4 = kv merge m3 [("port", "8443"), ("tls", "true")]
        _ = assert int equals (kv len m4) 3 "AC3: kv_merge len 3"
        _ = assert str eq (kv get m4 "port") "8443" "AC3: kv_merge overrides port"
        _ = assert str eq (kv get m4 "tls") "true" "AC3: kv_merge adds tls"
        m5 = kv remove m4 "host"
        _ = assert false (kv has m5 "host") "AC3: kv_remove removes host"
        _ = assert int equals (kv len m5) 2 "AC3: kv_remove len 2"
        ()

-- @tests TS-LIST-001
fn :: main => ()
      main =
        _ = test list indexing slicing and ranges
        _ = test list mergesort
        _ = test kv associative map
        echo "[PASS] test list: TS-LIST-001 passed"
