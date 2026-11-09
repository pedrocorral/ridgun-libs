-- ============================================================
-- src/test/ridgun/test_crypto.rg
-- Test suite for crypto.rg (TS-CRYPTO-003, TS-CRYPTO-004, TS-PERF-001)
-- @tests TS-CRYPTO-003
-- @tests TS-CRYPTO-004
-- @tests TS-CRYPTO-005
-- @tests TS-CRYPTO-006
-- @tests TS-PERF-001
-- ============================================================

import test
import posix
import crypto

fn :: range bytes Int Int => [Int]
      range bytes cur hi  =
        | cur > hi  = []
        | otherwise = [cur] :: (range bytes (cur + 1) hi)

fn :: nth of [Int]    Int => Int
      nth of []       _   =  0 - 1
      nth of (x:rest) idx =
        | idx <= 0  = x
        | otherwise = nth of rest (idx - 1)

fn :: int count [Int]    => Int
      int count []       =  0
      int count (_:rest) =  1 + (int count rest)

fn :: same ints [Int]  [Int]  => Bool
      same ints []     []     =  True
      same ints (a:ar) (b:br) =  (a == b) and (same ints ar br)
      same ints _      _      =  False

fn :: all byte str len one Int => Bool
      all byte str len one n   =
        | n > 255                     = True
        | (str len (byte str n)) != 1 = False
        | otherwise                   = all byte str len one (n + 1)

fn :: aead rc (Int String) => Int
      aead rc (rc, _)      =  rc

fn :: aead pt (Int String) => String
      aead pt (_, pt)      =  pt

-- ── TS-CRYPTO-003: RGF-019 Byte & Bitwise Ops, SHA-256, HMAC, PBKDF2 ──

-- @tests TS-CRYPTO-003
fn :: test rgf019 bytes and bitops => ()
      test rgf019 bytes and bitops =
        -- 1. Raw byte_str lengths, wraparound normalization, and full 0..255 round-trip
        _    = assert int equals (str len (byte str 0)) 1 "len byte_str 0"
        _    = assert int equals (str len (byte str 127)) 1 "len byte_str 127"
        _    = assert int equals (str len (byte str 128)) 1 "len byte_str 128"
        _    = assert int equals (str len (byte str 255)) 1 "len byte_str 255"
        _    = assert str eq (byte str (0 - 1)) (byte str 255) "byte_str -1 wraps to 255"
        _    = assert str eq (byte str 256) (byte str 0) "byte_str 256 wraps to 0"
        b5   = bytes from list [0, 1, 127, 128, 255]
        _    = assert int equals (str len b5) 5 "len b5 == 5"
        rt   = bytes to list b5
        _    = assert int equals (nth of rt 0) 0 "rt 0"
        _    = assert int equals (nth of rt 1) 1 "rt 1"
        _    = assert int equals (nth of rt 2) 127 "rt 2"
        _    = assert int equals (nth of rt 3) 128 "rt 3"
        _    = assert int equals (nth of rt 4) 255 "rt 4"
        b256 = bytes from list (range bytes 0 255)
        _    = assert int equals (str len b256) 256 "len b256 == 256"
        r256 = bytes to list b256
        _    = assert int equals (int count r256) 256 "r256 list len == 256"
        _    = assert int equals (nth of r256 0) 0 "r256[0] == 0"
        _    = assert int equals (nth of r256 128) 128 "r256[128] == 128"
        _    = assert int equals (nth of r256 255) 255 "r256[255] == 255"
        _    = assert true (same ints r256 (range bytes 0 255)) "bytes to list (bytes from list 0..255) == 0..255"

        -- ADR-0010: bytes are built on Tensor[U8]; values outside 0..255 are taken modulo 256
        hi7  = [0, 7, 128, 200, 255, 192, 245]
        b7   = bytes from list hi7
        _    = assert int equals (str len b7) 7 "len bytes from list hi7 == 7"
        _    = assert true (same ints (bytes to list b7) hi7) "bytes from list [0, 7, 128, 200, 255, 192, 245] round-trips"
        _    = assert true (all byte str len one 0) "str len (byte str n) == 1 for all n in 0..255"
        _    = assert str eq (bytes from list [256, 0 - 1, 300, 0 - 256]) (bytes from list [0, 255, 44, 0]) "bytes from list wraps modulo 256"
        _    = assert str eq (bytes from list []) "" "bytes from list [] is empty"
        _    = assert str eq (bytes to hex str (bytes from list hi7)) "000780c8ffc0f5" "bytes to hex str"
        _    = assert str eq (bytes list to hex (hex str to bytes "000780c8ffc0f5")) "000780c8ffc0f5" "hex str to bytes Tensor[U8] round-trip"
        _    = assert str eq (bytes to hex str (bitxor byte strings (hex to byte str "ff00f0") (hex to byte str "0f0fff"))) "f00f0f" "bitxor byte strings"
        _    = assert str eq (bytes to hex str (byte slice b7 2 5)) "80c8ff" "byte slice keeps high bytes"

        -- 2. RGF-019 32-bit unsigned bitwise operations and boundary shifts
        _    = assert int equals (band 4294967295 255) 255 "band"
        _    = assert int equals (band 305419896 0) 0 "band with 0"
        _    = assert int equals (bor 240 15) 255 "bor"
        _    = assert int equals (bor 305419896 0) 305419896 "bor with 0"
        _    = assert int equals (bxor 305419896 4294967295) 3989547399 "bxor"
        _    = assert int equals (bxor 305419896 305419896) 0 "bxor self == 0"
        _    = assert int equals (shl 1 0) 1 "shl 0"
        _    = assert int equals (shl 1 (0 - 1)) 0 "shl negative shift"
        _    = assert int equals (shl 1 31) 2147483648 "shl 31"
        _    = assert int equals (shl 1 32) 0 "shl 32"
        _    = assert int equals (shr 2147483648 0) 2147483648 "shr 0"
        _    = assert int equals (shr 2147483648 (0 - 1)) 0 "shr negative shift"
        _    = assert int equals (shr 2147483648 31) 1 "shr 31"
        _    = assert int equals (shr 2147483648 32) 0 "shr 32"
        ()

-- @tests TS-CRYPTO-003
fn :: test sha256 hmac and pbkdf2 => ()
      test sha256 hmac and pbkdf2 =
        -- 1. SHA-256 (empty string "" and "abc" -> FIPS 180-4 vectors)
        h_emp = sha256 hex ""
        _     = assert str eq h_emp "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" "sha256_hex empty"
        h_hex = sha256 hex "abc"
        _     = assert str eq h_hex "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad" "sha256_hex abc"
        h_raw = sha256 bytes "abc"
        _     = assert eq (str len h_raw) 32
        _     = assert str eq (bytes to hex str h_raw) h_hex "sha256_bytes matches sha256_hex"

        -- 2. HMAC-SHA-256 (RFC 4231 Test Case 2 and >64-byte key reduction)
        mac   = hmac sha256 "Jefe" "what do ya want for nothing?"
        _     = assert eq (str len mac) 32
        _     = assert str eq (bytes to hex str mac) "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843" "RFC 4231 Test Case 2"
        long_k = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef_extra_key_bytes"
        mac_lk = hmac sha256 long_k "message"
        _      = assert eq (str len mac_lk) 32
        _      = assert true (ct equal mac_lk (hmac sha256 (sha256 bytes long_k) "message")) "HMAC >64B key hashed to 32B"

        -- 3. Constant-time comparison (`ct_equal`)
        _     = assert true (ct equal "" "") "ct_equal empty strings"
        _     = assert true (ct equal mac mac) "ct_equal identical"
        _     = assert false (ct equal mac (sha256 bytes "abc")) "ct_equal different 32B"
        _     = assert false (ct equal "short" "longer") "ct_equal different lengths"

        -- 4. PBKDF2-HMAC-SHA-256 (RFC 6070 c=1, c=2, multi-block dk_len=64, sub-block dk_len=16, invalid args)
        dk1   = pbkdf2 hmac sha256 "password" "salt" 1 32
        _     = assert eq (str len dk1) 32
        _     = assert str eq (bytes to hex str dk1) "120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b" "RFC 6070 PBKDF2 c=1"
        dk2   = pbkdf2 hmac sha256 "password" "salt" 2 32
        _     = assert str eq (bytes to hex str dk2) "ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43" "RFC 6070 PBKDF2 c=2"
        dk16  = pbkdf2 hmac sha256 "password" "salt" 1 16
        _     = assert eq (str len dk16) 16
        _     = assert str eq (bytes to hex str dk16) "120fb6cffcf8b32c43e7225256c4f837" "PBKDF2 16-byte prefix"
        dk64  = pbkdf2 hmac sha256 "password" "salt" 1 64
        _     = assert eq (str len dk64) 64
        _     = assert str eq (byte slice dk64 0 32) dk1 "PBKDF2 64-byte block 1 matches dk1"
        _     = assert str eq (pbkdf2 hmac sha256 "password" "salt" 0 32) "" "PBKDF2 iterations=0 rejected"
        _     = assert str eq (pbkdf2 hmac sha256 "password" "salt" 1 0) "" "PBKDF2 dk_len=0 rejected"
        ()

