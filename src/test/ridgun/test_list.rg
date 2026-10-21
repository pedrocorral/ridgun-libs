-- ============================================================
-- src/test/ridgun/test_list.rg
-- Automated test suite for list.rg (TS-LIST-001)
-- @tests TS-LIST-001
-- ============================================================

import test
import list

-- @tests TS-LIST-001
fn :: test list indexing slicing and ranges => ()
      test list indexing slicing and ranges =
        xs = [10, 20, 30, 40, 50]
        _  = assert_int_equals (list len xs) 5 "list_len 5"
        _  = assert_true (list is empty []) "list_is_empty []"
        _  = assert_false (list is empty xs) "list_is_empty non-empty"
        _  = assert_int_equals (list nth xs 0) 10 "list_nth 0"
        _  = assert_int_equals (list nth xs 4) 50 "list_nth 4"
        _  = assert_int_equals (list nth or xs 99 (0 - 1)) (0 - 1) "list_nth_or out of bounds"
        _  = assert_int_equals (list nth or xs (0 - 1) (0 - 1)) (0 - 1) "list_nth_or negative"
        _  = assert_int_equals (list head xs 0) 10 "list_head"
        _  = assert_int_equals (list last xs 0) 50 "list_last"
        _  = assert eq (list take xs 3) [10, 20, 30]
        _  = assert eq (list drop xs 3) [40, 50]
        _  = assert eq (list slice xs 1 4) [20, 30, 40]
        _  = assert eq (list reverse xs) [50, 40, 30, 20, 10]
        _  = assert eq (list range 1 5) [1, 2, 3, 4, 5]
        _  = assert eq (list range 5 1) []
        _  = assert eq (list range step 0 6 2) [0, 2, 4, 6]
        _  = assert eq (list range step 6 0 (0 - 2)) [6, 4, 2, 0]
        _  = assert eq (list range step 1 5 0) []
        _  = assert eq (list replicate 3 7) [7, 7, 7]
        _  = assert_true (list contains xs 30) "list_contains 30"
        _  = assert_false (list contains xs 99) "list_contains 99"
        _  = assert_int_equals (list index of xs 30) 2 "list_index_of 30"
        _  = assert_int_equals (list index of xs 99) (0 - 1) "list_index_of missing"
        _  = assert_int_equals (list count [1, 2, 1, 3, 1] 1) 3 "list_count"
        _  = assert eq (list dedup [3, 1, 3, 2, 1]) [3, 1, 2]
        _  = assert eq (list str dedup ["b", "a", "b", "c"]) ["b", "a", "c"]
        ()

-- @tests TS-LIST-001
fn :: test list mergesort => ()
      test list mergesort =
        unsorted = [42, 7, 19, 7, 0, (0 - 5), 100, 3]
        sorted   = list sort unsorted
        _        = assert eq sorted [(0 - 5), 0, 3, 7, 7, 19, 42, 100]
        _        = assert_true (list is sorted sorted) "list_is_sorted after sort"
        _        = assert_false (list is sorted unsorted) "list_is_sorted false on unsorted"
        _        = assert eq (list sort []) []
        _        = assert eq (list sort [1]) [1]
        s_strs   = list str sort ["delta", "alpha", "charlie", "bravo", "alpha"]
        _        = assert eq s_strs ["alpha", "alpha", "bravo", "charlie", "delta"]
        ()

-- @tests TS-LIST-001
fn :: test kv associative map => ()
      test kv associative map =
        m0 = kv empty
        _  = assert_int_equals (kv len m0) 0 "kv_empty len 0"
        m1 = kv put m0 "host" "127.0.0.1"
        m2 = kv put m1 "port" "8080"
        m3 = kv put m2 "port" "9090"
        _  = assert_int_equals (kv len m3) 2 "kv_put updates in-place"
        _  = assert_true (kv has m3 "host") "kv_has host"
        _  = assert_false (kv has m3 "missing") "kv_has missing"
        _  = assert_str_eq (kv get m3 "port") "9090" "kv_get updated port"
        _  = assert_str_eq (kv get or m3 "mode" "prod") "prod" "kv_get_or default"
        _  = assert eq (kv keys m3) ["host", "port"]
        _  = assert eq (kv values m3) ["127.0.0.1", "9090"]
        m4 = kv merge m3 [("port", "8443"), ("tls", "true")]
        _  = assert_int_equals (kv len m4) 3 "kv_merge len 3"
        _  = assert_str_eq (kv get m4 "port") "8443" "kv_merge overrides port"
        _  = assert_str_eq (kv get m4 "tls") "true" "kv_merge adds tls"
        m5 = kv remove m4 "host"
        _  = assert_false (kv has m5 "host") "kv_remove removes host"
        _  = assert_int_equals (kv len m5) 2 "kv_remove len 2"
        ()

fn :: main => ()
      main =
        _ = test list indexing slicing and ranges
        _ = test list mergesort
        _ = test kv associative map
        echo "[PASS] test_list: TS-LIST-001 passed"
