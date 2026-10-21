-- ============================================================
-- src/test/ridgun/test_math.rg
-- Automated test suite for math.rg (TS-MATH-001)
-- @tests TS-MATH-001
-- ============================================================

import test
import math

-- @tests TS-MATH-001
fn :: test math bounds and division => ()
      test math bounds and division =
        _ = assert_int_equals (math abs (0 - 42)) 42 "math_abs negative"
        _ = assert_int_equals (math abs 42) 42 "math_abs positive"
        _ = assert_int_equals (math abs 0) 0 "math_abs zero"
        _ = assert_int_equals (math sign (0 - 99)) (0 - 1) "math_sign negative"
        _ = assert_int_equals (math sign 0) 0 "math_sign zero"
        _ = assert_int_equals (math sign 99) 1 "math_sign positive"
        _ = assert_int_equals (math min 10 (0 - 5)) (0 - 5) "math_min"
        _ = assert_int_equals (math max 10 (0 - 5)) 10 "math_max"
        _ = assert_int_equals (math clamp (0 - 10) 0 100) 0 "math_clamp low"
        _ = assert_int_equals (math clamp 50 0 100) 50 "math_clamp mid"
        _ = assert_int_equals (math clamp 250 0 100) 100 "math_clamp high"
        _ = assert_int_equals (clamp 150 between 10 and 100) 100 "op clamp between and"
        _ = assert_true (math is even 42) "math_is_even 42"
        _ = assert_false (math is even 41) "math_is_even 41"
        _ = assert_true (math is odd (0 - 7)) "math_is_odd -7"
        _ = assert_int_equals (math div ceil 7 3) 3 "math_div_ceil 7/3"
        _ = assert_int_equals (math div ceil 6 3) 2 "math_div_ceil 6/3"
        _ = assert_int_equals (math div ceil (0 - 7) 3) (0 - 2) "math_div_ceil -7/3"
        _ = assert_int_equals (math div floor (0 - 7) 3) (0 - 3) "math_div_floor -7/3"
        _ = assert_int_equals (math div floor 7 3) 2 "math_div_floor 7/3"
        _ = assert_int_equals (math mod euclid (0 - 7) 3) 2 "math_mod_euclid -7 % 3 == 2"
        _ = assert_int_equals (math div euclid (0 - 7) 3) (0 - 3) "math_div_euclid -7 / 3 == -3"
        -- Division by zero safety
        _ = assert_int_equals (math div ceil 10 0) 0 "math_div_ceil / 0 == 0"
        _ = assert_int_equals (math div floor 10 0) 0 "math_div_floor / 0 == 0"
        _ = assert_int_equals (math div euclid 10 0) 0 "math_div_euclid / 0 == 0"
        _ = assert_int_equals (math mod euclid 10 0) 0 "math_mod_euclid % 0 == 0"
        ()

-- @tests TS-MATH-001
fn :: test math powers number theory and combinatorics => ()
      test math powers number theory and combinatorics =
        _ = assert_int_equals (math pow 2 10) 1024 "2^10 == 1024"
        _ = assert_int_equals (math pow 5 0) 1 "5^0 == 1"
        _ = assert_int_equals (math pow 5 (0 - 2)) 0 "negative exp -> 0"
        _ = assert_int_equals (math isqrt 0) 0 "isqrt 0"
        _ = assert_int_equals (math isqrt 1) 1 "isqrt 1"
        _ = assert_int_equals (math isqrt 15) 3 "isqrt 15"
        _ = assert_int_equals (math isqrt 16) 4 "isqrt 16"
        _ = assert_int_equals (math isqrt 10000) 100 "isqrt 10000"
        _ = assert_int_equals (math isqrt (0 - 4)) (0 - 1) "isqrt negative -> -1"
        _ = assert_int_equals (math ilog2 1) 0 "ilog2 1 == 0"
        _ = assert_int_equals (math ilog2 1024) 10 "ilog2 1024 == 10"
        _ = assert_int_equals (math ilog2 0) (0 - 1) "ilog2 0 == -1"
        _ = assert_int_equals (math ilog10 999) 2 "ilog10 999 == 2"
        _ = assert_int_equals (math ilog10 1000) 3 "ilog10 1000 == 3"
        _ = assert_true (math is power of two 64) "64 is power of two"
        _ = assert_false (math is power of two 63) "63 is not power of two"
        _ = assert_false (math is power of two 0) "0 is not power of two"
        _ = assert_int_equals (math next power of two 33) 64 "next_power_of_two 33 == 64"
        _ = assert_int_equals (math gcd 48 18) 6 "gcd(48, 18) == 6"
        _ = assert_int_equals (math gcd (0 - 48) 18) 6 "gcd(-48, 18) == 6"
        _ = assert_int_equals (math lcm 12 18) 36 "lcm(12, 18) == 36"
        _ = assert_int_equals (math lcm 0 18) 0 "lcm(0, 18) == 0"
        _ = assert_int_equals (math mod pow 2 10 1000) 24 "2^10 mod 1000 == 24"
        _ = assert_int_equals (math mod pow 3 200 97) 62 "3^200 mod 97 == 62"
        _ = assert_int_equals (math mod inv 3 11) 4 "3 * 4 == 12 == 1 mod 11"
        _ = assert_int_equals (math mod inv 6 12) (0 - 1) "mod_inv non-coprime -> -1"
        _ = assert_false (math is prime 1) "1 not prime"
        _ = assert_true (math is prime 2) "2 prime"
        _ = assert_true (math is prime 97) "97 prime"
        _ = assert_false (math is prime 99) "99 not prime"
        _ = assert_int_equals (math factorial 5) 120 "5! == 120"
        _ = assert_int_equals (math factorial 0) 1 "0! == 1"
        _ = assert_int_equals (math ncr 10 3) 120 "C(10, 3) == 120"
        _ = assert_int_equals (math fibonacci 10) 55 "fib(10) == 55"
        ()

-- @tests TS-MATH-001
fn :: test math list statistics => ()
      test math list statistics =
        xs = [30, 10, 50, 20, 40]
        _  = assert_int_equals (math sum xs) 150 "sum"
        _  = assert_int_equals (math product [2, 3, 4]) 24 "product"
        _  = assert_int_equals (math mean xs) 30 "mean"
        _  = assert_int_equals (math median xs) 30 "median odd"
        _  = assert_int_equals (math median [10, 20, 30, 40]) 25 "median even"
        _  = assert_int_equals (math min list xs) 10 "min_list"
        _  = assert_int_equals (math max list xs) 50 "max_list"
        _  = assert_int_equals (math sum []) 0 "sum []"
        _  = assert_int_equals (math mean []) 0 "mean []"
        _  = assert_int_equals (math median []) 0 "median []"
        ()

fn :: main => ()
      main =
        _ = test math bounds and division
        _ = test math powers number theory and combinatorics
        _ = test math list statistics
        echo "[PASS] test_math: TS-MATH-001 passed"