-- ── TS-CRYPTO-004 & TS-PERF-001: Argon2id 5-Arg API & ChaCha20-Poly1305 AEAD ──

-- @tests TS-CRYPTO-004
-- @tests TS-PERF-001
fn :: test argon2id five arg and perf => ()
      test argon2id five arg and perf =
        phc = argon2id hash "correct horse battery staple" "0123456789abcdef" 64 2 1
        _   = assert true (str starts with phc "$argon2id$v=19$m=64,t=2,p=1$") "PHC header format"
        _   = assert true (argon2id verify "correct horse battery staple" phc) "argon2id_verify matching (pwd, phc)"
        _   = assert false (argon2id verify "wrong password" phc) "argon2id_verify wrong password"
        _   = assert false (argon2id verify "correct horse battery staple" "$argon2id$v=19$m=64,t=2,p=1$bad$bad") "argon2id_verify bad PHC"

        -- Negative parameter guards for 5-arg argon2id_hash
        _   = assert str eq (argon2id hash "password" "short" 64 2 1) "" "salt < 8 bytes rejected"
        _   = assert str eq (argon2id hash "password" "0123456789abcdef" 4 2 1) "" "m_cost < 8*p rejected"
        _   = assert str eq (argon2id hash "password" "0123456789abcdef" 64 0 1) "" "t_cost < 1 rejected"
        _   = assert str eq (argon2id hash "password" "0123456789abcdef" 64 2 0) "" "p_cost < 1 rejected"

        -- RG-050 / RG-051: Verify 100% in-process pure-Ridgun Argon2id and PBKDF2-HMAC-SHA256
        -- (OpenSSL 3.5 / RFC 9106 vectors + 4096-iteration PBKDF2 vector)
        phc_s       = argon2id hash "correct horse" "saltsaltsaltsalt" 64 2 1
        argon_exact = phc_s == "$argon2id$v=19$m=64,t=2,p=1$c2FsdHNhbHRzYWx0c2FsdA$5jdMIzWoFbzSOl6k3wai9uU3f8LD+HmGXQgo1uhHQPI"
        ok_s        = argon2id verify "correct horse" phc_s
        bad_s       = argon2id verify "wrong horse" phc_s
        bad_empty   = argon2id verify "correct horse" "$argon2id$v=19$m=64,t=2,p=1$c2FsdHNhbHRzYWx0c2FsdA$"
        phc_ok      = str starts with phc_s "$argon2id$v=19$m=64,t=2,p=1$"
        pb4k        = bytes to hex str (pbkdf2 hmac sha256 "correct horse battery staple" "0123456789abcdef" 4096 32)
        _           = assert true ok_s "Solstice RGF-015 argon_ok"
        _           = assert false bad_s "Solstice RGF-015 argon_bad"
        _           = assert false bad_empty "RG-051 reject PHC with empty tag"
        _           = assert true phc_ok "Solstice RGF-015 phc prefix"
        _           = assert true argon_exact "Solstice RGF-015 exact OpenSSL 3.5 / libsodium PHC"
        _           = assert str eq pb4k "b87f4b27148d3b05ad7985e3df997f0d9afa6e768e6384555bab71ba10f0c1a5" "Solstice RGF-015 PBKDF2 4096"

        -- RG-043: PBKDF2-HMAC-SHA256 600,000 iterations must match Python hashlib and run in < 3500 ms on one core (down from 32,600 ms)
        t_pbk0      = sys monotonic ms
        pb600k      = bytes to hex str (pbkdf2 hmac sha256 "correct horse battery staple" "0123456789abcdef" 600000 32)
        dt_pbk      = (sys monotonic ms) - t_pbk0
        _           = echo ("  [BENCH] PBKDF2 600,000 iterations: " + (int to str dt_pbk) + " ms")
        _           = assert str eq pb600k "6c4a646aad10d067add5fb79d9078a16da83d50f81670a8e7593b249e6d94936" "RG-043: PBKDF2 600,000 iterations matches Python hashlib"
        _           = assert true (dt_pbk < 3500) ("RG-043: PBKDF2 600,000 iterations must complete in < 3500 ms (took " + (int to str dt_pbk) + " ms)")

        -- RG-060: Argon2id OWASP m=19456 KiB, t=2, p=1 must match OpenSSL 3.5.7 and run in < 14500 ms on one core
        t_a20       = sys monotonic ms
        phc_19m     = argon2id hash "correct horse battery staple" "0123456789abcdef" 19456 2 1
        dt_a2       = (sys monotonic ms) - t_a20
        _           = echo ("  [BENCH] Argon2id m=19456, t=2, p=1: " + (int to str dt_a2) + " ms")
        _           = assert str eq phc_19m "$argon2id$v=19$m=19456,t=2,p=1$MDEyMzQ1Njc4OWFiY2RlZg$gy5SuVm5Z7Vw7keB9se9p87QGcomaseB/S2U1OhTsM0" "RG-060: Argon2id m=19456,t=2,p=1 matches OpenSSL 3.5.7"
        _           = assert true (dt_a2 < 14500) ("RG-060: Argon2id m=19456, t=2, p=1 must complete in < 14500 ms (took " + (int to str dt_a2) + " ms)")
        ()

-- @tests TS-CRYPTO-004
fn :: test rfc8439 chacha20 poly1305 aead => ()
      test rfc8439 chacha20 poly1305 aead =
        key   = bytes from list (range bytes 128 159)
        nonce = bytes from list [7, 0, 0, 0, 64, 65, 66, 67, 68, 69, 70, 71]
        aad   = bytes from list [80, 81, 82, 83, 192, 193, 194, 195, 196, 197, 198, 199]
        pt    = "Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it."

        sealed = aead seal key nonce aad pt
        _      = assert eq (str len sealed) ((str len pt) + 16)

        -- Verify first 16 ciphertext bytes and 16-byte Poly1305 tag match RFC 8439 §2.8.2 bit-for-bit
        ct_prefix_hex = bytes to hex str (byte slice sealed 0 16)
        tag_hex       = bytes to hex str (byte slice sealed 114 130)
        _             = assert str eq ct_prefix_hex "d31a8d34648e60db7b86afbc53ef7ec2" "RFC 8439 §2.8.2 ciphertext prefix"
        _             = assert str eq tag_hex "1ae10b594f09e26a7e902ecbd0600691" "RFC 8439 §2.8.2 Poly1305 tag"

        -- Verify aead_open succeeds with (0, pt)
        res_ok   = aead open key nonce aad sealed
        _        = assert eq (aead rc res_ok) 0
        _        = assert str eq (aead pt res_ok) pt "aead_open decrypted plaintext"

        -- Verify empty plaintext and empty AAD round-trip
        sealed_empty = aead seal key nonce "" ""
        _            = assert eq (str len sealed_empty) 16
        res_empty    = aead open key nonce "" sealed_empty
        _            = assert eq (aead rc res_empty) 0
        _            = assert str eq (aead pt res_empty) "" "aead_open empty plaintext"

        -- Verify tamper detection (-12 AUTH_FAILED) on modified AAD, modified nonce, modified ciphertext, or modified tag
        res_aad  = aead open key nonce "tampered-aad" sealed
        _        = assert eq (aead rc res_aad) (0 - 12)
        _        = assert str eq (aead pt res_aad) "" "tampered AAD returns empty plaintext"

        bad_nonce = bytes from list [8, 0, 0, 0, 64, 65, 66, 67, 68, 69, 70, 71]
        res_nonce = aead open key bad_nonce aad sealed
        _         = assert eq (aead rc res_nonce) (0 - 12)
        _         = assert str eq (aead pt res_nonce) "" "tampered nonce returns empty plaintext"

        bad_ct   = (byte str 0) + (byte slice sealed 1 130)
        res_ct   = aead open key nonce aad bad_ct
        _        = assert eq (aead rc res_ct) (0 - 12)
        _        = assert str eq (aead pt res_ct) "" "tampered ciphertext byte returns empty plaintext"

        bad_seal = (byte slice sealed 0 129) + (byte str 0)
        res_tag  = aead open key nonce aad bad_seal
        _        = assert eq (aead rc res_tag) (0 - 12)
        _        = assert str eq (aead pt res_tag) "" "tampered tag returns empty plaintext"

        -- Verify invalid key/nonce/ciphertext length returns (-7, "") or ""
        _        = assert str eq (aead seal "short-key" nonce aad pt) "" "aead_seal invalid key length"
        _        = assert str eq (aead seal key "short-nonce" aad pt) "" "aead_seal invalid nonce length"
        res_inv  = aead open "short-key" nonce aad sealed
        _        = assert eq (aead rc res_inv) (0 - 7)
        res_ninv = aead open key "short-nonce" aad sealed
        _        = assert eq (aead rc res_ninv) (0 - 7)
        res_tinv = aead open key nonce aad "short-tag"
        _        = assert eq (aead rc res_tinv) (0 - 7)
        ()

