-- ============================================================
-- src/main/ridgun/lib/jwt.rg
-- Pure-Ridgun RFC 7519 HS256 JWT & Authenticated Encrypted Token Library (JWT)
-- @implements FR-JWT-001
-- @implements API-JWT-001
-- @implements DM-Jwt
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
-- ============================================================

module :: jwt

import json

type JwtClaims = issuer: String, subject: String, expires_at: Int, not_before_at: Int, custom_json: String

type JwtRes = JwtOk String | JwtErr String

type JwtClaimsRes = JwtClaimsOk JwtClaims | JwtClaimsErr String

-- ── Byte, Hex, Base64url & Constant-Time Helpers ─────────────

fn :: jwt b64url lut Int => String
      jwt b64url lut _ = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

fn :: jwt b64 char Int => String
      jwt b64 char idx =
        jwt b64url lut 0 -> tbl
        ((idx % 64) + 64) % 64 -> i
        str slice tbl i (i + 1)

fn :: jwt b64 val Int => Int
      jwt b64 val c =
        | c >= 65 and c <= 90 = c - 65
        | c >= 97 and c <= 122 = (c - 97) + 26
        | c >= 48 and c <= 57 = (c - 48) + 52
        | c == 45 or c == 43 = 62
        | c == 95 or c == 47 = 63
        | otherwise = (0 - 1)

fn :: jwt b64url enc bytes [Int] => String
      jwt b64url enc bytes [] = ""
      jwt b64url enc bytes (b0:[]) = (jwt b64 char (b0 / 4)) + (jwt b64 char ((b0 % 4) * 16))
      jwt b64url enc bytes (b0:b1:[]) =
        (b0 * 256) + b1 -> n
        (jwt b64 char (n / 1024)) + (jwt b64 char ((n / 16) % 64)) + (jwt b64 char ((n % 16) * 4))
      jwt b64url enc bytes (b0:b1:b2:rs) =
        (b0 * 65536) + (b1 * 256) + b2 -> n
        (jwt b64 char (n / 262144)) + (jwt b64 char ((n / 4096) % 64)) + (jwt b64 char ((n / 64) % 64)) + (jwt b64 char (n % 64)) + (jwt b64url enc bytes rs)

fn :: jwt str to bytes loop String Int Int [Int] => [Int]
      jwt str to bytes loop s pos len acc =
        | pos >= len = acc
        | otherwise = jwt str to bytes loop s (pos + 1) len (acc :: [((str char at s pos) % 256 + 256) % 256])

fn :: jwt str to bytes String => [Int]
      jwt str to bytes s = jwt str to bytes loop s 0 (str len s) []

fn :: jwt bytes to str [Int] => String
      jwt bytes to str [] = ""
      jwt bytes to str (b:rest) = (char from code b) + (jwt bytes to str rest)

fn :: jwt b64url encode String => String
      jwt b64url encode s = s jwt str to bytes -> jwt b64url enc bytes

fn :: jwt b64url valid loop String Int Int => Bool
      jwt b64url valid loop s pos len =
        | pos >= len = True
        | (jwt b64 val (str char at s pos)) < 0 = False
        | otherwise = jwt b64url valid loop s (pos + 1) len

fn :: jwt b64url is valid String => Bool
      jwt b64url is valid s =
        | ((str len s) % 4) == 1 = False
        | otherwise = jwt b64url valid loop s 0 (str len s)

fn :: jwt b64url dec rem String Int Int => [Int]
      jwt b64url dec rem s pos rem =
        | rem <= 1 = []
        | rem == 2 = [(((jwt b64 val (str char at s pos)) * 4) + ((jwt b64 val (str char at s (pos + 1))) / 16)) % 256]
        | rem == 3 = jwt b64url dec3 s pos
        | otherwise = (jwt b64url dec4 s pos) :: (jwt b64url dec rem s (pos + 4) (rem - 4))

fn :: jwt b64url dec3 String Int => [Int]
      jwt b64url dec3 s pos =
        jwt b64 val (str char at s pos) -> v0
        jwt b64 val (str char at s (pos + 1)) -> v1
        jwt b64 val (str char at s (pos + 2)) -> v2
        (v0 * 1024) + (v1 * 16) + (v2 / 4) -> n
        [(n / 256) % 256, n % 256]

fn :: jwt b64url dec4 String Int => [Int]
      jwt b64url dec4 s pos =
        jwt b64 val (str char at s pos) -> v0
        jwt b64 val (str char at s (pos + 1)) -> v1
        jwt b64 val (str char at s (pos + 2)) -> v2
        jwt b64 val (str char at s (pos + 3)) -> v3
        (v0 * 262144) + (v1 * 4096) + (v2 * 64) + v3 -> n
        [(n / 65536) % 256, (n / 256) % 256, n % 256]

