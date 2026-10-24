-- ============================================================
-- src/main/ridgun/lib/math.rg
-- Pure-Ridgun Integer Mathematics, Number Theory, Combinatorics & Statistics Library (MATH)
-- @implements FR-MATH-001
-- @implements API-MATH-001
-- @mitigates VUL-INPUT-001
-- ============================================================

-- ── Bounds, Sign & Parity ────────────────────────────────────

-- @implements FR-MATH-001
-- @implements API-MATH-001
fn :: math abs Int => Int
      math abs x   =
        | x < 0     = 0 - x
        | otherwise = x

-- @implements FR-MATH-001
-- @implements API-MATH-001
fn :: math sign Int => Int
      math sign x   =
        | x < 0     = 0 - 1
        | x > 0     = 1
        | otherwise = 0

-- @implements FR-MATH-001
-- @implements API-MATH-001
fn :: math min Int Int => Int
      math min a   b   =
        | a <= b    = a
        | otherwise = b

-- @implements FR-MATH-001
-- @implements API-MATH-001
fn :: math max Int Int => Int
      math max a   b   =
        | a >= b    = a
        | otherwise = b

-- @implements FR-MATH-001
-- @implements API-MATH-001
fn :: math clamp Int Int Int => Int
      math clamp x   lo  hi  =
        | x < lo    = lo
        | x > hi    = hi
        | otherwise = x

-- @implements FR-MATH-001
-- @implements API-MATH-001
op :: clamp Int between Int and Int => Int
      clamp x   between lo  and hi  =  math clamp x lo hi

-- @implements FR-MATH-001
-- @implements API-MATH-001
fn :: math is even Int => Bool
      math is even x   =  (x % 2) == 0

-- @implements FR-MATH-001
-- @implements API-MATH-001
fn :: math is odd Int => Bool
      math is odd x   =  (x % 2) != 0

-- ── Rounding & Euclidean Division (Division-by-Zero Safe) ────

fn :: m fix mod Int Int => Int
      m fix mod r   mb  =
        | r < 0     = r + mb
        | otherwise = r

-- @implements FR-MATH-001
-- @implements API-MATH-001
-- @mitigates VUL-INPUT-001
fn :: math mod euclid Int Int => Int
      math mod euclid a   b   =
        | b == 0 = 0
        | otherwise =
          mb = math abs b
          m fix mod (a % mb) mb

-- @implements FR-MATH-001
-- @implements API-MATH-001
-- @mitigates VUL-INPUT-001
fn :: math div euclid Int Int => Int
      math div euclid a   b   =
        | b == 0 = 0
        | otherwise =
          r = math mod euclid a b
          (a - r) / b

fn :: m adjust floor Int Int Int Int => Int
      m adjust floor a b q r =
        | (r != 0) and (((a < 0) and (b > 0)) or ((a > 0) and (b < 0))) = q - 1
        | otherwise = q

-- @implements FR-MATH-001
-- @implements API-MATH-001
-- @mitigates VUL-INPUT-001
fn :: math div floor Int Int => Int
      math div floor a   b   =
        | b == 0    = 0
        | otherwise = m adjust floor a b (a / b) (a % b)

fn :: m adjust ceil Int Int Int Int => Int
      m adjust ceil a b q r =
        | (r != 0) and (((a > 0) and (b > 0)) or ((a < 0) and (b < 0))) = q + 1
        | otherwise = q

-- @implements FR-MATH-001
-- @implements API-MATH-001
-- @mitigates VUL-INPUT-001
fn :: math div ceil Int Int => Int
      math div ceil a   b   =
        | b == 0    = 0
        | otherwise = m adjust ceil a b (a / b) (a % b)

-- ── Powers, Integer Roots & Logarithms ───────────────────────

fn :: m pow loop Int Int Int => Int
      m pow loop base exp acc =
        | exp <= 0       = acc
        | (exp % 2) == 1 = m pow loop (base * base) (exp / 2) (acc * base)
        | otherwise      = m pow loop (base * base) (exp / 2) acc

-- @implements FR-MATH-001
-- @implements API-MATH-001
-- @mitigates VUL-INPUT-001
fn :: math pow Int  Int => Int
      math pow base exp =
        | exp < 0   = 0
        | exp == 0  = 1
        | otherwise = m pow loop base exp 1

fn :: m isqrt step Int Int Int => Int
      m isqrt step n x nx =
        | nx >= x   = x
        | otherwise = m isqrt loop n nx

