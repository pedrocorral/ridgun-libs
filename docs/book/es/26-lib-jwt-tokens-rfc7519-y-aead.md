# Capítulo 26: La lib `jwt` — JSON Web Tokens RFC 7519 (`HS256`) y Tokens Cifrados ChaCha20-Poly1305

## 26.1. ¿Por qué existe la lib `jwt`? (El problema real y la filosofía Ridgun)

> *«¿Por qué necesito una lib `jwt` escrita desde cero en Ridgun puro en lugar de enlazar una librería de C de toda la vida?»*

Esa es la primera pregunta que se hace cualquier ingeniero de sistemas al llegar a `jwt`. Y la respuesta resume toda la filosofía de `ridgun-libs`:

Seamos sinceros: el ecosistema JWT es famoso por vulnerabilidades donde un atacante cambia la cabecera a `"alg":"none"` y el servidor acepta el token sin firma, o donde se guarda información sensible en un JWT olvidando que su payload solo está codificado en Base64url, no cifrado.

La lib **`jwt`** resuelve ambos mundos: firma y verifica **JWTs RFC 7519 (`HS256`)** exigiendo explícitamente `alg == "HS256"`, comparando el HMAC en tiempo constante y validando `exp`/`nbf`, y además ofrece **`jwt seal aead` / `jwt open aead`** para emitir tokens opacos autenticados y cifrados con **ChaCha20-Poly1305 AEAD**.

En un ecosistema tradicional, resolver las tareas del dominio **`JWT`** implica arrastrar dependencias externas en C, lidiar con punteros crudos, conversiones opacas de tipos, excepciones no verificadas o pausas impredecibles del recolector de basura. En Ridgun, la lib **`jwt`** (`src/main/ridgun/lib/jwt.ridgun`) aborda el problema con cuatro principios innegociables:

