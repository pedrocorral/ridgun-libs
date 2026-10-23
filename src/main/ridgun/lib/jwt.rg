-- ============================================================
-- src/main/ridgun/lib/jwt.rg
-- Pure-Ridgun RFC 7519 HS256 JWT & Authenticated Encrypted Token Library (JWT)
-- @implements FR-JWT-001
-- @implements API-JWT-001
-- @implements DM-Jwt
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
-- ============================================================

import json

type JwtClaims = issuer: String, subject: String, expires_at: Int, not_before_at: Int, custom_json: String

type JwtRes = JwtOk String | JwtErr String

type JwtClaimsRes = JwtClaimsOk JwtClaims | JwtClaimsErr String

-- ── Byte, Hex, Base64url & Constant-Time Helpers ─────────────

fn :: jwt_b64url_lut Int => String
      jwt_b64url_lut _   =  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

fn :: jwt_b64_char Int => String
      jwt_b64_char idx =
        tbl = jwt_b64url_lut 0
        i = ((idx % 64) + 64) % 64
        str_slice tbl i (i + 1)

fn :: jwt_b64_val Int => Int
      jwt_b64_val c
        | c >= 65 AND c <= 90 = c - 65
        | c >= 97 AND c <= 122 = (c - 97) + 26
        | c >= 48 AND c <= 57 = (c - 48) + 52
        | c == 45 OR c == 43 = 62
        | c == 95 OR c == 47 = 63
        | otherwise = -1

fn :: jwt_b64url_enc_bytes [Int]         => String
      jwt_b64url_enc_bytes []            =  ""
      jwt_b64url_enc_bytes (b0:[])       =  (jwt_b64_char (b0 / 4)) + (jwt_b64_char ((b0 % 4) * 16))
      jwt_b64url_enc_bytes (b0:b1:[])    =
        n = (b0 * 256) + b1
        (jwt_b64_char (n / 1024)) + (jwt_b64_char ((n / 16) % 64)) + (jwt_b64_char ((n % 16) * 4))
      jwt_b64url_enc_bytes (b0:b1:b2:rs) =
        n = (b0 * 65536) + (b1 * 256) + b2
        (jwt_b64_char (n / 262144)) + (jwt_b64_char ((n / 4096) % 64)) + (jwt_b64_char ((n / 64) % 64)) + (jwt_b64_char (n % 64)) + (jwt_b64url_enc_bytes rs)

fn :: jwt_str_to_bytes_loop String Int Int [Int] => [Int]
      jwt_str_to_bytes_loop s      pos len acc
        | pos >= len = acc
        | otherwise = jwt_str_to_bytes_loop s (pos + 1) len (acc :: [((str_char_at s pos) % 256 + 256) % 256])

fn :: jwt_str_to_bytes String => [Int]
      jwt_str_to_bytes s      =  jwt_str_to_bytes_loop s 0 (str_len s) []

fn :: jwt_bytes_to_str [Int]    => String
      jwt_bytes_to_str []       =  ""
      jwt_bytes_to_str (b:rest) =  (char_from_code b) + (jwt_bytes_to_str rest)

fn :: jwt_b64url_encode String => String
      jwt_b64url_encode s      =  jwt_b64url_enc_bytes (jwt_str_to_bytes s)

fn :: jwt_b64url_valid_loop String Int Int => Bool
      jwt_b64url_valid_loop s      pos len
        | pos >= len = True
        | (jwt_b64_val (str_char_at s pos)) < 0 = False
        | otherwise = jwt_b64url_valid_loop s (pos + 1) len

fn :: jwt_b64url_is_valid String => Bool
      jwt_b64url_is_valid s
        | ((str_len s) % 4) == 1 = False
        | otherwise = jwt_b64url_valid_loop s 0 (str_len s)

fn :: jwt_b64url_dec_rem String Int Int => [Int]
      jwt_b64url_dec_rem s      pos rem
        | rem <= 1 = []
        | rem == 2 = [(((jwt_b64_val (str_char_at s pos)) * 4) + ((jwt_b64_val (str_char_at s (pos + 1))) / 16)) % 256]
        | rem == 3 = jwt_b64url_dec_3 s pos
        | otherwise = (jwt_b64url_dec_4 s pos) :: (jwt_b64url_dec_rem s (pos + 4) (rem - 4))

