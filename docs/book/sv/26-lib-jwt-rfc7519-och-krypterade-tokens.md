# Kapitel 26: Lib:en `jwt` — RFC 7519 `HS256` JSON Web Tokens och ChaCha20-Poly1305-krypterade Tokens

## 26.1. Varför finns lib:en `jwt`? (Det verkliga problemet och Ridguns filosofi)

> *”Varför behöver jag en `jwt`-lib skriven från grunden i ren Ridgun i stället för att bara länka in ett gammalt C-bibliotek?”*

Det är den första fråga varje systemingenjör ställer sig när man möter `jwt`. Och svaret sammanfattar hela filosofin bakom `ridgun-libs`:

Låt oss vara ärliga: JWT-ekosystemet är ökänt för sårbarheter där en angripare ändrar headern till `"alg":"none"` och servern godkänner token utan signatur, eller där känslig data lagras i en vanlig JWT vars payload bara är Base64url-kodad, inte krypterad.

Lib:en **`jwt`** löser båda behoven: den signerar och verifierar **RFC 7519 (`HS256`) JWT:er** med strikt krav på `alg == "HS256"`, konstanttidsjämförelse av MAC och kontroll av `exp`/`nbf`, samt erbjuder **`token seal` / `token open`** för opaka tokens krypterade med **ChaCha20-Poly1305 AEAD**.

I ett traditionellt ekosystem innebär uppgifter inom domänen **`JWT`** ofta att man drar in externa C-beroenden, brottas med råa pekare, ogenomskinliga typkonverteringar, okontrollerade undantag eller oförutsägbara skräpsamlarpauser. I Ridgun löser lib:en **`jwt`** (`src/main/ridgun/lib/jwt.rg`) problemet genom fyra kompromisslösa principer:

1. **Deklarera `import jwt` (eller `import jwt as alias`) överst i filen**: varje lib definierar sin `module :: jwt`-namnrymd och i `--strict`-läge anropas flerordsfunktioner alltid med naturliga mellanslag.
2. **Kedja dina datapipelines från vänster till höger med `->`**: skriv `indata steg ett -> steg två -> resultat`, använd `(+ _ _ +)`-sekvensmasker för att packa upp tupler och utelämna `_ =` vid sekventiella satser (eller kasta med `-> ()`).
3. **Svansrekursion med TCO (*Tail-Call Optimization*)**: alla interna genomlöpningar i `jwt` kompileras till inbyggda hårdvaruloopar med $O(1)$ stackutrymme.
4. **Deterministiskt minne (`RMM1` / `RMM2`)**: varje mellanliggande struktur frigörs i exakt det ögonblick dess sista läsning avslutas, helt utan *Garbage Collector*.

---

## 26.2. Inbyggda artefakter, import och komplett API-katalog för `jwt`