fn :: ten times String => String
      ten times s      =
        s2 = s + s
        s4 = s2 + s2
        s4 + s4 + s2

fn :: make a1m => String
      make a1m =
        "aaaaaaaaaa" ten times -> ten times -> ten times -> ten times -> ten times

fn :: t4 msg hex => String
      t4 msg hex =
        p0 = "08b8b2b733424243760fe426a4b54908632110a66c2f6591eabd3345e3e4eb98fa6e264bf09efe12ee50f8f54e9f77b1e355f6c50544e23fb1433ddf73be84d879de7c0046dc4996d9e773f4bc9efe5738829adb26c81b37c93a1b270b20329d658675fc6ea534e0810a4432826bf58c941efb65d57a338bbd2e26640f89ffbc"
        p1 = "1a858efcb8550ee3a5e1998bd177e93a7363c344fe6b199ee5d02e82d522c4feba15452f80288a821a579116ec6dad2b3b310da903401aa62100ab5d1a36553e06203b33890cc9b832f79ef80560ccb9a39ce767967ed628c6ad573cb116dbefefd75499da96bd68a8a97b928a8bbc103b6621fcde2beca1231d206be6cd9ec7"
        p2 = "aff6f6c94fcd7204ed3455c68c83f4a41da4af2b74ef5c53f1d8ac70bdcb7ed185ce81bd84359d44254d95629e9855a94a7c1958d1f8ada5d0532ed8a5aa3fb2d17ba70eb6248e594e1a2297acbbb39d502f1a8c6eb6f1ce22b3de1a1f40cc24554119a831a9aad6079cad88425de6bde1a9187ebb6092cf67bf2b13fd65f270"
        p3 = "88d78b7e883c8759d2c4f5c65adb7553878ad575f9fad878e80a0c9ba63bcbcc2732e69485bbc9c90bfbd62481d9089beccf80cfe2df16a2cf65bd92dd597b0707e0917af48bbb75fed413d238f5555a7a569d80c3414a8d0859dc65a46128bab27af87a71314f318c782b23ebfe808b82b0ce26401d2e22f04d83d1255dc51a"
        p4 = "ddd3b75a2b1ae0784504df543af8969be3ea7082ff7fc9888c144da2af58429ec96031dbcad3dad9af0dcbaaaf268cb8fcffead94f3c7ca495e056a9b47acdb751fb73e666c6c655ade8297297d07ad1ba5e43f1bca32301651339e22904cc8c42f58c30c04aafdb038dda0847dd988dcda6f3bfd15c4b4c4525004aa06eeff8"
        p5 = "ca61783aacec57fb3d1f92b0fe2fd1a85f6724517b65e614ad6808d6f6ee34dff7310fdc82aebfd904b01e1dc54b2927094b2db68d6f903b68401adebf5a7e08d78ff4ef5d63653a65040cf9bfd4aca7984a74d37145986780fc0b16ac451649de6188a7dbdf191f64b5fc5e2ab47b57f7f7276cd419c17a3ca8e1b939ae49e4"
        p6 = "88acba6b965610b5480109c8b17b80e1b7b750dfc7598d5d5011fd2dcc5600a32ef5b52a1ecc820e308aa342721aac0943bf6686b64b2579376504ccc493d97e6aed3fb0f9cd71a43dd497f01f17c0e2cb3797aa2a2f256656168e6c496afc5fb93246f6b1116398a346f1a641f3b041e989f7914f90cc2c7fff357876e506b5"
        p7 = "0d334ba77c225bc307ba537152f3f1610e4eafe595f6d9d90d11faa933a15ef1369546868a7f3a45a96768d40fd9d03412c091c6315cf4fde7cb68606937380db2eaaa707b4c4185c32eddcdd306705e4dc1ffc872eeee475a64dfac86aba41c0618983f8741c5ef68d3a101e8a3b8cac60c905c15fc910840b94c00a0b9d0"
        p0 + p1 + p2 + p3 + p4 + p5 + p6 + p7

fn :: ms kid (String String) => String
      ms kid (k, _)          =  k

fn :: ms pk (String String) => String
      ms pk (_, p)          =  p

-- ── TS-CRYPTO-005: FIPS 180-4 SHA-512, RFC 8032 Ed25519 & Minisign ──

-- @tests TS-CRYPTO-005
fn :: test sha512 fips vectors => ()
      test sha512 fips vectors =
        -- 1. Empty string ""
        h_emp = sha512 hex ""
        assert str eq h_emp "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e" "SHA-512 empty" -> ()
        assert eq (str len (sha512 bytes "")) 64 -> ()

        -- 2. "abc"
        h_abc = sha512 hex "abc"
        assert str eq h_abc "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f" "SHA-512 abc" -> ()
        assert str eq (bytes to hex str (sha512 bytes "abc")) h_abc "sha512 bytes matches sha512 hex" -> ()

        -- 3. 448-bit message (56 bytes)
        m448  = "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
        assert str eq (sha512 hex m448) "204a8fc6dda82f0a0ced7beb8e08a41657c16ef468b228a8279be331a703c33596fd15c13b1b07f9aa1d3bea57789ca031ad85c7a71dd70354ec631238ca3445" "SHA-512 448-bit" -> ()

        -- 4. 896-bit message (112 bytes, spans two 1024-bit blocks with padding)
        m896  = "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu"
        assert str eq (sha512 hex m896) "8e959b75dae313da8cf4f72814fc143f8f7779c6eb9f7fa17299aeadb6889018501d289e4900f7e4331b99dec4b5433ac7d329eeb6dd26545e96e55b874be909" "SHA-512 896-bit" -> ()

        -- 5. One million "a" characters
        t0    = sys monotonic ms
        h1m   = sha512 hex (make a1m)
        dt1m  = (sys monotonic ms) - t0
        echo ("  [BENCH] SHA-512 1,000,000 x 'a': " + (int to str dt1m) + " ms") -> ()
        assert str eq h1m "e718483d0ce769644e2e42c7bc15b4638e1f98b13b2044285632a803afa973ebde0ff244877ea60a4cb0432ce577c31beb009c5c2c49aa2e4eadb217ad8cc09b" "SHA-512 1,000,000 'a'" -> ()

