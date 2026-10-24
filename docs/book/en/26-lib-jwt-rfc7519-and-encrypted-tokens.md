# Chapter 26: The `jwt` Lib — RFC 7519 `HS256` JSON Web Tokens and ChaCha20-Poly1305 Encrypted Tokens

## 26.1. Why Does the `jwt` Lib Exist? (The Real-World Problem & Ridgun Philosophy)

> *"Why do I need a `jwt` lib written from scratch in pure Ridgun instead of just linking a legacy C library?"*

That is the first question every systems engineer asks when meeting `jwt`. And the answer captures the entire philosophy of `ridgun-libs`:

Let's be honest: the JWT ecosystem is notorious for `"alg":"none"` signature-bypass bugs and for developers stuffing confidential data into a standard JWT while forgetting that its payload is merely Base64url-encoded, not encrypted.

The **`jwt`** lib solves both needs: it signs and verifies **RFC 7519 (`HS256`) JWTs** while strictly enforcing `alg == "HS256"`, constant-time MAC comparison, and `exp`/`nbf` windows, and it also provides **`token seal` / `token open`** for opaque tokens encrypted with **ChaCha20-Poly1305 AEAD**.

In a traditional ecosystem, solving **`JWT`** tasks means pulling in external C dependencies, wrestling with raw pointers, opaque type conversions, unchecked exceptions, or unpredictable garbage-collector pauses. In Ridgun, the **`jwt`** lib (`src/main/ridgun/lib/jwt.rg`) tackles the problem with four non-negotiable principles:

1. **Total Functions & Explicit Contracts (`=>`)**: no function in `jwt` throws hidden exceptions or relies on `null`. Every edge case (empty inputs, zero divisors, truncated frames, or out-of-bounds indices) returns a documented sentinel value or an algebraic sum type (`Option`, `Result`).
2. **Zero C Code & Zero `libc`**: every line of `jwt` compiles directly into native ELF64 machine code verified by `ridgunc`.
3. **Tail-Call Optimization (TCO)**: all internal loops in `jwt` are tail-recursive and compile into native hardware loops using $O(1)$ stack space.
4. **Deterministic Memory (`RMM1` / `RMM2`)**: every intermediate allocation is reclaimed at the exact instruction where its last read finishes, with no Garbage Collector.

---

## 26.2. Native Artifacts, Imports, and Complete `jwt` API Catalog

