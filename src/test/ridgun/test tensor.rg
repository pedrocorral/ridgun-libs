-- ============================================================
-- src/test/ridgun/test tensor.rg
-- Test suite for tensor.rg and crypto.rg BlaMka tensor operations (TS-TENSOR-001)
-- @tests TS-TENSOR-001
-- ============================================================

import test
import tensor
import crypto

fn :: shape fst (Int Int) => Int
      shape fst (r, _)    =  r

fn :: shape snd (Int Int) => Int
      shape snd (_, c)    =  c

fn :: g fst (U64 U64 U64 U64) => U64
      g fst (a, _, _, _)      =  a

-- @tests TS-TENSOR-001
fn :: test tensor dimensions and views => ()
      test tensor dimensions and views =
        m   = Tensor[Int * 2 * 3]
        m_(0, 0) = 10
        m_(0, 1) = 20
        m_(0, 2) = 30
        m_(1, 0) = 40
        m_(1, 1) = 50
        m_(1, 2) = 60
        _   = assert int equals (tensor rows m) 2 "tensor rows == 2"
        _   = assert int equals (tensor cols m) 3 "tensor cols == 3"
        sh  = tensor shape m
        _   = assert int equals (shape fst sh) 2 "tensor shape rows == 2"
        _   = assert int equals (shape snd sh) 3 "tensor shape cols == 3"
        r1  = tensor row m 1
        _   = assert int equals r1_(0) 40 "row 1 col 0 == 40"
        _   = assert int equals r1_(1) 50 "row 1 col 1 == 50"
        _   = assert int equals r1_(2) 60 "row 1 col 2 == 60"
        c2  = tensor col m 2
        _   = assert int equals c2_(0) 30 "col 2 row 0 == 30"
        _   = assert int equals c2_(1) 60 "col 2 row 1 == 60"
        ()

-- @tests TS-TENSOR-001
fn :: test tensor hadamard and clone => ()
      test tensor hadamard and clone =
        a    = Tensor[Int * 2 * 2]
        a_(0, 0) = 10
        a_(0, 1) = 20
        a_(1, 0) = 30
        a_(1, 1) = 40
        b    = Tensor[Int * 2 * 2]
        b_(0, 0) = 1
        b_(0, 1) = 2
        b_(1, 0) = 3
        b_(1, 1) = 4
        s    = tensor add blocks a b
        _    = assert int equals s_(0, 0) 11 "add (0,0) == 11"
        _    = assert int equals s_(1, 1) 44 "add (1,1) == 44"
        d    = tensor sub blocks a b
        _    = assert int equals d_(0, 0) 9 "sub (0,0) == 9"
        _    = assert int equals d_(1, 1) 36 "sub (1,1) == 36"
        p    = tensor mul blocks a b
        _    = assert int equals p_(0, 0) 10 "mul (0,0) == 10"
        _    = assert int equals p_(1, 1) 160 "mul (1,1) == 160"
        ua   = Tensor[U64 * 2 * 2]
        ua_(0, 0) = 0xFF
        ua_(0, 1) = 0x0F
        ua_(1, 0) = 0xF0
        ua_(1, 1) = 0xAA
        ub   = Tensor[U64 * 2 * 2]
        ub_(0, 0) = 0x0F
        ub_(0, 1) = 0xFF
        ub_(1, 0) = 0x0F
        ub_(1, 1) = 0x55
        ux   = tensor_xor_blocks ua ub
        _    = assert int equals ux_(0, 0) 0xF0 "xor (0,0) == 0xF0"
        _    = assert int equals ux_(1, 1) 0xFF "xor (1,1) == 0xFF"
        uan  = tensor_and_blocks ua ub
        _    = assert int equals uan_(0, 0) 0x0F "and (0,0) == 0x0F"
        _    = assert int equals uan_(1, 1) 0x00 "and (1,1) == 0x00"
        uor  = tensor_or_blocks ua ub
        _    = assert int equals uor_(0, 0) 0xFF "or (0,0) == 0xFF"
        _    = assert int equals uor_(1, 0) 0xFF "or (1,0) == 0xFF"
        uc   = tensor clone ua
        uc_(0, 0) = 999
        _    = assert int equals ua_(0, 0) 0xFF "clone preserves original ua_(0,0)"
        _    = assert int equals uc_(0, 0) 999 "clone updates uc_(0,0)"
        ()

-- @tests TS-TENSOR-001
fn :: test tensor matmul => ()
      test tensor matmul =
        ma  = Tensor[Real * 2 * 3]
        ma_(0, 0) = 1
        ma_(0, 1) = 2
        ma_(0, 2) = 3
        ma_(1, 0) = 4
        ma_(1, 1) = 5
        ma_(1, 2) = 6
        mb  = Tensor[Real * 3 * 2]
        mb_(0, 0) = 7
        mb_(0, 1) = 8
        mb_(1, 0) = 9
        mb_(1, 1) = 10
        mb_(2, 0) = 11
        mb_(2, 1) = 12
        mc  = tensor matmul ma mb
        _   = assert int equals mc_(0, 0) 58 "matmul (0,0) == 58"
        _   = assert int equals mc_(0, 1) 64 "matmul (0,1) == 64"
        _   = assert int equals mc_(1, 0) 139 "matmul (1,0) == 139"
        _   = assert int equals mc_(1, 1) 154 "matmul (1,1) == 154"
        ()

-- @tests TS-TENSOR-001
fn :: test blamka tensor compression => ()
      test blamka tensor compression =
        fb  = f blamka 1 2
        _   = assert int equals fb 7 "f blamka 1 2 == 7"
        gr  = blamka g 1 2 3 4
        _   = assert true ((g fst gr) != 0) "blamka g non-zero output"
        bx  = Tensor[U64 * 8 * 16]
        by  = Tensor[U64 * 8 * 16]
        bx_(0, 0) = 1
        by_(0, 0) = 2
        bz  = compress block bx by
        _   = assert true (bz_(0, 0) != 0) "compress block non-zero (0,0)"
        _   = assert int equals bx_(0, 0) 1 "compress block preserves bx_(0,0)"
        _   = assert int equals by_(0, 0) 2 "compress block preserves by_(0,0)"
        ()

fn :: main => ()
      main =
        _ = test tensor dimensions and views
        _ = test tensor hadamard and clone
        _ = test tensor matmul
        _ = test blamka tensor compression
        echo "[PASS] test tensor: TS-TENSOR-001 passed"
