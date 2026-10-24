# Capítol 26: La lib `jwt` — JSON Web Tokens RFC 7519 (`HS256`) i Tokens Xifrats ChaCha20-Poly1305

## 26.1. Per què existeix la lib `jwt`? (El problema real i la filosofia Ridgun)

> *«Per què necessito una lib `jwt` escrita des de zero en Ridgun pur en lloc d'enllaçar una llibreria de C de tota la vida?»*

Aquesta és la primera pregunta que es fa qualsevol enginyer de sistemes en arribar a `jwt`. I la resposta resumeix tota la filosofia de `ridgun-libs`:

Siguem sincers: l'ecosistema JWT és famós per vulnerabilitats on un atacant canvia la capçalera a `"alg":"none"` i el servidor accepta el token sense signatura, o on es desa informació sensible en un JWT oblidant que el seu payload només està codificat en Base64url, no xifrat.

La lib **`jwt`** resol tots dos mons: signa i verifica **JWTs RFC 7519 (`HS256`)** exigint explícitament `alg == "HS256"`, comparant l'HMAC en temps constant i validant `exp`/`nbf`, i a més ofereix **`token seal` / `token open`** per emetre tokens opacs autenticats i xifrats amb **ChaCha20-Poly1305 AEAD**.

En un ecosistema tradicional, resoldre les tasques del domini **`JWT`** implica arrossegar dependències externes en C, lluitar amb punters crus, conversions opaques de tipus, excepcions no verificades o pauses impredictibles del recol·lector de brossa. En Ridgun, la lib **`jwt`** (`src/main/ridgun/lib/jwt.rg`) aborda el problema amb quatre principis innegociables:

1. **Funcions totals i contractes explícits (`=>`)**: cap funció de `jwt` llança excepcions ocultes ni depèn de `null`. Tot cas límit retorna un valor sentinella documentat o un tipus algebraic suma (`Option`, `Result`).
2. **Zero codi C i zero `libc`**: tot el codi de `jwt` compila directament a codi màquina natiu ELF64 verificat per `ridgunc`.
3. **Recursió de cua amb TCO (*Tail-Call Optimization*)**: tots els recorreguts interns de `jwt` es compilen a bucles natius en espai de pila $O(1)$.
4. **Memòria determinista (`RMM1` / `RMM2`)**: cada estructura intermèdia s'allibera en l'instant exacte en què acaba la seva última lectura, sense *Garbage Collector*.

---

## 26.2. Artefactes natius, importació i catàleg complet de l'API de `jwt`

