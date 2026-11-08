-- ============================================================
-- src/main/ridgun/lib/linalg.rg
-- Pure-Ridgun Real Tensor Linear Algebra, Norms, Linear Solver & Neural Activations Library (LINALG)
-- All values are Real (64-bit floating point). See ADR-0008.
-- @implements FR-LINALG-001
-- @implements API-LINALG-001
-- @implements DM-Linalg
-- @implements DM-Tensor
-- @mitigates VUL-INPUT-001
-- ============================================================

module :: linalg

import tensor

-- ── Internal Scalar Helpers ──────────────────────────────────

fn :: la abs Real => Real
      la abs x    =
        | x < 0.0   = 0.0 - x
        | otherwise = x

fn :: la max Real Real => Real
      la max a    b    =
        | a >= b    = a
        | otherwise = b

fn :: la max int Int Int => Int
      la max int a   b   =
        | a >= b    = a
        | otherwise = b

-- Newton's method from above: g >= sqrt(x) on every step, so the
-- iteration stops at the first step that no longer decreases.
fn :: la sqrt step Real Real Real => Real
      la sqrt step x    g    ng   =
        | ng >= g   = g
        | otherwise = la sqrt loop x ng

fn :: la sqrt loop Real Real => Real
      la sqrt loop x    g    =
        la sqrt step x g ((g + (x / g)) / 2.0)

-- @implements FR-LINALG-001
fn :: linalg sqrt Real => Real
      linalg sqrt x    =
        | x <= 0.0  = 0.0
        | otherwise = la sqrt loop x (la max x 1.0)

-- exp(r) for |r| <= 0.5 by its Taylor series (24 terms, below 1 ulp).
fn :: la exp series Real Real Real Real => Real
      la exp series r    term acc  fi   =
        | fi > 24.0 = acc
        | otherwise =
          t = (term * r) / fi
          la exp series r t (acc + t) (fi + 1.0)

fn :: la square times Real Int => Real
      la square times g    k   =
        | k <= 0    = g
        | otherwise = la square times (g * g) (k - 1)

-- exp(x) = exp(x / 2^k) ^ (2^k), with |x / 2^k| <= 0.5.
fn :: la exp reduce Real Int => Real
      la exp reduce r    k   =
        | (la abs r) > 0.5 = la exp reduce (r / 2.0) (k + 1)
        | otherwise        = la square times (la exp series r 1.0 1.0 1.0) k

-- @implements FR-LINALG-001
fn :: linalg exp Real => Real
      linalg exp x    =
        | x < (0.0 - 745.0) = 0.0
        | otherwise         = la exp reduce x 0

-- ── Dimension Introspection (`row_count`, `col_count`) ───────

-- @implements FR-LINALG-001
-- @implements API-LINALG-001
-- @implements DM-Linalg
fn :: linalg vec len Tensor[Real * n] => Int
      linalg vec len (Tensor[Real * n] v) = n

-- @implements FR-LINALG-001
-- @implements API-LINALG-001
-- @implements DM-Linalg
fn :: linalg mat rows Tensor[Real * r * c] => Int
      linalg mat rows (Tensor[Real * r * c] m) = r

-- @implements FR-LINALG-001
-- @implements API-LINALG-001
-- @implements DM-Linalg
fn :: linalg mat cols Tensor[Real * r * c] => Int
      linalg mat cols (Tensor[Real * r * c] m) = c

-- ── Matrix Transpose, Trace, Diagonal & Identity ─────────────

fn :: la transpose col loop Tensor[Real * r * c] Tensor[Real * c * r] Int Int Int => Tensor[Real * c * r]
      la transpose col loop m out i j cols =
        | j >= cols = out
        | otherwise =
          out_(j, i) = m_(i, j)
          la transpose col loop m out i (j + 1) cols

fn :: la transpose row loop Tensor[Real * r * c] Tensor[Real * c * r] Int Int Int => Tensor[Real * c * r]
      la transpose row loop m out i rows cols =
        | i >= rows = out
        | otherwise =
          out2 = la transpose col loop m out i 0 cols
          la transpose row loop m out2 (i + 1) rows cols