-- @tests TS-CRYPTO-005
fn :: test ed25519 rfc8032 vectors and negatives => ()
      test ed25519 rfc8032 vectors and negatives =
        -- RFC 8032 §7.1 TEST 1 (empty message "")
        t_ed0  = sys monotonic ms
        sk1    = hex to byte str "9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60"
        pk1    = ed25519 public key sk1
        sig1   = ed25519 sign sk1 ""
        ok1    = ed25519 verify pk1 "" sig1
        dt_ed  = (sys monotonic ms) - t_ed0
        echo ("  [BENCH] Ed25519 pubkey + sign + verify: " + (int to str dt_ed) + " ms") -> ()
        assert str eq (bytes to hex str pk1) "d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a" "RFC 8032 Test 1 pubkey" -> ()
        assert str eq (bytes to hex str sig1) "e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e065224901555fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b" "RFC 8032 Test 1 sig" -> ()
        assert true ok1 "RFC 8032 Test 1 verify" -> ()
        assert true (dt_ed < 1000) "Ed25519 sign+verify under 1000 ms" -> ()

        -- RFC 8032 §7.1 TEST 2 (1-byte message 0x72)
        sk2    = hex to byte str "4ccd089b28ff96da9db6c346ec114e0f5b8a319f35aba624da8cf6ed4fb8a6fb"
        pk2    = ed25519 public key sk2
        m2     = hex to byte str "72"
        sig2   = ed25519 sign sk2 m2
        assert str eq (bytes to hex str pk2) "3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c" "RFC 8032 Test 2 pubkey" -> ()
        assert str eq (bytes to hex str sig2) "92a009a9f0d4cab8720e820b5f642540a2b27b5416503f8fb3762223ebdb69da085ac1e43e15996e458f3613d0f11d8c387b2eaeb4302aeeb00d291612bb0c00" "RFC 8032 Test 2 sig" -> ()
        assert true (ed25519 verify pk2 m2 sig2) "RFC 8032 Test 2 verify" -> ()

        -- RFC 8032 §7.1 TEST 3 (2-byte message 0xaf82)
        sk3    = hex to byte str "c5aa8df43f9f837bedb7442f31dcb7b166d38535076f094b85ce3a2e0b4458f7"
        pk3    = ed25519 public key sk3
        m3     = hex to byte str "af82"
        sig3   = ed25519 sign sk3 m3
        assert str eq (bytes to hex str pk3) "fc51cd8e6218a1a38da47ed00230f0580816ed13ba3303ac5deb911548908025" "RFC 8032 Test 3 pubkey" -> ()
        assert str eq (bytes to hex str sig3) "6291d657deec24024827e69c3abe01a30ce548a284743a445e3680d7db5ac3ac18ff9b538d16f290ae67f760984dc6594a7c15e9716ed28dc027beceea1ec40a" "RFC 8032 Test 3 sig" -> ()
        assert true (ed25519 verify pk3 m3 sig3) "RFC 8032 Test 3 verify" -> ()

        -- RFC 8032 §7.1 TEST 1024 (1023-byte message)
        sk4    = hex to byte str "f5e5767cf153319517630f226876b86c8160cc583bc013744c6bf255f5cc0ee5"
        pk4    = ed25519 public key sk4
        m4     = hex to byte str (t4 msg hex)
        sig4   = ed25519 sign sk4 m4
        assert eq (str len m4) 1023 -> ()
        assert str eq (bytes to hex str pk4) "278117fc144c72340f67d0f2316e8386ceffbf2b2428c9c51fef7c597f1d426e" "RFC 8032 Test 1024 pubkey" -> ()
        assert str eq (bytes to hex str sig4) "0aab4c900501b3e24d7cdf4663326a3a87df5e4843b2cbdb67cbf6e460fec350aa5371b1508f9f4528ecea23c436d94b5e8fcd4f681e30a6ac00a9704a188a03" "RFC 8032 Test 1024 sig" -> ()
        assert true (ed25519 verify pk4 m4 sig4) "RFC 8032 Test 1024 verify" -> ()

        -- RFC 8032 §7.1 TEST SHA(abc) (64-byte SHA-512("abc") message)
        sk5    = hex to byte str "833fe62409237b9d62ec77587520911e9a759cec1d19755b7da901b96dca3d42"
        pk5    = ed25519 public key sk5
        m5     = sha512 bytes "abc"
        sig5   = ed25519 sign sk5 m5
        assert str eq (bytes to hex str pk5) "ec172b93ad5e563bf4932c70e1245034c35467ef2efd4d64ebf819683467e2bf" "RFC 8032 Test SHA(abc) pubkey" -> ()
        assert str eq (bytes to hex str sig5) "dc2a4459e7369633a52b1bf277839a00201009a3efbf3ecb69bea2186c26b58909351fc9ac90b3ecfdfbc7c66431e0303dca179c138ac17ad9bef1177331a704" "RFC 8032 Test SHA(abc) sig" -> ()
        assert true (ed25519 verify pk5 m5 sig5) "RFC 8032 Test SHA(abc) verify" -> ()

        -- Negative cases: flipped bits in message, R, S, and public key
        assert false (ed25519 verify pk3 (hex to byte str "ae82") sig3) "Flipped bit in message rejected" -> ()
        bad_r  = (byte str (byte bxor (norm byte (str char at sig3 0)) 1)) + (byte slice sig3 1 64)
        assert false (ed25519 verify pk3 m3 bad_r) "Flipped bit in R rejected" -> ()
        bad_s  = (byte slice sig3 0 32) + (byte str (byte bxor (norm byte (str char at sig3 32)) 1)) + (byte slice sig3 33 64)
        assert false (ed25519 verify pk3 m3 bad_s) "Flipped bit in S rejected" -> ()
        bad_pk = (byte str (byte bxor (norm byte (str char at pk3 0)) 1)) + (byte slice pk3 1 32)
        assert false (ed25519 verify bad_pk m3 sig3) "Flipped bit in pubkey rejected" -> ()

        -- Negative cases: S = L and S = L + 1 (malleability check S >= L)
        l_le   = hex to byte str "edd3f55c1a631258d69cf7a2def9de1400000000000000000000000000000010"
        lp1_le = hex to byte str "eed3f55c1a631258d69cf7a2def9de1400000000000000000000000000000010"
        assert false (ed25519 verify pk1 "" ((byte slice sig1 0 32) + l_le)) "S == L rejected" -> ()
        assert false (ed25519 verify pk1 "" ((byte slice sig1 0 32) + lp1_le)) "S == L + 1 rejected" -> ()

        -- Negative cases: non-canonical y = p (2^255 - 19) and non-curve point (y = 2)
        y_eq_p = hex to byte str "edffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7f"
        y_eq_2 = hex to byte str "0200000000000000000000000000000000000000000000000000000000000000"
        assert false (ed25519 verify y_eq_p "" sig1) "Non-canonical y == p pubkey rejected" -> ()
        assert false (ed25519 verify y_eq_2 "" sig1) "Non-curve point y == 2 pubkey rejected" -> ()
        assert false (ed25519 verify pk1 "" (y_eq_2 + (byte slice sig1 32 64))) "Non-curve point R rejected" -> ()

        -- Negative cases: invalid lengths
        assert str eq (ed25519 public key "short") "" "short seed pubkey returns empty" -> ()
        assert str eq (ed25519 sign "short" "msg") "" "short seed sign returns empty" -> ()
        assert false (ed25519 verify "short" "" sig1) "short pubkey verify returns False" -> ()
        assert false (ed25519 verify pk1 "" "short") "short sig verify returns False" -> ()

-- @tests TS-CRYPTO-005
fn :: test minisign roundtrip and tamper => ()
      test minisign roundtrip and tamper =
        seed   = hex to byte str "9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60"
        pk     = ed25519 public key seed
        kid    = "01234567"
        pk_b64 = minisign encode pubkey kid pk
        assert true ((str len pk_b64) == 56) "minisign encoded pubkey is 56 chars" -> ()

        dec1   = minisign decode pubkey pk_b64
        assert str eq (ms kid dec1) kid "minisign decode 1-line key_id" -> ()
        assert str eq (ms pk dec1) pk "minisign decode 1-line pubkey" -> ()

        pub_2l = "untrusted comment: ridgun release key\n" + pk_b64 + "\n"
        dec2   = minisign decode pubkey pub_2l
        assert str eq (ms kid dec2) kid "minisign decode 2-line key_id" -> ()
        assert str eq (ms pk dec2) pk "minisign decode 2-line pubkey" -> ()

        msg    = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  ridgun-v0.9.21-linux-x86_64.tar.gz\n"
        tc     = "timestamp:1761667200\tfile:SHA256SUMS"
        msig   = minisign sign seed kid msg "signature from ridgun secret key" tc
        assert str eq (minisign trusted comment msig) tc "minisign trusted comment extracted" -> ()
        assert true (minisign verify pub_2l msg msig) "minisign verify valid signature" -> ()
        assert true (minisign verify pk_b64 msg msig) "minisign verify valid with 1-line pubkey" -> ()

        -- Tampered payload rejected
        assert false (minisign verify pub_2l (msg + "x") msig) "minisign verify rejects tampered payload" -> ()

        -- Tampered trusted comment rejected even though payload signature is intact
        msig_bad_tc = minisign sign seed kid msg "signature from ridgun secret key" "timestamp:9999999999\tfile:EVIL"
        lines_good  = c split lines msig
        lines_bad   = c split lines msig_bad_tc
        forged_msig = (c nth str lines_good 0) + "\n" + (c nth str lines_good 1) + "\n" + (c nth str lines_bad 2) + "\n" + (c nth str lines_good 3) + "\n"
        assert false (minisign verify pub_2l msg forged_msig) "minisign verify rejects tampered trusted comment" -> ()

        -- Wrong key_id rejected
        other_pub = minisign encode pubkey "76543210" pk
        assert false (minisign verify other_pub msg msig) "minisign verify rejects mismatched key_id" -> ()

-- ── TS-CRYPTO-006: SHA-384, HKDF, X25519, AES-128-GCM, P-256/P-384, RSA, X.509 ──