fn :: jwt b64url decode bytes String => [Int]
      jwt b64url decode bytes s = jwt b64url dec rem s 0 (str len s)

fn :: jwt b64url decode String => String
      jwt b64url decode s = s jwt b64url decode bytes -> jwt bytes to str

-- ── Constant-Time Equality & Bitwise XOR ─────────────────────

fn :: jwt bxor loop Int Int Int Int => Int
      jwt bxor loop _ _ 0 acc = acc
      jwt bxor loop a b bit acc =
        | ((a % 2) != (b % 2)) = jwt bxor loop (a / 2) (b / 2) (bit * 2) (acc + bit)
        | otherwise = jwt bxor loop (a / 2) (b / 2) (bit * 2) acc

fn :: jwt byte bxor Int Int => Int
      jwt byte bxor a b = jwt bxor loop (((a % 256) + 256) % 256) (((b % 256) + 256) % 256) 1 0

fn :: jwt ct diff String String Int Int Int => Int
      jwt ct diff a b idx len acc =
        | idx >= len = acc
        | otherwise = jwt ct diff a b (idx + 1) len (acc + (jwt byte bxor (str char at a idx) (str char at b idx)))

fn :: jwt ct eq String String => Bool
      jwt ct eq a b =
        | (str len a) != (str len b) = False
        | otherwise = (jwt ct diff a b 0 (str len a) 0) == 0

-- ── HS256 (HMAC-SHA256) Signing & Verification ───────────────

fn :: jwt hex nib Int => Int
      jwt hex nib c =
        | c >= 48 and c <= 57 = c - 48
        | c >= 97 and c <= 102 = (c - 97) + 10
        | c >= 65 and c <= 70 = (c - 65) + 10
        | otherwise = 0

fn :: jwt hex to bytes loop String Int Int [Int] => [Int]
      jwt hex to bytes loop h pos len acc =
        | (pos + 1) >= len = acc
        | otherwise = jwt hex to bytes loop h (pos + 2) len (acc :: [((jwt hex nib (str char at h pos)) * 16) + (jwt hex nib (str char at h (pos + 1)))])

fn :: jwt hex to bytes String => [Int]
      jwt hex to bytes h = jwt hex to bytes loop h 0 (str len h) []

fn :: jwt pad key bytes [Int] Int => [Int]
      jwt pad key bytes bs idx =
        | idx >= 64 = []
        | bs == [] = [0] :: (jwt pad key bytes [] (idx + 1))
        | otherwise = jwt pad key head bs idx

fn :: jwt pad key head [Int] Int => [Int]
      jwt pad key head [] idx = jwt pad key bytes [] idx
      jwt pad key head (b:rest) idx = [b] :: (jwt pad key bytes rest (idx + 1))

fn :: jwt key block String => [Int]
      jwt key block secret =
        | (str len secret) > 64 = secret sha256 str -> jwt hex to bytes -> jwt pad key bytes 0
        | otherwise = secret jwt str to bytes -> jwt pad key bytes 0

fn :: jwt bxor pad str [Int] Int => String
      jwt bxor pad str [] _ = ""
      jwt bxor pad str (b:rest) pad =
        jwt byte bxor b pad -> xb
        (xb % 126) + 1 -> safe_c
        (char from code safe_c) + (jwt bxor pad str rest pad)

fn :: jwt hmac sha256 b64url String String => String
      jwt hmac sha256 b64url secret signing_input =
        secret jwt key block -> kb
        jwt bxor pad str kb 54 -> ipad
        jwt bxor pad str kb 92 -> opad
        (ipad + signing_input) -> sha256 str -> inner_hex
        (opad + inner_hex) -> sha256 str -> outer_hex
        outer_hex jwt hex to bytes -> jwt b64url enc bytes

fn :: jwt hs256 header json Int => String
      jwt hs256 header json _ = '{"alg":"HS256","typ":"JWT"}'

-- @implements FR-JWT-001
-- @implements API-JWT-001
-- @mitigates VUL-AUTHN-001
fn :: jwt sign hs256 String String => String
      jwt sign hs256 payload_json secret =
        jwt hs256 header json 0 -> jwt b64url encode -> hdr_b64
        payload_json jwt b64url encode -> pay_b64
        hdr_b64 + "." + pay_b64 -> signing_in
        jwt hmac sha256 b64url secret signing_in -> sig_b64
        signing_in + "." + sig_b64

fn :: jwt split dots loop String Int Int Int [String] => [String]
      jwt split dots loop s pos len start acc =
        | pos >= len = acc :: [str slice s start len]
        | (str char at s pos) == 46 = jwt split dots loop s (pos + 1) len (pos + 1) (acc :: [str slice s start pos])
        | otherwise = jwt split dots loop s (pos + 1) len start acc

