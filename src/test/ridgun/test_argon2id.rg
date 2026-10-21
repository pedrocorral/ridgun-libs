-- src/test/ridgun/test_argon2id.rg
-- Automated test suite for the Argon2id PHC password hashing, key derivation, and verification library
-- @tests TS-CRYPTO-001
-- @tests TS-CRYPTO-002

import test
import argon2id

fn :: is a2 ok Argon2Res     => Bool
      is a2 ok (Argon2Ok  _) =  True
      is a2 ok (Argon2Err _) =  False

fn :: unwrap a2 phc Argon2Res      => String
      unwrap a2 phc (Argon2Ok phc) =  phc
      unwrap a2 phc (Argon2Err _)  =  ""

fn :: is key ok Argon2KeyRes     => Bool
      is key ok (Argon2KeyOk  _) =  True
      is key ok (Argon2KeyErr _) =  False

fn :: unwrap key bytes Argon2KeyRes     => [Int]
      unwrap key bytes (Argon2KeyOk  bytes) = bytes
      unwrap key bytes (Argon2KeyErr _) =  []

fn :: is phc parsed ok Argon2PhcRes     => Bool
      is phc parsed ok (Argon2PhcOk  _) =  True
      is phc parsed ok (Argon2PhcErr _) =  False

-- @tests TS-CRYPTO-001
fn :: test_argon2id_phc_hashing_and_verification => ()
      test_argon2id_phc_hashing_and_verification =
        params   = argon2 params 32 2 2 16
        res1     = argon2id hash "correct-horse-battery-staple" "somesalt1234" params
        res2     = argon2id hash "correct-horse-battery-staple" "somesalt1234" params
        res_diff = argon2id hash "correct-horse-battery-staple" "othersalt999" params
        _        = assert ok (is a2 ok res1)
        _        = assert ok (is a2 ok res2)
        _        = assert ok (is a2 ok res_diff)
        phc1     = unwrap a2 phc res1
        phc2     = unwrap a2 phc res2
        phc_diff = unwrap a2 phc res_diff
        _        = assert eq phc1 phc2
        _        = assert eq (phc1 == phc_diff) False
        _        = assert ok (str_starts_with phc1 "$argon2id$v=19$m=32,t=2,p=2$")
        bad_t    = argon2id hash "password" "somesalt1234" (argon2 params 32 0 2 16)
        bad_p    = argon2id hash "password" "somesalt1234" (argon2 params 32 2 0 16)
        bad_m    = argon2id hash "password" "somesalt1234" (argon2 params 8 2 2 16)
        bad_tag  = argon2id hash "password" "somesalt1234" (argon2 params 32 2 2 2)
        bad_salt = argon2id hash "password" "short" params
        _        = assert eq (is a2 ok bad_t) False
        _        = assert eq (is a2 ok bad_p) False
        _        = assert eq (is a2 ok bad_m) False
        _        = assert eq (is a2 ok bad_tag) False
        _        = assert eq (is a2 ok bad_salt) False
        _        = assert ok (argon2id verify phc1 "correct-horse-battery-staple")
        _        = assert eq (argon2id verify phc1 "wrong-password") False
        _        = assert eq (argon2id verify "$argon2i$v=19$m=32,t=2,p=2$c29tZXNhbHQxMjM0$AAAA" "correct-horse-battery-staple") False
        _        = assert eq (argon2id verify "$argon2id$v=18$m=32,t=2,p=2$c29tZXNhbHQxMjM0$AAAA" "correct-horse-battery-staple") False
        _        = assert eq (argon2id verify "malformed_phc_string" "correct-horse-battery-staple") False
        _        = assert ok (constant time eq "abc123xyz" "abc123xyz")
        assert eq (constant time eq "abc123xyz" "abc123xyw") False

-- @tests TS-CRYPTO-002
fn :: test_argon2id_key_derivation_salting_and_rehash => ()
      test_argon2id_key_derivation_salting_and_rehash =
        salt16    = argon2id generate salt 16
        salt_min  = argon2id generate salt 2
        _         = assert eq (str_len salt16) 16
        _         = assert eq (str_len salt_min) 16
        p_inter   = argon2 interactive params
        p_mod     = argon2 moderate params
        p_sens    = argon2 sensitive params
        _         = assert eq (m_cost p_inter) 64
        _         = assert eq (m_cost p_mod) 128
        _         = assert eq (m_cost p_sens) 256
        auto_res  = argon2id hash password "my-secret-passphrase" p_inter
        _         = assert ok (is a2 ok auto_res)
        auto_phc  = unwrap a2 phc auto_res
        _         = assert ok (argon2id verify auto_phc "my-secret-passphrase")
        _         = assert eq (argon2id verify auto_phc "other-passphrase") False
        parsed    = argon2id parse phc auto_phc
        _         = assert ok (is phc parsed ok parsed)
        _         = assert eq (argon2id needs rehash auto_phc p_inter) False
        _         = assert ok (argon2id needs rehash auto_phc p_mod)
        _         = assert ok (argon2id needs rehash "invalid_phc" p_inter)
        k_res     = argon2id derive key "encryption-passphrase" "1234567890abcdef" p_inter
        kh_res    = argon2id derive key hex "encryption-passphrase" "1234567890abcdef" p_inter
        _         = assert ok (is key ok k_res)
        _         = assert ok (is a2 ok kh_res)
        _         = assert eq (a2 list len (unwrap key bytes k_res)) 32
        _         = assert eq (str_len (unwrap a2 phc kh_res)) 64
        ctx_res   = argon2id hash ctx "user-password" "1234567890abcdef" "app-pepper-key" "tenant:42" p_inter
        _         = assert ok (is a2 ok ctx_res)
        ctx_phc   = unwrap a2 phc ctx_res
        _         = assert ok (argon2id verify ctx ctx_phc "user-password" "app-pepper-key" "tenant:42")
        _         = assert eq (argon2id verify ctx ctx_phc "user-password" "wrong-pepper" "tenant:42") False
        assert eq (argon2id verify ctx ctx_phc "user-password" "app-pepper-key" "tenant:99") False

fn :: main => ()
      main =
        _ = test_argon2id_phc_hashing_and_verification
        _ = test_argon2id_key_derivation_salting_and_rehash
        echo "=== All argon2id tests passed ==="