-- @tests TS-CRYPTO-006
fn :: test sha384 hkdf x25519 aes128gcm => ()
      test sha384 hkdf x25519 aes128gcm =
        -- 1. SHA-384 & HMAC-SHA-384 (FIPS 180-4 & RFC 4231 TC2)
        h384_emp = sha384 hex ""
        assert str eq h384_emp "38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b" "SHA-384 empty" -> ()
        h384_abc = sha384 hex "abc"
        assert str eq h384_abc "cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed8086072ba1e7cc2358baeca134c825a7" "SHA-384 abc" -> ()
        assert eq (str len (sha384 bytes "abc")) 48 -> ()
        mac384   = hmac sha384 "Jefe" "what do ya want for nothing?"
        assert str eq (bytes to hex str mac384) "af45d2e376484031617f78d2b58a6b1b9c7ef464f5a01b47e42ec3736322445e8e2240ca5e69e2c78b3239ecfab21649" "RFC 4231 TC2 HMAC-SHA-384" -> ()

        -- 2. HKDF-SHA-256 (RFC 5869 Appendix A Test Case 1) & TLS 1.3 Derive-Secret (RFC 8448 §3)
        ikm1 = hex to byte str "0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b"
        slt1 = hex to byte str "000102030405060708090a0b0c"
        inf1 = hex to byte str "f0f1f2f3f4f5f6f7f8f9"
        prk1 = hkdf extract slt1 ikm1
        okm1 = hkdf expand prk1 inf1 42
        assert str eq (bytes to hex str prk1) "077709362c2e32df0ddc3f0dc47bba6390b6c73bb50f9c3122ec844ad7c2b3e5" "RFC 5869 TC1 PRK" -> ()
        assert str eq (bytes to hex str okm1) "3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865" "RFC 5869 TC1 OKM" -> ()
        early_sec = hkdf extract "" (c repeat byte 0 32)
        assert str eq (bytes to hex str early_sec) "33ad0a1c607ec03b09e6cd9893680ce210adf300aa1f2660e1b22e10f170f92a" "RFC 8448 Early Secret" -> ()
        derived_s = derive secret early_sec "derived" ""
        assert str eq (bytes to hex str derived_s) "6f2615a108c702c5678f54fc9dbab69716c076189c48250cebeac3576c3611ba" "RFC 8448 Derived Secret" -> ()

        -- 3. RFC 7748 X25519 Test Vectors (§5.2 and §6.1 Alice/Bob DH)
        x_sc1  = hex to byte str "a546e36bf0527c9d3b16154b82465edd62144c0ac1fc5a18506a2244ba449ac4"
        x_u1   = hex to byte str "e6db6867583030db3594c1a424b15f7c726624ec26b3353b10a903a6d0ab1c4c"
        x_out1 = x25519 x_sc1 x_u1
        assert str eq (bytes to hex str x_out1) "c3da55379de9c6908e94ea4df28d084f32eccf03491c71f754b4075577a28552" "RFC 7748 §5.2 vector 1" -> ()
        a_priv = hex to byte str "77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a"
        a_pub  = x25519 public key a_priv
        b_priv = hex to byte str "5dab087e624a8a4b79e17f8b83800ee66f3bb1292618b6fd1c2f8b27ff88e0eb"
        b_pub  = x25519 public key b_priv
        assert str eq (bytes to hex str a_pub) "8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a" "RFC 7748 §6.1 Alice pubkey" -> ()
        assert str eq (bytes to hex str b_pub) "de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f" "RFC 7748 §6.1 Bob pubkey" -> ()
        sh_ab  = x25519 a_priv b_pub
        sh_ba  = x25519 b_priv a_pub
        assert str eq (bytes to hex str sh_ab) "4a5d9d5ba4ce2de1728e3bf480350f25e07e21c947d19e3376f09b3c1e161742" "RFC 7748 §6.1 shared secret" -> ()
        assert str eq sh_ab sh_ba "X25519 Alice == Bob" -> ()
        assert str eq (x25519 a_priv (c repeat byte 0 32)) "" "X25519 rejects all-zero low-order point" -> ()

        -- 4. FIPS 197 AES-128 & NIST SP 800-38D AES-128-GCM
        aes_k   = hex to byte str "2b7e151628aed2a6abf7158809cf4f3c"
        aes_pt  = hex to byte str "3243f6a8885a308d313198a2e0370734"
        aes_ct  = aes128 block aes_k aes_pt
        assert str eq (bytes to hex str aes_ct) "3925841d02dc09fbdc118597196a0b32" "FIPS 197 Appendix B AES-128 block" -> ()

        gk1     = c repeat byte 0 16
        gn1     = c repeat byte 0 12
        g_seal1 = aes128 gcm seal gk1 gn1 "" ""
        assert str eq (bytes to hex str g_seal1) "58e2fccefa7e3061367f1d57a4e7455a" "NIST GCM Test Case 1 empty PT/AAD" -> ()
        g_seal2 = aes128 gcm seal gk1 gn1 "" (c repeat byte 0 16)
        assert str eq (bytes to hex str g_seal2) "0388dace60b6a392f328c2b971b2fe78ab6e47d42cec13bdf53a67b21257bddf" "NIST GCM Test Case 2 16B zero PT" -> ()
        g_open2 = aes128 gcm open gk1 gn1 "" g_seal2
        assert eq (aead rc g_open2) 0 -> ()
        assert str eq (aead pt g_open2) (c repeat byte 0 16) "AES-128-GCM open TC2" -> ()

        -- Tampered tag / AAD rejected with (-12, "")
        g_bad_aad = aes128 gcm open gk1 gn1 "wrong-aad" g_seal2
        assert eq (aead rc g_bad_aad) (0 - 12) -> ()
        assert str eq (aead pt g_bad_aad) "" "AES-128-GCM tampered AAD returns empty" -> ()
        g_bad_tag = aes128 gcm open gk1 gn1 "" ((byte slice g_seal2 0 31) + (byte str 0))
        assert eq (aead rc g_bad_tag) (0 - 12) -> ()