fn :: jwt str list len [String] => Int
      jwt str list len [] = 0
      jwt str list len (_:rest) = 1 + (jwt str list len rest)

fn :: jwt str at [String] Int => String
      jwt str at [] _ = ""
      jwt str at (s:_) 0 = s
      jwt str at (_:rest) idx = jwt str at rest (idx - 1)

-- @implements FR-JWT-001
-- @implements API-JWT-001
-- @mitigates VUL-INPUT-001
fn :: jwt decode payload String => JwtRes
      jwt decode payload token =
        jwt split dots loop token 0 (str len token) 0 [] -> parts
        jwt decode parts parts

fn :: jwt decode parts [String] => JwtRes
      jwt decode parts parts =
        | (jwt str list len parts) != 3 = JwtErr "invalid JWT format: expected 3 dot-separated parts"
        | (str len (jwt str at parts 0)) == 0 or (str len (jwt str at parts 1)) == 0 or (str len (jwt str at parts 2)) == 0 = JwtErr "invalid JWT format: empty segment"
        | not (jwt b64url is valid (jwt str at parts 1)) = JwtErr "invalid JWT payload Base64url encoding"
        | otherwise = JwtOk (jwt b64url decode (jwt str at parts 1))

fn :: jwt header is hs256 String => Bool
      jwt header is hs256 hdr_b64 =
        | not (jwt b64url is valid hdr_b64) = False
        | otherwise = hdr_b64 jwt b64url decode -> json parse -> jwt check hdr json

fn :: jwt check hdr json JsonRes => Bool
      jwt check hdr json (JsonErr _) = False
      jwt check hdr json (JsonOk node) = (json get str node "alg" "") == "HS256"

-- @implements FR-JWT-001
-- @implements API-JWT-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: jwt verify hs256 String String => JwtRes
      jwt verify hs256 token secret =
        jwt split dots loop token 0 (str len token) 0 [] -> parts
        jwt verify parts parts secret

fn :: jwt verify parts [String] String => JwtRes
      jwt verify parts parts secret =
        | (jwt str list len parts) != 3 = JwtErr "invalid JWT format"
        | (str len (jwt str at parts 2)) == 0 = JwtErr "missing JWT signature"
        | not (jwt header is hs256 (jwt str at parts 0)) = JwtErr "unsupported or missing alg: expected HS256"
        | otherwise = jwt verify sig (jwt str at parts 0) (jwt str at parts 1) (jwt str at parts 2) secret

fn :: jwt verify sig String String String String => JwtRes
      jwt verify sig hdr_b64 pay_b64 sig_b64 secret =
        jwt hmac sha256 b64url secret (hdr_b64 + "." + pay_b64) -> expected_sig
        jwt verify sig ct (jwt ct eq sig_b64 expected_sig) pay_b64

fn :: jwt verify sig ct Bool String => JwtRes
      jwt verify sig ct False _ = JwtErr "JWT signature verification failed"
      jwt verify sig ct True pay_b64 =
        | not (jwt b64url is valid pay_b64) = JwtErr "invalid payload Base64url"
        | otherwise = JwtOk (jwt b64url decode pay_b64)

-- ── Structured Claims Signing & Temporal Validation ──────────

-- @implements FR-JWT-001
-- @implements API-JWT-001
fn :: jwt sign claims JwtClaims String => String
      jwt sign claims c secret =
        JsonObj [JsonField "iss" (JsonStr (issuer c)), JsonField "sub" (JsonStr (subject c)), JsonField "exp" (JsonInt (expires_at c)), JsonField "nbf" (JsonInt (not_before_at c)), JsonField "custom" (JsonStr (custom_json c))] -> base_obj
        jwt sign hs256 (json stringify base_obj) secret

-- @implements FR-JWT-001
-- @implements API-JWT-001
-- @mitigates VUL-AUTHN-001
fn :: jwt verify claims String String Int => JwtClaimsRes
      jwt verify claims token secret now =
        jwt verify hs256 token secret -> vres
        jwt validate verified payload vres now

fn :: jwt validate verified payload JwtRes Int => JwtClaimsRes
      jwt validate verified payload (JwtErr msg) _ = JwtClaimsErr msg
      jwt validate verified payload (JwtOk pay_str) now = jwt validate parsed claims (json parse pay_str) now

fn :: jwt validate parsed claims JsonRes Int => JwtClaimsRes
      jwt validate parsed claims (JsonErr msg) _ = JwtClaimsErr ("invalid claims JSON: " + msg)
      jwt validate parsed claims (JsonOk node) now =
        json get str node "iss" "" -> iss
        json get str node "sub" "" -> sub
        json get int node "exp" 0 -> exp_t
        json get int node "nbf" 0 -> nbf_t
        json get str node "custom" "" -> cust
        jwt check claim times (JwtClaims iss sub exp_t nbf_t cust) now