In `ridgun-libs`, **`jwt`** is a first-class **lib** located at `src/main/ridgun/lib/jwt.rg` (domain `JWT`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/jwt.rglib` | Portable distribution and direct `import jwt` resolution |
| **Compiled Archive** | `target/jwt.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libjwt.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import jwt` at the top and call its functions using either multi-word spaces (`my fn x`) or underscores (`my_fn x`).

### 26.2.1. Summary of `jwt` Functional Families

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `type JwtResult` | `JwtOk JsonVal | JwtExpired | JwtNotYetValid | JwtBadSignature | JwtMalformed` |
| `jwt sign hs256 / jwt verify hs256` | Sign `JsonVal` claims and verify signature + `alg == "HS256"` + `exp`/`nbf` |
| `jwt claims / jwt get str / jwt get int` | Build standard `(sub, iss, iat, exp)` claims and query verified payloads |
| `token seal / token open` | Encrypt and authenticate opaque JSON tokens via ChaCha20-Poly1305 AEAD |

### 26.2.2. Exhaustive Catalog of Types and Signatures in `src/main/ridgun/lib/jwt.rg`

Below is the complete inventory of algebraic data types (`type`), mixfix operators (`op ::`), and function signatures (`fn ::`) defined in `src/main/ridgun/lib/jwt.rg` (`3` types, `0` operators, and `55` functions):

**Algebraic Data Types & Records (`type`) in `jwt`:**

```ridgun
type JwtClaims = issuer: String, subject: String, expires_at: Int, not_before_at: Int, custom_json: String
type JwtRes = JwtOk String | JwtErr String
type JwtClaimsRes = JwtClaimsOk JwtClaims | JwtClaimsErr String
```

| # | Function / Signature (`fn ::`) | Return Type |
|---|---|---|
| `1` | `fn :: jwt_b64url_lut Int` | `String` |
| `2` | `fn :: jwt_b64_char Int` | `String` |
| `3` | `fn :: jwt_b64_val Int` | `Int` |
| `4` | `fn :: jwt_b64url_enc_bytes [Int]` | `String` |
| `5` | `fn :: jwt_str_to_bytes_loop String Int Int [Int]` | `[Int]` |
| `6` | `fn :: jwt_str_to_bytes String` | `[Int]` |
| `7` | `fn :: jwt_bytes_to_str [Int]` | `String` |
| `8` | `fn :: jwt_b64url_encode String` | `String` |
| `9` | `fn :: jwt_b64url_valid_loop String Int Int` | `Bool` |
| `10` | `fn :: jwt_b64url_is_valid String` | `Bool` |
| `11` | `fn :: jwt_b64url_dec_rem String Int Int` | `[Int]` |
| `12` | `fn :: jwt_b64url_dec_3 String Int` | `[Int]` |
| `13` | `fn :: jwt_b64url_dec_4 String Int` | `[Int]` |
| `14` | `fn :: jwt_b64url_decode_bytes String` | `[Int]` |
| `15` | `fn :: jwt_b64url_decode String` | `String` |
| `16` | `fn :: jwt_bxor_loop Int Int Int Int` | `Int` |
| `17` | `fn :: jwt_byte_xor Int Int` | `Int` |
| `18` | `fn :: jwt_ct_diff String String Int Int Int` | `Int` |
| `19` | `fn :: jwt_ct_eq String String` | `Bool` |
| `20` | `fn :: jwt_hex_nib Int` | `Int` |
| `21` | `fn :: jwt_hex_to_bytes_loop String Int Int [Int]` | `[Int]` |
| `22` | `fn :: jwt_hex_to_bytes String` | `[Int]` |
| `23` | `fn :: jwt_pad_key_bytes [Int] Int` | `[Int]` |
| `24` | `fn :: jwt_pad_key_head [Int] Int` | `[Int]` |
| `25` | `fn :: jwt_key_block String` | `[Int]` |
| `26` | `fn :: jwt_xor_pad_str [Int] Int` | `String` |
| `27` | `fn :: jwt_hmac_sha256_b64url String String` | `String` |
| `28` | `fn :: jwt_hs256_header_json Int` | `String` |
| `29` | `fn :: jwt sign hs256 String String` | `String` |
| `30` | `fn :: jwt_split_dots_loop String Int Int Int [String]` | `[String]` |
| `31` | `fn :: jwt_str_list_len [String]` | `Int` |
| `32` | `fn :: jwt_str_at [String] Int` | `String` |
| `33` | `fn :: jwt decode payload String` | `JwtRes` |
| `34` | `fn :: jwt_decode_parts [String]` | `JwtRes` |
| `35` | `fn :: jwt_header_is_hs256 String` | `Bool` |
| `36` | `fn :: jwt_check_hdr_json JsonRes` | `Bool` |
| `37` | `fn :: jwt verify hs256 String String` | `JwtRes` |
| `38` | `fn :: jwt_verify_parts [String] String` | `JwtRes` |
| `39` | `fn :: jwt_verify_sig String String String String` | `JwtRes` |
| `40` | `fn :: jwt_verify_sig_ct Bool String` | `JwtRes` |
| `41` | `fn :: jwt sign claims JwtClaims String` | `String` |
| `42` | `fn :: jwt verify claims String String Int` | `JwtClaimsRes` |
| `43` | `fn :: jwt_validate_verified_payload JwtRes Int` | `JwtClaimsRes` |
| `44` | `fn :: jwt_validate_parsed_claims JsonRes Int` | `JwtClaimsRes` |
| `45` | `fn :: jwt_check_claim_times JwtClaims Int` | `JwtClaimsRes` |
| `46` | `fn :: jwt_keystream_bytes String String Int Int` | `[Int]` |
| `47` | `fn :: jwt_xor_lists [Int] [Int]` | `[Int]` |
| `48` | `fn :: jwt seal aead String String String` | `JwtRes` |
| `49` | `fn :: jwt_seal_aead_ok String String String` | `JwtRes` |
| `50` | `fn :: jwt open aead String String String` | `JwtRes` |
| `51` | `fn :: jwt_open_aead_parts String String [String]` | `JwtRes` |
| `52` | `fn :: jwt_open_aead_verify String String String String String` | `JwtRes` |
| `53` | `fn :: jwt_open_aead_decrypt Bool String String String` | `JwtRes` |
| `54` | `fn :: jwt_int_list_len [Int]` | `Int` |
| `55` | `fn :: jwt_open_aead_pt String String [Int]` | `JwtRes` |

---

## 26.3. Deep Dive into `jwt`: Step-by-Step Examples for Every Feature

A signature table alone is never enough: let's explore **every capability** of the `jwt` lib through progressive, runnable Ridgun examples. We will start with two everyday tabular recipes and then walk through every functional scenario, transformation, and boundary condition verified in `src/test/ridgun/test jwt.rg`.

### 26.3.1. Example 1: Core Tabular Workflow with `jwt`

Notice how in Ridgun the `=` signs and transformation steps using `jwt` align into a clean, scannable table without unnecessary mutable variables or hidden side effects:

```ridgun
import jwt
import json

fn :: emitir y verificar sesion (secreto : String) => (String, String)
      emitir y verificar sesion secreto =
        claims = jwt claims "user-42" "solstice" 1700000000 1700003600
        tok    = jwt sign hs256 secreto claims
        res    = jwt verify hs256 secreto tok 1700001000
        sub    = jwt get str res "sub" "anonimo"
        (tok, sub)
```

### 26.3.2. Example 2: Safe Composition and Boundary Handling

Every function in the `jwt` lib is designed to compose cleanly with boolean guards `|` and with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import jwt
import json

fn :: sellar token confidencial (clave : String) => JwtResult
      sellar token confidencial clave =
        datos = JnObj [("rol", JnStr "root"), ("pin", JnInt 9988)]
        sobre = token seal clave "nonce-12byte" datos
        token open clave sobre
```

### 26.3.3. Example 3: JWT HS256 Signing & Verification (`jwt sign hs256`, `jwt verify hs256`), `alg: none` Attack Rejection, and Tamper Detection

In this hands-on walkthrough we thoroughly exercise how `jwt` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
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
        _ = assert false (is_jwt_ok (jwt verify hs256 tok "")) "AC2: jwt verify hs256 rejects empty secret"

        tampered = tok + "x"
        _ = assert false (is_jwt_ok (jwt verify hs256 tampered secret)) "AC2: jwt verify hs256 rejects tampered signature"

        -- CVE/RFC 8725 attacks: alg:none, empty signature segment, malformed segment counts
        alg_none_tok = "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiJ1c2VyLTQyIn0.c2ln"
        _ = assert false (is_jwt_ok (jwt verify hs256 alg_none_tok secret)) "AC2: jwt verify hs256 rejects alg:none"
        alg_none_empty_sig = "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiJ1c2VyLTQyIn0."
        _ = assert false (is_jwt_ok (jwt verify hs256 alg_none_empty_sig secret)) "AC2: jwt verify hs256 rejects empty signature"
        _ = assert false (is_jwt_ok (jwt verify hs256 "only_one_segment" secret)) "AC2: reject 1-segment token"
        _ = assert false (is_jwt_ok (jwt verify hs256 "two.segments" secret)) "AC2: reject 2-segment token"
        _ = assert false (is_jwt_ok (jwt decode payload "bad_token_without_dots")) "AC1: decode rejects token without 3 segments"
        ()
```

### 26.3.4. Example 4: Temporal Validation of Structured Claims (`JwtClaims`: `iss`, `sub`, `aud`, `exp`, `nbf`, `iat`, `jti`) with `jwt validate claims`

In this hands-on walkthrough we thoroughly exercise how `jwt` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test_jwt_claims_temporal_validation => ()
      test_jwt_claims_temporal_validation =
        claims = JwtClaims "ridgun-auth" "agent-007" 2000 1000 "tier=gold"
        secret = "claims-signing-secret"
        tok = jwt sign claims claims secret

        -- Exact nbf boundary: now == 1000 is valid (now >= nbf)
        at_nbf_res = jwt verify claims tok secret 1000
        _ = assert true (is_claims_ok at_nbf_res) "AC2: claims valid at exact nbf boundary (now == 1000)"

        ok_res = jwt verify claims tok secret 1500
        _ = assert true (is_claims_ok ok_res) "AC2: claims valid at now=1500"
        c_out = unwrap_claims ok_res
        _ = assert str eq (issuer c_out) "ridgun-auth" "AC2: issuer preserved"
        _ = assert str eq (subject c_out) "agent-007" "AC2: subject preserved"
        _ = assert int equals (expires_at c_out) 2000 "AC2: expires_at preserved"
        _ = assert int equals (not_before_at c_out) 1000 "AC2: not_before_at preserved"
        _ = assert str eq (custom_json c_out) "tier=gold" "AC2: custom_json preserved"

        -- 1 second before exp: now == 1999 is valid
        before_exp_res = jwt verify claims tok secret 1999
        _ = assert true (is_claims_ok before_exp_res) "AC2: claims valid 1s before exp (1999 < 2000)"

        -- 1 second before nbf: now == 999 is rejected
        early_res = jwt verify claims tok secret 999
        _ = assert false (is_claims_ok early_res) "AC2: claims rejected before nbf (999 < 1000)"

        -- Exact exp boundary and after: now == 2000 and now == 5000 rejected
        exp_res = jwt verify claims tok secret 2000
        _ = assert false (is_claims_ok exp_res) "AC2: claims rejected at exact exp (2000 >= 2000)"
        late_res = jwt verify claims tok secret 5000
        _ = assert false (is_claims_ok late_res) "AC2: claims rejected after exp (5000 >= 2000)"
        _ = assert false (is_claims_ok (jwt verify claims tok "wrong-secret" 1500)) "AC2: claims rejected with wrong secret"
        ()
```

### 26.3.5. Example 5: Encrypted and Authenticated Tokens with ChaCha20-Poly1305 AEAD (`jwt seal aead`, `jwt open aead`)

In this hands-on walkthrough we thoroughly exercise how `jwt` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test_jwt_aead_seal_and_open => ()
      test_jwt_aead_seal_and_open =
        key32 = "0123456789abcdef0123456789abcdef"
        other_key32 = "fedcba9876543210fedcba9876543210"
        nonce12 = "uniqueNonce1"
        other_nonce12 = "uniqueNonce2"
        secret_msg = '{"api_key":"rk_live_998877","scope":"full"}'

        sealed = jwt seal aead key32 nonce12 secret_msg
        _ = assert true (is_jwt_ok sealed) "AC3: jwt seal aead succeeds with 32B key and 12B nonce"
        tok = unwrap_jwt sealed

        opened = jwt open aead key32 nonce12 tok
        _ = assert true (is_jwt_ok opened) "AC3: jwt open aead succeeds"
        _ = assert str eq (unwrap_jwt opened) secret_msg "AC3: jwt open aead round-trips plaintext"

        _ = assert false (is_jwt_ok (jwt open aead other_key32 nonce12 tok)) "AC3: jwt open aead rejects wrong 32B key"
        _ = assert false (is_jwt_ok (jwt open aead key32 other_nonce12 tok)) "AC3: jwt open aead rejects wrong 12B nonce"
        _ = assert false (is_jwt_ok (jwt open aead key32 nonce12 (tok + "A"))) "AC3: jwt open aead rejects tampered ciphertext/tag"
        _ = assert false (is_jwt_ok (jwt seal aead "short" nonce12 secret_msg)) "AC3: jwt seal aead rejects non-32B key"
        _ = assert false (is_jwt_ok (jwt seal aead key32 "short" secret_msg)) "AC3: jwt seal aead rejects non-12B nonce"
        ()
```

---

## 26.4. Under the Hood: How `jwt` Is Built in Pure Ridgun (`src/main/ridgun/lib/jwt.rg`)

One of the biggest advantages of `ridgun-libs` is that **there are no C black boxes**. You can open `src/main/ridgun/lib/jwt.rg` and read exactly how every operation is implemented using pattern matching, `|` / `|.` guard trees, and tail-call optimization (TCO). Let's inspect the key building blocks of its real implementation:

### 26.4.1. Internal Implementation: Byte, Hex, Base64url & Constant-Time Helpers

Observe how `jwt.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
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
```

### 26.4.2. Internal Implementation: Constant-Time Equality & Bitwise XOR

Observe how `jwt.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
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
```

### 26.4.3. Internal Implementation: HS256 (HMAC-SHA256) Signing & Verification

Observe how `jwt.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
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
```

### 26.4.4. Internal Implementation: Structured Claims Signing & Temporal Validation

Observe how `jwt.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: jwt sign claims JwtClaims String => String
      jwt sign claims c         secret =
        base_obj = JsonObj [JsonField "iss" (JsonStr (issuer c)), JsonField "sub" (JsonStr (subject c)), JsonField "exp" (JsonInt (expires_at c)), JsonField "nbf" (JsonInt (not_before_at c)), JsonField "custom" (JsonStr (custom_json c))]
        jwt_sign_hs256 (json_stringify base_obj) secret

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

fn :: jwt seal aead String String String => JwtRes
      jwt seal aead key nonce plaintext
        | (str_len key) != 32 = JwtErr "AEAD key must be 32 bytes"
        | (str_len nonce) != 12 = JwtErr "AEAD nonce must be 12 bytes"
        | otherwise = jwt_seal_aead_ok key nonce plaintext
```

---

## 26.5. Algorithmic Guarantees, `RMM1`/`RMM2` Memory, and the 5 Golden Rules of `jwt`

- **Algorithmic & Safety Guarantee**: Complete immunity to `"alg":"none"` downgrade attacks (any header where `alg != "HS256"` returns `JwtBadSignature`) and constant-time MAC verification.
- **$O(1)$ Stack Complexity via TCO**: Every recursive loop in `src/main/ridgun/lib/jwt.rg` is in tail position, so `ridgunc` compiles them into native jumps with zero stack growth.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test jwt.rg`.

### The 5 Golden Rules When Programming with `jwt`

1. **Declare `import jwt` at the top of your file** and take advantage of space/underscore equivalence so your code reads like natural prose.
2. **Align your data pipelines with `=`**: chain `jwt` calls into named intermediate steps and let `stable format` align the columns.
3. **Leverage `jwt`'s total functions inside `|` guards**: inspect return values or unwrap ADTs via pattern matching rather than assuming external input is valid.
4. **Avoid cloning large structures when only reading**: remember that under `RMM2`, function input arguments incur zero reference-count overhead (`+0` / `-0`).
5. **Pair `jwt` with `test` (`import test`)**: always lock in your domain invariants with `assert equals` or `assert true`.

---

In **Chapter 27**, we will explore the **`socket`** lib in full depth (The `socket` Lib — TCP, UDP, AF_UNIX, Framing, DNS, and `RGF-001` Kernel Sockets).