-- @tests TS-CRYPTO-006
fn :: test p256 p384 rsa and x509 => ()
      test p256 p384 rsa and x509 =
        -- 1. P-256 ECDHE & ECDSA P-256 / P-384 Verification
        sk256 = hex to byte str "c9afa9d845ba75166b5c215767b1d6934e50c3db36e89b127b8a622b120f6721"
        pk256 = p256 public key sk256
        assert str eq (bytes to hex str pk256) "0460fed4ba255a9d31c961eb74c6356d68c049b8923b61fa6ce669622e60f29fb67903fe1008b8bc99a41ae9e95628bc64f2f1b20c2d7e9f5177a3c294d4462299" "RFC 6979 P-256 pubkey" -> ()
        sk256_b = hex to byte str "0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20"
        pk256_b = p256 public key sk256_b
        ecdh_ab = p256 ecdh sk256 pk256_b
        ecdh_ba = p256 ecdh sk256_b pk256
        assert eq (str len ecdh_ab) 32 -> ()
        assert str eq ecdh_ab ecdh_ba "P-256 ECDH Alice == Bob" -> ()
        assert str eq (p256 ecdh sk256 ((byte str 4) + (c repeat byte 0 64))) "" "P-256 ECDH rejects off-curve point" -> ()

        sig256 = hex to byte str "3045022057d754539de74a3c6ce2a8744b91c3f73001c733f3e20179f196819bab767e58022100dcd06a946d1b7e568d3ff29a46698e3fe49746f86811588354a4d2d43102d665"
        assert true (ecdsa p256 verify sha256 pk256 "sample" sig256) "ECDSA P-256 verify valid" -> ()
        assert false (ecdsa p256 verify sha256 pk256 "tampered" sig256) "ECDSA P-256 rejects tampered msg" -> ()

        pk384  = hex to byte str "04ec3a4e415b4e19a4568618029f427fa5da9a8bc4ae92e02e06aae5286b300c64def8f0ea9055866064a254515480bc138015d9b72d7d57244ea8ef9ac0c621896708a59367f9dfb9f54ca84b3f1c9db1288b231c3ae0d4fe7344fd2533264720"
        sig384 = hex to byte str "306502307cb9078a9a1ee3685d0eede601238685b0e0bb514de400f799b582a0455be88141853a4cb0284f9d7ed980ea4795126a023100a88ce84cce196de0d329328b915d442bb4f64f8020fc0c6d8337d9887dfabc787cca7eecd1a5661e6f6839df126e92f1"
        assert true (ecdsa p384 verify sha384 pk384 "sample" sig384) "ECDSA P-384 verify valid" -> ()
        assert false (ecdsa p384 verify sha384 pk384 "tampered" sig384) "ECDSA P-384 rejects tampered msg" -> ()

        -- 2. RSA-2048 PKCS#1 v1.5 and RSA-PSS Verification + < 2048-bit rejection
        rsa_n     = hex to byte str ("af2e53e5eec127b0965a32813c253b4513c21de33c05ddb775ae20c53a8cea9743c06a65b9bede2bdba5fb1d307bb91d6822d3750d0b0a7a55189a51c897912e" + "550bd4d6d0ee3a561cf4171b0e8229e346754fe9315b1ca397109a8973f3ad0c3474bbd78e62f745f1530a6a97d2d787fe42def67734aed9b19e05348805d74c" + "68583858b0a477af413a9f39c7f61b6a21b3dd53db9b7025ee4519813ec95e6f60cd35cdd67bc27f874558e55b9eb88008d424be1e92bb60e4fe582907b975b6" + "1a18f5ed1332746aeaf01023ab676cbf0f424783b9c4769a69f33c829a194cdb8313a16a768ef2b2b4a90dcc597fe2764783e4b24906f856eaf81b1fe9a0efbb")
        rsa_e     = hex to byte str "010001"
        rsa_pkcs1 = hex to byte str ("6bef0571302c2a2b4c82c4641140cc21823f643127c7fa60ba699901fe23032a7631276ac204314fde6f48586a417967cea5cbfe4d4b02b90acdfc611d5bba7e" + "b1625c3dfec8bb897c73bebf154f1dd79f236e1b62e6ae277d6ad7da32b9e470daa0acbed7b2ae3e247dc97e0cc8ebffd1ba16453fb2879401daf9fc12f766c0" + "9efec85dbcd778cad083d980d40bf8a3aeba6a5cd01b4d6334dbb25128abc6b04166c1307a82be8a327718cb3601d7bb79bc2e407fc0b43db3fe4545b5b503db" + "20aef99e875544301ac564ee95275ad19522d2344316da5ce082dbf1b70516a43e6f0be568d0de055e4ffa5ab13c3ab6feab85a00ce7af459324317078ccfc1c")
        rsa_pss   = hex to byte str ("5a2ab42312f8554944f88a34e57488750221776acf9b700f48b7e125dfae6f971f7650e18e47065d1c4c494df233fd4d80505fac99110eabee67fc9e9ca7b9e8" + "f4a26f5b677f4d9a05aea41a82301f649e635b63e7b8d944d3fd41c491d7c985ccc933715308b601e6006e6b7486b7c252bf5bafe2570469f51f3cbcfe332a96" + "8e4fd94f2b4d88b64aa994305bbf8fc039506b9efc9fe4791dcebc2d7c64776dfc64fe860f1cae8b4b962a371c6299fa79df3868666df62868e31e3bacf777b1" + "ee7b134e5ceb05ba70f2d260fe54e591bcecce083af82026da8ca9a64bc088ade262610bd9f7a19cff3e1f9bba3558811629a5163b775947a58fe3405ca2e1d2")
        assert true (rsa verify pkcs1 rsa_n rsa_e "sha256" "hello tls 1.3" rsa_pkcs1) "RSA-2048 PKCS#1 v1.5 valid" -> ()
        assert false (rsa verify pkcs1 rsa_n rsa_e "sha256" "wrong msg" rsa_pkcs1) "RSA-2048 PKCS#1 v1.5 rejects wrong msg" -> ()
        assert true (rsa verify pss rsa_n rsa_e "sha256" "hello tls 1.3" rsa_pss) "RSA-2048 PSS valid" -> ()
        assert false (rsa verify pss rsa_n rsa_e "sha256" "wrong msg" rsa_pss) "RSA-2048 PSS rejects wrong msg" -> ()
        assert false (rsa verify pkcs1 (byte slice rsa_n 0 128) rsa_e "sha256" "hello tls 1.3" (byte slice rsa_pkcs1 0 128)) "RSA < 2048 bits rejected" -> ()

        -- 3. PEM, ASN.1 DER, X.509 v3 Certificate Parsing, RFC 6125 SAN Matching & Signature Verification
        cert_pem = "-----BEGIN CERTIFICATE-----\n" + "MIIBezCCASGgAwIBAgICA+kwCgYIKoZIzj0EAwIwFjEUMBIGA1UEAwwLZXhhbXBs\n" + "ZS5jb20wHhcNMjUwMTAxMDAwMDAwWhcNMzAwMTAxMDAwMDAwWjAWMRQwEgYDVQQD\n" + "DAtleGFtcGxlLmNvbTBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABGD+1LolWp0x\n" + "yWHrdMY1bWjASbiSO2H6bOZpYi5g8p+2eQP+EAi4vJmkGunpVii8ZPLxsgwtfp9R\n" + "d6PClNRGIpmjXzBdMCUGA1UdEQQeMByCDSouZXhhbXBsZS5jb22CC2V4YW1wbGUu\n" + "b3JnMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgKEMBMGA1UdJQQMMAoG\n" + "CCsGAQUFBwMBMAoGCCqGSM49BAMCA0gAMEUCIQCVhHPDc7KdyWWTnxAvfq/cVF1z\n" + "uCcPqO/wDbrwbY72awIgPq5F1Ab9+6ax8pFdr0ryT/h+n6znJEDCfjtZvnzE2wI=\n" + "-----END CERTIFICATE-----\n"
        ders     = pem decode blocks cert_pem "CERTIFICATE"
        assert eq (c str list len ders 0) 1 -> ()
        ok_c, cert = x509 parse cert (c nth str ders 0)
        assert true ok_c "x509 parse cert succeeds" -> ()
        assert str eq (subject_cn cert) "example.com" "X.509 subject CN" -> ()
        assert str eq (key_alg cert) "ec_p256" "X.509 SPKI key_alg" -> ()
        assert str eq (sig_alg cert) "ecdsa_sha256" "X.509 sig_alg" -> ()
        assert true (is_ca cert) "X.509 basicConstraints CA=TRUE" -> ()
        assert true (has_server_auth cert) "X.509 EKU serverAuth" -> ()
        assert eq (not_before_at cert) 1735689600 -> ()
        assert eq (not_after_at cert) 1893456000 -> ()
        assert true (x509 match hostname cert "api.example.com") "RFC 6125 wildcard matches leftmost label" -> ()
        assert true (x509 match hostname cert "example.org") "RFC 6125 exact SAN match" -> ()
        assert false (x509 match hostname cert "sub.api.example.com") "RFC 6125 wildcard rejects multi-label prefix" -> ()
        assert false (x509 match hostname cert "example.com") "RFC 6125 wildcard does not match bare apex" -> ()
        assert false (x509 match single san "a.*.example.com" "a.b.example.com") "RFC 6125 rejects non-leftmost wildcard" -> ()
        assert false (x509 match single san "*.com" "example.com") "RFC 6125 rejects top-level wildcard" -> ()
        assert true (x509 verify cert sig cert cert) "X.509 self-signed signature verified" -> ()

