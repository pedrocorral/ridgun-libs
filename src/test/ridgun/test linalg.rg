-- ============================================================
-- src/test/ridgun/test linalg.rg
-- Comprehensive test suite for linalg.rg (TS-LINALG-001)
-- Inspired by nalgebra, gonum/mat, and NumPy/SciPy linalg test suites
-- @tests TS-LINALG-001
-- ============================================================

import test
import linalg

-- @tests TS-LINALG-001
fn :: test transpose trace diag identity => ()
      test transpose trace diag identity =
        -- 1. Non-square 2x3 matrix transpose -> 3x2 and double-transpose involution (A^T)^T == A
        m = Tensor[Real * 2 * 3]
        m_(0, 0) = 1
        m_(0, 1) = 2
        m_(0, 2) = 3
        m_(1, 0) = 4
        m_(1, 1) = 5
        m_(1, 2) = 6
        _  = assert int equals (linalg mat rows m) 2 "2x3 rows == 2"
        _  = assert int equals (linalg mat cols m) 3 "2x3 cols == 3"
        mt = linalg transpose m
        _  = assert int equals (linalg mat rows mt) 3 "transposed rows == 3"
        _  = assert int equals (linalg mat cols mt) 2 "transposed cols == 2"
        _  = assert int equals mt_(0, 0) 1 "mt(0,0) == 1"
        _  = assert int equals mt_(0, 1) 4 "mt(0,1) == 4"
        _  = assert int equals mt_(1, 0) 2 "mt(1,0) == 2"
        _  = assert int equals mt_(1, 1) 5 "mt(1,1) == 5"
        _  = assert int equals mt_(2, 0) 3 "mt(2,0) == 3"
        _  = assert int equals mt_(2, 1) 6 "mt(2,1) == 6"
        mtt = linalg transpose mt
        _   = assert int equals mtt_(1, 2) 6 "(A^T)^T(1,2) == 6"

        -- 2. Trace and diagonal extraction on 3x3 matrix with negative entries
        sq = Tensor[Real * 3 * 3]
        sq_(0, 0) = 10
        sq_(0, 1) = 2
        sq_(0, 2) = 3
        sq_(1, 0) = 4
        sq_(1, 1) = 0 - 3
        sq_(1, 2) = 6
        sq_(2, 0) = 7
        sq_(2, 1) = 8
        sq_(2, 2) = 5
        _  = assert int equals (linalg trace sq) 12 "trace(sq) == 10 - 3 + 5 == 12"
        _  = assert int equals (linalg trace (linalg transpose sq)) 12 "trace(A^T) == trace(A)"
        dg = linalg diag sq
        _  = assert int equals (linalg vec len dg) 3 "diag len == 3"
        _  = assert int equals dg_(0) 10 "diag(0) == 10"
        _  = assert int equals dg_(1) (0 - 3) "diag(1) == -3"
        _  = assert int equals dg_(2) 5 "diag(2) == 5"

        -- 3. Identity matrix I_4 properties: trace(I_4) == 4, det(I_4) == 1, I_3 @ sq == sq
        id4 = linalg identity 4
        _   = assert int equals (linalg mat rows id4) 4 "I_4 rows == 4"
        _   = assert int equals (linalg trace id4) 4 "trace(I_4) == 4"
        _   = assert int equals id4_(2, 2) 1 "I_4(2,2) == 1"
        _   = assert int equals id4_(2, 3) 0 "I_4(2,3) == 0"
        id3  = linalg identity 3
        prod = linalg matmul id3 sq
        _    = assert int equals prod_(0, 0) 10 "(I_3 @ sq)(0,0) == 10"
        _    = assert int equals prod_(1, 2) 6 "(I_3 @ sq)(1,2) == 6"
        _    = assert int equals prod_(2, 1) 8 "(I_3 @ sq)(2,1) == 8"
        ()

