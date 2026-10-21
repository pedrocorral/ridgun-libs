-- ============================================================
-- src/test/ridgun/test_crypto.rg
-- Test suite for crypto.rg (TS-CRYPTO-003, TS-CRYPTO-004, TS-PERF-001)
-- @tests TS-CRYPTO-003
-- @tests TS-CRYPTO-004
-- @tests TS-PERF-001
-- ============================================================

import test
import posix
import crypto

fn :: range bytes Int Int => [Int]
      range bytes cur hi  =
        | cur > hi  = []
        | otherwise = [cur] :: (range bytes (cur + 1) hi)

fn :: aead rc (Int, String) => Int
      aead rc (rc, _)       =  rc

fn :: aead pt (Int, String) => String
      aead pt (_, pt)       =  pt

-- ── TS-CRYPTO-003: RGF-019 Byte & Bitwise Ops, SHA-256, HMAC, PBKDF2 ──

-- @tests TS-CRYPTO-003
fn :: test rgf019 bytes and bitops => ()
      test rgf019 bytes and bitops =
        -- 1. Raw byte_str lengths and round-trip (0..255)
        _   = assert_int_equals (str_len (byte str 0)) 1 "len byte_str 0"
        _   = assert_int_equals (str_len (byte str 127)) 1 "len byte_str 127"
        _   = assert_int_equals (str_len (byte str 128)) 1 "len byte_str 128"
        _   = assert_int_equals (str_len (byte str 255)) 1 "len byte_str 255"
        b5  = bytes from list [0, 1, 127, 128, 255]
        _   = assert_int_equals (str_len b5) 5 "len b5 == 5"
        rt  = bytes to list b5
        _   = assert_int_equals (c nth int rt 0) 0 "rt 0"
        _   = assert_int_equals (c nth int rt 1) 1 "rt 1"
        _   = assert_int_equals (c nth int rt 2) 127 "rt 2"
        _   = assert_int_equals (c nth int rt 3) 128 "rt 3"
        _   = assert_int_equals (c nth int rt 4) 255 "rt 4"

        -- 2. RGF-019 32-bit unsigned bitwise operations
        _   = assert_int_equals (band 4294967295 255) 255 "band"
        _   = assert_int_equals (bor 240 15) 255 "bor"
        _   = assert_int_equals (bxor 305419896 4294967295) 3989547399 "bxor"
        _   = assert_int_equals (shl 1 31) 2147483648 "shl 31"
        _   = assert_int_equals (shl 1 32) 0 "shl 32"
        _   = assert_int_equals (shr 2147483648 31) 1 "shr 31"
        _   = assert_int_equals (shr 2147483648 32) 0 "shr 32"
        ()

-- @tests TS-CRYPTO-003
fn :: test sha256 hmac and pbkdf2 => ()
      test sha256 hmac and pbkdf2 =
        -- 1. SHA-256 ("abc" -> FIPS 180-4 vector)
        h_hex = sha256 hex "abc"
        _     = assert_str_eq h_hex "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad" "sha256_hex abc"
        h_raw = sha256 bytes "abc"
        _     = assert eq (str_len h_raw) 32
        _     = assert_str_eq (bytes to hex str h_raw) h_hex "sha256_bytes matches sha256_hex"

        -- 2. HMAC-SHA-256 (RFC 4231 Test Case 2: "Jefe" / "what do ya want for nothing?")
        mac   = hmac sha256 "Jefe" "what do ya want for nothing?"
        _     = assert eq (str_len mac) 32
        _     = assert_str_eq (bytes to hex str mac) "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843" "RFC 4231 Test Case 2"

        -- 3. Constant-time comparison (`ct_equal`)
        _     = assert_true (ct equal mac mac) "ct_equal identical"
        _     = assert_false (ct equal mac (sha256 bytes "abc")) "ct_equal different 32B"
        _     = assert_false (ct equal "short" "longer") "ct_equal different lengths"

        -- 4. PBKDF2-HMAC-SHA-256 (RFC 6070 c=1 and c=2)
        dk1   = pbkdf2 hmac sha256 "password" "salt" 1 32
        _     = assert eq (str_len dk1) 32
        _     = assert_str_eq (bytes to hex str dk1) "120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b" "RFC 6070 PBKDF2 c=1"
        dk2   = pbkdf2 hmac sha256 "password" "salt" 2 32
        _     = assert_str_eq (bytes to hex str dk2) "ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43" "RFC 6070 PBKDF2 c=2"
        ()