-- @implements FR-LINALG-001
-- @implements API-LINALG-001
-- @implements DM-Linalg
fn :: linalg transpose Tensor[Real * r * c] => Tensor[Real * c * r]
      linalg transpose (Tensor[Real * r * c] m) =
        out = Tensor[Real * c * r]
        la transpose row loop m out 0 r c

fn :: la trace loop Tensor[Real * r * c] Int Int Real => Real
      la trace loop m idx n acc =
        | idx >= n  = acc
        | otherwise = la trace loop m (idx + 1) n (acc + m_(idx, idx))

-- @implements FR-LINALG-001
-- @implements API-LINALG-001
-- @implements DM-Linalg
fn :: linalg trace Tensor[Real * r * c] => Real
      linalg trace (Tensor[Real * r * c] m) =
        la trace loop m 0 r 0.0

fn :: la diag loop Tensor[Real * r * c] Tensor[Real * r] Int Int => Tensor[Real * r]
      la diag loop m out idx n =
        | idx >= n  = out
        | otherwise =
          out_(idx) = m_(idx, idx)
          la diag loop m out (idx + 1) n

-- @implements FR-LINALG-001
-- @implements API-LINALG-001
-- @implements DM-Linalg
fn :: linalg diag Tensor[Real * r * c] => Tensor[Real * r]
      linalg diag (Tensor[Real * r * c] m) =
        out = Tensor[Real * r]
        la diag loop m out 0 r

fn :: la identity loop Tensor[Real * n * n] Int Int => Tensor[Real * n * n]
      la identity loop out idx n =
        | idx >= n  = out
        | otherwise =
          out_(idx, idx) = 1.0
          la identity loop out (idx + 1) n

-- @implements FR-LINALG-001
-- @implements API-LINALG-001
-- @implements DM-Linalg
-- @mitigates VUL-INPUT-001
fn :: linalg identity Int => Tensor[Real * n * n]
      linalg identity dim =
        la max int 1 dim -> n
        out = Tensor[Real * n * n]
        la identity loop out 0 n

-- ── Dot Product, Outer Product, Matrix-Vector & Matrix-Matrix Ops ──

fn :: la dot loop Tensor[Real * n] Tensor[Real * n] Int Int Real => Real
      la dot loop a b idx n acc =
        | idx >= n  = acc
        | otherwise = la dot loop a b (idx + 1) n (acc + (a_(idx) * b_(idx)))

-- @implements FR-LINALG-001
-- @implements API-LINALG-001
-- @implements DM-Linalg
fn :: linalg dot Tensor[Real * n] Tensor[Real * n] => Real
      linalg dot (Tensor[Real * n] a) (Tensor[Real * n] b) =
        la dot loop a b 0 n 0.0

fn :: la outer col loop Tensor[Real * r] Tensor[Real * c] Tensor[Real * r * c] Int Int Int => Tensor[Real * r * c]
      la outer col loop a b out i j cols =
        | j >= cols = out
        | otherwise =
          out_(i, j) = a_(i) * b_(j)
          la outer col loop a b out i (j + 1) cols

fn :: la outer row loop Tensor[Real * r] Tensor[Real * c] Tensor[Real * r * c] Int Int Int => Tensor[Real * r * c]
      la outer row loop a b out i rows cols =
        | i >= rows = out
        | otherwise =
          out2 = la outer col loop a b out i 0 cols
          la outer row loop a b out2 (i + 1) rows cols

-- @implements FR-LINALG-001
-- @implements API-LINALG-001
-- @implements DM-Linalg
fn :: linalg outer Tensor[Real * r] Tensor[Real * c] => Tensor[Real * r * c]
      linalg outer (Tensor[Real * r] a) (Tensor[Real * c] b) =
        out = Tensor[Real * r * c]
        la outer row loop a b out 0 r c

fn :: la matvec row dot Tensor[Real * r * c] Tensor[Real * c] Int Int Int Real => Real
      la matvec row dot m v row j cols acc =
        | j >= cols = acc
        | otherwise = la matvec row dot m v row (j + 1) cols (acc + (m_(row, j) * v_(j)))

