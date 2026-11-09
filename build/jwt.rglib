-- ============================================================
-- src/main/ridgun/lib/jwt.rg
-- Pure-Ridgun RFC 7519 HS256 JWT & Authenticated Encrypted Token Library (JWT)
-- Bytes are Tensor[U8] (ADR-0010).
-- @implements FR-JWT-001
-- @implements API-JWT-001
-- @implements DM-Jwt
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
-- ============================================================

module :: jwt

import json
import crypto

type JwtClaims = issuer: String, subject: String, expires_at: Int, not_before_at: Int, custom_json: String

type JwtRes = JwtOk String | JwtErr String

type JwtClaimsRes = JwtClaimsOk JwtClaims | JwtClaimsErr String

-- ── Tensor[U8] Byte & Base64url Helpers (ADR-0010) ──────────

fn :: jwt blen Tensor[U8] => Int
      jwt blen (Tensor[U8 * n] t) = n

fn :: jwt u8 Int => Int
      jwt u8 x = ((x % 256) + 256) % 256

fn :: jwt b64url lut Int => String
      jwt b64url lut _ = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

fn :: jwt b64 code String Int => Int
      jwt b64 code tbl idx = str char at tbl (((idx % 64) + 64) % 64)

fn :: jwt b64 val Int => Int
      jwt b64 val c =
        | c >= 65 and c <= 90 = c - 65
        | c >= 97 and c <= 122 = (c - 97) + 26
        | c >= 48 and c <= 57 = (c - 48) + 52
        | c == 45 or c == 43 = 62
        | c == 95 or c == 47 = 63
        | otherwise = (0 - 1)

-- Unpadded Base64url (RFC 4648 §5) length of n bytes.
fn :: jwt b64url enc len Int => Int
      jwt b64url enc len n =
        | (n % 3) == 0 = (n / 3) * 4
        | otherwise = ((n / 3) * 4) + (n % 3) + 1

fn :: jwt b64url enc bytes Tensor[U8] => String
      jwt b64url enc bytes bs =
        n = jwt blen bs
        out = Tensor[U8 * (jwt b64url enc len n)]
        jwt b64url enc loop bs n out (jwt b64url lut 0) 0 0 -> tensor to str

fn :: jwt b64url enc loop Tensor[U8] Int Tensor[U8] String Int Int => Tensor[U8]
      jwt b64url enc loop bs n out tbl i o =
        | i >= n = out
        | (n - i) == 1 = jwt b64url enc tail1 bs out tbl i o
        | (n - i) == 2 = jwt b64url enc tail2 bs out tbl i o
        | otherwise = jwt b64url enc group bs n out tbl i o

fn :: jwt b64url enc group Tensor[U8] Int Tensor[U8] String Int Int => Tensor[U8]
      jwt b64url enc group bs n out tbl i o =
        v = (bs_(i) * 65536) + (bs_(i + 1) * 256) + bs_(i + 2)
        out_(o) = jwt b64 code tbl (v / 262144)
        out_(o + 1) = jwt b64 code tbl ((v / 4096) % 64)
        out_(o + 2) = jwt b64 code tbl ((v / 64) % 64)
        out_(o + 3) = jwt b64 code tbl (v % 64)
        jwt b64url enc loop bs n out tbl (i + 3) (o + 4)

fn :: jwt b64url enc tail1 Tensor[U8] Tensor[U8] String Int Int => Tensor[U8]
      jwt b64url enc tail1 bs out tbl i o =
        b0 = bs_(i)
        out_(o) = jwt b64 code tbl (b0 / 4)
        out_(o + 1) = jwt b64 code tbl ((b0 % 4) * 16)
        out

fn :: jwt b64url enc tail2 Tensor[U8] Tensor[U8] String Int Int => Tensor[U8]
      jwt b64url enc tail2 bs out tbl i o =
        v = (bs_(i) * 256) + bs_(i + 1)
        out_(o) = jwt b64 code tbl (v / 1024)
        out_(o + 1) = jwt b64 code tbl ((v / 16) % 64)
        out_(o + 2) = jwt b64 code tbl ((v % 16) * 4)
        out

fn :: jwt b64url encode String => String
      jwt b64url encode s = s tensor from str -> jwt b64url enc bytes

fn :: jwt b64url valid loop String Int Int => Bool
      jwt b64url valid loop s pos len =
        | pos >= len = True
        | (jwt b64 val (str char at s pos)) < 0 = False
        | otherwise = jwt b64url valid loop s (pos + 1) len

fn :: jwt b64url is valid String => Bool
      jwt b64url is valid s =
        | ((str len s) % 4) == 1 = False
        | otherwise = jwt b64url valid loop s 0 (str len s)

-- Decoded length of an unpadded Base64url text of len characters (a trailing single character is ignored).
fn :: jwt b64url dec len Int => Int
      jwt b64url dec len len =
        | (len % 4) == 2 = ((len / 4) * 3) + 1
        | (len % 4) == 3 = ((len / 4) * 3) + 2
        | otherwise = (len / 4) * 3

fn :: jwt b64 at String Int => Int
      jwt b64 at s pos = jwt b64 val (str char at s pos)

