-- ============================================================
-- src/test/ridgun/test hashmap.rg
-- Test suite for hashmap.rg: put, get, has, add, size, pairs, unusual keys, growth
-- @tests TS-HASHMAP-001
-- ============================================================

import test
import hashmap

type Visit = page: String, hits: Int

-- Program functions named like common field names: they must not change the map.
fn :: fill Int => Int
      fill n = n + 1

fn :: count [Int] => Int
      count xs = 0

fn :: seed => String
      seed = "fixed"

fn :: rep text String Int => String
      rep text s n =
        | n <= 0    = ""
        | otherwise = s + (rep text s (n - 1))

fn :: kb10 String => String
      kb10 last = (rep text (rep text "k" 100) 100) + last

fn :: put many (HashMap Int) Int Int => HashMap Int
      put many m i n =
        | i >= n    = m
        | otherwise = put many (hashmap put m "key {i}" i) (i + 1) n

fn :: all found (HashMap Int) Int Int => Bool
      all found m i n =
        | i >= n                            = True
        | hashmap get m "key {i}" (0 - 1) != i = False
        | otherwise                         = all found m (i + 1) n

fn :: sum values [String Int] Int => Int
      sum values []            acc = acc
      sum values ((_, v):rest) acc = sum values rest (acc + v)

fn :: first keys [String Int] Int [String] => [String]
      first keys _             0 acc = acc
      first keys []            _ acc = acc
      first keys ((k, _):rest) n acc = first keys rest (n - 1) (acc :: [k])

-- @tests TS-HASHMAP-001
fn :: test hashmap basics => ()
      test hashmap basics =
        e = hashmap empty
        _ = assert int equals (hashmap get e "a" 7) 7 "AC1: get on empty gives the default"
        _ = assert false (hashmap has e "a") "AC1: has on empty"
        _ = assert int equals (hashmap size e) 0 "AC1: size of empty"
        _ = assert eq (hashmap pairs e) []

        m = hashmap put (hashmap put (hashmap put hashmap empty "b" 2) "a" 1) "c" 3
        m2 = hashmap put m "a" 10
        _ = assert int equals (hashmap get m2 "a" 0) 10 "AC1: put replaces the value"
        _ = assert int equals (hashmap get m2 "b" 0) 2 "AC1: get b"
        _ = assert int equals (hashmap get m2 "zz" (0 - 1)) (0 - 1) "AC1: missing key gives the default"
        _ = assert true (hashmap has m2 "c") "AC1: has c"
        _ = assert false (hashmap has m2 "zz") "AC1: has missing"
        _ = assert int equals (hashmap size m2) 3 "AC1: replacing does not add a key"
        _ = assert eq (hashmap pairs m2) [("b", 2), ("a", 10), ("c", 3)]
        ()

-- @tests TS-HASHMAP-001
fn :: test hashmap add => ()
      test hashmap add =
        m = hashmap add (hashmap add (hashmap add hashmap empty "x" 2) "y" 5) "x" 3
        _ = assert int equals (hashmap get m "x" 0) 5 "AC2: add sums"
        _ = assert int equals (hashmap get m "y" 0) 5 "AC2: a missing key starts at 0"
        m2 = hashmap add m "y" (0 - 5)
        _ = assert int equals (hashmap get m2 "y" 99) 0 "AC2: add can reach 0 and the key stays"
        _ = assert true (hashmap has m2 "y") "AC2: has after reaching 0"
        _ = assert eq (hashmap pairs m2) [("x", 5), ("y", 0)]
        ()

-- @tests TS-HASHMAP-001
fn :: test hashmap unusual keys => ()
      test hashmap unusual keys =
        hi = (char from code 200) + (char from code 255)
        la = kb10 "a"
        lb = kb10 "b"
        m = hashmap put (hashmap put (hashmap put (hashmap put hashmap empty "" 1) hi 2) la 3) lb 4
        _ = assert int equals (hashmap get m "" 0) 1 "AC3: empty key"
        _ = assert int equals (hashmap get m hi 0) 2 "AC3: bytes >= 128"
        _ = assert int equals (hashmap get m la 0) 3 "AC3: 10 KB key"
        _ = assert int equals (hashmap get m lb 0) 4 "AC3: 10 KB key differing in the last byte"
        _ = assert false (hashmap has m (kb10 "c")) "AC3: another 10 KB key is missing"
        _ = assert false (hashmap has m (char from code 200)) "AC3: prefix of a key is missing"
        _ = assert int equals (hashmap size m) 4 "AC3: four keys"
        ()

-- @tests TS-HASHMAP-001
fn :: test hashmap record values => ()
      test hashmap record values =
        m = hashmap put (hashmap put (hashmap put hashmap empty "/a" (Visit "/a" 3)) "/b" (Visit "/b" 7)) "/a" (Visit "/a" 4)
        _ = assert eq (hashmap get m "/a" (Visit "" 0)) (Visit "/a" 4)
        _ = assert eq (hashmap get m "/b" (Visit "" 0)) (Visit "/b" 7)
        _ = assert eq (hashmap get m "/c" (Visit "" 0)) (Visit "" 0)
        _ = assert int equals (hits (hashmap get m "/a" (Visit "" 0))) 4 "AC4: record field"
        ()

-- @tests TS-HASHMAP-001
fn :: test hashmap growth => ()
      test hashmap growth =
        n = 20000
        m = put many hashmap empty 0 n
        _ = assert int equals (hashmap size m) n "AC1: 20000 keys after growing"
        _ = assert true (all found m 0 n) "AC1: every key found after growing"
        ps = hashmap pairs m
        _ = assert int equals (sum values ps 0) (n * (n - 1) / 2) "AC1: pairs hold every value"
        _ = assert eq (first keys ps 3 []) ["key 0", "key 1", "key 2"]
        _ = assert int equals (fill 1 + count [] + str len seed) 7 "Program functions named like fields still work"
        ()

-- @tests TS-HASHMAP-001
fn :: main => ()
      main =
        _ = test hashmap basics
        _ = test hashmap add
        _ = test hashmap unusual keys
        _ = test hashmap record values
        _ = test hashmap growth
        echo "[PASS] test hashmap: TS-HASHMAP-001 passed"