fn :: la matvec loop Tensor[Real * r * c] Tensor[Real * c] Tensor[Real * r] Int Int Int => Tensor[Real * r]
      la matvec loop m v out i rows cols =
        | i >= rows = out
        | otherwise =
          out_(i) = la matvec row dot m v i 0 cols 0.0
          la matvec loop m v out (i + 1) rows cols

-- @implements FR-LINALG-001
-- @implements API-LINALG-001
-- @implements DM-Linalg
fn :: linalg matvec Tensor[Real * r * c] Tensor[Real * c] => Tensor[Real * r]
      linalg matvec (Tensor[Real * r * c] m) (Tensor[Real * c] v) =
        out = Tensor[Real * r]
        la matvec loop m v out 0 r c

-- @implements FR-LINALG-001
-- @implements API-LINALG-001
-- @implements DM-Linalg
fn :: linalg matmul Tensor[Real * r * k] Tensor[Real * k * c] => Tensor[Real * r * c]
      linalg matmul a b =
        tensor matmul a b

-- ── Vector & Matrix Norms (`norm_l1`, `norm_l2`, `norm_linf`, `frobenius`) ──

fn :: la norm l1 loop Tensor[Real * n] Int Int Real => Real
      la norm l1 loop v idx n acc =
        | idx >= n  = acc
        | otherwise = la norm l1 loop v (idx + 1) n (acc + (la abs v_(idx)))

-- @implements FR-LINALG-001
-- @implements API-LINALG-001
-- @implements DM-Linalg
fn :: linalg norm l1 Tensor[Real * n] => Real
      linalg norm l1 (Tensor[Real * n] v) =
        la norm l1 loop v 0 n 0.0

-- @implements FR-LINALG-001
-- @implements API-LINALG-001
-- @implements DM-Linalg
fn :: linalg norm l2 sq Tensor[Real * n] => Real
      linalg norm l2 sq (Tensor[Real * n] v) =
        la dot loop v v 0 n 0.0

-- @implements FR-LINALG-001
-- @implements API-LINALG-001
-- @implements DM-Linalg
fn :: linalg norm l2 Tensor[Real * n] => Real
      linalg norm l2 (Tensor[Real * n] v) =
        linalg sqrt (la dot loop v v 0 n 0.0)

fn :: la norm linf loop Tensor[Real * n] Int Int Real => Real
      la norm linf loop v idx n best =
        | idx >= n  = best
        | otherwise = la norm linf loop v (idx + 1) n (la max best (la abs v_(idx)))

-- @implements FR-LINALG-001
-- @implements API-LINALG-001
-- @implements DM-Linalg
fn :: linalg norm linf Tensor[Real * n] => Real
      linalg norm linf (Tensor[Real * n] v) =
        la norm linf loop v 0 n 0.0

fn :: la frob col loop Tensor[Real * r * c] Int Int Int Real => Real
      la frob col loop m i j cols acc =
        | j >= cols = acc
        | otherwise =
          x = m_(i, j)
          la frob col loop m i (j + 1) cols (acc + (x * x))

fn :: la frob row loop Tensor[Real * r * c] Int Int Int Real => Real
      la frob row loop m i rows cols acc =
        | i >= rows = acc
        | otherwise = la frob row loop m (i + 1) rows cols (la frob col loop m i 0 cols acc)

-- @implements FR-LINALG-001
-- @implements API-LINALG-001
-- @implements DM-Linalg
fn :: linalg frobenius norm Tensor[Real * r * c] => Real
      linalg frobenius norm (Tensor[Real * r * c] m) =
        linalg sqrt (la frob row loop m 0 r c 0.0)

fn :: la norm vec loop Tensor[Real * n] Tensor[Real * n] Real Int Int => Tensor[Real * n]
      la norm vec loop v out norm_val idx n =
        | idx >= n  = out
        | otherwise =
          out_(idx) = v_(idx) / norm_val
          la norm vec loop v out norm_val (idx + 1) n

