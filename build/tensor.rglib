-- ============================================================
-- src/main/ridgun/lib/tensor.rg
-- Pure-Ridgun Typed Tensor Operations, Subscript Views, Hadamard & Linear Algebra Library (TENSOR)
-- @implements FR-TENSOR-001
-- @implements API-TENSOR-001
-- @implements DM-Tensor
-- @mitigates VUL-INPUT-001
-- ============================================================

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
fn :: tensor xor blocks Tensor[U64 * r * c] Tensor[U64 * r * c] => Tensor[U64 * r * c]
      tensor xor blocks a b = a_ij xor b_ij

-- @implements FR-TENSOR-001
-- @implements API-TENSOR-001
-- @implements DM-Tensor
fn :: tensor and blocks Tensor[U64 * r * c] Tensor[U64 * r * c] => Tensor[U64 * r * c]
      tensor and blocks a b = a_ij and b_ij

-- @implements FR-TENSOR-001
-- @implements API-TENSOR-001
-- @implements DM-Tensor
fn :: tensor or blocks Tensor[U64 * r * c] Tensor[U64 * r * c] => Tensor[U64 * r * c]
      tensor or blocks a b = a_ij or b_ij

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

-- @implements FR-TENSOR-001
-- @implements API-TENSOR-001
-- @implements DM-Tensor
fn :: tensor matmul Tensor[Real * r * k] Tensor[Real * k * c] => Tensor[Real * r * c]
      tensor matmul a b = a_ik @ b_kj