fn :: jwt check claim times JwtClaims Int => JwtClaimsRes
      jwt check claim times c now =
        | (not_before_at c) > 0 and now < (not_before_at c) = JwtClaimsErr "JWT token not yet valid (nbf)"
        | (expires_at c) > 0 and now >= (expires_at c) = JwtClaimsErr "JWT token expired (exp)"
        | otherwise = JwtClaimsOk c

-- ── Authenticated Encrypted Tokens (`jwt seal aead` / `jwt open aead`) ─

fn :: jwt keystream bytes String String Int Int => [Int]
      jwt keystream bytes key nonce blk rem =
        | rem <= 0 = []
        | otherwise = (jwt hex to bytes (sha256 str (key + ":" + nonce + ":" + (int to str blk)))) :: (jwt keystream bytes key nonce (blk + 1) (rem - 32))

fn :: jwt bxor lists [Int] [Int] => [Int]
      jwt bxor lists [] _ = []
      jwt bxor lists _ [] = []
      jwt bxor lists (a:arst) (b:brst) = [jwt byte bxor a b] :: (jwt bxor lists arst brst)

-- @implements FR-JWT-001
-- @implements API-JWT-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: jwt seal aead String String String => JwtRes
      jwt seal aead key nonce plaintext =
        | (str len key) != 32 = JwtErr "AEAD key must be 32 bytes"
        | (str len nonce) != 12 = JwtErr "AEAD nonce must be 12 bytes"
        | otherwise = jwt seal aead ok key nonce plaintext

fn :: jwt seal aead ok String String String => JwtRes
      jwt seal aead ok key nonce plaintext =
        plaintext jwt str to bytes -> pt_bs
        jwt keystream bytes key nonce 1 (str len plaintext) -> ks_bs
        jwt bxor lists pt_bs ks_bs -> ct_bs
        nonce jwt b64url encode -> nonce_b64
        ct_bs jwt b64url enc bytes -> ct_b64
        "RGAEAD1." + nonce_b64 + "." + ct_b64 -> aad_in
        jwt hmac sha256 b64url key aad_in -> tag_b64
        JwtOk (aad_in + "." + tag_b64)

-- @implements FR-JWT-001
-- @implements API-JWT-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: jwt open aead String String String => JwtRes
      jwt open aead key nonce token =
        | (str len key) != 32 = JwtErr "AEAD key must be 32 bytes"
        | (str len nonce) != 12 = JwtErr "AEAD nonce must be 12 bytes"
        | otherwise = jwt open aead parts key nonce (jwt split dots loop token 0 (str len token) 0 [])

fn :: jwt open aead parts String String [String] => JwtRes
      jwt open aead parts key nonce parts =
        | (jwt str list len parts) != 4 = JwtErr "invalid AEAD token format"
        | (jwt str at parts 0) != "RGAEAD1" = JwtErr "invalid AEAD token version"
        | not (jwt ct eq (jwt str at parts 1) (jwt b64url encode nonce)) = JwtErr "AEAD nonce mismatch"
        | otherwise = jwt open aead verify key nonce (jwt str at parts 1) (jwt str at parts 2) (jwt str at parts 3)

fn :: jwt open aead verify String String String String String => JwtRes
      jwt open aead verify key nonce nonce_b64 ct_b64 tag_b64 =
        aad_in = "RGAEAD1." + nonce_b64 + "." + ct_b64
        exp_tag = jwt hmac sha256 b64url key aad_in
        jwt open aead decrypt (jwt ct eq tag_b64 exp_tag) key nonce ct_b64

fn :: jwt open aead decrypt Bool String String String => JwtRes
      jwt open aead decrypt False _ _ _ = JwtErr "AEAD authentication tag verification failed"
      jwt open aead decrypt True key nonce ct_b64 =
        | not (jwt b64url is valid ct_b64) = JwtErr "invalid AEAD ciphertext Base64url"
        | otherwise = jwt open aead pt key nonce (jwt b64url decode bytes ct_b64)

fn :: jwt int list len [Int] => Int
      jwt int list len [] = 0
      jwt int list len (_:rest) = 1 + (jwt int list len rest)

fn :: jwt open aead pt String String [Int] => JwtRes
      jwt open aead pt key nonce ct_bs =
        ks_bs = jwt keystream bytes key nonce 1 (jwt int list len ct_bs)
        pt_bs = jwt bxor lists ct_bs ks_bs
        JwtOk (jwt bytes to str pt_bs)
