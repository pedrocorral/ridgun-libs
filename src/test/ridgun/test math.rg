-- ============================================================
-- src/test/ridgun/test math.rg
-- Automated test suite for math.rg (TS-MATH-001)
-- @tests TS-MATH-001
-- ============================================================

import test
import math

-- @tests TS-MATH-001
fn :: test math bounds and division => ()
      test math bounds and division =
        _ = assert int equals (math abs (0 - 42)) 42 "math abs negative"
        _ = assert int equals (math abs 42) 42 "math abs positive"
        _ = assert int equals (math abs 0) 0 "math abs zero"
        _ = assert int equals (math sign (0 - 99)) (0 - 1) "math sign negative"
        _ = assert int equals (math sign 0) 0 "math sign zero"
        _ = assert int equals (math sign 99) 1 "math sign positive"
        _ = assert int equals (math min 10 (0 - 5)) (0 - 5) "math min"
        _ = assert int equals (math max 10 (0 - 5)) 10 "math max"
        _ = assert int equals (math clamp (0 - 10) 0 100) 0 "math clamp low"
        _ = assert int equals (math clamp 50 0 100) 50 "math clamp mid"
        _ = assert int equals (math clamp 250 0 100) 100 "math clamp high"
        _ = assert int equals (clamp 150 between 10 and 100) 100 "op clamp between and"
        _ = assert true (math is even 42) "math is even 42"
        _ = assert false (math is even 41) "math is even 41"
        _ = assert true (math is odd (0 - 7)) "math is odd -7"
        _ = assert int equals (math div ceil 7 3) 3 "math div ceil 7/3"
        _ = assert int equals (math div ceil 6 3) 2 "math div ceil 6/3"
        _ = assert int equals (math div ceil (0 - 7) 3) (0 - 2) "math div ceil -7/3"
        _ = assert int equals (math div floor (0 - 7) 3) (0 - 3) "math div floor -7/3"
        _ = assert int equals (math div floor 7 3) 2 "math div floor 7/3"
        _ = assert int equals (math mod euclid (0 - 7) 3) 2 "math mod euclid -7 % 3 == 2"
        _ = assert int equals (math div euclid (0 - 7) 3) (0 - 3) "math div euclid -7 / 3 == -3"
        -- Division by zero safety
        _ = assert int equals (math div ceil 10 0) 0 "math div ceil / 0 == 0"
        _ = assert int equals (math div floor 10 0) 0 "math div floor / 0 == 0"
        _ = assert int equals (math div euclid 10 0) 0 "math div euclid / 0 == 0"
        _ = assert int equals (math mod euclid 10 0) 0 "math mod euclid % 0 == 0"
        ()

-- @tests TS-MATH-001
fn :: test math powers number theory and combinatorics => ()
      test math powers number theory and combinatorics =
        _ = assert int equals (math pow 2 10) 1024 "2^10 == 1024"
        _ = assert int equals (math pow 5 0) 1 "5^0 == 1"
        _ = assert int equals (math pow 5 (0 - 2)) 0 "negative exp -> 0"
        _ = assert int equals (math isqrt 0) 0 "isqrt 0"
        _ = assert int equals (math isqrt 1) 1 "isqrt 1"
        _ = assert int equals (math isqrt 15) 3 "isqrt 15"
        _ = assert int equals (math isqrt 16) 4 "isqrt 16"
        _ = assert int equals (math isqrt 10000) 100 "isqrt 10000"
        _ = assert int equals (math isqrt (0 - 4)) (0 - 1) "isqrt negative -> -1"
        _ = assert int equals (math ilog2 1) 0 "ilog2 1 == 0"
        _ = assert int equals (math ilog2 1024) 10 "ilog2 1024 == 10"
        _ = assert int equals (math ilog2 0) (0 - 1) "ilog2 0 == -1"
        _ = assert int equals (math ilog10 999) 2 "ilog10 999 == 2"
        _ = assert int equals (math ilog10 1000) 3 "ilog10 1000 == 3"
        _ = assert true (math is power of two 64) "64 is power of two"
        _ = assert false (math is power of two 63) "63 is not power of two"
        _ = assert false (math is power of two 0) "0 is not power of two"
        _ = assert int equals (math next power of two 33) 64 "next power of two 33 == 64"
        _ = assert int equals (math gcd 48 18) 6 "gcd(48, 18) == 6"
        _ = assert int equals (math gcd (0 - 48) 18) 6 "gcd(-48, 18) == 6"
        _ = assert int equals (math lcm 12 18) 36 "lcm(12, 18) == 36"
        _ = assert int equals (math lcm 0 18) 0 "lcm(0, 18) == 0"
        _ = assert int equals (math mod pow 2 10 1000) 24 "2^10 mod 1000 == 24"
        _ = assert int equals (math mod pow 3 200 97) 62 "3^200 mod 97 == 62"
        _ = assert int equals (math mod inv 3 11) 4 "3 * 4 == 12 == 1 mod 11"
        _ = assert int equals (math mod inv 6 12) (0 - 1) "mod inv non-coprime -> -1"
        _ = assert false (math is prime 1) "1 not prime"
        _ = assert true (math is prime 2) "2 prime"
        _ = assert true (math is prime 97) "97 prime"
        _ = assert false (math is prime 99) "99 not prime"
        _ = assert int equals (math factorial 5) 120 "5! == 120"
        _ = assert int equals (math factorial 0) 1 "0! == 1"
        _ = assert int equals (math ncr 10 3) 120 "C(10, 3) == 120"
        _ = assert int equals (math fibonacci 10) 55 "fib(10) == 55"
        ()

-- @tests TS-MATH-001
fn :: test math list statistics => ()
      test math list statistics =
        xs = [30, 10, 50, 20, 40]
        _  = assert int equals (math sum xs) 150 "sum"
        _  = assert int equals (math product [2, 3, 4]) 24 "product"
        _  = assert int equals (math mean xs) 30 "mean"
        _  = assert int equals (math median xs) 30 "median odd"
        _  = assert int equals (math median [10, 20, 30, 40]) 25 "median even"
        _  = assert int equals (math min list xs) 10 "min list"
        _  = assert int equals (math max list xs) 50 "max list"
        _  = assert int equals (math sum []) 0 "sum []"
        _  = assert int equals (math mean []) 0 "mean []"
        _  = assert int equals (math median []) 0 "median []"
        ()

fn :: main => ()
      main =
        _ = test math bounds and division
        _ = test math powers number theory and combinatorics
        _ = test math list statistics
        echo "[PASS] test math: TS-MATH-001 passed"
