-- ============================================================
-- src/test/ridgun/test linalg.rg
-- Test suite for linalg.rg on Real tensors (TS-LINALG-001, ADR-0008)
-- Reference values: exact arithmetic, or IEEE double results of the same formula.
-- @tests TS-LINALG-001
-- ============================================================

import test
import linalg

-- |a - b| <= 1e-12 * max(1, |b|)
fn :: tol abs Real => Real
      tol abs x    =
        | x < 0.0   = 0.0 - x
        | otherwise = x

fn :: near Real Real => Bool
      near a    b    =
        scale = | (tol abs b) > 1.0 = tol abs b
                | otherwise         = 1.0
        (tol abs (a - b)) <= (0.000000000001 * scale)

-- @tests TS-LINALG-001
fn :: test sqrt and exp => ()
      test sqrt and exp =
        assert true (near (linalg sqrt 25.0) 5.0) "sqrt(25) == 5"
        assert true (near (linalg sqrt 2.0) 1.4142135623730951) "sqrt(2)"
        assert true (near (linalg sqrt 0.25) 0.5) "sqrt(0.25) == 0.5"
        assert true (near (linalg sqrt 1000000.0) 1000.0) "sqrt(1e6) == 1000"
        assert true (near (linalg sqrt 0.0) 0.0) "sqrt(0) == 0"
        assert true (near (linalg sqrt (0.0 - 4.0)) 0.0) "sqrt of a negative is 0 (guard)"
        assert true (near (linalg exp 0.0) 1.0) "exp(0) == 1"
        assert true (near (linalg exp 1.0) 2.718281828459045) "exp(1) == e"
        assert true (near (linalg exp (0.0 - 1.0)) 0.36787944117144233) "exp(-1)"
        assert true (near (linalg exp 10.0) 22026.465794806718) "exp(10)"
        assert true (near ((linalg exp (0.0 - 20.0)) * 1000000000.0) 2.061153622438558) "exp(-20)"
        assert true (near (linalg exp (0.0 - 800.0)) 0.0) "exp(-800) underflows to 0"
        ()

-- @tests TS-LINALG-001
fn :: test transpose trace diag identity => ()
      test transpose trace diag identity =
        -- 1. Non-square 2x3 transpose -> 3x2, and (A^T)^T == A
        m = Tensor[Real * 2 * 3]
        m_(0, 0) = 1.0
        m_(0, 1) = 2.0
        m_(0, 2) = 3.0
        m_(1, 0) = 4.0
        m_(1, 1) = 5.5
        m_(1, 2) = 6.0
        assert int equals (linalg mat rows m) 2 "2x3 rows == 2"
        assert int equals (linalg mat cols m) 3 "2x3 cols == 3"
        mt = linalg transpose m
        assert int equals (linalg mat rows mt) 3 "transposed rows == 3"
        assert int equals (linalg mat cols mt) 2 "transposed cols == 2"
        assert true (near mt_(0, 0) 1.0) "mt(0,0) == 1"
        assert true (near mt_(0, 1) 4.0) "mt(0,1) == 4"
        assert true (near mt_(1, 1) 5.5) "mt(1,1) == 5.5"
        assert true (near mt_(2, 0) 3.0) "mt(2,0) == 3"
        mtt = linalg transpose mt
        assert true (near mtt_(1, 2) 6.0) "(A^T)^T(1,2) == 6"

        -- 2. Trace and diagonal on a 3x3 matrix with negative and fractional entries
        sq = Tensor[Real * 3 * 3]
        sq_(0, 0) = 10.0
        sq_(0, 1) = 2.0
        sq_(0, 2) = 3.0
        sq_(1, 0) = 4.0
        sq_(1, 1) = 0.0 - 3.5
        sq_(1, 2) = 6.0
        sq_(2, 0) = 7.0
        sq_(2, 1) = 8.0
        sq_(2, 2) = 5.0
        assert true (near (linalg trace sq) 11.5) "trace(sq) == 10 - 3.5 + 5"
        assert true (near (linalg trace (linalg transpose sq)) 11.5) "trace(A^T) == trace(A)"
        dg = linalg diag sq
        assert int equals (linalg vec len dg) 3 "diag len == 3"
        assert true (near dg_(1) (0.0 - 3.5)) "diag(1) == -3.5"

        -- 3. Identity: trace(I_4) == 4, det(I_4) == 1, I_3 @ sq == sq
        id4 = linalg identity 4
        assert int equals (linalg mat rows id4) 4 "I_4 rows == 4"
        assert true (near (linalg trace id4) 4.0) "trace(I_4) == 4"
        assert true (near id4_(2, 2) 1.0) "I_4(2,2) == 1"
        assert true (near id4_(2, 3) 0.0) "I_4(2,3) == 0"
        assert true (near (linalg det id4) 1.0) "det(I_4) == 1"
        id3  = linalg identity 3
        prod = linalg matmul id3 sq
        assert true (near prod_(0, 0) 10.0) "(I_3 @ sq)(0,0) == 10"
        assert true (near prod_(1, 1) (0.0 - 3.5)) "(I_3 @ sq)(1,1) == -3.5"
        assert true (near prod_(2, 1) 8.0) "(I_3 @ sq)(2,1) == 8"
        ()