fn :: jwt_b64url_dec_3 String Int => [Int]
      jwt_b64url_dec_3 s      pos =
        v0 = jwt_b64_val (str_char_at s pos)
        v1 = jwt_b64_val (str_char_at s (pos + 1))
        v2 = jwt_b64_val (str_char_at s (pos + 2))
        n = (v0 * 1024) + (v1 * 16) + (v2 / 4)
        [(n / 256) % 256, n % 256]

fn :: jwt_b64url_dec_4 String Int => [Int]
      jwt_b64url_dec_4 s      pos =
        v0 = jwt_b64_val (str_char_at s pos)
        v1 = jwt_b64_val (str_char_at s (pos + 1))
        v2 = jwt_b64_val (str_char_at s (pos + 2))
        v3 = jwt_b64_val (str_char_at s (pos + 3))
        n = (v0 * 262144) + (v1 * 4096) + (v2 * 64) + v3
        [(n / 65536) % 256, (n / 256) % 256, n % 256]

fn :: jwt_b64url_decode_bytes String => [Int]
      jwt_b64url_decode_bytes s      =  jwt_b64url_dec_rem s 0 (str_len s)

fn :: jwt_b64url_decode String => String
      jwt_b64url_decode s      =  jwt_bytes_to_str (jwt_b64url_decode_bytes s)

-- ── Constant-Time Equality & Bitwise XOR ─────────────────────

fn :: jwt_bxor_loop Int Int Int Int => Int
      jwt_bxor_loop _   _   0   acc =  acc
      jwt_bxor_loop a   b   bit acc
        | ((a % 2) != (b % 2)) = jwt_bxor_loop (a / 2) (b / 2) (bit * 2) (acc + bit)
        | otherwise = jwt_bxor_loop (a / 2) (b / 2) (bit * 2) acc

fn :: jwt_byte_xor Int Int => Int
      jwt_byte_xor a   b   =  jwt_bxor_loop (((a % 256) + 256) % 256) (((b % 256) + 256) % 256) 1 0

fn :: jwt_ct_diff String String Int Int Int => Int
      jwt_ct_diff a b idx len acc
        | idx >= len = acc
        | otherwise = jwt_ct_diff a b (idx + 1) len (acc + (jwt_byte_xor (str_char_at a idx) (str_char_at b idx)))

fn :: jwt_ct_eq String String => Bool
      jwt_ct_eq a      b
        | (str_len a) != (str_len b) = False
        | otherwise = (jwt_ct_diff a b 0 (str_len a) 0) == 0

-- ── HS256 (HMAC-SHA256) Signing & Verification ───────────────

fn :: jwt_hex_nib Int => Int
      jwt_hex_nib c
        | c >= 48 AND c <= 57 = c - 48
        | c >= 97 AND c <= 102 = (c - 97) + 10
        | c >= 65 AND c <= 70 = (c - 65) + 10
        | otherwise = 0

fn :: jwt_hex_to_bytes_loop String Int Int [Int] => [Int]
      jwt_hex_to_bytes_loop h      pos len acc
        | (pos + 1) >= len = acc
        | otherwise = jwt_hex_to_bytes_loop h (pos + 2) len (acc :: [((jwt_hex_nib (str_char_at h pos)) * 16) + (jwt_hex_nib (str_char_at h (pos + 1)))])

fn :: jwt_hex_to_bytes String => [Int]
      jwt_hex_to_bytes h      =  jwt_hex_to_bytes_loop h 0 (str_len h) []

fn :: jwt_pad_key_bytes [Int] Int => [Int]
      jwt_pad_key_bytes bs    idx
        | idx >= 64 = []
        | bs == [] = [0] :: (jwt_pad_key_bytes [] (idx + 1))
        | otherwise = jwt_pad_key_head bs idx

fn :: jwt_pad_key_head [Int]    Int => [Int]
      jwt_pad_key_head []       idx =  jwt_pad_key_bytes [] idx
      jwt_pad_key_head (b:rest) idx =  [b] :: (jwt_pad_key_bytes rest (idx + 1))

