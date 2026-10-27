-- ============================================================
-- src/main/ridgun/lib/test.rg
-- Pure-Ridgun Unit & Functional Test Assertion Library (TST)
-- @implements FR-TST-001
-- @implements API-TST-001
-- @implements NFR-OBS-001
-- ============================================================

module :: test

fn :: fail test String => ()
      fail test msg    =
        _ = echo "[FAIL] {msg}"
        sys exit 1

-- ── Non-Exiting Predicate Helpers ────────────────────────────

fn :: check eq A      A        => Bool
      check eq actual expected =  actual == expected

fn :: check str eq String String   => Bool
      check str eq actual expected =  actual == expected

fn :: check true Bool => Bool
      check true cond =  cond

-- ── RG-011 Message-Annotated Assertions ──────────────────────

fn :: assert true Bool String => ()
      assert true cond label  =
        | cond      = ()
        | otherwise = fail test "assert_true failed: {label}"

fn :: assert false Bool String => ()
      assert false cond label  =
        | not cond  = ()
        | otherwise = fail test "assert_false failed: {label}"

fn :: assert equals A      A        String => ()
      assert equals actual expected label  =
        | actual == expected = ()
        | otherwise          = fail test "assert_equals failed: {label}"

fn :: assert str eq String String String => ()
      assert str eq actual expected label =
        | actual == expected = ()
        | otherwise          = fail test "assert_str_eq failed ({label}): got '{actual}', expected '{expected}'"

fn :: assert int equals Int Int String => ()
      assert int equals actual expected label =
        | actual == expected = ()
        | otherwise          = fail test "assert_int_equals failed ({label}): got {actual}, expected {expected}"

-- ── Concise Label-Free Assertion Helpers ─────────────────────

fn :: assert ok Bool => ()
      assert ok cond =  assert true cond "assert_ok"

fn :: assert not Bool => ()
      assert not cond =  assert false cond "assert_not"

fn :: assert eq A      A        => ()
      assert eq actual expected =  assert equals actual expected "assert_eq"