fn :: jwt b64url dec loop String Int Tensor[U8] Int => Tensor[U8]
      jwt b64url dec loop s len out o =
        | (len - ((o / 3) * 4)) >= 4 = jwt b64url dec4 s len out o
        | (len - ((o / 3) * 4)) == 3 = jwt b64url dec3 s out o
        | (len - ((o / 3) * 4)) == 2 = jwt b64url dec2 s out o
        | otherwise = out

fn :: jwt b64url dec4 String Int Tensor[U8] Int => Tensor[U8]
      jwt b64url dec4 s len out o =
        pos = (o / 3) * 4
        n = ((jwt b64 at s pos) * 262144) + ((jwt b64 at s (pos + 1)) * 4096) + ((jwt b64 at s (pos + 2)) * 64) + (jwt b64 at s (pos + 3))
        out_(o) = jwt u8 (n / 65536)
        out_(o + 1) = jwt u8 (n / 256)
        out_(o + 2) = jwt u8 n
        jwt b64url dec loop s len out (o + 3)

fn :: jwt b64url dec3 String Tensor[U8] Int => Tensor[U8]
      jwt b64url dec3 s out o =
        pos = (o / 3) * 4
        n = ((jwt b64 at s pos) * 1024) + ((jwt b64 at s (pos + 1)) * 16) + ((jwt b64 at s (pos + 2)) / 4)
        out_(o) = jwt u8 (n / 256)
        out_(o + 1) = jwt u8 n
        out

fn :: jwt b64url dec2 String Tensor[U8] Int => Tensor[U8]
      jwt b64url dec2 s out o =
        pos = (o / 3) * 4
        out_(o) = jwt u8 (((jwt b64 at s pos) * 4) + ((jwt b64 at s (pos + 1)) / 16))
        out

fn :: jwt b64url decode bytes String => Tensor[U8]
      jwt b64url decode bytes s =
        len = str len s
        out = Tensor[U8 * (jwt b64url dec len len)]
        jwt b64url dec loop s len out 0

fn :: jwt b64url decode String => String
      jwt b64url decode s = s jwt b64url decode bytes -> tensor to str

-- ── Constant-Time Equality ───────────────────────────────────

fn :: jwt byte bxor Int Int => Int
      jwt byte bxor a b = (jwt u8 a) xor (jwt u8 b)

fn :: jwt ct diff String String Int Int Int => Int
      jwt ct diff a b idx len acc =
        | idx >= len = acc
        | otherwise = jwt ct diff a b (idx + 1) len (acc or (jwt byte bxor (str char at a idx) (str char at b idx)))

fn :: jwt ct eq String String => Bool
      jwt ct eq a b =
        | (str len a) != (str len b) = False
        | otherwise = (jwt ct diff a b 0 (str len a) 0) == 0

-- ── HS256 (HMAC-SHA256) Signing & Verification ───────────────

-- RFC 2104 HMAC-SHA256 (crypto lib, RFC 4231 vectors), as an unpadded Base64url tag.
fn :: jwt hmac sha256 b64url String String => String
      jwt hmac sha256 b64url secret signing_input =  hmac sha256 secret signing_input -> tensor from str -> jwt b64url enc bytes

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

-- Token: "RGAEAD2." nonce "." ciphertext "." tag, each part unpadded Base64url.
-- RFC 8439 ChaCha20-Poly1305 (crypto lib); the AAD is "RGAEAD2." nonce, so the version
-- and the nonce are authenticated too.
fn :: jwt aead version => String
      jwt aead version =  "RGAEAD2"

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
        aad = (jwt aead version) + "." + (jwt b64url encode nonce)
        sealed = aead seal key nonce aad plaintext
        ct_len = (str len sealed) - 16
        ct_b64 = jwt b64url encode (str slice sealed 0 ct_len)
        tag_b64 = jwt b64url encode (str slice sealed ct_len (str len sealed))
        JwtOk (aad + "." + ct_b64 + "." + tag_b64)

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
        | (jwt str at parts 0) != (jwt aead version) = JwtErr "invalid AEAD token version"
        | not (jwt ct eq (jwt str at parts 1) (jwt b64url encode nonce)) = JwtErr "AEAD nonce mismatch"
        | not (jwt b64url is valid (jwt str at parts 2)) = JwtErr "invalid AEAD ciphertext Base64url"
        | not (jwt b64url is valid (jwt str at parts 3)) or (str len (jwt str at parts 3)) != 22 = JwtErr "invalid AEAD tag"
        | otherwise = jwt open aead verify key nonce (jwt str at parts 1) (jwt str at parts 2) (jwt str at parts 3)

fn :: jwt open aead verify String String String String String => JwtRes
      jwt open aead verify key nonce nonce_b64 ct_b64 tag_b64 =
        aad = (jwt aead version) + "." + nonce_b64
        res = aead open key nonce aad ((jwt b64url decode ct_b64) + (jwt b64url decode tag_b64))
        jwt open aead result res

fn :: jwt open aead result (Int String) => JwtRes
      jwt open aead result (0, pt) = JwtOk pt
      jwt open aead result (_, _)  = JwtErr "AEAD authentication tag verification failed"
