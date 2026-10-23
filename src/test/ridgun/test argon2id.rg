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
fn :: test argon2id phc hashing and verification => ()
      test argon2id phc hashing and verification =
        -- LIB-1: OpenSSL 3.5 / libsodium reference vectors
        v1 = unwrap a2 phc (argon2id derive key hex "correct horse" "saltsaltsaltsalt" (argon2 params 8 1 1 32))
        v2 = unwrap a2 phc (argon2id derive key hex "correct horse" "saltsaltsaltsalt" (argon2 params 64 2 1 32))
        v3 = unwrap a2 phc (argon2id derive key hex "correct horse" "saltsaltsaltsalt" (argon2 params 256 2 1 32))
        _  = assert str eq v1 "b7940bccc95f48f2cc7b36f55ff851c356ca4d3a6bc8cd4986a0692f2aac78ec" "LIB-1 vector m=8,t=1,p=1"
        _  = assert str eq v2 "e6374c2335a815bcd23a5ea4df06a2f6e5377fc2c3f879865d0828d6e84740f2" "LIB-1 vector m=64,t=2,p=1"
        _  = assert str eq v3 "8f65ef99a71b1e98450f2c80d78604af3644276f965db52045bbed139b03b5fd" "LIB-1 vector m=256,t=2,p=1"

        -- LIB-1: RFC 9106 §5.3 official test vector (pwd=32*0x01, salt=16*0x02, secret=8*0x03, ad=12*0x04, m=32, t=3, p=4, tag=32)
        pwd32  = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        salt16 = [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]
        sec8   = a2 bytes to str [3, 3, 3, 3, 3, 3, 3, 3]
        ad12   = a2 bytes to str [4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4]
        rfc_h  = bytes to hex (derive raw tag ctx pwd32 salt16 sec8 ad12 (argon2 params 32 3 4 32))
        _      = assert str eq rfc_h "0d640df58d78766c08c037a34a8b53c9d01ef0452d75b65eb52520e96b01e659" "RFC 9106 §5.3 official vector"

        params   = argon2 params 32 2 2 16
        res1     = argon2id hash params "correct-horse-battery-staple" "somesalt1234" params
        res2     = argon2id hash params "correct-horse-battery-staple" "somesalt1234" params
        res_diff = argon2id hash params "correct-horse-battery-staple" "othersalt999" params
        _        = assert ok (is a2 ok res1)
        _        = assert ok (is a2 ok res2)
        _        = assert ok (is a2 ok res_diff)
        phc1     = unwrap a2 phc res1
        phc2     = unwrap a2 phc res2
        phc_diff = unwrap a2 phc res_diff
        _        = assert eq phc1 phc2
        _        = assert eq (phc1 == phc_diff) False
        _        = assert ok (str starts with phc1 "$argon2id$v=19$m=32,t=2,p=2$")
        bad_t    = argon2id hash params "password" "somesalt1234" (argon2 params 32 0 2 16)
        bad_p    = argon2id hash params "password" "somesalt1234" (argon2 params 32 2 0 16)
        bad_m    = argon2id hash params "password" "somesalt1234" (argon2 params 8 2 2 16)
        bad_tag  = argon2id hash params "password" "somesalt1234" (argon2 params 32 2 2 2)
        bad_salt = argon2id hash params "password" "short" params
        _        = assert eq (is a2 ok bad_t) False
        _        = assert eq (is a2 ok bad_p) False
        _        = assert eq (is a2 ok bad_m) False
        _        = assert eq (is a2 ok bad_tag) False
        _        = assert eq (is a2 ok bad_salt) False

        -- LIB-7: Fixed (password, phc) argument order; never swaps if password starts with "$argon2id$"
        _          = assert ok (argon2id verify "correct-horse-battery-staple" phc1)
        _          = assert eq (argon2id verify phc1 "correct-horse-battery-staple") False
        _          = assert eq (argon2id verify "wrong-password" phc1) False
        tricky_pwd = "$argon2id$v=19$m=32,t=2,p=2$not-a-hash-just-a-password"
        tricky_phc = argon2id hash tricky_pwd "0123456789abcdef" 32 2 1
        _          = assert ok (argon2id verify tricky_pwd tricky_phc)
        _          = assert eq (argon2id verify tricky_phc tricky_pwd) False
        _          = assert eq (argon2id verify "correct-horse-battery-staple" "$argon2i$v=19$m=32,t=2,p=2$c29tZXNhbHQxMjM0$AAAA") False
        _          = assert eq (argon2id verify "correct-horse-battery-staple" "$argon2id$v=18$m=32,t=2,p=2$c29tZXNhbHQxMjM0$AAAA") False
        _          = assert eq (argon2id verify "correct-horse-battery-staple" "malformed_phc_string") False
        _          = assert ok (constant time eq "abc123xyz" "abc123xyz")
        assert eq (constant time eq "abc123xyz" "abc123xyw") False

