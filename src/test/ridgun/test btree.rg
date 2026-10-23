-- ============================================================
-- src/test/ridgun/test btree.rg
-- Comprehensive test suite for btree.rg inspired by Rust std::collections::{BTreeMap, BTreeSet, BinaryHeap}
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

-- 1. Ascending, descending, and sawtooth AVL insertion balance + root/internal/leaf removals
-- @tests TS-BTREE-001
fn :: test_btree_map_avl_balance_and_crud => ()
      test_btree_map_avl_balance_and_crud =
        m0 = btree empty
        _ = assert int equals (btree size m0) 0 "AC1: empty map size 0"
        _ = assert int equals (btree height m0) 0 "AC1: empty map height 0"
        m1 = btree put m0 "k01" "v1"
        m2 = btree put m1 "k02" "v2"
        m3 = btree put m2 "k03" "v3"
        m4 = btree put m3 "k04" "v4"
        m5 = btree put m4 "k05" "v5"
        m6 = btree put m5 "k06" "v6"
        m7 = btree put m6 "k07" "v7"
        m8 = btree put m7 "k08" "v8"
        m9 = btree put m8 "k09" "v9"
        m10 = btree put m9 "k10" "v10"
        m11 = btree put m10 "k11" "v11"
        m12 = btree put m11 "k12" "v12"
        m13 = btree put m12 "k13" "v13"
        m14 = btree put m13 "k14" "v14"
        m15 = btree put m14 "k15" "v15"
        _ = assert int equals (btree size m15) 15 "AC1: btree size after 15 ascending puts"
        _ = assert true ((btree height m15) <= 5) "AC1: AVL tree height <= 5 on 15 sequential ascending keys"
        _ = assert str eq (btree get m15 "k08") "v8" "AC1: btree get k08"
        _ = assert str eq (btree_get_or m15 "k99" "def") "def" "AC1: btree get or fallback"
        _ = assert true (btree has m15 "k15") "AC1: btree has k15"
        _ = assert false (btree has m15 "k00") "AC1: btree has k00 false"

        -- Descending insertion order (triggers right-rotations) + RL/LR double rotations
        d0 = btree_from_list [("z", "26"), ("x", "24"), ("v", "22"), ("t", "20"), ("r", "18"), ("u", "21"), ("y", "25")]
        _ = assert int equals (btree size d0) 7 "AC1: descending + RL/LR size 7"
        _ = assert true ((btree height d0) <= 4) "AC1: descending + RL/LR height <= 4"
        _ = assert str eq (bt_join_strs (btree keys d0)) "r,t,u,v,x,y,z" "AC1: keys in-order after RL/LR rotations"
        _ = assert str eq (bt_join_strs (btree values d0)) "18,20,21,22,24,25,26" "AC1: values in key order"

        -- Overwrite existing key preserves size
        d_upd = btree put d0 "v" "22_new"
        _ = assert int equals (btree size d_upd) 7 "AC1: update existing key preserves size"
        _ = assert str eq (btree get d_upd "v") "22_new" "AC1: updated value retrieved"

        -- Remove root/two-child node, single-child node, leaf node, and non-existent key
        d_rem1 = btree remove d_upd "v"
        d_rem2 = btree remove d_rem1 "r"
        d_rem3 = btree remove d_rem2 "nonexistent"
        _ = assert int equals (btree size d_rem3) 5 "AC1: size after removing 2 existing keys and 1 missing key"
        _ = assert false (btree has d_rem3 "v") "AC1: removed two-child node 'v' absent"
        _ = assert false (btree has d_rem3 "r") "AC1: removed leaf node 'r' absent"
        _ = assert str eq (bt_join_strs (btree keys d_rem3)) "t,u,x,y,z" "AC1: keys remain strictly sorted after removals"

        pairs = btree_to_list d_rem3
        m_rt = btree_from_list pairs
        _ = assert int equals (btree size m_rt) 5 "AC1: btree to/from list round-trip size"
        _ = assert str eq (btree get m_rt "y") "25" "AC1: btree to/from list round-trip lookup"
        ()

