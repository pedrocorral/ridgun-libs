-- ============================================================
-- src/test/ridgun/test jwt.rg
-- Comprehensive test suite for jwt.rg inspired by Rust jsonwebtoken & RFC 7519 security vectors
-- @tests TS-JWT-001
-- ============================================================

import test
import jwt

fn :: is jwt ok JwtRes     => Bool
      is jwt ok (JwtOk _)  =  True
      is jwt ok (JwtErr _) =  False

fn :: unwrap jwt JwtRes     => String
      unwrap jwt (JwtOk s)  =  s
      unwrap jwt (JwtErr _) =  ""

fn :: is claims ok JwtClaimsRes     => Bool
      is claims ok (JwtClaimsOk _)  =  True
      is claims ok (JwtClaimsErr _) =  False

fn :: unwrap claims JwtClaimsRes     => JwtClaims
      unwrap claims (JwtClaimsOk c)  =  c
      unwrap claims (JwtClaimsErr _) =  JwtClaims "" "" 0 0 ""

-- 1. RFC 7519 HS256 signing, verification, alg:none defense, and structural/tamper rejection
-- @tests TS-JWT-001
fn :: test jwt hs256 sign verify and tamper => ()
      test jwt hs256 sign verify and tamper =
        payload = '{"sub":"user-42","role":"admin"}'
        secret = "super-secret-hmac-key-2026"
        tok = jwt sign hs256 payload secret

        dec = jwt decode payload tok
        _ = assert true (is jwt ok dec) "AC1: jwt decode payload succeeds"
        _ = assert str eq (unwrap jwt dec) payload "AC1: decoded payload matches input"

        ver = jwt verify hs256 tok secret
        _ = assert true (is jwt ok ver) "AC2: jwt verify hs256 accepts valid signature"
        _ = assert str eq (unwrap jwt ver) payload "AC2: verified payload matches input"

        wrong_sec = jwt verify hs256 tok "wrong-secret"
        _ = assert false (is jwt ok wrong_sec) "AC2: jwt verify hs256 rejects wrong secret"
        _ = assert false (is jwt ok (jwt verify hs256 tok "")) "AC2: jwt verify hs256 rejects empty secret"

        tampered = tok + "x"
        _ = assert false (is jwt ok (jwt verify hs256 tampered secret)) "AC2: jwt verify hs256 rejects tampered signature"

        -- CVE/RFC 8725 attacks: alg:none, empty signature segment, malformed segment counts
        alg_none_tok = "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiJ1c2VyLTQyIn0.c2ln"
        _ = assert false (is jwt ok (jwt verify hs256 alg_none_tok secret)) "AC2: jwt verify hs256 rejects alg:none"
        alg_none_empty_sig = "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiJ1c2VyLTQyIn0."
        _ = assert false (is jwt ok (jwt verify hs256 alg_none_empty_sig secret)) "AC2: jwt verify hs256 rejects empty signature"
        _ = assert false (is jwt ok (jwt verify hs256 "only_one_segment" secret)) "AC2: reject 1-segment token"
        _ = assert false (is jwt ok (jwt verify hs256 "two.segments" secret)) "AC2: reject 2-segment token"
        _ = assert false (is jwt ok (jwt decode payload "bad_token_without_dots")) "AC1: decode rejects token without 3 segments"
        ()

