-- ============================================================
-- src/main/ridgun/lib/tensor.rg
-- Pure-Ridgun Typed Tensor Operations, Subscript Views, Hadamard & Linear Algebra Library (TENSOR)
-- @implements FR-TENSOR-001
-- @implements API-TENSOR-001
-- @implements DM-Tensor
-- @mitigates VUL-INPUT-001
-- ============================================================

module :: tensor

-- @implements FR-TENSOR-001
-- @implements API-TENSOR-001
-- @implements DM-Tensor
fn :: tensor rows Tensor[Int * r * c] => Int
      tensor rows (Tensor[Int * r * c] m) = r

-- @implements FR-TENSOR-001
-- @implements API-TENSOR-001
-- @implements DM-Tensor
fn :: tensor cols Tensor[Int * r * c] => Int
      tensor cols (Tensor[Int * r * c] m) = c

-- @implements FR-TENSOR-001
-- @implements API-TENSOR-001
-- @implements DM-Tensor
fn :: tensor shape Tensor[Int * r * c] => Int Int
      tensor shape (Tensor[Int * r * c] m) = (r, c)

-- @implements FR-TENSOR-001
-- @implements API-TENSOR-001
-- @implements DM-Tensor
-- @mitigates VUL-INPUT-001
fn :: tensor row Tensor[Int * r * c] Int => Tensor[Int * c]
      tensor row m                   idx =  m_(idx,)

-- @implements FR-TENSOR-001
-- @implements API-TENSOR-001
-- @implements DM-Tensor
-- @mitigates VUL-INPUT-001
fn :: tensor col Tensor[Int * r * c] Int => Tensor[Int * r]
      tensor col m                   idx =  m_(,idx)

-- @implements FR-TENSOR-001
-- @implements API-TENSOR-001
-- @implements DM-Tensor
fn :: tensor bitxor blocks Tensor[U64 * r * c] Tensor[U64 * r * c] => Tensor[U64 * r * c]
      tensor bitxor blocks a b = a_ij xor b_ij

-- @implements FR-TENSOR-001
-- @implements API-TENSOR-001
-- @implements DM-Tensor
fn :: tensor bitand blocks Tensor[U64 * r * c] Tensor[U64 * r * c] => Tensor[U64 * r * c]
      tensor bitand blocks a b = a_ij and b_ij

-- @implements FR-TENSOR-001
-- @implements API-TENSOR-001
-- @implements DM-Tensor
fn :: tensor bitor blocks Tensor[U64 * r * c] Tensor[U64 * r * c] => Tensor[U64 * r * c]
      tensor bitor blocks a b = a_ij or b_ij

-- @implements FR-TENSOR-001
-- @implements API-TENSOR-001
-- @implements DM-Tensor
fn :: tensor add blocks Tensor[Int * r * c] Tensor[Int * r * c] => Tensor[Int * r * c]
      tensor add blocks a b = a_ij + b_ij

-- @implements FR-TENSOR-001
-- @implements API-TENSOR-001
-- @implements DM-Tensor
fn :: tensor sub blocks Tensor[Int * r * c] Tensor[Int * r * c] => Tensor[Int * r * c]
      tensor sub blocks a b = a_ij - b_ij

-- @implements FR-TENSOR-001
-- @implements API-TENSOR-001
-- @implements DM-Tensor
fn :: tensor mul blocks Tensor[Int * r * c] Tensor[Int * r * c] => Tensor[Int * r * c]
      tensor mul blocks a b = a_ij * b_ij

-- @implements FR-TENSOR-001
-- @implements API-TENSOR-001
-- @implements DM-Tensor
fn :: tensor clone Tensor[U64 * r * c] => Tensor[U64 * r * c]
      tensor clone m                   =
        z_ij = m_ij
        z_ij

-- Explicit loops: with ridgunc 0.9.41, `a_ik @ b_kj` on Real tensors returns zeros.
fn :: tensor matmul cell Tensor[Real * r * k] Tensor[Real * k * c] Int Int Int Int Real => Real
      tensor matmul cell a b i j p kk acc =
        | p >= kk   = acc
        | otherwise = tensor matmul cell a b i j (p + 1) kk (acc + (a_(i, p) * b_(p, j)))

fn :: tensor matmul cols Tensor[Real * r * k] Tensor[Real * k * c] Tensor[Real * r * c] Int Int Int Int => Tensor[Real * r * c]
      tensor matmul cols a b out i j cc kk =
        | j >= cc   = out
        | otherwise =
          out_(i, j) = tensor matmul cell a b i j 0 kk 0.0
          tensor matmul cols a b out i (j + 1) cc kk

fn :: tensor matmul rows Tensor[Real * r * k] Tensor[Real * k * c] Tensor[Real * r * c] Int Int Int Int => Tensor[Real * r * c]
      tensor matmul rows a b out i rr cc kk =
        | i >= rr   = out
        | otherwise =
          out2 = tensor matmul cols a b out i 0 cc kk
          tensor matmul rows a b out2 (i + 1) rr cc kk

-- @implements FR-TENSOR-001
-- @implements API-TENSOR-001
-- @implements DM-Tensor
fn :: tensor matmul Tensor[Real * r * k] Tensor[Real * k * c] => Tensor[Real * r * c]
      tensor matmul (Tensor[Real * r * k] a) (Tensor[Real * k * c] b) =
        out = Tensor[Real * r * c]
        tensor matmul rows a b out 0 r c k