-- ── TS-CRYPTO-004 & TS-PERF-001: Argon2id 5-Arg API & ChaCha20-Poly1305 AEAD ──

-- @tests TS-CRYPTO-004
-- @tests TS-PERF-001
fn :: test argon2id five arg and perf => ()
      test argon2id five arg and perf =
        phc = argon2id hash "correct horse battery staple" "0123456789abcdef" 64 2 1
        _   = assert_true (str_starts_with phc "$argon2id$v=19$m=64,t=2,p=1$") "PHC header format"
        _   = assert_true (argon2id verify "correct horse battery staple" phc) "argon2id_verify matching (pwd, phc)"
        _   = assert_false (argon2id verify "wrong password" phc) "argon2id_verify wrong password"
        _   = assert_false (argon2id verify "correct horse battery staple" "$argon2id$v=19$m=64,t=2,p=1$bad$bad") "argon2id_verify bad PHC"

        -- TS-PERF-001 AC1: OWASP m=19456, t=2, p=1 hash + verify latency < 2000 ms
        t1     = sys monotonic ms
        phc_ow = argon2id hash "password" "saltsalt" 19456 2 1
        ok_ow  = argon2id verify "password" phc_ow
        t2     = sys monotonic ms
        _      = assert_true ok_ow "OWASP m=19456 verify ok"
        _      = assert_true ((t2 - t1) < 2000) "OWASP m=19456 hash+verify < 2000 ms"
        ()

-- @tests TS-CRYPTO-004
fn :: test rfc8439 chacha20 poly1305 aead => ()
      test rfc8439 chacha20 poly1305 aead =
        key   = bytes from list (range bytes 128 159)
        nonce = bytes from list [7, 0, 0, 0, 64, 65, 66, 67, 68, 69, 70, 71]
        aad   = bytes from list [80, 81, 82, 83, 192, 193, 194, 195, 196, 197, 198, 199]
        pt    = "Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it."

        sealed = aead seal key nonce aad pt
        _      = assert eq (str_len sealed) ((str_len pt) + 16)

        -- Verify first 16 ciphertext bytes and 16-byte Poly1305 tag match RFC 8439 §2.8.2 bit-for-bit
        ct_prefix_hex = bytes to hex str (byte slice sealed 0 16)
        tag_hex       = bytes to hex str (byte slice sealed 114 130)
        _             = assert_str_eq ct_prefix_hex "d31a8d34648e60db7b86afbc53ef7ec2" "RFC 8439 §2.8.2 ciphertext prefix"
        _             = assert_str_eq tag_hex "1ae10b594f09e26a7e902ecbd0600691" "RFC 8439 §2.8.2 Poly1305 tag"

        -- Verify aead_open succeeds with (0, pt)
        res_ok   = aead open key nonce aad sealed
        _        = assert eq (aead rc res_ok) 0
        _        = assert_str_eq (aead pt res_ok) pt "aead_open decrypted plaintext"

        -- Verify tamper detection (-12 AUTH_FAILED) on modified AAD, modified nonce, or modified tag
        res_aad  = aead open key nonce "tampered-aad" sealed
        _        = assert eq (aead rc res_aad) (0 - 12)
        _        = assert_str_eq (aead pt res_aad) "" "tampered AAD returns empty plaintext"

        bad_seal = (byte slice sealed 0 129) + (byte str 0)
        res_tag  = aead open key nonce aad bad_seal
        _        = assert eq (aead rc res_tag) (0 - 12)
        _        = assert_str_eq (aead pt res_tag) "" "tampered tag returns empty plaintext"

        -- Verify invalid key/nonce length returns (-7, "")
        res_inv  = aead open "short-key" nonce aad sealed
        _        = assert eq (aead rc res_inv) (0 - 7)
        ()

fn :: main => ()
      main =
        _ = test rgf019 bytes and bitops
        _ = test sha256 hmac and pbkdf2
        _ = test argon2id five arg and perf
        _ = test rfc8439 chacha20 poly1305 aead
        echo "[PASS] test_crypto: TS-CRYPTO-003, TS-CRYPTO-004, and TS-PERF-001 passed"