-- @tests TS-LINALG-001
fn :: test dot outer matvec norms => ()
      test dot outer matvec norms =
        -- 1. Dot product, commutativity and orthogonal vectors
        u = Tensor[Real * 3]
        u_(0) = 1.0
        u_(1) = 0.0 - 2.0
        u_(2) = 3.0
        v = Tensor[Real * 3]
        v_(0) = 4.0
        v_(1) = 5.0
        v_(2) = 6.5
        assert true (near (linalg dot u v) 13.5) "dot([1,-2,3], [4,5,6.5]) == 4 - 10 + 19.5"
        assert true (near (linalg dot v u) 13.5) "dot is commutative"
        o1 = Tensor[Real * 3]
        o1_(0) = 1.0
        o1_(1) = 2.0
        o1_(2) = 0.0 - 1.0
        o2 = Tensor[Real * 3]
        o2_(0) = 2.0
        o2_(1) = 0.0
        o2_(2) = 2.0
        assert true (near (linalg dot o1 o2) 0.0) "orthogonal dot == 0"
        assert true (near (linalg cosine similarity o1 o2) 0.0) "orthogonal cosine similarity == 0"
        assert true (near (linalg cosine similarity o1 o1) 1.0) "cosine similarity with itself == 1"

        -- 2. Outer product u (3) (x) w (2) -> 3x2; a square outer product has det 0
        w = Tensor[Real * 2]
        w_(0) = 0.5
        w_(1) = 0.0 - 8.0
        out = linalg outer u w
        assert int equals (linalg mat rows out) 3 "outer rows == 3"
        assert int equals (linalg mat cols out) 2 "outer cols == 2"
        assert true (near out_(0, 0) 0.5) "outer(0,0) == 0.5"
        assert true (near out_(1, 0) (0.0 - 1.0)) "outer(1,0) == -1"
        assert true (near out_(2, 1) (0.0 - 24.0)) "outer(2,1) == -24"
        rk1 = linalg outer u v
        assert true (near (linalg det rk1) 0.0) "rank-1 outer product has det == 0"

        -- 3. Norms and normalization on (3, -4, 0)
        p = Tensor[Real * 3]
        p_(0) = 3.0
        p_(1) = 0.0 - 4.0
        p_(2) = 0.0
        assert true (near (linalg norm l1 p) 7.0) "L1([3,-4,0]) == 7"
        assert true (near (linalg norm l2 sq p) 25.0) "L2^2([3,-4,0]) == 25"
        assert true (near (linalg norm l2 p) 5.0) "L2([3,-4,0]) == 5"
        assert true (near (linalg norm linf p) 4.0) "L_inf([3,-4,0]) == 4"
        np = linalg normalize vec p
        assert true (near np_(0) 0.6) "normalized(0) == 0.6"
        assert true (near np_(1) (0.0 - 0.8)) "normalized(1) == -0.8"
        assert true (near np_(2) 0.0) "normalized(2) == 0"
        assert true (near (linalg norm l2 np) 1.0) "normalized vector has L2 == 1"
        fm = Tensor[Real * 2 * 2]
        fm_(0, 0) = 1.0
        fm_(0, 1) = 2.0
        fm_(1, 0) = 2.0
        fm_(1, 1) = 4.0
        assert true (near (linalg frobenius norm fm) 5.0) "Frobenius([1,2;2,4]) == 5"

        -- Zero-vector normalization guard (VUL-INPUT-001)
        z3 = Tensor[Real * 3]
        nz = linalg normalize vec z3
        assert true (near nz_(0) 0.0) "normalize zero vector is safe (0)"
        ()