fn :: m isqrt loop Int Int => Int
      m isqrt loop n   x   =  m isqrt step n x ((x + (n / x)) / 2)

-- @implements FR-MATH-001
-- @implements API-MATH-001
-- @mitigates VUL-INPUT-001
fn :: math isqrt Int => Int
      math isqrt n   =
        | n < 0     = 0 - 1
        | n == 0    = 0
        | n < 4     = 1
        | otherwise = m isqrt loop n (n / 2)

fn :: m ilog2 loop Int Int => Int
      m ilog2 loop n   acc =
        | n <= 1    = acc
        | otherwise = m ilog2 loop (n / 2) (acc + 1)

-- @implements FR-MATH-001
-- @implements API-MATH-001
-- @mitigates VUL-INPUT-001
fn :: math ilog2 Int => Int
      math ilog2 n   =
        | n <= 0    = 0 - 1
        | otherwise = m ilog2 loop n 0

fn :: m ilog10 loop Int Int => Int
      m ilog10 loop n   acc =
        | n < 10    = acc
        | otherwise = m ilog10 loop (n / 10) (acc + 1)

-- @implements FR-MATH-001
-- @implements API-MATH-001
-- @mitigates VUL-INPUT-001
fn :: math ilog10 Int => Int
      math ilog10 n   =
        | n <= 0    = 0 - 1
        | otherwise = m ilog10 loop n 0

fn :: m next pow2 loop Int Int => Int
      m next pow2 loop target cur =
        | cur >= target = cur
        | otherwise     = m next pow2 loop target (cur * 2)

-- @implements FR-MATH-001
-- @implements API-MATH-001
fn :: math next power of two Int => Int
      math next power of two n =
        | n <= 1    = 1
        | otherwise = m next pow2 loop n 1

-- @implements FR-MATH-001
-- @implements API-MATH-001
fn :: math is power of two Int => Bool
      math is power of two n =
        | n <= 0    = False
        | otherwise = (math next power of two n) == n

-- ── Number Theory & Modular Arithmetic ───────────────────────

fn :: m gcd loop Int Int => Int
      m gcd loop a   b   =
        | b == 0    = a
        | otherwise = m gcd loop b (a % b)

-- @implements FR-MATH-001
-- @implements API-MATH-001
fn :: math gcd Int Int => Int
      math gcd a   b   =  m gcd loop (math abs a) (math abs b)

-- @implements FR-MATH-001
-- @implements API-MATH-001
-- @mitigates VUL-INPUT-001
fn :: math lcm Int Int => Int
      math lcm a   b   =
        | a == 0 or b == 0 = 0
        | otherwise =
          g = math gcd a b
          ((math abs a) / g) * (math abs b)

fn :: m mod pow loop Int Int Int Int => Int
      m mod pow loop base exp m acc =
        | exp <= 0       = acc
        | (exp % 2) == 1 = m mod pow loop ((base * base) % m) (exp / 2) m ((acc * base) % m)
        | otherwise      = m mod pow loop ((base * base) % m) (exp / 2) m acc

-- @implements FR-MATH-001
-- @implements API-MATH-001
-- @mitigates VUL-INPUT-001
fn :: math mod pow Int Int Int => Int
      math mod pow base exp m =
        | m <= 1 or exp < 0 = 0
        | otherwise =
          b0 = math mod euclid base m
          m mod pow loop b0 exp m 1

fn :: m egcd loop Int Int Int Int => Int Int
      m egcd loop old_r r old_s s =
        | r == 0 = (old_r, old_s)
        | otherwise =
          q = old_r / r
          m egcd loop r (old_r - (q * r)) s (old_s - (q * s))

fn :: m finish mod inv (Int Int) Int => Int
      m finish mod inv (g, x) m =
        | g != 1    = 0 - 1
        | otherwise = math mod euclid x m

-- @implements FR-MATH-001
-- @implements API-MATH-001
-- @mitigates VUL-INPUT-001
fn :: math mod inv Int Int => Int
      math mod inv a   m   =
        | m <= 1    = 0 - 1
        | otherwise = m finish mod inv (m egcd loop (math mod euclid a m) m 1 0) m

fn :: m prime loop Int Int => Bool
      m prime loop n   d   =
        | (d * d) > n        = True
        | (n % d) == 0       = False
        | (n % (d + 2)) == 0 = False
        | otherwise          = m prime loop n (d + 6)

