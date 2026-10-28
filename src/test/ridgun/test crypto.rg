-- ============================================================
-- src/test/ridgun/test_crypto.rg
-- Test suite for crypto.rg (TS-CRYPTO-003, TS-CRYPTO-004, TS-PERF-001)
-- @tests TS-CRYPTO-003
-- @tests TS-CRYPTO-004
-- @tests TS-CRYPTO-005
-- @tests TS-PERF-001
-- ============================================================

import test
import posix
import crypto

fn :: range bytes Int Int => [Int]
      range bytes cur hi  =
        | cur > hi  = []
        | otherwise = [cur] :: (range bytes (cur + 1) hi)

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
        _    = assert int equals (c nth int rt 0) 0 "rt 0"
        _    = assert int equals (c nth int rt 1) 1 "rt 1"
        _    = assert int equals (c nth int rt 2) 127 "rt 2"
        _    = assert int equals (c nth int rt 3) 128 "rt 3"
        _    = assert int equals (c nth int rt 4) 255 "rt 4"
        b256 = bytes from list (range bytes 0 255)
        _    = assert int equals (str len b256) 256 "len b256 == 256"
        r256 = bytes to list b256
        _    = assert int equals (c list len r256) 256 "r256 list len == 256"
        _    = assert int equals (c nth int r256 0) 0 "r256[0] == 0"
        _    = assert int equals (c nth int r256 128) 128 "r256[128] == 128"
        _    = assert int equals (c nth int r256 255) 255 "r256[255] == 255"

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
      ten times s =
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
      ms kid (k, _) =  k

fn :: ms pk (String String) => String
      ms pk (_, p)  =  p

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

fn :: main => ()
      main =
        test rgf019 bytes and bitops -> ()
        test sha256 hmac and pbkdf2 -> ()
        test argon2id five arg and perf -> ()
        test rfc8439 chacha20 poly1305 aead -> ()
        test sha512 fips vectors -> ()
        test ed25519 rfc8032 vectors and negatives -> ()
        test minisign roundtrip and tamper -> ()
        echo "[PASS] test_crypto: TS-CRYPTO-003, TS-CRYPTO-004, TS-CRYPTO-005, and TS-PERF-001 passed"