-- 2. BTreeSet algebraic laws (idempotence, commutativity, difference, disjoint sets)
-- @tests TS-BTREE-001
fn :: test_btree_set_operations => ()
      test_btree_set_operations =
        s1 = bset_from_list ["charlie", "alpha", "bravo", "alpha", "charlie"]
        s2 = bset_from_list ["bravo", "delta", "echo"]
        s_empty = bset empty
        _ = assert int equals (bset size s1) 3 "AC2: bset deduplicates items"
        _ = assert true (bset has s1 "bravo") "AC2: bset has bravo"
        _ = assert false (bset has s1 "delta") "AC2: bset has delta false"
        _ = assert str eq (bt_join_strs (bset_to_list s1)) "alpha,bravo,charlie" "AC2: bset sorted order"

        s1_rem = bset remove s1 "bravo"
        _ = assert int equals (bset size s1_rem) 2 "AC2: bset remove size"
        _ = assert false (bset has s1_rem "bravo") "AC2: bset remove membership"

        u = bset union s1 s2
        _ = assert str eq (bt_join_strs (bset_to_list u)) "alpha,bravo,charlie,delta,echo" "AC2: bset union"
        _ = assert int equals (bset size (bset union s1 s1)) 3 "AC2: union idempotence A U A = A"
        _ = assert int equals (bset size (bset union s1 s_empty)) 3 "AC2: union identity A U empty = A"

        inter = bset intersect s1 s2
        _ = assert str eq (bt_join_strs (bset_to_list inter)) "bravo" "AC2: bset intersect"
        _ = assert int equals (bset size (bset intersect s1 s_empty)) 0 "AC2: intersect with empty is empty"

        df = bset diff s1 s2
        _ = assert str eq (bt_join_strs (bset_to_list df)) "alpha,charlie" "AC2: bset diff A \\ B"
        _ = assert int equals (bset size (bset diff s1 s1)) 0 "AC2: self difference A \\ A is empty"
        ()

-- 3. Leftist MinHeap priority queue: duplicate priorities and interleaved push/pop
-- @tests TS-BTREE-001
fn :: test_min_heap_priority_queue => ()
      test_min_heap_priority_queue =
        h0 = heap empty
        _ = assert int equals (heap size h0) 0 "AC3: empty heap size 0"
        h1 = heap push h0 50 "low"
        h2 = heap push h1 10 "urgent-1"
        h3 = heap push h2 30 "normal"
        h4 = heap push h3 20 "high"
        h5 = heap push h4 10 "urgent-2"
        h6 = heap push h5 (-5) "critical"
        _ = assert int equals (heap size h6) 6 "AC3: heap size 6"
        pk = heap peek h6
        _ = assert int equals (hp_peek_prio pk) (-5) "AC3: heap peek negative priority (-5)"
        _ = assert str eq (hp_peek_val pk) "critical" "AC3: heap peek critical value"

        p0 = heap pop h6
        _ = assert int equals (hp_pop_prio p0) (-5) "AC3: pop 0 (-5)"
        p1 = heap pop (hp_pop_rest p0)
        _ = assert int equals (hp_pop_prio p1) 10 "AC3: pop 1 (10)"
        p2 = heap pop (hp_pop_rest p1)
        _ = assert int equals (hp_pop_prio p2) 10 "AC3: pop 2 duplicate priority (10)"

        -- Interleaved push after partial pop
        h_mid = heap push (hp_pop_rest p2) 15 "medium-high"
        p3 = heap pop h_mid
        _ = assert int equals (hp_pop_prio p3) 15 "AC3: interleaved push 15 popped before 20"
        p4 = heap pop (hp_pop_rest p3)
        _ = assert int equals (hp_pop_prio p4) 20 "AC3: pop 20"
        p5 = heap pop (hp_pop_rest p4)
        _ = assert int equals (hp_pop_prio p5) 30 "AC3: pop 30"
        p6 = heap pop (hp_pop_rest p5)
        _ = assert int equals (hp_pop_prio p6) 50 "AC3: pop 50"
        _ = assert int equals (heap size (hp_pop_rest p6)) 0 "AC3: heap empty after popping all"
        ()

-- @tests TS-BTREE-001
fn :: main => ()
      main =
        _ = test_btree_map_avl_balance_and_crud
        _ = test_btree_set_operations
        _ = test_min_heap_priority_queue
        echo "[PASS] test btree: TS-BTREE-001 passed"