fn :: la normalize vec step Tensor[Real * n] Tensor[Real * n] Real Int => Tensor[Real * n]
      la normalize vec step v out norm_value n =
        | norm_value <= 0.0 = out
        | otherwise         = la norm vec loop v out norm_value 0 n

-- @implements FR-LINALG-001
-- @implements API-LINALG-001
-- @implements DM-Linalg
-- @mitigates VUL-INPUT-001
fn :: linalg normalize vec Tensor[Real * n] => Tensor[Real * n]
      linalg normalize vec (Tensor[Real * n] v) =
        la normalize vec step v (Tensor[Real * n]) (linalg norm l2 v) n

fn :: la cosine step Tensor[Real * n] Tensor[Real * n] Real Real => Real
      la cosine step a b na nb =
        | na <= 0.0 or nb <= 0.0 = 0.0
        | otherwise              = (linalg dot a b) / (na * nb)

-- @implements FR-LINALG-001
-- @implements API-LINALG-001
-- @implements DM-Linalg
-- @mitigates VUL-INPUT-001
fn :: linalg cosine similarity Tensor[Real * n] Tensor[Real * n] => Real
      linalg cosine similarity (Tensor[Real * n] a) (Tensor[Real * n] b) =
        la cosine step a b (linalg norm l2 a) (linalg norm l2 b)

-- ── Gaussian Elimination with Partial Pivoting (`linalg det`, `linalg solve`) ──

fn :: la clone mat col Tensor[Real * r * c] Tensor[Real * n * n] Int Int Int => Tensor[Real * n * n]
      la clone mat col src dst i j n =
        | j >= n    = dst
        | otherwise =
          dst_(i, j) = src_(i, j)
          la clone mat col src dst i (j + 1) n

fn :: la clone mat row Tensor[Real * r * c] Tensor[Real * n * n] Int Int => Tensor[Real * n * n]
      la clone mat row src dst i n =
        | i >= n    = dst
        | otherwise =
          dst2 = la clone mat col src dst i 0 n
          la clone mat row src dst2 (i + 1) n

fn :: la clone vec loop Tensor[Real * n] Tensor[Real * n] Int Int => Tensor[Real * n]
      la clone vec loop src dst i n =
        | i >= n    = dst
        | otherwise =
          dst_(i) = src_(i)
          la clone vec loop src dst (i + 1) n

fn :: la find pivot step Tensor[Real * n * n] Int Int Int Int Real Real => Int
      la find pivot step a k row n best_row best_val cur =
        | cur > best_val = la find pivot row a k (row + 1) n row cur
        | otherwise      = la find pivot row a k (row + 1) n best_row best_val

-- Row (k..n-1) with the largest |a(row, k)|; the first one wins a tie.
fn :: la find pivot row Tensor[Real * n * n] Int Int Int Int Real => Int
      la find pivot row a k row n best_row best_val =
        | row >= n  = best_row
        | otherwise = la find pivot step a k row n best_row best_val (la abs a_(row, k))

fn :: la swap mat rows loop Tensor[Real * n * n] Int Int Int Int => Tensor[Real * n * n]
      la swap mat rows loop a r1 r2 j n =
        | r1 == r2 or j >= n = a
        | otherwise          =
          tmp       = a_(r1, j)
          a_(r1, j) = a_(r2, j)
          a_(r2, j) = tmp
          la swap mat rows loop a r1 r2 (j + 1) n

fn :: la swap vec elems Tensor[Real * n] Int Int => Tensor[Real * n]
      la swap vec elems b r1 r2 =
        | r1 == r2  = b
        | otherwise =
          tmp    = b_(r1)
          b_(r1) = b_(r2)
          b_(r2) = tmp
          b

-- a(row, j) -= f * a(k, j) for j in k..n-1
fn :: la elim col loop Tensor[Real * n * n] Int Int Real Int Int => Tensor[Real * n * n]
      la elim col loop a k row f j n =
        | j >= n    = a
        | otherwise =
          a_(row, j) = a_(row, j) - (f * a_(k, j))
          la elim col loop a k row f (j + 1) n