-- @tests TS-CRYPTO-006
fn :: test crypto006 edge cases and certs => ()
      test crypto006 edge cases and certs =
        -- 1. X25519 rejects wrong input lengths (AC2)
        x_k = hex to byte str "77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a"
        assert str eq (x25519 (byte slice x_k 0 31) (c repeat byte 9 32)) "" "X25519 rejects 31-byte scalar" -> ()
        assert str eq (x25519 x_k (c repeat byte 9 33)) "" "X25519 rejects 33-byte u-coordinate" -> ()
        assert str eq (x25519 public key (byte slice x_k 0 16)) "" "X25519 public key rejects 16-byte scalar" -> ()

        -- 2. NIST SP 800-38D AES-128-GCM Test Cases 3 and 4 (AC3)
        gk3  = hex to byte str "feffe9928665731c6d6a8f9467308308"
        gn3  = hex to byte str "cafebabefacedbaddecaf888"
        gp3  = hex to byte str ("d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a72" + "1c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b391aafd255")
        gs3  = aes128 gcm seal gk3 gn3 "" gp3
        assert str eq (bytes to hex str gs3) ("42831ec2217774244b7221b784d0d49ce3aa212f2c02a4e035c17e2329aca12e" + "21d514b25466931c7d8f6a5aac84aa051ba30b396a0aac973d58e091473f5985" + "4d5c2af327cd64a62cf35abd2ba6fab4") "NIST GCM Test Case 3" -> ()
        gp4  = byte slice gp3 0 60
        ga4  = hex to byte str "feedfacedeadbeeffeedfacedeadbeefabaddad2"
        gs4  = aes128 gcm seal gk3 gn3 ga4 gp4
        assert str eq (bytes to hex str gs4) ("42831ec2217774244b7221b784d0d49ce3aa212f2c02a4e035c17e2329aca12e" + "21d514b25466931c7d8f6a5aac84aa051ba30b396a0aac973d58e091" + "5bc94fbc3221a5db94fae95ae7121a47") "NIST GCM Test Case 4 with AAD" -> ()
        go4  = aes128 gcm open gk3 gn3 ga4 gs4
        assert eq (aead rc go4) 0 -> ()
        assert str eq (aead pt go4) gp4 "AES-128-GCM open TC4" -> ()
        gbad = (byte str 1) + (byte slice gs4 1 (str len gs4))
        assert eq (aead rc (aes128 gcm open gk3 gn3 ga4 gbad)) (0 - 12) -> ()
        assert eq (aead rc (aes128 gcm open (byte slice gk3 0 15) gn3 ga4 gs4)) (0 - 7) -> ()

        -- 3. ECDSA P-256 raw r || s signature and tampered signature (AC4)
        sk_e  = hex to byte str "c9afa9d845ba75166b5c215767b1d6934e50c3db36e89b127b8a622b120f6721"
        pk_e  = p256 public key sk_e
        raw_e = hex to byte str ("57d754539de74a3c6ce2a8744b91c3f73001c733f3e20179f196819bab767e58" + "dcd06a946d1b7e568d3ff29a46698e3fe49746f86811588354a4d2d43102d665")
        assert true (ecdsa p256 verify sha256 pk_e "sample" raw_e) "ECDSA P-256 raw r||s valid" -> ()
        bad_e = (byte slice raw_e 0 63) + (byte str 0)
        assert false (ecdsa p256 verify sha256 pk_e "sample" bad_e) "ECDSA P-256 rejects tampered signature" -> ()

        -- 4. RSA-2048 PKCS#1 v1.5 SHA-384/SHA-512 and RSA-PSS SHA-384 (AC5)
        rk_n = hex to byte str ("c602350d97a36b3342f59b62741c4657de7edb6e7095733a548eeef5c3e99244df3ae1712743860e457eaf4e3bbccdab5b75713b49cdba1927010da595809151" + "0f9f2ff87c0e01868b51dfb47a08fda7df71f4917870444e7485368d202824d76668e50e55fe43135f681ab7a41cc84eef2dee276997ef324b9267bfb1a83f8f" + "a8f209bb42928d74435073e9f5a3eb27925aa7306744bc3b8a3f34a6b78b5f945c3aa5e0d5907f60666fdeca9524f3be2a9963128e92bff579953b6b6acfeeb5" + "fc361b64a46fe8310731d69d531899744ef905024030c860793440c7e6a8f4ad5da70508d90b1505b3b30e27f77cabfe47794909bd44cf0af57358fbe280f9d1")
        rk_e = hex to byte str "010001"
        s512 = hex to byte str ("5af14292d1d30acb0104b64ea57b31266c8f58307b92d2a3abb80ef66696cd29b59654b72de41e2559f58fcf033ec070246655fdfb339bb61a5e99b76789ed56" + "297fbbfe0285920d57a5f74f500000698e6a9f75a8e7cdc7544ac2e333daf8783246b8f54a3cb87f20847770987719f9eb4a2c46e7afd1da8a69524e80dfb984" + "8e8547d4e356a16821e80f88a3ebd48e78d96a29a7f06de6f8884d24d8a24c9601aeb421493c97a1605f05b32fd351c378b51e8ed38defbd50e1c0020d2aa340" + "7c13db18ebc2422096e4063c111e6a082b7175e26fd9fbc238a67af8e01c1803bcd8cf7294e916031f64e68ea5f6b05e88b3c576ec6a341229e39b0c053e7ccd")
        s384 = hex to byte str ("2d7b014c1227bb49f5bb69495278e6829f44cb2364170ee2b0975c65d59674cd31121bb4a096a99567e01af26c6add5783dff2e0c6b9d6c05b4a6f643c6b3f0a" + "9f3f82bd7ba1eb4757dbe53359006dfeb4a65346ce6ee10bd62ed3a75c04b59f325efe322896246b49e3b38ab6b0a72930682e0f9f556c037a9cc6df1cfed339" + "518bb33ffa00a5f4569a0493c1e9060b7ffb1c570641428f690eecaa959fddfdfb0e53ba6d18a7a124047063a60d462e48f16a19724d3c866476ef9005259375" + "aded472bf9e0ed6107f7d34cd45ceeb78371b0dc17c1d3bcf147f2f85d1a48ac1dc489fe2ce7e5c07680cfa56d760171fc5c19fd9b13f1a1fb5e14e51abb49b9")
        p384s = hex to byte str ("56377f9c6a7e58606912df904da1fba3a8c40e263bb2fde3c303210e5c0e5426e9e70d5c593ecdef343d33b92eedb736e3c6c6461c0fbca4708a104d60c942d1" + "cf62eb69ec6d03bbf051b97e7d517af04f7b53b431e244abd5350a3e76bad74dd90b762ca20ad66e62b1e26b3ce2b77eb32b2d770fd5521eb0148664e420b2f9" + "588619f7d998c32221bc64b95b2e3c23022488600682d41392487fb6439779bf3f5ece2a8bc08d4414a843c703578bbdebad1efd72afe7f102e4025abeadfd73" + "8cf987392f123933d7fb1ac0a4723818d570aa1296e9dd36f9aeea56adbf72978cf886b6c2ee6c99829cde03f9f8f4d78dc146abdda631bb4555094289e1833e")
        assert true (rsa verify pkcs1 rk_n rk_e "sha512" "hello tls 1.2" s512) "RSA PKCS#1 v1.5 SHA-512 valid" -> ()
        assert true (rsa verify pkcs1 rk_n rk_e "sha384" "hello tls 1.2" s384) "RSA PKCS#1 v1.5 SHA-384 valid" -> ()
        assert false (rsa verify pkcs1 rk_n rk_e "sha384" "hello tls 1.2" s512) "RSA PKCS#1 v1.5 rejects hash mismatch" -> ()
        assert true (rsa verify pss rk_n rk_e "sha384" "hello tls 1.2" p384s) "RSA-PSS SHA-384 valid" -> ()
        bad_r = (byte slice s512 0 255) + (byte str 0)
        assert false (rsa verify pkcs1 rk_n rk_e "sha512" "hello tls 1.2" bad_r) "RSA PKCS#1 v1.5 rejects tampered signature" -> ()

        -- 5. X.509: RSA CA, P-384 and Ed25519 self-signed certs, CA-signed leaf (AC6)
        ca_pem = "-----BEGIN CERTIFICATE-----\n" + "MIICwDCCAaigAwIBAgIBATANBgkqhkiG9w0BAQwFADAZMRcwFQYDVQQDDA5SaWRn\n" + "dW4gVGVzdCBDQTAeFw0yNTAxMDEwMDAwMDBaFw0zMDAxMDEwMDAwMDBaMBkxFzAV\n" + "BgNVBAMMDlJpZGd1biBUZXN0IENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB\n" + "CgKCAQEAxgI1DZejazNC9ZtidBxGV95+225wlXM6VI7u9cPpkkTfOuFxJ0OGDkV+\n" + "r047vM2rW3VxO0nNuhknAQ2llYCRUQ+fL/h8DgGGi1HftHoI/affcfSReHBETnSF\n" + "No0gKCTXZmjlDlX+QxNfaBq3pBzITu8t7idpl+8yS5Jnv7GoP4+o8gm7QpKNdENQ\n" + "c+n1o+snklqnMGdEvDuKPzSmt4tflFw6peDVkH9gZm/eypUk874qmWMSjpK/9XmV\n" + "O2tqz+61/DYbZKRv6DEHMdadUxiZdE75BQJAMMhgeTRAx+ao9K1dpwUI2QsVBbOz\n" + "Dif3fKv+R3lJCb1Ezwr1c1j74oD50QIDAQABoxMwETAPBgNVHRMBAf8EBTADAQH/\n" + "MA0GCSqGSIb3DQEBDAUAA4IBAQAGiAYEZCsQ72QJ5EvS1o8w5LZ4SoATUmaLnLSo\n" + "nWMzrsFjuLnB8mFIvM8Bd7n8Y8cC84fPFuaFWVntNmB+UdWr1eQCYsX0bFslgron\n" + "K5U9xKbF8nNjAzlQMKUYPceh/OOAyb20uTOMz4423q4hqpZG0Hmyn9UEgGTTyxOe\n" + "UYnFQ5l7ih6CJlb2wgsh2cvdESs0E5B3O6c+P9E3wp1n+8C+KxUSuxTeDLtnMswV\n" + "0aqP1FXVJ+C6NDGq9pXnD4BIRBiCK8bpp5YqM96htw5FBN7FMCtcJtBh1Lm06d/W\n" + "Tghqly2jDVSNwOlHWLUix/QKQ0AfOsIoOGmivs9wtFc4BIHP\n" + "-----END CERTIFICATE-----\n"
        p384_pem = "-----BEGIN CERTIFICATE-----\n" + "MIIBjzCCARWgAwIBAgIBAjAKBggqhkjOPQQDAzAUMRIwEAYDVQQDDAlwMzg0LnRl\n" + "c3QwHhcNMjUwMTAxMDAwMDAwWhcNMzAwMTAxMDAwMDAwWjAUMRIwEAYDVQQDDAlw\n" + "Mzg0LnRlc3QwdjAQBgcqhkjOPQIBBgUrgQQAIgNiAAQN7YsHxPPMDkG+FJ/BoQFZ\n" + "iM0A3NY5RbJbIXX/0iOyequPyOqu8Mly/SNQTHu9zUFezlNxroKowLvipPcCBqX0\n" + "Fh/dEuzKdIS3JYa+IZi7B8c9X08zDsYu9K6w4+tsQf+jOzA5MAwGA1UdEwEB/wQC\n" + "MAAwFAYDVR0RBA0wC4IJcDM4NC50ZXN0MBMGA1UdJQQMMAoGCCsGAQUFBwMBMAoG\n" + "CCqGSM49BAMDA2gAMGUCMQCzuFGZ+otJVilqEid6Cp2qm09R8/XAggZKv/BWdIkx\n" + "cytCxMqMgVMjLJai/L145HICMCTL6kr17XVpxIFgZJYVIW5gvHUH2/L/5qGirtxX\n" + "Mw5JE45iq16UnChyMmQoxYD9XA==\n" + "-----END CERTIFICATE-----\n"
        ed_pem = "-----BEGIN CERTIFICATE-----\n" + "MIIBCzCBvqADAgECAgEDMAUGAytlcDASMRAwDgYDVQQDDAdlZC50ZXN0MB4XDTI1\n" + "MDEwMTAwMDAwMFoXDTMwMDEwMTAwMDAwMFowEjEQMA4GA1UEAwwHZWQudGVzdDAq\n" + "MAUGAytlcAMhADwgYcwt5uAE05LKMMZaxPUqcfDkcYQrJSjFzrCAOQwaozkwNzAM\n" + "BgNVHRMBAf8EAjAAMBIGA1UdEQQLMAmCB2VkLnRlc3QwEwYDVR0lBAwwCgYIKwYB\n" + "BQUHAwEwBQYDK2VwA0EAt7s0zYTktgQRJv5qOSfzFieWxjGcTw8yV6vRfcaESdpa\n" + "ZhEnvm5qwFVC7LgK/rs0GLSccgBKGNPNV1hLFLxTBQ==\n" + "-----END CERTIFICATE-----\n"
        leaf_pem = "-----BEGIN CERTIFICATE-----\n" + "MIICQjCCASqgAwIBAgIBBDANBgkqhkiG9w0BAQsFADAZMRcwFQYDVQQDDA5SaWRn\n" + "dW4gVGVzdCBDQTAeFw0yNTAxMDEwMDAwMDBaFw0zMDAxMDEwMDAwMDBaMBQxEjAQ\n" + "BgNVBAMMCWxlYWYudGVzdDB2MBAGByqGSM49AgEGBSuBBAAiA2IABA3tiwfE88wO\n" + "Qb4Un8GhAVmIzQDc1jlFslshdf/SI7J6q4/I6q7wyXL9I1BMe73NQV7OU3GugqjA\n" + "u+Kk9wIGpfQWH90S7Mp0hLclhr4hmLsHxz1fTzMOxi70rrDj62xB/6NIMEYwDAYD\n" + "VR0TAQH/BAIwADAhBgNVHREEGjAYgglsZWFmLnRlc3SCCyoubGVhZi50ZXN0MBMG\n" + "A1UdJQQMMAoGCCsGAQUFBwMBMA0GCSqGSIb3DQEBCwUAA4IBAQBxD/RWuxNKchIB\n" + "j/IBryFHERjKQjUHOGbf/L+AWMgwbMsPSQPpLTZFNQa8222Dm0Jx958JJZ4vufSu\n" + "wNRvh2nFSQ9xg8KGWbdV6gmaI7eMz7kluu8RcHayhObhPyQccCHKGCgSjeIsndjD\n" + "Ezp/OqdfFpmNMDB1WyGNLzuNVupb62x3Q+9EXD4se/1w9sfePqZzRyyJ2duJ+Rc2\n" + "gbUueCot7UGAq7/z9wzg4ouIiXvW7SP+/p9NCtuEjN9X5+qybKTb+f8eKmkthywd\n" + "iPtPwwS1q+rGiPev69clnhkB03RLxQbDYWorYbOrqNy8/qVtAvTgMry8guQHRCnf\n" + "wZSHzFQS\n" + "-----END CERTIFICATE-----\n"
        ok_ca, ca_c = x509 parse cert (c nth str (pem decode blocks ca_pem "CERTIFICATE") 0)
        assert true ok_ca "x509 parse RSA CA" -> ()
        assert str eq (key_alg ca_c) "rsa" "RSA SPKI key_alg" -> ()
        assert str eq (bytes to hex str (pubkey_bytes ca_c)) "c602350d97a36b3342f59b62741c4657de7edb6e7095733a548eeef5c3e99244df3ae1712743860e457eaf4e3bbccdab5b75713b49cdba1927010da5958091510f9f2ff87c0e01868b51dfb47a08fda7df71f4917870444e7485368d202824d76668e50e55fe43135f681ab7a41cc84eef2dee276997ef324b9267bfb1a83f8fa8f209bb42928d74435073e9f5a3eb27925aa7306744bc3b8a3f34a6b78b5f945c3aa5e0d5907f60666fdeca9524f3be2a9963128e92bff579953b6b6acfeeb5fc361b64a46fe8310731d69d531899744ef905024030c860793440c7e6a8f4ad5da70508d90b1505b3b30e27f77cabfe47794909bd44cf0af57358fbe280f9d1" "RSA SPKI modulus" -> ()
        assert str eq (bytes to hex str (rsa_exp_bytes ca_c)) "010001" "RSA SPKI exponent" -> ()
        assert str eq (sig_alg ca_c) "rsa_pkcs1_sha384" "RSA CA sig_alg" -> ()
        assert true (is_ca ca_c) "RSA CA basicConstraints" -> ()
        assert true (x509 verify cert sig ca_c ca_c) "RSA CA self-signature" -> ()
        ok_p, p_c = x509 parse cert (c nth str (pem decode blocks p384_pem "CERTIFICATE") 0)
        assert true ok_p "x509 parse P-384 cert" -> ()
        assert str eq (key_alg p_c) "ec_p384" "P-384 SPKI key_alg" -> ()
        assert str eq (sig_alg p_c) "ecdsa_sha384" "P-384 sig_alg" -> ()
        assert false (is_ca p_c) "P-384 leaf is not CA" -> ()
        assert true (x509 verify cert sig p_c p_c) "P-384 self-signature" -> ()
        ok_d, d_c = x509 parse cert (c nth str (pem decode blocks ed_pem "CERTIFICATE") 0)
        assert true ok_d "x509 parse Ed25519 cert" -> ()
        assert str eq (key_alg d_c) "ed25519" "Ed25519 SPKI key_alg" -> ()
        assert eq (str len (pubkey_bytes d_c)) 32 -> ()
        assert true (x509 verify cert sig d_c d_c) "Ed25519 self-signature" -> ()
        ok_l, l_c = x509 parse cert (c nth str (pem decode blocks leaf_pem "CERTIFICATE") 0)
        assert true ok_l "x509 parse CA-signed leaf" -> ()
        assert str eq (issuer_cn l_c) "Ridgun Test CA" "leaf issuer CN" -> ()
        assert str eq (issuer_der l_c) (subject_der ca_c) "leaf issuer == CA subject" -> ()
        assert true (x509 verify cert sig l_c ca_c) "leaf signed by RSA CA" -> ()
        assert false (x509 verify cert sig l_c p_c) "leaf signature rejected with wrong issuer key" -> ()
        assert true (x509 match hostname l_c "www.leaf.test") "leaf wildcard SAN" -> ()
        assert false (x509 match hostname l_c "other.test") "leaf rejects unrelated host" -> ()
        assert eq (not_after_at l_c) 1893456000 -> ()
        two = pem decode blocks (ca_pem + leaf_pem) "CERTIFICATE"
        assert eq (c str list len two 0) 2 -> ()


fn :: main => ()
      main =
        test rgf019 bytes and bitops -> ()
        test sha256 hmac and pbkdf2 -> ()
        test argon2id five arg and perf -> ()
        test rfc8439 chacha20 poly1305 aead -> ()
        test sha512 fips vectors -> ()
        test ed25519 rfc8032 vectors and negatives -> ()
        test minisign roundtrip and tamper -> ()
        test sha384 hkdf x25519 aes128gcm -> ()
        test p256 p384 rsa and x509 -> ()
        test crypto006 edge cases and certs -> ()
        echo "[PASS] test_crypto: TS-CRYPTO-003, TS-CRYPTO-004, TS-CRYPTO-005, TS-CRYPTO-006, and TS-PERF-001 passed"
