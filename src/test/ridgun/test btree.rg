-- ============================================================
-- src/test/ridgun/test btree.rg
-- Automated unit tests for btree.rg (AVL BTreeMap, BTreeSet & MinHeap)
-- @tests TS-BTREE-001
-- ============================================================

import test
import btree

fn :: bt_join_strs [String] => String
      bt_join_strs []       =  ""
      bt_join_strs (x:[])   =  x
      bt_join_strs (x:rest) =  x + "," + (bt_join_strs rest)

fn :: hp_peek_prio (Int String) => Int
      hp_peek_prio (p, _)       =  p

fn :: hp_peek_val (Int String) => String
      hp_peek_val (_, v)       =  v

fn :: hp_pop_prio (Int String MinHeap) => Int
      hp_pop_prio (p, _, _)            =  p

fn :: hp_pop_val (Int String MinHeap) => String
      hp_pop_val (_, v, _)            =  v

fn :: hp_pop_rest (Int String MinHeap) => MinHeap
      hp_pop_rest (_, _, h)            =  h

-- @tests TS-BTREE-001
fn :: test_btree_map_avl_balance_and_crud => ()
      test_btree_map_avl_balance_and_crud =
        m0 = btree empty
        m1 = btree put m0 "k1" "v1"
        m2 = btree put m1 "k2" "v2"
        m3 = btree put m2 "k3" "v3"
        m4 = btree put m3 "k4" "v4"
        m5 = btree put m4 "k5" "v5"
        m6 = btree put m5 "k6" "v6"
        m7 = btree put m6 "k7" "v7"
        _ = assert int equals (btree size m7) 7 "AC1: btree size after 7 sequential puts"
        _ = assert true ((btree height m7) <= 4) "AC1: AVL tree height logarithmic on sequential keys"
        _ = assert str eq (btree get m7 "k4") "v4" "AC1: btree get k4"
        _ = assert str eq (btree_get_or m7 "k99" "def") "def" "AC1: btree get or fallback"
        _ = assert true (btree has m7 "k6") "AC1: btree has k6"
        _ = assert false (btree has m7 "k0") "AC1: btree has k0 false"
        _ = assert str eq (bt_join_strs (btree keys m7)) "k1,k2,k3,k4,k5,k6,k7" "AC1: btree keys sorted"

        m7_upd = btree put m7 "k4" "v4_new"
        _ = assert int equals (btree size m7_upd) 7 "AC1: update existing key preserves size"
        _ = assert str eq (btree get m7_upd "k4") "v4_new" "AC1: updated value retrieved"

        m_del = btree remove m7_upd "k4"
        _ = assert int equals (btree size m_del) 6 "AC1: btree remove decrements size"
        _ = assert false (btree has m_del "k4") "AC1: removed key not present"
        _ = assert str eq (bt_join_strs (btree keys m_del)) "k1,k2,k3,k5,k6,k7" "AC1: keys sorted after remove"

        pairs = btree_to_list m_del
        m_rt = btree_from_list pairs
        _ = assert int equals (btree size m_rt) 6 "AC1: btree to/from list round-trip size"
        _ = assert str eq (btree get m_rt "k6") "v6" "AC1: btree to/from list round-trip lookup"
        ()

-- @tests TS-BTREE-001
fn :: test_btree_set_operations => ()
      test_btree_set_operations =
        s1 = bset_from_list ["charlie", "alpha", "bravo", "alpha"]
        s2 = bset_from_list ["bravo", "delta", "echo"]
        _ = assert int equals (bset size s1) 3 "AC2: bset deduplicates items"
        _ = assert str eq (bt_join_strs (bset_to_list s1)) "alpha,bravo,charlie" "AC2: bset sorted order"

        u = bset union s1 s2
        _ = assert str eq (bt_join_strs (bset_to_list u)) "alpha,bravo,charlie,delta,echo" "AC2: bset union"

        inter = bset intersect s1 s2
        _ = assert str eq (bt_join_strs (bset_to_list inter)) "bravo" "AC2: bset intersect"

        df = bset diff s1 s2
        _ = assert str eq (bt_join_strs (bset_to_list df)) "alpha,charlie" "AC2: bset diff"
        ()

-- @tests TS-BTREE-001
fn :: test_min_heap_priority_queue => ()
      test_min_heap_priority_queue =
        h0 = heap empty
        h1 = heap push h0 50 "low"
        h2 = heap push h1 10 "urgent"
        h3 = heap push h2 30 "normal"
        h4 = heap push h3 20 "high"
        _ = assert int equals (heap size h4) 4 "AC3: heap size 4"
        pk = heap peek h4
        _ = assert int equals (hp_peek_prio pk) 10 "AC3: heap peek lowest priority score"
        _ = assert str eq (hp_peek_val pk) "urgent" "AC3: heap peek urgent value"

        p1 = heap pop h4
        _ = assert str eq (hp_pop_val p1) "urgent" "AC3: pop 1 urgent (10)"
        p2 = heap pop (hp_pop_rest p1)
        _ = assert str eq (hp_pop_val p2) "high" "AC3: pop 2 high (20)"
        p3 = heap pop (hp_pop_rest p2)
        _ = assert str eq (hp_pop_val p3) "normal" "AC3: pop 3 normal (30)"
        p4 = heap pop (hp_pop_rest p3)
        _ = assert str eq (hp_pop_val p4) "low" "AC3: pop 4 low (50)"
        _ = assert int equals (heap size (hp_pop_rest p4)) 0 "AC3: heap empty after popping all"
        ()

-- @tests TS-BTREE-001
fn :: main => ()
      main =
        _ = test_btree_map_avl_balance_and_crud
        _ = test_btree_set_operations
        _ = test_min_heap_priority_queue
        echo "[PASS] test btree: TS-BTREE-001 passed"