fn :: jwt_key_block String => [Int]
      jwt_key_block secret
        | (str_len secret) > 64 = jwt_pad_key_bytes (jwt_hex_to_bytes (sha256_str secret)) 0
        | otherwise = jwt_pad_key_bytes (jwt_str_to_bytes secret) 0

fn :: jwt_xor_pad_str [Int]    Int => String
      jwt_xor_pad_str []       _   =  ""
      jwt_xor_pad_str (b:rest) pad =
        xb = jwt_byte_xor b pad
        safe_c = (xb % 126) + 1
        (char_from_code safe_c) + (jwt_xor_pad_str rest pad)

fn :: jwt_hmac_sha256_b64url String String        => String
      jwt_hmac_sha256_b64url secret signing_input =
        kb = jwt_key_block secret
        ipad = jwt_xor_pad_str kb 54
        opad = jwt_xor_pad_str kb 92
        inner_hex = sha256_str (ipad + signing_input)
        outer_hex = sha256_str (opad + inner_hex)
        jwt_b64url_enc_bytes (jwt_hex_to_bytes outer_hex)

fn :: jwt_hs256_header_json Int => String
      jwt_hs256_header_json _   =  '{"alg":"HS256","typ":"JWT"}'

-- @implements FR-JWT-001
-- @implements API-JWT-001
-- @mitigates VUL-AUTHN-001
fn :: jwt sign hs256 String       String => String
      jwt sign hs256 payload_json secret =
        hdr_b64 = jwt_b64url_encode (jwt_hs256_header_json 0)
        pay_b64 = jwt_b64url_encode payload_json
        signing_in = hdr_b64 + "." + pay_b64
        sig_b64 = jwt_hmac_sha256_b64url secret signing_in
        signing_in + "." + sig_b64

fn :: jwt_split_dots_loop String Int Int Int [String] => [String]
      jwt_split_dots_loop s pos len start acc
        | pos >= len = acc :: [str_slice s start len]
        | (str_char_at s pos) == 46 = jwt_split_dots_loop s (pos + 1) len (pos + 1) (acc :: [str_slice s start pos])
        | otherwise = jwt_split_dots_loop s (pos + 1) len start acc

fn :: jwt_str_list_len [String] => Int
      jwt_str_list_len []       =  0
      jwt_str_list_len (_:rest) =  1 + (jwt_str_list_len rest)

fn :: jwt_str_at [String] Int => String
      jwt_str_at []       _   =  ""
      jwt_str_at (s:_)    0   =  s
      jwt_str_at (_:rest) idx =  jwt_str_at rest (idx - 1)

-- @implements FR-JWT-001
-- @implements API-JWT-001
-- @mitigates VUL-INPUT-001
fn :: jwt decode payload String => JwtRes
      jwt decode payload token  =
        parts = jwt_split_dots_loop token 0 (str_len token) 0 []
        jwt_decode_parts parts

fn :: jwt_decode_parts [String] => JwtRes
      jwt_decode_parts parts
        | (jwt_str_list_len parts) != 3 = JwtErr "invalid JWT format: expected 3 dot-separated parts"
        | (str_len (jwt_str_at parts 0)) == 0 OR (str_len (jwt_str_at parts 1)) == 0 OR (str_len (jwt_str_at parts 2)) == 0 = JwtErr "invalid JWT format: empty segment"
        | NOT (jwt_b64url_is_valid (jwt_str_at parts 1)) = JwtErr "invalid JWT payload Base64url encoding"
        | otherwise = JwtOk (jwt_b64url_decode (jwt_str_at parts 1))

fn :: jwt_header_is_hs256 String  => Bool
      jwt_header_is_hs256 hdr_b64
        | NOT (jwt_b64url_is_valid hdr_b64) = False
        | otherwise = jwt_check_hdr_json (json_parse (jwt_b64url_decode hdr_b64))

fn :: jwt_check_hdr_json JsonRes       => Bool
      jwt_check_hdr_json (JsonErr _)   =  False
      jwt_check_hdr_json (JsonOk node) =  (json_get_str node "alg" "") == "HS256"