-- @implements FR-MATH-001
-- @implements API-MATH-001
fn :: math is prime Int => Bool
      math is prime n   =
        | n <= 1       = False
        | n <= 3       = True
        | (n % 2) == 0 = False
        | (n % 3) == 0 = False
        | otherwise    = m prime loop n 5

-- ── Combinatorics & Sequences ────────────────────────────────

fn :: m fact loop Int Int => Int
      m fact loop n   acc =
        | n <= 1    = acc
        | otherwise = m fact loop (n - 1) (acc * n)

-- @implements FR-MATH-001
-- @implements API-MATH-001
fn :: math factorial Int => Int
      math factorial n   =
        | n < 0     = 0
        | otherwise = m fact loop n 1

fn :: m ncr loop Int Int Int Int => Int
      m ncr loop n k idx acc =
        | idx > k   = acc
        | otherwise = m ncr loop n k (idx + 1) ((acc * ((n - k) + idx)) / idx)

-- @implements FR-MATH-001
-- @implements API-MATH-001
fn :: math ncr Int Int => Int
      math ncr n   k   =
        | k < 0 or n < 0 or k > n = 0
        | k == 0 or k == n        = 1
        | otherwise =
          eff_k = math min k (n - k)
          m ncr loop n eff_k 1 1

fn :: m fib loop Int Int Int => Int
      m fib loop rem a b =
        | rem <= 0  = a
        | otherwise = m fib loop (rem - 1) b (a + b)

-- @implements FR-MATH-001
-- @implements API-MATH-001
fn :: math fibonacci Int => Int
      math fibonacci n   =
        | n <= 0    = 0
        | otherwise = m fib loop n 0 1

-- ── Integer List Statistics ──────────────────────────────────

fn :: m list len [Int]    => Int
      m list len []       =  0
      m list len (_:rest) =  1 + (m list len rest)

fn :: m nth int [Int]    Int => Int
      m nth int []       _   =  0
      m nth int (x:rest) idx =
        | idx <= 0  = x
        | otherwise = m nth int rest (idx - 1)

-- @implements FR-MATH-001
-- @implements API-MATH-001
fn :: math sum [Int]    => Int
      math sum []       =  0
      math sum (x:rest) =  x + (math sum rest)

-- @implements FR-MATH-001
-- @implements API-MATH-001
fn :: math product [Int]    => Int
      math product []       =  1
      math product (x:rest) =  x * (math product rest)

fn :: m mean len [Int] Int => Int
      m mean len xs    n   =
        | n == 0    = 0
        | otherwise = (math sum xs) / n

-- @implements FR-MATH-001
-- @implements API-MATH-001
fn :: math mean [Int] => Int
      math mean xs    =  m mean len xs (m list len xs)

fn :: m min loop [Int]    Int => Int
      m min loop []       cur =  cur
      m min loop (x:rest) cur =  m min loop rest (math min cur x)

-- @implements FR-MATH-001
-- @implements API-MATH-001
fn :: math min list [Int]    => Int
      math min list []       =  0
      math min list (x:rest) =  m min loop rest x

fn :: m max loop [Int]    Int => Int
      m max loop []       cur =  cur
      m max loop (x:rest) cur =  m max loop rest (math max cur x)

-- @implements FR-MATH-001
-- @implements API-MATH-001
fn :: math max list [Int]    => Int
      math max list []       =  0
      math max list (x:rest) =  m max loop rest x

fn :: m insert sorted Int [Int]    => [Int]
      m insert sorted v   []       =  [v]
      m insert sorted v   (x:rest) =
        | v <= x    = [v, x] :: rest
        | otherwise = [x] :: (m insert sorted v rest)

fn :: m sort ints [Int]    => [Int]
      m sort ints []       =  []
      m sort ints (x:rest) =  m insert sorted x (m sort ints rest)

fn :: m median sorted [Int] Int Int => Int
      m median sorted sorted n mid =
        | n == 0       = 0
        | (n % 2) == 1 = m nth int sorted mid
        | otherwise    = ((m nth int sorted (mid - 1)) + (m nth int sorted mid)) / 2

-- @implements FR-MATH-001
-- @implements API-MATH-001
fn :: math median [Int] => Int
      math median xs    =
        n = m list len xs
        m median sorted (m sort ints xs) n (n / 2)