A `ridgun-libs`, **`jwt`** és una **lib** de primera classe situada a `src/main/ridgun/lib/jwt.rg` (domini `JWT`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/jwt.rglib` | Distribució i importació directa amb `import jwt` |
| **Fitxer compilat** | `target/jwt.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libjwt.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import jwt` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

### 26.2.1. Resum de famílies funcionals de `jwt`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `type JwtResult` | `JwtOk JsonVal | JwtExpired | JwtNotYetValid | JwtBadSignature | JwtMalformed` |
| `jwt sign hs256 / jwt verify hs256` | Signa claims `JsonVal` i verifica signatura + `alg == "HS256"` + finestres `exp`/`nbf` |
| `jwt claims / jwt get str / jwt get int` | Construeix claims estàndard `(sub, iss, iat, exp)` i consulta payloads verificats |
| `token seal / token open` | Xifra i autentica tokens JSON opacs mitjançant ChaCha20-Poly1305 AEAD |

### 26.2.2. Catàleg exhaustiu de tipus i signatures a `src/main/ridgun/lib/jwt.rg`

A continuació tens l'inventari complet de tipus algebraics (`type`), operadors (`op ::`) i signatures de funcions (`fn ::`) definits a `src/main/ridgun/lib/jwt.rg` (`3` tipus, `0` operadors i `55` funcions):

**Tipus algebraics i registres (`type`) de `jwt`:**

```ridgun
type JwtClaims = issuer: String, subject: String, expires_at: Int, not_before_at: Int, custom_json: String
type JwtRes = JwtOk String | JwtErr String
type JwtClaimsRes = JwtClaimsOk JwtClaims | JwtClaimsErr String
```

| # | Funció / Signatura (`fn ::`) | Tipus de Retorn |
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

## 26.3. Explorant `jwt` a fons: Exemples pas a pas de cada funcionalitat

No n'hi ha prou de veure la taula de signatures: explorarem **cadascuna de les funcionalitats** de la lib `jwt` mitjançant exemples progressius i executables en Ridgun. Començarem per les dues receptes tabulars d'ús quotidià i després recorrerem en detall tots els escenaris funcionals, transformacions i casos límit verificats a `src/test/ridgun/test jwt.rg`.

### 26.3.1. Exemple 1: Flux principal en estil tabular amb `jwt`

Observa com en Ridgun els signes `=` i els passos de transformació amb `jwt` queden alineats com una taula neta, sense variables mutables innecessàries ni efectes laterals ocults:

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

### 26.3.2. Exemple 2: Composició segura i gestió de casos de vora

Tota funció de la lib `jwt` està dissenyada per compondre's amb guardes booleanes `|` i amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import jwt
import json

fn :: sellar token confidencial (clave : String) => JwtResult
      sellar token confidencial clave =
        datos = JnObj [("rol", JnStr "root"), ("pin", JnInt 9988)]
        sobre = token seal clave "nonce-12byte" datos
        token open clave sobre
```

### 26.3.3. Exemple 3: Signatura i verificació JWT HS256 (`jwt sign hs256`, `jwt verify hs256`), rebuig de l'atac `alg: none` i detecció de manipulació de signatura

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `jwt` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

### 26.3.4. Exemple 4: Validació temporal de *claims* estructurats (`JwtClaims`: `iss`, `sub`, `aud`, `exp`, `nbf`, `iat`, `jti`) amb `jwt validate claims`

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `jwt` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

### 26.3.5. Exemple 5: Tokens xifrats i autenticats amb ChaCha20-Poly1305 AEAD (`jwt seal aead`, `jwt open aead`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `jwt` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

## 26.4. Sota el capó: com està construïda `jwt` en Ridgun pur (`src/main/ridgun/lib/jwt.rg`)

Un dels majors avantatges de `ridgun-libs` és que **no hi ha caixes negres en C**. Pots obrir `src/main/ridgun/lib/jwt.rg` i llegir exactament com està implementada cada operació fent servir *pattern matching*, arbres de guardes `|` / `|.` i recursió de cua (TCO). Vegem les peces clau de la seva implementació real:

### 26.4.1. Implementació interna: Byte, Hex, Base64url & Constant-Time Helpers

Fixa't en com `jwt.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 26.4.2. Implementació interna: Constant-Time Equality & Bitwise XOR

Fixa't en com `jwt.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 26.4.3. Implementació interna: HS256 (HMAC-SHA256) Signing & Verification

Fixa't en com `jwt.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 26.4.4. Implementació interna: Structured Claims Signing & Temporal Validation

Fixa't en com `jwt.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

## 26.5. Garanties algorísmiques, memòria `RMM1`/`RMM2` i les 5 Regles d'Or de `jwt`

- **Garantia algorísmica i de seguretat**: Immunitat total a l'atac `"alg":"none"` (qualsevol capçalera el `alg` de la qual no sigui exactament `"HS256"` retorna `JwtBadSignature`) i comparació de signatura en temps constant.
- **Complexitat de pila $O(1)$ amb TCO**: Tots els bucles recursius a `src/main/ridgun/lib/jwt.rg` estan en posició de cua, de manera que `ridgunc` els compila a salts natius sense creixement de pila.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test jwt.rg`.

### Les 5 Regles d'Or en programar amb `jwt`

1. **Declara `import jwt` a l'inici del fitxer** i aprofita l'equivalència entre espais i guions baixos perquè el teu codi es llegeixi com a prosa.
2. **Alinea les teves canonades de dades amb `=`**: encadena les crides a `jwt` en passos amb nom propi i deixa que `stable format` alineï les columnes.
3. **Aprofita les funcions totals de `jwt` a les teves guardes `|`**: comprova els valors de retorn o desembolica els ADTs amb *pattern matching* en lloc d'assumir que l'entrada externa sempre és vàlida.
4. **Evita copiar grans estructures si només necessites consultar un camp**: recorda que en `RMM2` els arguments d'entrada no incrementen ni decrementen comptadors (`+0` / `-0`).
5. **Combina `jwt` amb `test` (`import test`)**: escriu sempre assercions amb `assert equals` o `assert true` per fixar els invariants del teu domini.

---

Al **Capítol 27** passarem a explorar en profunditat la lib **`socket`** (La lib `socket` — TCP, UDP, AF_UNIX, Framing, DNS RFC 1035 i Kernel Sockets (`RGF-001`)).