-- 2. Temporal claim boundaries (nbf inclusive, exp exclusive, exact boundary checks)
-- @tests TS-JWT-001
fn :: test jwt claims temporal validation => ()
      test jwt claims temporal validation =
        claims = JwtClaims "ridgun-auth" "agent-007" 2000 1000 "tier=gold"
        secret = "claims-signing-secret"
        tok = jwt sign claims claims secret

        -- Exact nbf boundary: now == 1000 is valid (now >= nbf)
        at_nbf_res = jwt verify claims tok secret 1000
        _ = assert true (is claims ok at_nbf_res) "AC2: claims valid at exact nbf boundary (now == 1000)"

        ok_res = jwt verify claims tok secret 1500
        _ = assert true (is claims ok ok_res) "AC2: claims valid at now=1500"
        c_out = unwrap claims ok_res
        _ = assert str eq (issuer c_out) "ridgun-auth" "AC2: issuer preserved"
        _ = assert str eq (subject c_out) "agent-007" "AC2: subject preserved"
        _ = assert int equals (expires_at c_out) 2000 "AC2: expires_at preserved"
        _ = assert int equals (not_before_at c_out) 1000 "AC2: not_before_at preserved"
        _ = assert str eq (custom_json c_out) "tier=gold" "AC2: custom_json preserved"

        -- 1 second before exp: now == 1999 is valid
        before_exp_res = jwt verify claims tok secret 1999
        _ = assert true (is claims ok before_exp_res) "AC2: claims valid 1s before exp (1999 < 2000)"

        -- 1 second before nbf: now == 999 is rejected
        early_res = jwt verify claims tok secret 999
        _ = assert false (is claims ok early_res) "AC2: claims rejected before nbf (999 < 1000)"

        -- Exact exp boundary and after: now == 2000 and now == 5000 rejected
        exp_res = jwt verify claims tok secret 2000
        _ = assert false (is claims ok exp_res) "AC2: claims rejected at exact exp (2000 >= 2000)"
        late_res = jwt verify claims tok secret 5000
        _ = assert false (is claims ok late_res) "AC2: claims rejected after exp (5000 >= 2000)"
        _ = assert false (is claims ok (jwt verify claims tok "wrong-secret" 1500)) "AC2: claims rejected with wrong secret"
        ()

-- 3. ChaCha20-Poly1305 AEAD encrypted token sealing, opening, wrong key/nonce, and key/nonce size validation
-- @tests TS-JWT-001
fn :: test jwt aead seal and open => ()
      test jwt aead seal and open =
        key32 = "0123456789abcdef0123456789abcdef"
        other_key32 = "fedcba9876543210fedcba9876543210"
        nonce12 = "uniqueNonce1"
        other_nonce12 = "uniqueNonce2"
        secret_msg = '{"api_key":"rk_live_998877","scope":"full"}'

        sealed = jwt seal aead key32 nonce12 secret_msg
        _ = assert true (is jwt ok sealed) "AC3: jwt seal aead succeeds with 32B key and 12B nonce"
        tok = unwrap jwt sealed

        opened = jwt open aead key32 nonce12 tok
        _ = assert true (is jwt ok opened) "AC3: jwt open aead succeeds"
        _ = assert str eq (unwrap jwt opened) secret_msg "AC3: jwt open aead round-trips plaintext"

        _ = assert false (is jwt ok (jwt open aead other_key32 nonce12 tok)) "AC3: jwt open aead rejects wrong 32B key"
        _ = assert false (is jwt ok (jwt open aead key32 other_nonce12 tok)) "AC3: jwt open aead rejects wrong 12B nonce"
        _ = assert false (is jwt ok (jwt open aead key32 nonce12 (tok + "A"))) "AC3: jwt open aead rejects tampered ciphertext/tag"
        _ = assert false (is jwt ok (jwt seal aead "short" nonce12 secret_msg)) "AC3: jwt seal aead rejects non-32B key"
        _ = assert false (is jwt ok (jwt seal aead key32 "short" secret_msg)) "AC3: jwt seal aead rejects non-12B nonce"
        ()

-- 4. Byte-level Base64url over Tensor[U8] (ADR-0010) and UTF-8 payloads round-trip byte for byte
-- @tests TS-JWT-001
fn :: test jwt bytes and utf8 round trip => ()
      test jwt bytes and utf8 round trip =
        bs = Tensor[U8 * 3]
        bs_(1) = 128
        bs_(2) = 255
        enc = jwt b64url enc bytes bs
        _ = assert str eq enc "AID_" "AC1: Base64url of bytes [0, 128, 255]"
        dec = jwt b64url decode bytes enc
        _ = assert true (dec == bs) "AC1: Base64url decode gives bytes [0, 128, 255]"
        _ = assert str eq (jwt b64url encode "foobar") "Zm9vYmFy" "AC1: RFC 4648 vector foobar"
        _ = assert str eq (jwt b64url decode "Zm9vYg") "foob" "AC1: RFC 4648 vector foob, unpadded"

        utf8_payload = '{"name":"José"}'
        tok = jwt sign hs256 utf8_payload "utf8-secret"
        _ = assert str eq (unwrap jwt (jwt verify hs256 tok "utf8-secret")) utf8_payload "AC2: UTF-8 payload verifies byte for byte"
        _ = assert str eq (unwrap jwt (jwt decode payload tok)) utf8_payload "AC1: UTF-8 payload decodes byte for byte"

        key32 = "0123456789abcdef0123456789abcdef"
        nonce12 = "uniqueNonce1"
        utf8_msg = "ñandú-ü-€"
        sealed = unwrap jwt (jwt seal aead key32 nonce12 utf8_msg)
        _ = assert str eq (unwrap jwt (jwt open aead key32 nonce12 sealed)) utf8_msg "AC3: UTF-8 plaintext round-trips byte for byte"
        ()

