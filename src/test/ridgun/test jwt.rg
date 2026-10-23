-- ============================================================
-- src/test/ridgun/test jwt.rg
-- Automated unit tests for jwt.rg (RFC 7519 HS256 JWT & AEAD Tokens)
-- @tests TS-JWT-001
-- ============================================================

import test
import jwt

fn :: is_jwt_ok JwtRes     => Bool
      is_jwt_ok (JwtOk _)  =  True
      is_jwt_ok (JwtErr _) =  False

fn :: unwrap_jwt JwtRes     => String
      unwrap_jwt (JwtOk s)  =  s
      unwrap_jwt (JwtErr _) =  ""

fn :: is_claims_ok JwtClaimsRes     => Bool
      is_claims_ok (JwtClaimsOk _)  =  True
      is_claims_ok (JwtClaimsErr _) =  False

fn :: unwrap_claims JwtClaimsRes     => JwtClaims
      unwrap_claims (JwtClaimsOk c)  =  c
      unwrap_claims (JwtClaimsErr _) =  JwtClaims "" "" 0 0 ""

-- @tests TS-JWT-001
fn :: test_jwt_hs256_sign_verify_and_tamper => ()
      test_jwt_hs256_sign_verify_and_tamper =
        payload = '{"sub":"user-42","role":"admin"}'
        secret = "super-secret-hmac-key-2026"
        tok = jwt sign hs256 payload secret

        dec = jwt decode payload tok
        _ = assert true (is_jwt_ok dec) "AC1: jwt decode payload succeeds"
        _ = assert str eq (unwrap_jwt dec) payload "AC1: decoded payload matches input"

        ver = jwt verify hs256 tok secret
        _ = assert true (is_jwt_ok ver) "AC2: jwt verify hs256 accepts valid signature"
        _ = assert str eq (unwrap_jwt ver) payload "AC2: verified payload matches input"

        wrong_sec = jwt verify hs256 tok "wrong-secret"
        _ = assert false (is_jwt_ok wrong_sec) "AC2: jwt verify hs256 rejects wrong secret"

        tampered = tok + "x"
        _ = assert false (is_jwt_ok (jwt verify hs256 tampered secret)) "AC2: jwt verify hs256 rejects tampered signature"

        alg_none_tok = "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiJ1c2VyLTQyIn0.c2ln"
        _ = assert false (is_jwt_ok (jwt verify hs256 alg_none_tok secret)) "AC2: jwt verify hs256 rejects alg:none"
        ()

-- @tests TS-JWT-001
fn :: test_jwt_claims_temporal_validation => ()
      test_jwt_claims_temporal_validation =
        claims = JwtClaims "ridgun-auth" "agent-007" 2000 1000 "tier=gold"
        secret = "claims-signing-secret"
        tok = jwt sign claims claims secret

        ok_res = jwt verify claims tok secret 1500
        _ = assert true (is_claims_ok ok_res) "AC2: claims valid at now=1500"
        c_out = unwrap_claims ok_res
        _ = assert str eq (issuer c_out) "ridgun-auth" "AC2: issuer preserved"
        _ = assert str eq (subject c_out) "agent-007" "AC2: subject preserved"
        _ = assert int equals (expires_at c_out) 2000 "AC2: expires_at preserved"
        _ = assert str eq (custom_json c_out) "tier=gold" "AC2: custom_json preserved"

        early_res = jwt verify claims tok secret 999
        _ = assert false (is_claims_ok early_res) "AC2: claims rejected before nbf (999 < 1000)"

        exp_res = jwt verify claims tok secret 2000
        _ = assert false (is_claims_ok exp_res) "AC2: claims rejected at/after exp (2000 >= 2000)"
        ()

-- @tests TS-JWT-001
fn :: test_jwt_aead_seal_and_open => ()
      test_jwt_aead_seal_and_open =
        key32 = "0123456789abcdef0123456789abcdef"
        nonce12 = "uniqueNonce1"
        secret_msg = '{"api_key":"rk_live_998877","scope":"full"}'

        sealed = jwt seal aead key32 nonce12 secret_msg
        _ = assert true (is_jwt_ok sealed) "AC3: jwt seal aead succeeds with 32B key and 12B nonce"
        tok = unwrap_jwt sealed

        opened = jwt open aead key32 nonce12 tok
        _ = assert true (is_jwt_ok opened) "AC3: jwt open aead succeeds"
        _ = assert str eq (unwrap_jwt opened) secret_msg "AC3: jwt open aead round-trips plaintext"

        bad_open = jwt open aead key32 nonce12 (tok + "A")
        _ = assert false (is_jwt_ok bad_open) "AC3: jwt open aead rejects tampered token"

        bad_key = jwt seal aead "short" nonce12 secret_msg
        _ = assert false (is_jwt_ok bad_key) "AC3: jwt seal aead rejects non-32B key"
        ()

-- @tests TS-JWT-001
fn :: main => ()
      main =
        _ = test_jwt_hs256_sign_verify_and_tamper
        _ = test_jwt_claims_temporal_validation
        _ = test_jwt_aead_seal_and_open
        echo "[PASS] test jwt: TS-JWT-001 passed"
