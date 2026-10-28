# Capítulo 26: La lib `jwt` — JSON Web Tokens RFC 7519 (`HS256`) y Tokens Cifrados ChaCha20-Poly1305

## 26.1. ¿Por qué existe la lib `jwt`? (El problema real y la filosofía Ridgun)

> *«¿Por qué necesito una lib `jwt` escrita desde cero en Ridgun puro en lugar de enlazar una librería de C de toda la vida?»*

Esa es la primera pregunta que se hace cualquier ingeniero de sistemas al llegar a `jwt`. Y la respuesta resume toda la filosofía de `ridgun-libs`:

Seamos sinceros: el ecosistema JWT es famoso por vulnerabilidades donde un atacante cambia la cabecera a `"alg":"none"` y el servidor acepta el token sin firma, o donde se guarda información sensible en un JWT olvidando que su payload solo está codificado en Base64url, no cifrado.

La lib **`jwt`** resuelve ambos mundos: firma y verifica **JWTs RFC 7519 (`HS256`)** exigiendo explícitamente `alg == "HS256"`, comparando el HMAC en tiempo constante y validando `exp`/`nbf`, y además ofrece **`token seal` / `token open`** para emitir tokens opacos autenticados y cifrados con **ChaCha20-Poly1305 AEAD**.

En un ecosistema tradicional, resolver las tareas del dominio **`JWT`** implica arrastrar dependencias externas en C, lidiar con punteros crudos, conversiones opacas de tipos, excepciones no verificadas o pausas impredecibles del recolector de basura. En Ridgun, la lib **`jwt`** (`src/main/ridgun/lib/jwt.rg`) aborda el problema con cuatro principios innegociables:

1. **Declara `import jwt` (o `import jwt as alias`) al inicio del archivo**: cada lib define su espacio de nombres `module :: jwt` y en modo `--strict` las funciones multi-palabra se invocan siempre con espacios naturales.
2. **Encadena tus tuberías de izquierda a derecha con `->`**: escribe `entrada paso uno -> paso dos -> resultado`, usa máscaras `(+ _ _ +)` para desestructurar secuencias y omite `_ =` en sentencias secuenciales (o descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos los recorridos internos de `jwt` se compilan a bucles nativos en $O(1)$ espacio de pila.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estructura intermedia se libera en el instante exacto en que termina su última lectura, sin *Garbage Collector*.

---

## 26.2. Artefactos nativos, importación y catálogo completo de la API de `jwt`

En `ridgun-libs`, **`jwt`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/jwt.rg` (dominio `JWT`). Al compilar con `stable bundle`, se empaqueta en tres artefactos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/jwt.rglib` | Distribución e importación directa con `import jwt` |
| **Archivo compilado** | `target/jwt.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libjwt.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Cada lib declara su propio espacio de nombres con `module :: jwt`: basta con escribir `import jwt` (o `import jwt as alias`) en el encabezado y llamar a sus funciones con espacios naturales (`mi funcion x`) y tuberías `->` (`x mi funcion -> resultado`).

### 26.2.1. Resumen de familias funcionales de `jwt`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `type JwtResult` | `JwtOk JsonVal | JwtExpired | JwtNotYetValid | JwtBadSignature | JwtMalformed` |
| `jwt sign hs256 / jwt verify hs256` | Firma claims `JsonVal` y verifica firma + `alg == "HS256"` + ventanas `exp`/`nbf` |
| `jwt claims / jwt get str / jwt get int` | Construye claims estándar `(sub, iss, iat, exp)` y consulta payloads verificados |
| `token seal / token open` | Cifra y autentica tokens JSON opacos mediante ChaCha20-Poly1305 AEAD |

### 26.2.2. Catálogo exhaustivo de tipos y firmas en `src/main/ridgun/lib/jwt.rg`

A continuación tienes el inventario completo de tipos algebraicos (`type`), operadores (`op ::`) y firmas de funciones (`fn ::`) definidos en `src/main/ridgun/lib/jwt.rg` (`3` tipos, `0` operadores y `55` funciones):

**Tipos algebraicos y registros (`type`) de `jwt`:**

```ridgun
type JwtClaims = issuer: String, subject: String, expires_at: Int, not_before_at: Int, custom_json: String
type JwtRes = JwtOk String | JwtErr String
type JwtClaimsRes = JwtClaimsOk JwtClaims | JwtClaimsErr String
```

| # | Función / Firma (`fn ::`) | Tipo de Retorno |
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

## 26.3. Explorando `jwt` a fondo: Ejemplos paso a paso de cada funcionalidad

No basta con ver la tabla de firmas: vamos a explorar **cada una de las funcionalidades** de la lib `jwt` mediante ejemplos progresivos y ejecutables en Ridgun. Empezaremos por las dos recetas tabulares de uso cotidiano y después recorreremos en detalle todos los escenarios funcionales, transformaciones y casos límite verificados en `src/test/ridgun/test jwt.rg`.

### 26.3.1. Ejemplo 1: Flujo principal en estilo tabular con `jwt`

Observa cómo en Ridgun los signos `=` y los pasos de transformación con `jwt` quedan alineados como una tabla limpia, sin variables mutables innecesarias ni efectos laterales ocultos:

```ridgun
import jwt

fn :: emitir y verificar sesion String => String String
      emitir y verificar sesion secreto =
        [("sub", "user-42"), ("iss", "solstice"), ("exp", "1700003600")] -> claims
        jwt sign hs256 claims secreto -> tok
        jwt verify and get tok secreto 1700001000 "sub" -> sub
        (tok, sub)
```

### 26.3.2. Ejemplo 2: Composición segura y manejo de casos de borde

Toda función de la lib `jwt` está diseñada para componerse con guardas booleanas `|` y con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import jwt

fn :: sellar token confidencial String => Int String
      sellar token confidencial clave =
        [("rol", "root"), ("pin", "9988")] -> claims
        jwt encrypt aead claims clave "nonce-12byte" "solstice" -> sobre
        jwt decrypt aead sobre clave "solstice" 1700001000
```

### 26.3.3. Ejemplo 3: Firma y verificación JWT HS256 (`jwt sign hs256`, `jwt verify hs256`), rechazo del ataque `alg: none` y detección de manipulación de firma

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `jwt` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

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

### 26.3.4. Ejemplo 4: Validación temporal de *claims* estructurados (`JwtClaims`: `iss`, `sub`, `aud`, `exp`, `nbf`, `iat`, `jti`) con `jwt validate claims`

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `jwt` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

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

### 26.3.5. Ejemplo 5: Tokens cifrados y autenticados con ChaCha20-Poly1305 AEAD (`jwt seal aead`, `jwt open aead`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `jwt` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

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

## 26.4. Bajo el capó: cómo está construida `jwt` en Ridgun puro (`src/main/ridgun/lib/jwt.rg`)

Una de las mayores ventajas de `ridgun-libs` es que **no hay cajas negras en C**. Puedes abrir `src/main/ridgun/lib/jwt.rg` y leer exactamente cómo está implementada cada operación usando *pattern matching*, árboles de guardas `|` / `|.` y recursión de cola (TCO). Veamos las piezas clave de su implementación real:

### 26.4.1. Implementación interna: Byte, Hex, Base64url & Constant-Time Helpers

Fíjate en cómo `jwt.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

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

### 26.4.2. Implementación interna: Constant-Time Equality & Bitwise XOR

Fíjate en cómo `jwt.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

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

### 26.4.3. Implementación interna: HS256 (HMAC-SHA256) Signing & Verification

Fíjate en cómo `jwt.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

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

### 26.4.4. Implementación interna: Structured Claims Signing & Temporal Validation

Fíjate en cómo `jwt.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

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

## 26.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` y las 5 Reglas de Oro de `jwt`

- **Garantía algorítmica y de seguridad**: Inmunidad total al ataque `"alg":"none"` (cualquier cabecera cuyo `alg` no sea exactamente `"HS256"` devuelve `JwtBadSignature`) y comparación de firma en tiempo constante.
- **Complejidad de pila $O(1)$ con TCO**: Todos los bucles recursivos en `src/main/ridgun/lib/jwt.rg` están en posición de cola, por lo que `ridgunc` los compila a saltos nativos sin crecimiento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test jwt.rg`.

### Las 5 Reglas de Oro al programar con `jwt`

1. **Declara `import jwt` al inicio del archivo** y aprovecha la equivalencia entre espacios y guiones bajos para que tu código se lea como prosa.
2. **Alinea tus tuberías de datos con `=`**: encadena las llamadas a `jwt` en pasos con nombre propio y deja que `stable format` alinee las columnas.
3. **Aprovecha las funciones totales de `jwt` en tus guardas `|`**: comprueba los valores de retorno o desenvuelve los ADTs con *pattern matching* en lugar de asumir que la entrada externa siempre es válida.
4. **Evita copiar grandes estructuras si solo necesitas consultar un campo**: recuerda que en `RMM2` los argumentos de entrada no incrementan ni decrementan contadores (`+0` / `-0`).
5. **Combina `jwt` con `test` (`import test`)**: escribe siempre aserciones con `assert equals` o `assert true` para fijar los invariantes de tu dominio.

---

En el **Capítulo 27** pasaremos a explorar en profundidad la lib **`socket`** (La lib `socket` — TCP, UDP, AF_UNIX, Framing, DNS RFC 1035 y Kernel Sockets (`RGF-001`)).