-- 5. Standard vectors: HS256 is RFC 2104 HMAC-SHA256 and the AEAD is RFC 8439 ChaCha20-Poly1305
-- @tests TS-JWT-001
fn :: jwt token part JwtRes Int => String
      jwt token part res i =
        tok = unwrap jwt res
        jwt str at (jwt split dots loop tok 0 (str len tok) 0 []) i

fn :: first n [Int] Int => [Int]
      first n []     _ = []
      first n _      0 = []
      first n (x:xs) n_ = [x] :: (first n xs (n_ - 1))

fn :: test jwt standard vectors => ()
      test jwt standard vectors =
        _ = assert str eq (jwt hmac sha256 b64url "Jefe" "what do ya want for nothing?") "W9zBRr9gdU5qBCQmCJV1x1oAPwidJzmDnexYuWTsOEM" "AC2: HMAC-SHA256 is RFC 4231 test case 2"

        rfc_key = jwt b64url decode "AyM1SysPpbyDfgZld3umj1qzKObwVMkoqQ-EstJQLr_T-1qS0gZH75aKtMN3Yj0iPS4hcgUuTwjAzZr1Z9CAow"
        rfc_in = "eyJ0eXAiOiJKV1QiLA0KICJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJqb2UiLA0KICJleHAiOjEzMDA4MTkzODAsDQogImh0dHA6Ly9leGFtcGxlLmNvbS9pc19yb290Ijp0cnVlfQ"
        rfc_sig = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
        _ = assert str eq (jwt hmac sha256 b64url rfc_key rfc_in) rfc_sig "AC2: RFC 7515 A.1 HS256 signature"
        rfc_res = jwt verify hs256 (rfc_in + "." + rfc_sig) rfc_key
        _ = assert true (is jwt ok rfc_res) "AC2: RFC 7515 A.1 token verifies"
        _ = assert true (str starts with (unwrap jwt rfc_res) '{"iss":"joe",') "AC2: RFC 7515 A.1 payload"

        key = bytes from list [128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159]
        nonce = bytes from list [7, 0, 0, 0, 64, 65, 66, 67, 68, 69, 70, 71]
        pt = "Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it."
        sealed = jwt seal aead key nonce pt
        _ = assert true (is jwt ok sealed) "AC3: jwt seal aead with the RFC 8439 key and nonce"
        ct = jwt b64url decode bytes (jwt token part sealed 2)
        ct_list = tensor to list ct
        _ = assert true ((first n ct_list 16) == [211, 26, 141, 52, 100, 142, 96, 219, 123, 134, 175, 188, 83, 239, 126, 194]) "AC3: ciphertext is RFC 8439 2.8.2 ChaCha20"
        aad = "RGAEAD2." + (jwt token part sealed 1)
        tag = jwt b64url decode (jwt token part sealed 3)
        _ = assert true ((aead seal key nonce aad pt) == ((tensor to str ct) + tag)) "AC3: token is RFC 8439 ChaCha20-Poly1305 over the version and nonce as AAD"
        _ = assert false (is jwt ok (jwt open aead key nonce ("RGAEAD1." + (jwt token part sealed 1) + "." + (jwt token part sealed 2) + "." + (jwt token part sealed 3)))) "AC3: tokens of the old RGAEAD1 format are rejected"
        ()

-- @tests TS-JWT-001
fn :: main => ()
      main =
        _ = test jwt hs256 sign verify and tamper
        _ = test jwt claims temporal validation
        _ = test jwt aead seal and open
        _ = test jwt bytes and utf8 round trip
        _ = test jwt standard vectors
        echo "[PASS] test jwt: TS-JWT-001 passed"