-- Clears column k below the pivot a(k, k) = piv.
fn :: la elim rows Tensor[Real * n * n] Int Int Real Int => Tensor[Real * n * n]
      la elim rows a k row piv n =
        | row >= n  = a
        | otherwise =
          f  = a_(row, k) / piv
          a2 = la elim col loop a k row f k n
          la elim rows a2 k (row + 1) piv n

-- Applies the same row operations to b; runs before la elim rows clears column k.
fn :: la elim b loop Tensor[Real * n * n] Tensor[Real * n] Int Int Real Int => Tensor[Real * n]
      la elim b loop a b k row piv n =
        | row >= n  = b
        | otherwise =
          b_(row) = b_(row) - ((a_(row, k) / piv) * b_(k))
          la elim b loop a b k (row + 1) piv n

fn :: la solve pivot Tensor[Real * n * n] Tensor[Real * n] Int Int Real => Tensor[Real * n]
      la solve pivot a b k n piv =
        | piv == 0.0 = la solve loop a b (k + 1) n
        | otherwise  =
          b2 = la elim b loop a b k (k + 1) piv n
          a2 = la elim rows a k (k + 1) piv n
          la solve loop a2 b2 (k + 1) n

fn :: la solve loop Tensor[Real * n * n] Tensor[Real * n] Int Int => Tensor[Real * n]
      la solve loop a b k n =
        | k >= n    = la backsub loop a b (Tensor[Real * n]) (n - 1) n
        | otherwise =
          piv_row = la find pivot row a k (k + 1) n k (la abs a_(k, k))
          a_sw    = la swap mat rows loop a k piv_row 0 n
          b_sw    = la swap vec elems b k piv_row
          la solve pivot a_sw b_sw k n a_sw_(k, k)

fn :: la backsub sum Tensor[Real * n * n] Tensor[Real * n] Int Int Int Real => Real
      la backsub sum a x row j n acc =
        | j >= n    = acc
        | otherwise = la backsub sum a x row (j + 1) n (acc + (a_(row, j) * x_(j)))

fn :: la backsub div Real Real Real => Real
      la backsub div b_val s    piv  =
        | piv == 0.0 = 0.0
        | otherwise  = (b_val - s) / piv

fn :: la backsub loop Tensor[Real * n * n] Tensor[Real * n] Tensor[Real * n] Int Int => Tensor[Real * n]
      la backsub loop a b x row n =
        | row < 0   = x
        | otherwise =
          s       = la backsub sum a x row (row + 1) n 0.0
          x_(row) = la backsub div b_(row) s a_(row, row)
          la backsub loop a b x (row - 1) n

-- @implements FR-LINALG-001
-- @implements API-LINALG-001
-- @implements DM-Linalg
-- @mitigates VUL-INPUT-001
fn :: linalg solve Tensor[Real * n * c] Tensor[Real * n] => Tensor[Real * n]
      linalg solve (Tensor[Real * n * c] a) (Tensor[Real * n] b) =
        work_a = la clone mat row a (Tensor[Real * n * n]) 0 n
        work_b = la clone vec loop b (Tensor[Real * n]) 0 n
        la solve loop work_a work_b 0 n

fn :: la pivot sign Int Int Real => Real
      la pivot sign piv_row k acc =
        | piv_row == k = acc
        | otherwise    = 0.0 - acc

fn :: la det pivot Tensor[Real * n * n] Int Real Int Real => Real
      la det pivot a k acc n piv =
        | piv == 0.0 = 0.0
        | otherwise  =
          a2 = la elim rows a k (k + 1) piv n
          la det loop a2 (k + 1) (acc * piv) n

-- det = (-1)^swaps * product of the pivots
fn :: la det loop Tensor[Real * n * n] Int Real Int => Real
      la det loop a k acc n =
        | k >= n    = acc
        | otherwise =
          piv_row = la find pivot row a k (k + 1) n k (la abs a_(k, k))
          a_sw    = la swap mat rows loop a k piv_row 0 n
          la det pivot a_sw k (la pivot sign piv_row k acc) n a_sw_(k, k)