-- @tests TS-LINALG-001
fn :: test det and linear solver => ()
      test det and linear solver =
        -- 1. 2x2: [2, 3; 5, 4] x = [13, 22] => x = [2, 3]
        a2 = Tensor[Real * 2 * 2]
        a2_(0, 0) = 2.0
        a2_(0, 1) = 3.0
        a2_(1, 0) = 5.0
        a2_(1, 1) = 4.0
        b2 = Tensor[Real * 2]
        b2_(0) = 13.0
        b2_(1) = 22.0
        assert true (near (linalg det a2) (0.0 - 7.0)) "det([2,3;5,4]) == -7"
        x2 = linalg solve a2 b2
        assert true (near x2_(0) 2.0) "2x2 solve x0 == 2"
        assert true (near x2_(1) 3.0) "2x2 solve x1 == 3"
        r2 = linalg matvec a2 x2
        assert true (near r2_(0) 13.0) "A*x(0) == 13"
        assert true (near r2_(1) 22.0) "A*x(1) == 22"

        -- 2. 3x3 with a 0 in (0,0), so partial pivoting is required:
        -- [0, 2, 1; 1, -2, -3; -1, 1, 2] x = [-8, 0, 3] => x = [-4, -5, 2]
        a3 = Tensor[Real * 3 * 3]
        a3_(0, 0) = 0.0
        a3_(0, 1) = 2.0
        a3_(0, 2) = 1.0
        a3_(1, 0) = 1.0
        a3_(1, 1) = 0.0 - 2.0
        a3_(1, 2) = 0.0 - 3.0
        a3_(2, 0) = 0.0 - 1.0
        a3_(2, 1) = 1.0
        a3_(2, 2) = 2.0
        b3 = Tensor[Real * 3]
        b3_(0) = 0.0 - 8.0
        b3_(1) = 0.0
        b3_(2) = 3.0
        assert true (near (linalg det a3) 1.0) "det(a3) == 1"
        x3 = linalg solve a3 b3
        assert true (near x3_(0) (0.0 - 4.0)) "3x3 pivoted solve x0 == -4"
        assert true (near x3_(1) (0.0 - 5.0)) "3x3 pivoted solve x1 == -5"
        assert true (near x3_(2) 2.0) "3x3 pivoted solve x2 == 2"
        r3 = linalg matvec a3 x3
        assert true (near r3_(0) (0.0 - 8.0)) "A3*x3(0) == -8"
        assert true (near r3_(1) 0.0) "A3*x3(1) == 0"
        assert true (near r3_(2) 3.0) "A3*x3(2) == 3"

        -- 3. Fractional solution: [4, 1; 1, 3] x = [1, 2] => x = [1/11, 7/11]
        f2 = Tensor[Real * 2 * 2]
        f2_(0, 0) = 4.0
        f2_(0, 1) = 1.0
        f2_(1, 0) = 1.0
        f2_(1, 1) = 3.0
        fb = Tensor[Real * 2]
        fb_(0) = 1.0
        fb_(1) = 2.0
        xf = linalg solve f2 fb
        assert true (near xf_(0) (1.0 / 11.0)) "fractional solve x0 == 1/11"
        assert true (near xf_(1) (7.0 / 11.0)) "fractional solve x1 == 7/11"
        assert true (near (linalg det f2) 11.0) "det([4,1;1,3]) == 11"

        -- 4. Singular matrix: det 0, solve does not divide by zero (VUL-INPUT-001)
        s2 = Tensor[Real * 2 * 2]
        s2_(0, 0) = 1.0
        s2_(0, 1) = 2.0
        s2_(1, 0) = 2.0
        s2_(1, 1) = 4.0
        assert true (near (linalg det s2) 0.0) "singular det == 0"
        xs = linalg solve s2 fb
        assert int equals (linalg vec len xs) 2 "singular solve returns a vector"
        ()