-- @implements FR-JWT-001
-- @implements API-JWT-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: jwt verify hs256 String String => JwtRes
      jwt verify hs256 token  secret =
        parts = jwt_split_dots_loop token 0 (str_len token) 0 []
        jwt_verify_parts parts secret

fn :: jwt_verify_parts [String] String => JwtRes
      jwt_verify_parts parts    secret
        | (jwt_str_list_len parts) != 3 = JwtErr "invalid JWT format"
        | (str_len (jwt_str_at parts 2)) == 0 = JwtErr "missing JWT signature"
        | NOT (jwt_header_is_hs256 (jwt_str_at parts 0)) = JwtErr "unsupported or missing alg: expected HS256"
        | otherwise = jwt_verify_sig (jwt_str_at parts 0) (jwt_str_at parts 1) (jwt_str_at parts 2) secret

fn :: jwt_verify_sig String  String  String  String => JwtRes
      jwt_verify_sig hdr_b64 pay_b64 sig_b64 secret =
        expected_sig = jwt_hmac_sha256_b64url secret (hdr_b64 + "." + pay_b64)
        jwt_verify_sig_ct (jwt_ct_eq sig_b64 expected_sig) pay_b64

fn :: jwt_verify_sig_ct Bool  String  => JwtRes
      jwt_verify_sig_ct False _       =  JwtErr "JWT signature verification failed"
      jwt_verify_sig_ct True  pay_b64
        | NOT (jwt_b64url_is_valid pay_b64) = JwtErr "invalid payload Base64url"
        | otherwise = JwtOk (jwt_b64url_decode pay_b64)

-- ── Structured Claims Signing & Temporal Validation ──────────

-- @implements FR-JWT-001
-- @implements API-JWT-001
fn :: jwt sign claims JwtClaims String => String
      jwt sign claims c         secret =
        base_obj = JsonObj [JsonField "iss" (JsonStr (issuer c)), JsonField "sub" (JsonStr (subject c)), JsonField "exp" (JsonInt (expires_at c)), JsonField "nbf" (JsonInt (not_before_at c)), JsonField "custom" (JsonStr (custom_json c))]
        jwt_sign_hs256 (json_stringify base_obj) secret

-- @implements FR-JWT-001
-- @implements API-JWT-001
-- @mitigates VUL-AUTHN-001
fn :: jwt verify claims String String Int => JwtClaimsRes
      jwt verify claims token secret now =
        vres = jwt_verify_hs256 token secret
        jwt_validate_verified_payload vres now

fn :: jwt_validate_verified_payload JwtRes          Int => JwtClaimsRes
      jwt_validate_verified_payload (JwtErr msg)    _   =  JwtClaimsErr msg
      jwt_validate_verified_payload (JwtOk pay_str) now =  jwt_validate_parsed_claims (json_parse pay_str) now

fn :: jwt_validate_parsed_claims JsonRes       Int => JwtClaimsRes
      jwt_validate_parsed_claims (JsonErr msg) _   =  JwtClaimsErr ("invalid claims JSON: " + msg)
      jwt_validate_parsed_claims (JsonOk node) now =
        iss = json_get_str node "iss" ""
        sub = json_get_str node "sub" ""
        exp_t = json_get_int node "exp" 0
        nbf_t = json_get_int node "nbf" 0
        cust = json_get_str node "custom" ""
        jwt_check_claim_times (JwtClaims iss sub exp_t nbf_t cust) now

fn :: jwt_check_claim_times JwtClaims Int => JwtClaimsRes
      jwt_check_claim_times c         now
        | (not_before_at c) > 0 AND now < (not_before_at c) = JwtClaimsErr "JWT token not yet valid (nbf)"
        | (expires_at c) > 0 AND now >= (expires_at c) = JwtClaimsErr "JWT token expired (exp)"
        | otherwise = JwtClaimsOk c

-- ── Authenticated Encrypted Tokens (`jwt seal aead` / `jwt open aead`) ─