-- @tests TS-LINALG-001
fn :: test dot outer matvec norms => ()
      test dot outer matvec norms =
        -- 1. Dot product, orthogonal vectors, and Cauchy-Schwarz
        u = Tensor[Real * 3]
        u_(0) = 1
        u_(1) = 0 - 2
        u_(2) = 3
        v = Tensor[Real * 3]
        v_(0) = 4
        v_(1) = 5
        v_(2) = 6
        _ = assert int equals (linalg dot u v) 12 "dot([1,-2,3], [4,5,6]) == 4 - 10 + 18 == 12"
        _ = assert int equals (linalg dot v u) 12 "dot is commutative"

        -- Orthogonal vectors: [1, 2, -1] . [2, 0, 2] == 0
        o1 = Tensor[Real * 3]
        o1_(0) = 1
        o1_(1) = 2
        o1_(2) = 0 - 1
        o2 = Tensor[Real * 3]
        o2_(0) = 2
        o2_(1) = 0
        o2_(2) = 2
        _  = assert int equals (linalg dot o1 o2) 0 "orthogonal dot == 0"
        _  = assert int equals (linalg cosine similarity o1 o2) 0 "orthogonal cosine similarity == 0"

        -- 2. Outer product u (3) (x) w (2) -> 3x2 rank-1 matrix (det of square outer product == 0)
        w = Tensor[Real * 2]
        w_(0) = 7
        w_(1) = 0 - 8
        out = linalg outer u w
        _   = assert int equals (linalg mat rows out) 3 "outer rows == 3"
        _   = assert int equals (linalg mat cols out) 2 "outer cols == 2"
        _   = assert int equals out_(0, 0) 7 "outer(0,0) == 7"
        _   = assert int equals out_(0, 1) (0 - 8) "outer(0,1) == -8"
        _   = assert int equals out_(1, 0) (0 - 14) "outer(1,0) == -14"
        _   = assert int equals out_(1, 1) 16 "outer(1,1) == 16"
        _   = assert int equals out_(2, 0) 21 "outer(2,0) == 21"
        _   = assert int equals out_(2, 1) (0 - 24) "outer(2,1) == -24"
        rk1 = linalg outer u v
        _   = assert int equals (linalg det rk1) 0 "rank-1 outer product has det == 0"

        -- 3. Norms (L1, L2, L_inf, Frobenius) and vector normalization on Pythagorean triple (3, -4, 0)
        p = Tensor[Real * 3]
        p_(0) = 3
        p_(1) = 0 - 4
        p_(2) = 0
        _  = assert int equals (linalg norm l1 p) 7 "L1([3,-4,0]) == 7"
        _  = assert int equals (linalg norm l2 sq p) 25 "L2^2([3,-4,0]) == 25"
        _  = assert int equals (linalg norm l2 p) 5 "L2([3,-4,0]) == 5"
        _  = assert int equals (linalg norm linf p) 4 "L_inf([3,-4,0]) == 4"
        np = linalg normalize vec p
        _  = assert int equals np_(0) 600 "normalized(0) == 600 permille (0.6)"
        _  = assert int equals np_(1) (0 - 800) "normalized(1) == -800 permille (-0.8)"
        _  = assert int equals np_(2) 0 "normalized(2) == 0"

        -- Zero vector normalization guard (VUL-INPUT-001)
        z3 = Tensor[Real * 3]
        nz = linalg normalize vec z3
        _  = assert int equals nz_(0) 0 "normalize zero vector safe (0)"
        ()