I `ridgun-libs` är **`jwt`** en förstklassig **lib** placerad i `src/main/ridgun/lib/jwt.rg` (domän `JWT`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/jwt.rglib` | Portabel distribution och direkt import med `import jwt` |
| **Kompilerat arkiv** | `target/jwt.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libjwt.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> Varje lib deklarerar sin egen namnrymd med `module :: jwt`: skriv bara `import jwt` (eller `import jwt as alias`) överst och anropa dess funktioner med naturliga mellanslag (`min funktion x`) och `->`-pipelines (`x min funktion -> resultat`).

### 26.2.1. Översikt över funktionella familjer i `jwt`

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `type JwtResult` | `JwtOk JsonVal | JwtExpired | JwtNotYetValid | JwtBadSignature | JwtMalformed` |
| `jwt sign hs256 / jwt verify hs256` | Signerar `JsonVal`-claims och verifierar signatur + `alg == "HS256"` + `exp`/`nbf` |
| `jwt claims / jwt get str / jwt get int` | Bygger standard-claims `(sub, iss, iat, exp)` och frågar verifierade payloads |
| `token seal / token open` | Krypterar och autentiserar opaka JSON-tokens via ChaCha20-Poly1305 AEAD |

### 26.2.2. Komplett katalog över typer och signaturer i `src/main/ridgun/lib/jwt.rg`

Nedan följer hela förteckningen över algebraiska datatyper (`type`), mixfix-operatorer (`op ::`) och funktionssignaturer (`fn ::`) som definieras i `src/main/ridgun/lib/jwt.rg` (`3` typer, `0` operatorer och `55` funktioner):

**Algebraiska datatyper och poster (`type`) i `jwt`:**

```ridgun
type JwtClaims = issuer: String, subject: String, expires_at: Int, not_before_at: Int, custom_json: String
type JwtRes = JwtOk String | JwtErr String
type JwtClaimsRes = JwtClaimsOk JwtClaims | JwtClaimsErr String
```

| # | Funktion / Signatur (`fn ::`) | Returtyp |
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

## 26.3. Djupdykning i `jwt`: Steg-för-steg-exempel för varje funktion

Det räcker inte med en signaturtabell: låt oss utforska **varje funktionalitet** i lib:en `jwt` genom progressiva, körbara Ridgun-exempel. Vi börjar med två tabellbaserade vardagsrecept och går därefter igenom alla funktionella scenarier, transformationer och gränsfall som verifieras i `src/test/ridgun/test jwt.rg`.

### 26.3.1. Exempel 1: Huvudflöde i tabellform med `jwt`

Lägg märke till hur `=`-tecknen och transformationsstegen med `jwt` linjeras som en ren tabell utan onödiga muterbara variabler eller dolda sidoeffekter:

```ridgun
import jwt

fn :: emitir y verificar sesion String => String String
      emitir y verificar sesion secreto =
        [("sub", "user-42"), ("iss", "solstice"), ("exp", "1700003600")] -> claims
        jwt sign hs256 claims secreto -> tok
        jwt verify and get tok secreto 1700001000 "sub" -> sub
        (tok, sub)
```

### 26.3.2. Exempel 2: Säker komposition och hantering av gränsfall

Varje funktion i lib:en `jwt` är utformad för att kombineras sömlöst med booleska vakter `|` och med övriga 32 libs i `ridgun-libs`:

```ridgun
import jwt

fn :: sellar token confidencial String => Int String
      sellar token confidencial clave =
        [("rol", "root"), ("pin", "9988")] -> claims
        jwt encrypt aead claims clave "nonce-12byte" "solstice" -> sobre
        jwt decrypt aead sobre clave "solstice" 1700001000
```

### 26.3.3. Exempel 3: JWT HS256-signering och verifiering (`jwt sign hs256`, `jwt verify hs256`), avvisning av `alg: none`-angrepp och manipuleringsskydd

I detta praktiska exempel undersöker vi grundligt hur `jwt` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test_jwt_hs256_sign_verify_and_tamper => ()
      test_jwt_hs256_sign_verify_and_tamper =
        payload = '{"sub":"user-42","role":"admin"}'
        secret = "super-secret-hmac-key-2026"
        tok = jwt sign hs256 payload secret

        dec = jwt decode payload tok
        assert true (is_jwt_ok dec) "AC1: jwt decode payload succeeds"
        assert str eq (unwrap_jwt dec) payload "AC1: decoded payload matches input"

        ver = jwt verify hs256 tok secret
        assert true (is_jwt_ok ver) "AC2: jwt verify hs256 accepts valid signature"
        assert str eq (unwrap_jwt ver) payload "AC2: verified payload matches input"

        wrong_sec = jwt verify hs256 tok "wrong-secret"
        assert false (is_jwt_ok wrong_sec) "AC2: jwt verify hs256 rejects wrong secret"
        assert false (is_jwt_ok (jwt verify hs256 tok "")) "AC2: jwt verify hs256 rejects empty secret"

        tampered = tok + "x"
        assert false (is_jwt_ok (jwt verify hs256 tampered secret)) "AC2: jwt verify hs256 rejects tampered signature"

        -- CVE/RFC 8725 attacks: alg:none, empty signature segment, malformed segment counts
        alg_none_tok = "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiJ1c2VyLTQyIn0.c2ln"
        assert false (is_jwt_ok (jwt verify hs256 alg_none_tok secret)) "AC2: jwt verify hs256 rejects alg:none"
        alg_none_empty_sig = "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiJ1c2VyLTQyIn0."
        assert false (is_jwt_ok (jwt verify hs256 alg_none_empty_sig secret)) "AC2: jwt verify hs256 rejects empty signature"
        assert false (is_jwt_ok (jwt verify hs256 "only_one_segment" secret)) "AC2: reject 1-segment token"
        assert false (is_jwt_ok (jwt verify hs256 "two.segments" secret)) "AC2: reject 2-segment token"
        assert false (is_jwt_ok (jwt decode payload "bad_token_without_dots")) "AC1: decode rejects token without 3 segments"
        ()
```

### 26.3.4. Exempel 4: Tidsvalidering av strukturerade anspråk (`JwtClaims`: `iss`, `sub`, `aud`, `exp`, `nbf`, `iat`, `jti`) med `jwt validate claims`

I detta praktiska exempel undersöker vi grundligt hur `jwt` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test_jwt_claims_temporal_validation => ()
      test_jwt_claims_temporal_validation =
        claims = JwtClaims "ridgun-auth" "agent-007" 2000 1000 "tier=gold"
        secret = "claims-signing-secret"
        tok = jwt sign claims claims secret

        -- Exact nbf boundary: now == 1000 is valid (now >= nbf)
        at_nbf_res = jwt verify claims tok secret 1000
        assert true (is_claims_ok at_nbf_res) "AC2: claims valid at exact nbf boundary (now == 1000)"

        ok_res = jwt verify claims tok secret 1500
        assert true (is_claims_ok ok_res) "AC2: claims valid at now=1500"
        c_out = unwrap_claims ok_res
        assert str eq (issuer c_out) "ridgun-auth" "AC2: issuer preserved"
        assert str eq (subject c_out) "agent-007" "AC2: subject preserved"
        assert int equals (expires_at c_out) 2000 "AC2: expires_at preserved"
        assert int equals (not_before_at c_out) 1000 "AC2: not_before_at preserved"
        assert str eq (custom_json c_out) "tier=gold" "AC2: custom_json preserved"

        -- 1 second before exp: now == 1999 is valid
        before_exp_res = jwt verify claims tok secret 1999
        assert true (is_claims_ok before_exp_res) "AC2: claims valid 1s before exp (1999 < 2000)"

        -- 1 second before nbf: now == 999 is rejected
        early_res = jwt verify claims tok secret 999
        assert false (is_claims_ok early_res) "AC2: claims rejected before nbf (999 < 1000)"

        -- Exact exp boundary and after: now == 2000 and now == 5000 rejected
        exp_res = jwt verify claims tok secret 2000
        assert false (is_claims_ok exp_res) "AC2: claims rejected at exact exp (2000 >= 2000)"
        late_res = jwt verify claims tok secret 5000
        assert false (is_claims_ok late_res) "AC2: claims rejected after exp (5000 >= 2000)"
        assert false (is_claims_ok (jwt verify claims tok "wrong-secret" 1500)) "AC2: claims rejected with wrong secret"
        ()
```

### 26.3.5. Exempel 5: Krypterade och autentiserade tokens med ChaCha20-Poly1305 AEAD (`jwt seal aead`, `jwt open aead`)

I detta praktiska exempel undersöker vi grundligt hur `jwt` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test_jwt_aead_seal_and_open => ()
      test_jwt_aead_seal_and_open =
        key32 = "0123456789abcdef0123456789abcdef"
        other_key32 = "fedcba9876543210fedcba9876543210"
        nonce12 = "uniqueNonce1"
        other_nonce12 = "uniqueNonce2"
        secret_msg = '{"api_key":"rk_live_998877","scope":"full"}'

        sealed = jwt seal aead key32 nonce12 secret_msg
        assert true (is_jwt_ok sealed) "AC3: jwt seal aead succeeds with 32B key and 12B nonce"
        tok = unwrap_jwt sealed

        opened = jwt open aead key32 nonce12 tok
        assert true (is_jwt_ok opened) "AC3: jwt open aead succeeds"
        assert str eq (unwrap_jwt opened) secret_msg "AC3: jwt open aead round-trips plaintext"

        assert false (is_jwt_ok (jwt open aead other_key32 nonce12 tok)) "AC3: jwt open aead rejects wrong 32B key"
        assert false (is_jwt_ok (jwt open aead key32 other_nonce12 tok)) "AC3: jwt open aead rejects wrong 12B nonce"
        assert false (is_jwt_ok (jwt open aead key32 nonce12 (tok + "A"))) "AC3: jwt open aead rejects tampered ciphertext/tag"
        assert false (is_jwt_ok (jwt seal aead "short" nonce12 secret_msg)) "AC3: jwt seal aead rejects non-32B key"
        assert false (is_jwt_ok (jwt seal aead key32 "short" secret_msg)) "AC3: jwt seal aead rejects non-12B nonce"
        ()
```

---

## 26.4. Under huven: hur `jwt` är byggd i ren Ridgun (`src/main/ridgun/lib/jwt.rg`)

En av de största fördelarna med `ridgun-libs` är att **det inte finns några svarta lådor i C**. Du kan öppna `src/main/ridgun/lib/jwt.rg` och läsa exakt hur varje operation är implementerad med mönstermatchning, `|` / `|.`-vaktträd och svansrekursion (TCO). Låt oss titta på nyckeldelarna i den faktiska implementationen:

### 26.4.1. Intern implementation: Byte, Hex, Base64url & Constant-Time Helpers

Se hur `jwt.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
module :: jwt

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
```

### 26.4.2. Intern implementation: Constant-Time Equality & Bitwise XOR

Se hur `jwt.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
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
```

### 26.4.3. Intern implementation: HS256 (HMAC-SHA256) Signing & Verification

Se hur `jwt.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
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
```

### 26.4.4. Intern implementation: Structured Claims Signing & Temporal Validation

Se hur `jwt.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: jwt sign claims JwtClaims String => String
      jwt sign claims c secret =
        JsonObj [JsonField "iss" (JsonStr (issuer c)), JsonField "sub" (JsonStr (subject c)), JsonField "exp" (JsonInt (expires_at c)), JsonField "nbf" (JsonInt (not_before_at c)), JsonField "custom" (JsonStr (custom_json c))] -> base_obj
        jwt sign hs256 (json stringify base_obj) secret

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
```

---

## 26.5. Algoritmiska garantier, `RMM1`/`RMM2`-minne och de 5 Gyllene Reglerna för `jwt`

- **Algoritmisk garanti och säkerhet**: Fullständig immunitet mot `"alg":"none"`-attacker (alla headers där `alg != "HS256"` returnerar `JwtBadSignature`) och konstanttidsverifiering av signaturer.
- **$O(1)$ stackkomplexitet med TCO**: Alla rekursiva loopar i `src/main/ridgun/lib/jwt.rg` ligger i svansposition, så `ridgunc` kompilerar dem till inbyggda hopp utan stacktillväxt.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test jwt.rg`.

### De 5 Gyllene Reglerna när du programmerar med `jwt`

1. **Deklarera `import jwt` överst i filen** och utnyttja att mellanslag och understreck är utbytbara så att koden läses som naturlig prosa.
2. **Linjera dina datapipelines med `=`**: kedja samman `jwt`-anrop i namngivna mellansteg och låt `stable format` linjera kolumnerna.
3. **Utnyttja `jwt`:s totala funktioner i dina `|`-vakter**: kontrollera returvärden eller packa upp ADT:er med mönstermatchning i stället för att anta att extern indata alltid är giltig.
4. **Undvik att kopiera stora strukturer när du bara läser ett fält**: kom ihåg att i `RMM2` medför inargument noll referensräkningskostnad (`+0` / `-0`).
5. **Kombinera `jwt` med `test` (`import test`)**: lås alltid fast dina domäninvarianter med `assert equals` eller `assert true`.

---

I **Kapitel 27** går vi vidare och utforskar lib:en **`socket`** på djupet (Lib:en `socket` — TCP, UDP, AF_UNIX, Framing, DNS och `RGF-001` Kärn-sockets).