-- @implements FR-LINALG-001
-- @implements API-LINALG-001
-- @implements DM-Linalg
fn :: linalg det Tensor[Real * n * c] => Real
      linalg det (Tensor[Real * n * c] m) =
        | n <= 0 or n != c = 0.0
        | otherwise        =
          work = la clone mat row m (Tensor[Real * n * n]) 0 n
          la det loop work 0 1.0 n

-- ── Neural Activations (`linalg relu`, `linalg sigmoid`, `linalg softmax`) ──

fn :: la relu scalar Real => Real
      la relu scalar x    =
        | x <= 0.0  = 0.0
        | otherwise = x

fn :: la relu loop Tensor[Real * n] Tensor[Real * n] Int Int => Tensor[Real * n]
      la relu loop v out idx n =
        | idx >= n  = out
        | otherwise =
          out_(idx) = la relu scalar v_(idx)
          la relu loop v out (idx + 1) n

-- @implements FR-LINALG-001
-- @implements API-LINALG-001
-- @implements DM-Linalg
fn :: linalg relu Tensor[Real * n] => Tensor[Real * n]
      linalg relu (Tensor[Real * n] v) =
        la relu loop v (Tensor[Real * n]) 0 n

fn :: la sigmoid neg Real => Real
      la sigmoid neg e    = e / (1.0 + e)

-- 1 / (1 + exp(-x)); exp only ever gets a value <= 0, so it cannot overflow.
fn :: la sigmoid scalar Real => Real
      la sigmoid scalar x    =
        | x >= 0.0  = 1.0 / (1.0 + (linalg exp (0.0 - x)))
        | otherwise = la sigmoid neg (linalg exp x)

fn :: la sigmoid loop Tensor[Real * n] Tensor[Real * n] Int Int => Tensor[Real * n]
      la sigmoid loop v out idx n =
        | idx >= n  = out
        | otherwise =
          out_(idx) = la sigmoid scalar v_(idx)
          la sigmoid loop v out (idx + 1) n

-- @implements FR-LINALG-001
-- @implements API-LINALG-001
-- @implements DM-Linalg
fn :: linalg sigmoid Tensor[Real * n] => Tensor[Real * n]
      linalg sigmoid (Tensor[Real * n] v) =
        la sigmoid loop v (Tensor[Real * n]) 0 n

fn :: la max vec loop Tensor[Real * n] Int Int Real => Real
      la max vec loop v idx n best =
        | idx >= n  = best
        | otherwise = la max vec loop v (idx + 1) n (la max best v_(idx))

fn :: la sum vec loop Tensor[Real * n] Int Int Real => Real
      la sum vec loop v idx n acc =
        | idx >= n  = acc
        | otherwise = la sum vec loop v (idx + 1) n (acc + v_(idx))

fn :: la exp shifted loop Tensor[Real * n] Tensor[Real * n] Real Int Int => Tensor[Real * n]
      la exp shifted loop v out max_val idx n =
        | idx >= n  = out
        | otherwise =
          out_(idx) = linalg exp (v_(idx) - max_val)
          la exp shifted loop v out max_val (idx + 1) n

fn :: la softmax scale loop Tensor[Real * n] Tensor[Real * n] Real Int Int => Tensor[Real * n]
      la softmax scale loop exps out tot idx n =
        | idx >= n  = out
        | otherwise =
          out_(idx) = exps_(idx) / tot
          la softmax scale loop exps out tot (idx + 1) n

-- @implements FR-LINALG-001
-- @implements API-LINALG-001
-- @implements DM-Linalg
-- @mitigates VUL-INPUT-001
fn :: linalg softmax Tensor[Real * n] => Tensor[Real * n]
      linalg softmax (Tensor[Real * n] v) =
        | n <= 0    = Tensor[Real * n]
        | otherwise =
          max_v = la max vec loop v 1 n v_(0)
          exps  = la exp shifted loop v (Tensor[Real * n]) max_v 0 n
          tot   = la sum vec loop exps 0 n 0.0
          la softmax scale loop exps (Tensor[Real * n]) tot 0 n