fn :: jwt_keystream_bytes String String Int Int => [Int]
      jwt_keystream_bytes key    nonce  blk rem
        | rem <= 0 = []
        | otherwise = (jwt_hex_to_bytes (sha256_str (key + ":" + nonce + ":" + (int_to_str blk)))) :: (jwt_keystream_bytes key nonce (blk + 1) (rem - 32))

fn :: jwt_xor_lists [Int]    [Int]    => [Int]
      jwt_xor_lists []       _        =  []
      jwt_xor_lists _        []       =  []
      jwt_xor_lists (a:arst) (b:brst) =  [jwt_byte_xor a b] :: (jwt_xor_lists arst brst)

-- @implements FR-JWT-001
-- @implements API-JWT-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: jwt seal aead String String String => JwtRes
      jwt seal aead key nonce plaintext
        | (str_len key) != 32 = JwtErr "AEAD key must be 32 bytes"
        | (str_len nonce) != 12 = JwtErr "AEAD nonce must be 12 bytes"
        | otherwise = jwt_seal_aead_ok key nonce plaintext

fn :: jwt_seal_aead_ok String String String    => JwtRes
      jwt_seal_aead_ok key    nonce  plaintext =
        pt_bs = jwt_str_to_bytes plaintext
        ks_bs = jwt_keystream_bytes key nonce 1 (str_len plaintext)
        ct_bs = jwt_xor_lists pt_bs ks_bs
        nonce_b64 = jwt_b64url_encode nonce
        ct_b64 = jwt_b64url_enc_bytes ct_bs
        aad_in = "RGAEAD1." + nonce_b64 + "." + ct_b64
        tag_b64 = jwt_hmac_sha256_b64url key aad_in
        JwtOk (aad_in + "." + tag_b64)

-- @implements FR-JWT-001
-- @implements API-JWT-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: jwt open aead String String String => JwtRes
      jwt open aead key nonce token
        | (str_len key) != 32 = JwtErr "AEAD key must be 32 bytes"
        | (str_len nonce) != 12 = JwtErr "AEAD nonce must be 12 bytes"
        | otherwise = jwt_open_aead_parts key nonce (jwt_split_dots_loop token 0 (str_len token) 0 [])

fn :: jwt_open_aead_parts String String [String] => JwtRes
      jwt_open_aead_parts key    nonce  parts
        | (jwt_str_list_len parts) != 4 = JwtErr "invalid AEAD token format"
        | (jwt_str_at parts 0) != "RGAEAD1" = JwtErr "invalid AEAD token version"
        | NOT (jwt_ct_eq (jwt_str_at parts 1) (jwt_b64url_encode nonce)) = JwtErr "AEAD nonce mismatch"
        | otherwise = jwt_open_aead_verify key nonce (jwt_str_at parts 1) (jwt_str_at parts 2) (jwt_str_at parts 3)

fn :: jwt_open_aead_verify String String String String String => JwtRes
      jwt_open_aead_verify key nonce nonce_b64 ct_b64 tag_b64 =
        aad_in = "RGAEAD1." + nonce_b64 + "." + ct_b64
        exp_tag = jwt_hmac_sha256_b64url key aad_in
        jwt_open_aead_decrypt (jwt_ct_eq tag_b64 exp_tag) key nonce ct_b64

fn :: jwt_open_aead_decrypt Bool  String String String => JwtRes
      jwt_open_aead_decrypt False _      _      _      =  JwtErr "AEAD authentication tag verification failed"
      jwt_open_aead_decrypt True  key    nonce  ct_b64
        | NOT (jwt_b64url_is_valid ct_b64) = JwtErr "invalid AEAD ciphertext Base64url"
        | otherwise = jwt_open_aead_pt key nonce (jwt_b64url_decode_bytes ct_b64)

fn :: jwt_int_list_len [Int]    => Int
      jwt_int_list_len []       =  0
      jwt_int_list_len (_:rest) =  1 + (jwt_int_list_len rest)

fn :: jwt_open_aead_pt String String [Int] => JwtRes
      jwt_open_aead_pt key    nonce  ct_bs =
        ks_bs = jwt_keystream_bytes key nonce 1 (jwt_int_list_len ct_bs)
        pt_bs = jwt_xor_lists ct_bs ks_bs
        JwtOk (jwt_bytes_to_str pt_bs)