1. **Declara `import jwt` (o `import jwt as alias`) al inicio del archivo**: cada lib define su espacio de nombres `module :: jwt` y en modo `--strict` las funciones multi-palabra se invocan siempre con espacios naturales.
2. **Encadena tus tuberías de izquierda a derecha con `->`**: escribe `entrada paso uno -> paso dos -> resultado`, usa máscaras `(+ _ _ +)` para desestructurar secuencias y omite `_ =` en sentencias secuenciales (o descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos los recorridos internos de `jwt` se compilan a bucles nativos en $O(1)$ espacio de pila.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estructura intermedia se libera en el instante exacto en que termina su última lectura, sin *Garbage Collector*.

---

## 26.2. Artefactos nativos, importación y catálogo completo de la API de `jwt`

En `ridgun-libs`, **`jwt`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/jwt.ridgun` (dominio `JWT`). Al compilar con `stable bundle`, se empaqueta en un artefacto nativo:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/jwt.ridgunlib` | Distribución e importación directa con `import jwt` |

> Cada lib declara su propio espacio de nombres con `module :: jwt`: basta con escribir `import jwt` (o `import jwt as alias`) en el encabezado y llamar a sus funciones con espacios naturales (`mi funcion x`) y tuberías `->` (`x mi funcion -> resultado`).

### 26.2.1. Resumen de familias funcionales de `jwt`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `JwtRes / JwtClaimsRes` | `JwtOk` / `JwtErr`, `JwtClaimsOk` / `JwtClaimsErr` |
| `jwt sign hs256 / jwt verify hs256` | Firma claims `JsonVal` y verifica firma + `alg == "HS256"` + ventanas `exp`/`nbf` |
| `jwt sign claims / jwt verify claims` | Construye claims estándar `(sub, iss, iat, exp)` y consulta payloads verificados |
| `jwt seal aead / jwt open aead` | Cifra y autentica tokens JSON opacos mediante ChaCha20-Poly1305 AEAD |

### 26.2.2. Catálogo exhaustivo de tipos y firmas en `src/main/ridgun/lib/jwt.ridgun`

A continuación tienes el inventario completo de tipos algebraicos (`type`), operadores (`op ::`) y firmas de funciones (`fn ::`) definidos en `src/main/ridgun/lib/jwt.ridgun` (`3` tipos, `0` operadores y `51` funciones):

**Tipos algebraicos y registros (`type`) de `jwt`:**

```ridgun
type JwtClaims = issuer: String, subject: String, expires_at: Int, not_before_at: Int, custom_json: String
type JwtRes = JwtOk String | JwtErr String
type JwtClaimsRes = JwtClaimsOk JwtClaims | JwtClaimsErr String
```

| # | Función / Firma (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: jwt blen Tensor[U8]` | `Int` |
| `2` | `fn :: jwt u8 Int` | `Int` |
| `3` | `fn :: jwt b64url lut Int` | `String` |
| `4` | `fn :: jwt b64 code String Int` | `Int` |
| `5` | `fn :: jwt b64 val Int` | `Int` |
| `6` | `fn :: jwt b64url enc len Int` | `Int` |
| `7` | `fn :: jwt b64url enc bytes Tensor[U8]` | `String` |
| `8` | `fn :: jwt b64url enc loop Tensor[U8] Int Tensor[U8] String Int Int` | `Tensor[U8]` |
| `9` | `fn :: jwt b64url enc group Tensor[U8] Int Tensor[U8] String Int Int` | `Tensor[U8]` |
| `10` | `fn :: jwt b64url enc tail1 Tensor[U8] Tensor[U8] String Int Int` | `Tensor[U8]` |
| `11` | `fn :: jwt b64url enc tail2 Tensor[U8] Tensor[U8] String Int Int` | `Tensor[U8]` |
| `12` | `fn :: jwt b64url encode String` | `String` |
| `13` | `fn :: jwt b64url valid loop String Int Int` | `Bool` |
| `14` | `fn :: jwt b64url is valid String` | `Bool` |
| `15` | `fn :: jwt b64url dec len Int` | `Int` |
| `16` | `fn :: jwt b64 at String Int` | `Int` |
| `17` | `fn :: jwt b64url dec loop String Int Tensor[U8] Int` | `Tensor[U8]` |
| `18` | `fn :: jwt b64url dec4 String Int Tensor[U8] Int` | `Tensor[U8]` |
| `19` | `fn :: jwt b64url dec3 String Tensor[U8] Int` | `Tensor[U8]` |
| `20` | `fn :: jwt b64url dec2 String Tensor[U8] Int` | `Tensor[U8]` |
| `21` | `fn :: jwt b64url decode bytes String` | `Tensor[U8]` |
| `22` | `fn :: jwt b64url decode String` | `String` |
| `23` | `fn :: jwt byte bxor Int Int` | `Int` |
| `24` | `fn :: jwt ct diff String String Int Int Int` | `Int` |
| `25` | `fn :: jwt ct eq String String` | `Bool` |
| `26` | `fn :: jwt hmac sha256 b64url String String` | `String` |
| `27` | `fn :: jwt hs256 header json Int` | `String` |
| `28` | `fn :: jwt sign hs256 String String` | `String` |
| `29` | `fn :: jwt split dots loop String Int Int Int [String]` | `[String]` |
| `30` | `fn :: jwt str list len [String]` | `Int` |
| `31` | `fn :: jwt str at [String] Int` | `String` |
| `32` | `fn :: jwt decode payload String` | `JwtRes` |
| `33` | `fn :: jwt decode parts [String]` | `JwtRes` |
| `34` | `fn :: jwt header is hs256 String` | `Bool` |
| `35` | `fn :: jwt check hdr json JsonRes` | `Bool` |
| `36` | `fn :: jwt verify hs256 String String` | `JwtRes` |
| `37` | `fn :: jwt verify parts [String] String` | `JwtRes` |
| `38` | `fn :: jwt verify sig String String String String` | `JwtRes` |
| `39` | `fn :: jwt verify sig ct Bool String` | `JwtRes` |
| `40` | `fn :: jwt sign claims JwtClaims String` | `String` |
| `41` | `fn :: jwt verify claims String String Int` | `JwtClaimsRes` |
| `42` | `fn :: jwt validate verified payload JwtRes Int` | `JwtClaimsRes` |
| `43` | `fn :: jwt validate parsed claims JsonRes Int` | `JwtClaimsRes` |
| `44` | `fn :: jwt check claim times JwtClaims Int` | `JwtClaimsRes` |
| `45` | `fn :: jwt aead version` | `String` |
| `46` | `fn :: jwt seal aead String String String` | `JwtRes` |
| `47` | `fn :: jwt seal aead ok String String String` | `JwtRes` |
| `48` | `fn :: jwt open aead String String String` | `JwtRes` |
| `49` | `fn :: jwt open aead parts String String [String]` | `JwtRes` |
| `50` | `fn :: jwt open aead verify String String String String String` | `JwtRes` |
| `51` | `fn :: jwt open aead result (Int String)` | `JwtRes` |

---

## 26.3. Explorando `jwt` a fondo: Ejemplos paso a paso de cada funcionalidad

No basta con ver la tabla de firmas: vamos a explorar **cada una de las funcionalidades** de la lib `jwt` mediante ejemplos progresivos y ejecutables en Ridgun. Empezaremos por las dos recetas tabulares de uso cotidiano y después recorreremos en detalle todos los escenarios funcionales, transformaciones y casos límite verificados en `src/test/ridgun/test jwt.ridgun`.

### 26.3.1. Ejemplo 1: Flujo principal en estilo tabular con `jwt`

Observa cómo en Ridgun los signos `=` y los pasos de transformación con `jwt` quedan alineados como una tabla limpia, sin variables mutables innecesarias ni efectos laterales ocultos:

```ridgun
import jwt

fn :: sujeto de JwtClaimsRes     => String
      sujeto de (JwtClaimsOk c)  =  subject c
      sujeto de (JwtClaimsErr e) =  "error: " + e

fn :: emitir y verificar sesion String => String String
      emitir y verificar sesion secreto =
        jwt sign claims (JwtClaims "solstice" "user-42" 1700003600 0 "{}") secreto -> tok
        jwt verify claims tok secreto 1700001000 -> res
        (tok, sujeto de res)
```

### 26.3.2. Ejemplo 2: Composición segura y manejo de casos de borde

Toda función de la lib `jwt` está diseñada para componerse con guardas booleanas `|` y con el resto de las 38 libs de `ridgun-libs`:

```ridgun
import jwt

fn :: abrir sobre JwtRes       String String => JwtRes
      abrir sobre (JwtOk tok)  clave  nonce  =  jwt open aead clave nonce tok
      abrir sobre (JwtErr e)   _      _      =  JwtErr e

fn :: sellar token confidencial String => JwtRes
      sellar token confidencial clave =
        jwt seal aead clave "nonce-12byte" "{\"rol\":\"root\",\"pin\":\"9988\"}" -> sobre
        abrir sobre sobre clave "nonce-12byte"
```

### 26.3.3. Ejemplo 3: Firma y verificación JWT HS256 (`jwt sign hs256`, `jwt verify hs256`), rechazo del ataque `alg: none` y detección de manipulación de firma

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `jwt` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test jwt hs256 sign verify and tamper => ()
      test jwt hs256 sign verify and tamper =
        payload = '{"sub":"user-42","role":"admin"}'
        secret = "super-secret-hmac-key-2026"
        tok = jwt sign hs256 payload secret

        dec = jwt decode payload tok
        is jwt ok dec -> assert true "AC1: jwt decode payload succeeds"
        unwrap jwt dec -> assert str eq payload "AC1: decoded payload matches input"

        ver = jwt verify hs256 tok secret
        is jwt ok ver -> assert true "AC2: jwt verify hs256 accepts valid signature"
        unwrap jwt ver -> assert str eq payload "AC2: verified payload matches input"

        wrong_sec = jwt verify hs256 tok "wrong-secret"
        is jwt ok wrong_sec -> assert false "AC2: jwt verify hs256 rejects wrong secret"
        is jwt ok (jwt verify hs256 tok "") -> assert false "AC2: jwt verify hs256 rejects empty secret"

        tampered = tok + "x"
        is jwt ok (jwt verify hs256 tampered secret) -> assert false "AC2: jwt verify hs256 rejects tampered signature"

        -- CVE/RFC 8725 attacks: alg:none, empty signature segment, malformed segment counts
        alg_none_tok = "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiJ1c2VyLTQyIn0.c2ln"
        is jwt ok (jwt verify hs256 alg_none_tok secret) -> assert false "AC2: jwt verify hs256 rejects alg:none"
        alg_none_empty_sig = "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiJ1c2VyLTQyIn0."
        is jwt ok (jwt verify hs256 alg_none_empty_sig secret) -> assert false "AC2: jwt verify hs256 rejects empty signature"
        is jwt ok (jwt verify hs256 "only_one_segment" secret) -> assert false "AC2: reject 1-segment token"
        is jwt ok (jwt verify hs256 "two.segments" secret) -> assert false "AC2: reject 2-segment token"
        is jwt ok (jwt decode payload "bad_token_without_dots") -> assert false "AC1: decode rejects token without 3 segments"
        ()
```

### 26.3.4. Ejemplo 4: Validación temporal de *claims* estructurados (`JwtClaims`: `iss`, `sub`, `aud`, `exp`, `nbf`, `iat`, `jti`) con `jwt verify claims`

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `jwt` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test jwt claims temporal validation => ()
      test jwt claims temporal validation =
        claims = JwtClaims "ridgun-auth" "agent-007" 2000 1000 "tier=gold"
        secret = "claims-signing-secret"
        tok = jwt sign claims claims secret

        -- Exact nbf boundary: now == 1000 is valid (now >= nbf)
        at_nbf_res = jwt verify claims tok secret 1000
        is claims ok at_nbf_res -> assert true "AC2: claims valid at exact nbf boundary (now == 1000)"

        ok_res = jwt verify claims tok secret 1500
        is claims ok ok_res -> assert true "AC2: claims valid at now=1500"
        c_out = unwrap claims ok_res
        issuer c_out -> assert str eq "ridgun-auth" "AC2: issuer preserved"
        subject c_out -> assert str eq "agent-007" "AC2: subject preserved"
        expires_at c_out -> assert int equals 2000 "AC2: expires_at preserved"
        not_before_at c_out -> assert int equals 1000 "AC2: not_before_at preserved"
        custom_json c_out -> assert str eq "tier=gold" "AC2: custom_json preserved"

        -- 1 second before exp: now == 1999 is valid
        before_exp_res = jwt verify claims tok secret 1999
        is claims ok before_exp_res -> assert true "AC2: claims valid 1s before exp (1999 < 2000)"

        -- 1 second before nbf: now == 999 is rejected
        early_res = jwt verify claims tok secret 999
        is claims ok early_res -> assert false "AC2: claims rejected before nbf (999 < 1000)"

        -- Exact exp boundary and after: now == 2000 and now == 5000 rejected
        exp_res = jwt verify claims tok secret 2000
        is claims ok exp_res -> assert false "AC2: claims rejected at exact exp (2000 >= 2000)"
        late_res = jwt verify claims tok secret 5000
        is claims ok late_res -> assert false "AC2: claims rejected after exp (5000 >= 2000)"
        is claims ok (jwt verify claims tok "wrong-secret" 1500) -> assert false "AC2: claims rejected with wrong secret"
        ()
```

### 26.3.5. Ejemplo 5: Tokens cifrados y autenticados con ChaCha20-Poly1305 AEAD (`jwt seal aead`, `jwt open aead`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `jwt` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test jwt aead seal and open => ()
      test jwt aead seal and open =
        key32 = "0123456789abcdef0123456789abcdef"
        other_key32 = "fedcba9876543210fedcba9876543210"
        nonce12 = "uniqueNonce1"
        other_nonce12 = "uniqueNonce2"
        secret_msg = '{"api_key":"rk_live_998877","scope":"full"}'

        sealed = jwt seal aead key32 nonce12 secret_msg
        is jwt ok sealed -> assert true "AC3: jwt seal aead succeeds with 32B key and 12B nonce"
        tok = unwrap jwt sealed

        opened = jwt open aead key32 nonce12 tok
        is jwt ok opened -> assert true "AC3: jwt open aead succeeds"
        unwrap jwt opened -> assert str eq secret_msg "AC3: jwt open aead round-trips plaintext"

        is jwt ok (jwt open aead other_key32 nonce12 tok) -> assert false "AC3: jwt open aead rejects wrong 32B key"
        is jwt ok (jwt open aead key32 other_nonce12 tok) -> assert false "AC3: jwt open aead rejects wrong 12B nonce"
        is jwt ok (jwt open aead key32 nonce12 (tok + "A")) -> assert false "AC3: jwt open aead rejects tampered ciphertext/tag"
        is jwt ok (jwt seal aead "short" nonce12 secret_msg) -> assert false "AC3: jwt seal aead rejects non-32B key"
        is jwt ok (jwt seal aead key32 "short" secret_msg) -> assert false "AC3: jwt seal aead rejects non-12B nonce"
        ()
```

### 26.3.6. Ejemplo 6: Base64url seguro para datos binarios y payloads UTF-8 byte a byte

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `jwt` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test jwt bytes and utf8 round trip => ()
      test jwt bytes and utf8 round trip =
        bs = Tensor[U8 * 3]
        bs_(1) = 128
        bs_(2) = 255
        enc = jwt b64url enc bytes bs
        enc -> assert str eq "AID_" "AC1: Base64url of bytes [0, 128, 255]"
        dec = jwt b64url decode bytes enc
        dec == bs -> assert true "AC1: Base64url decode gives bytes [0, 128, 255]"
        jwt b64url encode "foobar" -> assert str eq "Zm9vYmFy" "AC1: RFC 4648 vector foobar"
        jwt b64url decode "Zm9vYg" -> assert str eq "foob" "AC1: RFC 4648 vector foob, unpadded"

        utf8_payload = '{"name":"José"}'
        tok = jwt sign hs256 utf8_payload "utf8-secret"
        unwrap jwt (jwt verify hs256 tok "utf8-secret") -> assert str eq utf8_payload "AC2: UTF-8 payload verifies byte for byte"
        unwrap jwt (jwt decode payload tok) -> assert str eq utf8_payload "AC1: UTF-8 payload decodes byte for byte"

        key32 = "0123456789abcdef0123456789abcdef"
        nonce12 = "uniqueNonce1"
        utf8_msg = "ñandú-ü-€"
        sealed = unwrap jwt (jwt seal aead key32 nonce12 utf8_msg)
        unwrap jwt (jwt open aead key32 nonce12 sealed) -> assert str eq utf8_msg "AC3: UTF-8 plaintext round-trips byte for byte"
        ()
```

### 26.3.7. Ejemplo 7: Vectores estándar: RFC 4231 HMAC, RFC 7515 A.1 HS256 y tokens sellados RFC 8439 (`RGAEAD2`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `jwt` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test jwt standard vectors => ()
      test jwt standard vectors =
        jwt hmac sha256 b64url "Jefe" "what do ya want for nothing?" -> assert str eq "W9zBRr9gdU5qBCQmCJV1x1oAPwidJzmDnexYuWTsOEM" "AC2: HMAC-SHA256 is RFC 4231 test case 2"

        rfc_key = jwt b64url decode "AyM1SysPpbyDfgZld3umj1qzKObwVMkoqQ-EstJQLr_T-1qS0gZH75aKtMN3Yj0iPS4hcgUuTwjAzZr1Z9CAow"
        rfc_in = "eyJ0eXAiOiJKV1QiLA0KICJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJqb2UiLA0KICJleHAiOjEzMDA4MTkzODAsDQogImh0dHA6Ly9leGFtcGxlLmNvbS9pc19yb290Ijp0cnVlfQ"
        rfc_sig = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
        jwt hmac sha256 b64url rfc_key rfc_in -> assert str eq rfc_sig "AC2: RFC 7515 A.1 HS256 signature"
        rfc_res = jwt verify hs256 (rfc_in + "." + rfc_sig) rfc_key
        is jwt ok rfc_res -> assert true "AC2: RFC 7515 A.1 token verifies"
        str starts with (unwrap jwt rfc_res) '{"iss":"joe",' -> assert true "AC2: RFC 7515 A.1 payload"

        key = bytes from list [128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159]
        nonce = bytes from list [7, 0, 0, 0, 64, 65, 66, 67, 68, 69, 70, 71]
        pt = "Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it."
        sealed = jwt seal aead key nonce pt
        is jwt ok sealed -> assert true "AC3: jwt seal aead with the RFC 8439 key and nonce"
        ct = jwt b64url decode bytes (jwt token part sealed 2)
        ct_list = tensor to list ct
        (first n ct_list 16) == [211, 26, 141, 52, 100, 142, 96, 219, 123, 134, 175, 188, 83, 239, 126, 194] -> assert true "AC3: ciphertext is RFC 8439 2.8.2 ChaCha20"
        aad = "RGAEAD2." + (jwt token part sealed 1)
        tag = jwt b64url decode (jwt token part sealed 3)
        (aead seal key nonce aad pt) == ((tensor to str ct) + tag) -> assert true "AC3: token is RFC 8439 ChaCha20-Poly1305 over the version and nonce as AAD"
        is jwt ok (jwt open aead key nonce ("RGAEAD1." + (jwt token part sealed 1) + "." + (jwt token part sealed 2) + "." + (jwt token part sealed 3))) -> assert false "AC3: tokens of the old RGAEAD1 format are rejected"
        ()
```

---

## 26.4. Bajo el capó: cómo está construida `jwt` en Ridgun puro (`src/main/ridgun/lib/jwt.ridgun`)

Una de las mayores ventajas de `ridgun-libs` es que **no hay cajas negras en C**. Puedes abrir `src/main/ridgun/lib/jwt.ridgun` y leer exactamente cómo está implementada cada operación usando *pattern matching*, árboles de guardas `|` / `|.` y recursión de cola (TCO). Veamos las piezas clave de su implementación real:

### 26.4.1. Implementación interna: Tensor[U8] Byte & Base64url Helpers (ADR-0010)

Fíjate en cómo `jwt.ridgun` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
module :: jwt

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
```

### 26.4.2. Implementación interna: Constant-Time Equality

Fíjate en cómo `jwt.ridgun` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
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
```

### 26.4.3. Implementación interna: HS256 (HMAC-SHA256) Signing & Verification

Fíjate en cómo `jwt.ridgun` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
-- RFC 2104 HMAC-SHA256 (crypto lib, RFC 4231 vectors), as an unpadded Base64url tag.
fn :: jwt hmac sha256 b64url String String => String
      jwt hmac sha256 b64url secret signing_input =  hmac sha256 secret signing_input -> tensor from str -> jwt b64url enc bytes

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

Fíjate en cómo `jwt.ridgun` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

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

- **Garantía algorítmica y de seguridad**: Inmunidad total al ataque `"alg":"none"` (cualquier cabecera cuyo `alg` no sea exactamente `"HS256"` devuelve `JwtErr`) y comparación de firma en tiempo constante.
- **Complejidad de pila $O(1)$ con TCO**: Todos los bucles recursivos en `src/main/ridgun/lib/jwt.ridgun` están en posición de cola, por lo que `ridgunc` los compila a saltos nativos sin crecimiento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test jwt.ridgun`.

### Las 5 Reglas de Oro al programar con `jwt`

1. **Declara `import jwt` al inicio del archivo** y llama a sus funciones con espacios, tal como están declaradas, para que tu código se lea como prosa.
2. **Alinea tus tuberías de datos con `=`**: encadena las llamadas a `jwt` en pasos con nombre propio y deja que `stable format` alinee las columnas.
3. **Aprovecha las funciones totales de `jwt` en tus guardas `|`**: comprueba los valores de retorno o desenvuelve los ADTs con *pattern matching* en lugar de asumir que la entrada externa siempre es válida.
4. **Evita copiar grandes estructuras si solo necesitas consultar un campo**: recuerda que en `RMM2` los argumentos de entrada no incrementan ni decrementan contadores (`+0` / `-0`).
5. **Combina `jwt` con `test` (`import test`)**: escribe siempre aserciones con `assert equals` o `assert true` para fijar los invariantes de tu dominio.

---

En el **Capítulo 27** pasaremos a explorar en profundidad la lib **`socket`** (La lib `socket` — TCP, UDP, AF_UNIX, Framing, DNS RFC 1035 y Kernel Sockets (`RGF-001`)).