-- @tests TS-LINALG-001
fn :: test neural activations => ()
      test neural activations =
        -- 1. ReLU: negatives -> 0, positives preserved
        v = Tensor[Real * 4]
        v_(0) = 0.0 - 10.0
        v_(1) = 0.0
        v_(2) = 0.5
        v_(3) = 42.0
        rv = linalg relu v
        assert true (near rv_(0) 0.0) "relu(-10) == 0"
        assert true (near rv_(1) 0.0) "relu(0) == 0"
        assert true (near rv_(2) 0.5) "relu(0.5) == 0.5"
        assert true (near rv_(3) 42.0) "relu(42) == 42"

        -- 2. Sigmoid: in (0, 1), sigmoid(0) == 0.5, sigmoid(-x) + sigmoid(x) == 1
        sv = Tensor[Real * 4]
        sv_(0) = 0.0 - 2.0
        sv_(1) = 0.0
        sv_(2) = 2.0
        sv_(3) = 0.0 - 1000.0
        sg = linalg sigmoid sv
        assert true (near sg_(1) 0.5) "sigmoid(0) == 0.5"
        assert true (near sg_(2) 0.8807970779778823) "sigmoid(2)"
        assert true (sg_(0) > 0.0 and sg_(0) < 0.5) "sigmoid(-2) in (0, 0.5)"
        assert true (near (sg_(0) + sg_(2)) 1.0) "sigmoid(-2) + sigmoid(2) == 1"
        assert true (near sg_(3) 0.0) "sigmoid(-1000) == 0 without overflow"

        -- 3. Softmax: known values, sums to 1, shift-invariant, overflow-safe
        logits = Tensor[Real * 3]
        logits_(0) = 1.0
        logits_(1) = 2.0
        logits_(2) = 3.0
        sm = linalg softmax logits
        assert true (near sm_(0) 0.09003057317038046) "softmax([1,2,3])(0)"
        assert true (near sm_(1) 0.24472847105479764) "softmax([1,2,3])(1)"
        assert true (near sm_(2) 0.6652409557748219) "softmax([1,2,3])(2)"
        assert true (near (sm_(0) + sm_(1) + sm_(2)) 1.0) "softmax sums to 1"
        shifted = Tensor[Real * 3]
        shifted_(0) = 1000001.0
        shifted_(1) = 1000002.0
        shifted_(2) = 1000003.0
        sm_sh = linalg softmax shifted
        assert true (near sm_sh_(0) sm_(0)) "softmax shift-invariance (0)"
        assert true (near sm_sh_(1) sm_(1)) "softmax shift-invariance (1)"
        assert true (near sm_sh_(2) sm_(2)) "softmax shift-invariance (2)"
        ()

fn :: main => ()
      main =
        test sqrt and exp
        test transpose trace diag identity
        test dot outer matvec norms
        test det and linear solver
        test neural activations
        echo "[PASS] test linalg: TS-LINALG-001 passed"