-- @tests TS-LINALG-001
fn :: test det and linear solver => ()
      test det and linear solver =
        -- 1. 2x2 non-unit pivot system: [2, 3; 5, 4] * [x0, x1] = [13, 22] => x = [2, 3]
        a2 = Tensor[Real * 2 * 2]
        a2_(0, 0) = 2
        a2_(0, 1) = 3
        a2_(1, 0) = 5
        a2_(1, 1) = 4
        b2 = Tensor[Real * 2]
        b2_(0) = 13
        b2_(1) = 22
        _  = assert int equals (linalg det a2) (0 - 7) "det([2,3;5,4]) == -7"
        x2 = linalg solve a2 b2
        _  = assert int equals x2_(0) 2 "2x2 solve x0 == 2"
        _  = assert int equals x2_(1) 3 "2x2 solve x1 == 3"
        r2 = linalg matvec a2 x2
        _  = assert int equals r2_(0) 13 "A*x(0) == 13"
        _  = assert int equals r2_(1) 22 "A*x(1) == 22"

        -- 2. 3x3 system requiring partial pivoting (0 in (0,0) entry!):
        -- [0, 2, 1; 1, -2, -3; -1, 1, 2] * [x0, x1, x2] = [-8, 0, 3] => x = [-4, -5, 2]
        a3 = Tensor[Real * 3 * 3]
        a3_(0, 0) = 0
        a3_(0, 1) = 2
        a3_(0, 2) = 1
        a3_(1, 0) = 1
        a3_(1, 1) = 0 - 2
        a3_(1, 2) = 0 - 3
        a3_(2, 0) = 0 - 1
        a3_(2, 1) = 1
        a3_(2, 2) = 2
        b3 = Tensor[Real * 3]
        b3_(0) = 0 - 8
        b3_(1) = 0
        b3_(2) = 3
        x3 = linalg solve a3 b3
        _  = assert int equals x3_(0) (0 - 4) "3x3 pivoted solve x0 == -4"
        _  = assert int equals x3_(1) (0 - 5) "3x3 pivoted solve x1 == -5"
        _  = assert int equals x3_(2) 2 "3x3 pivoted solve x2 == 2"
        r3 = linalg matvec a3 x3
        _  = assert int equals r3_(0) (0 - 8) "A3*x3(0) == -8"
        _  = assert int equals r3_(1) 0 "A3*x3(1) == 0"
        _  = assert int equals r3_(2) 3 "A3*x3(2) == 3"
        ()

-- @tests TS-LINALG-001
fn :: test neural activations => ()
      test neural activations =
        -- 1. ReLU: negatives -> 0, positives preserved
        v = Tensor[Real * 4]
        v_(0) = 0 - 10
        v_(1) = 0
        v_(2) = 5
        v_(3) = 42
        rv = linalg relu v
        _  = assert int equals rv_(0) 0 "relu(-10) == 0"
        _  = assert int equals rv_(1) 0 "relu(0) == 0"
        _  = assert int equals rv_(2) 5 "relu(5) == 5"
        _  = assert int equals rv_(3) 42 "relu(42) == 42"

        -- 2. Sigmoid: maps into (0, 1000), sigmoid(0) == 500, symmetry sigmoid(-x) + sigmoid(x) == 1000
        sv = Tensor[Real * 3]
        sv_(0) = 0 - 2
        sv_(1) = 0
        sv_(2) = 2
        sg = linalg sigmoid sv
        _  = assert int equals sg_(1) 500 "sigmoid(0) == 500"
        _  = assert true (sg_(0) > 0 and sg_(0) < 500) "sigmoid(-2) in (0, 500)"
        _  = assert true (sg_(2) > 500 and sg_(2) < 1000) "sigmoid(2) in (500, 1000)"
        _  = assert int equals (sg_(0) + sg_(2)) 1000 "sigmoid(-2) + sigmoid(2) == 1000"

        -- 3. Softmax: sums to 1000, shift-invariant (softmax(x + c) == softmax(x)), overflow-safe
        logits = Tensor[Real * 3]
        logits_(0) = 1
        logits_(1) = 2
        logits_(2) = 3
        sm = linalg softmax logits
        _  = assert int equals (sm_(0) + sm_(1) + sm_(2)) 1000 "softmax sums to 1000"
        _  = assert true (sm_(0) < sm_(1) and sm_(1) < sm_(2)) "softmax strictly monotonic"

        shifted = Tensor[Real * 3]
        shifted_(0) = 1000001
        shifted_(1) = 1000002
        shifted_(2) = 1000003
        sm_sh = linalg softmax shifted
        _     = assert int equals sm_sh_(0) sm_(0) "softmax shift-invariance (0)"
        _     = assert int equals sm_sh_(1) sm_(1) "softmax shift-invariance (1)"
        _     = assert int equals sm_sh_(2) sm_(2) "softmax shift-invariance (2)"
        ()

fn :: main => ()
      main =
        _ = test transpose trace diag identity
        _ = test dot outer matvec norms
        _ = test det and linear solver
        _ = test neural activations
        echo "[PASS] test linalg: TS-LINALG-001 passed"