-- @tests TS-CRYPTO-002
fn :: test argon2id key derivation salting and rehash => ()
      test argon2id key derivation salting and rehash =
        -- LIB-3: Non-deterministic CSPRNG raw byte salt generation
        salt16    = argon2id generate salt 16
        salt16_b  = argon2id generate salt 16
        salt_min  = argon2id generate salt 2
        _         = assert eq (str len salt16) 16
        _         = assert eq (str len salt16_b) 16
        _         = assert eq (str len salt_min) 16
        _         = assert eq (salt16 == salt16_b) False

        -- LIB-4: Presets at or above OWASP (19456 KiB) and RFC 9106 §4 (65536 KiB)
        p_def     = default argon2 params
        p_inter   = argon2 interactive params
        p_mod     = argon2 moderate params
        p_sens    = argon2 sensitive params
        _         = assert eq (m_cost p_def) 19456
        _         = assert eq (t_cost p_def) 2
        _         = assert eq (lanes p_def) 1
        _         = assert eq (tag_len p_def) 32
        _         = assert eq (m_cost p_inter) 19456
        _         = assert eq (m_cost p_mod) 47104
        _         = assert eq (m_cost p_sens) 65536
        _         = assert eq (t_cost p_sens) 3
        _         = assert eq (lanes p_sens) 4

        p_fast    = argon2 params 64 2 2 32
        auto_res  = argon2id hash password "my-secret-passphrase" p_fast
        _         = assert ok (is a2 ok auto_res)
        auto_phc  = unwrap a2 phc auto_res
        _         = assert ok (argon2id verify "my-secret-passphrase" auto_phc)
        _         = assert eq (argon2id verify "other-passphrase" auto_phc) False
        parsed    = argon2id parse phc auto_phc
        _         = assert ok (is phc parsed ok parsed)
        _         = assert eq (is phc parsed ok (argon2id parse phc "invalid_phc")) False
        _         = assert eq (argon2id needs rehash auto_phc p_fast) False
        _         = assert ok (argon2id needs rehash auto_phc p_inter)
        _         = assert ok (argon2id needs rehash auto_phc (argon2 params 64 3 2 32))
        _         = assert ok (argon2id needs rehash auto_phc (argon2 params 64 2 4 32))
        _         = assert ok (argon2id needs rehash auto_phc (argon2 params 64 2 2 64))
        _         = assert ok (argon2id needs rehash "invalid_phc" p_fast)
        k_res     = argon2id derive key "encryption-passphrase" "1234567890abcdef" p_fast
        kh_res    = argon2id derive key hex "encryption-passphrase" "1234567890abcdef" p_fast
        k_bad     = argon2id derive key "encryption-passphrase" "short" p_fast
        kh_bad    = argon2id derive key hex "encryption-passphrase" "short" p_fast
        _         = assert ok (is key ok k_res)
        _         = assert ok (is a2 ok kh_res)
        _         = assert eq (is key ok k_bad) False
        _         = assert eq (is a2 ok kh_bad) False
        _         = assert eq (a2 list len (unwrap key bytes k_res)) 32
        _         = assert eq (str len (unwrap a2 phc kh_res)) 64
        ctx_res   = argon2id hash ctx "user-password" "1234567890abcdef" "app-pepper-key" "tenant:42" p_fast
        ctx_bad   = argon2id hash ctx "user-password" "short" "app-pepper-key" "tenant:42" p_fast
        _         = assert ok (is a2 ok ctx_res)
        _         = assert eq (is a2 ok ctx_bad) False
        ctx_phc   = unwrap a2 phc ctx_res
        _         = assert ok (argon2id verify ctx "user-password" ctx_phc "app-pepper-key" "tenant:42")
        _         = assert eq (argon2id verify ctx "user-password" ctx_phc "wrong-pepper" "tenant:42") False
        _         = assert eq (argon2id verify ctx "user-password" ctx_phc "app-pepper-key" "tenant:99") False

        -- RG-051: PHC string with empty tag segment must be rejected by parse & verify
        _         = assert eq (is phc parsed ok (argon2id parse phc "$argon2id$v=19$m=64,t=2,p=1$c2FsdHNhbHRzYWx0c2FsdA$")) False
        assert eq (argon2id verify "correct horse" "$argon2id$v=19$m=64,t=2,p=1$c2FsdHNhbHRzYWx0c2FsdA$") False

fn :: main => ()
      main =
        _ = test argon2id phc hashing and verification
        _ = test argon2id key derivation salting and rehash
        echo "=== All argon2id tests passed ==="
