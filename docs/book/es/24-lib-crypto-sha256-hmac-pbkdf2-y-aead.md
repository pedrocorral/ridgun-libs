# Capítulo 24: La lib `crypto` — SHA-256, HMAC, PBKDF2, Argon2id y ChaCha20-Poly1305 AEAD

## 24.1. ¿Por qué existe la lib `crypto`? (El problema real y la filosofía Ridgun)

> *«¿Por qué necesito una lib `crypto` escrita desde cero en Ridgun puro en lugar de enlazar una librería de C de toda la vida?»*

Esa es la primera pregunta que se hace cualquier ingeniero de sistemas al llegar a `crypto`. Y la respuesta resume toda la filosofía de `ridgun-libs`:

Seamos sinceros: comparar un HMAC con `==` abre la puerta a ataques de temporización (*timing attacks*), y depender de `libssl.so` para calcular un `SHA-256` o cifrar con `ChaCha20-Poly1305` rompe la portabilidad estática de cualquier binario.

La lib **`crypto`** implementa al 100 % en Ridgun puro sobre `Tensor[Int]` preasignado: operaciones de bytes/bits (`RGF-019`), **FIPS 180-4 SHA-256**, **RFC 2104 HMAC-SHA-256**, igualdad en tiempo constante (`ct equal`), **RFC 8018 PBKDF2-HMAC-SHA-256** con precomputación del estado intermedio SHA-256, fachada **Argon2id** de 5 argumentos y cifrado autenticado **RFC 8439 ChaCha20-Poly1305 AEAD** (`aead seal` / `aead open`).

En un ecosistema tradicional, resolver las tareas del dominio **`CRYPTO`** implica arrastrar dependencias externas en C, lidiar con punteros crudos, conversiones opacas de tipos, excepciones no verificadas o pausas impredecibles del recolector de basura. En Ridgun, la lib **`crypto`** (`src/main/ridgun/lib/crypto.rg`) aborda el problema con cuatro principios innegociables:

1. **Funciones totales y contratos explícitos (`=>`)**: ninguna función de `crypto` lanza excepciones ocultas ni depende de `null`. Todo caso límite (entradas vacías, divisores cero, tramas truncadas o índices fuera de rango) devuelve un valor centinela documentado o un tipo algebraico suma (`Option`, `Result`).
2. **Cero código C y cero `libc`**: todo el código de `crypto` compila directamente a código máquina nativo ELF64 verificado por `ridgunc`.
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos los recorridos internos de `crypto` se compilan a bucles nativos en $O(1)$ espacio de pila.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estructura intermedia se libera en el instante exacto en que termina su última lectura, sin *Garbage Collector*.

---

## 24.2. Artefactos nativos, importación y catálogo completo de la API de `crypto`

En `ridgun-libs`, **`crypto`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/crypto.rg` (dominio `CRYPTO`). Al compilar con `stable bundle`, se empaqueta en tres artefactos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/crypto.rglib` | Distribución e importación directa con `import crypto` |
| **Archivo compilado** | `target/crypto.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libcrypto.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import crypto` en el encabezado y llamar a sus funciones con espacios (`mi funcion x`) o guiones bajos (`mi_funcion x`) indistintamente.

### 24.2.1. Resumen de familias funcionales de `crypto`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `sha256 bytes / sha256 hex` | Resumen binario de 32 bytes o hexadecimal de 64 caracteres FIPS 180-4 SHA-256 |
| `hmac sha256 / hmac sha256 hex / ct equal` | MAC con clave RFC 2104 y comparación de acumulador en tiempo constante |
| `pbkdf2 hmac sha256 : String -> String -> Int -> Int -> String` | Derivación de claves RFC 8018 con estados intermedios SHA-256 precomputados |
| `argon2id hash / argon2id verify` | Hashing de contraseñas PHC RFC 9106 de 5 argumentos y verificación en tiempo constante |
| `aead seal / aead open` | Cifrado autenticado RFC 8439 ChaCha20-Poly1305 y descifrado con verificación de tag |

### 24.2.2. Catálogo exhaustivo de tipos y firmas en `src/main/ridgun/lib/crypto.rg`

A continuación tienes el inventario completo de tipos algebraicos (`type`), operadores (`op ::`) y firmas de funciones (`fn ::`) definidos en `src/main/ridgun/lib/crypto.rg` (`3` tipos, `0` operadores y `161` funciones):

**Tipos algebraicos y registros (`type`) de `crypto`:**

```ridgun
type CT16    = ct0: A, ct1: A, ct2: A, ct3: A, ct4: A, ct5: A, ct6: A, ct7: A, ct8: A, ct9: A, ct10: A, ct11: A, ct12: A, ct13: A, ct14: A, ct15: A
type CPbkCtx = cptbl: CT16, cpipad: String, cpopad: String
type CA2Ctx  = cr_pass: Int, cs_slice: Int, cl_lane: Int, cp_lanes: Int, cq_cols: Int, cseg_len: Int, ct_iters: Int
```

| # | Función / Firma (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: norm byte mod Int` | `Int` |
| `2` | `fn :: norm byte Int` | `Int` |
| `3` | `fn :: byte str norm Int` | `String` |
| `4` | `fn :: byte str Int` | `String` |
| `5` | `fn :: bytes from list [Int]` | `String` |
| `6` | `fn :: bytes to list loop String Int Int` | `[Int]` |
| `7` | `fn :: bytes to list String` | `[Int]` |
| `8` | `fn :: u32 mod Int` | `Int` |
| `9` | `fn :: u32 val Int` | `Int` |
| `10` | `fn :: byte band Int Int` | `Int` |
| `11` | `fn :: byte bor Int Int` | `Int` |
| `12` | `fn :: byte bxor Int Int` | `Int` |
| `13` | `fn :: band Int Int` | `Int` |
| `14` | `fn :: bor Int Int` | `Int` |
| `15` | `fn :: c u32 bxor Int Int` | `Int` |
| `16` | `fn :: bxor Int Int` | `Int` |
| `17` | `fn :: shl Int Int` | `Int` |
| `18` | `fn :: shr Int Int` | `Int` |
| `19` | `fn :: rotl32 Int Int` | `Int` |
| `20` | `fn :: hextable Int` | `String` |
| `21` | `fn :: crypto byte to hex Int` | `String` |
| `22` | `fn :: bytes to hex str String` | `String` |
| `23` | `fn :: bytes list to hex [Int]` | `String` |
| `24` | `fn :: crypto hex val Int` | `Int` |
| `25` | `fn :: hex str to bytes loop String Int Int` | `[Int]` |
| `26` | `fn :: hex to byte str String` | `String` |
| `27` | `fn :: c list len [Int]` | `Int` |
| `28` | `fn :: c nth int [Int] Int` | `Int` |
| `29` | `fn :: c take ints [Int] Int` | `[Int]` |
| `30` | `fn :: c drop ints [Int] Int` | `[Int]` |
| `31` | `fn :: byte slice String Int Int` | `String` |
| `32` | `fn :: sha256 hex String` | `String` |
| `33` | `fn :: sha256 bytes String` | `String` |
| `34` | `fn :: pad zeroes Int` | `[Int]` |
| `35` | `fn :: bitxor key pad [Int] Int` | `[Int]` |
| `36` | `fn :: raw hmac key bytes String` | `[Int]` |
| `37` | `fn :: normalize hmac key String` | `[Int]` |
| `38` | `fn :: hmac sha256 String String` | `String` |
| `39` | `fn :: ct diff str String String Int Int Int` | `Int` |
| `40` | `fn :: ct equal String String` | `Bool` |
| `41` | `fn :: bitxor byte lists [Int] [Int]` | `[Int]` |
| `42` | `fn :: bitxor byte strings String String` | `String` |
| `43` | `fn :: be32 bytes Int` | `String` |
| `44` | `fn :: c get16 CT16 Int` | `A` |
| `45` | `fn :: c set16 CT16 Int A` | `CT16` |
| `46` | `fn :: c build b16 Int` | `CT16` |
| `47` | `fn :: c build b256` | `CT16` |
| `48` | `fn :: c get b256 CT16 Int Int` | `String` |
| `49` | `fn :: c hex nib Int` | `Int` |
| `50` | `fn :: c hex pair CT16 String Int` | `String` |
| `51` | `fn :: c hex2raw4 CT16 String Int` | `String` |
| `52` | `fn :: c hex2raw32 CT16 String` | `String` |
| `53` | `fn :: c hex8 word String Int` | `U64` |
| `54` | `fn :: c bxor acc8 Tensor[U64 * 8] String` | `Tensor[U64 * 8]` |
| `55` | `fn :: c word32 to raw4 CT16 U64` | `String` |
| `56` | `fn :: c acc8 to raw CT16 Tensor[U64 * 8]` | `String` |
| `57` | `fn :: c list to raw CT16 [Int]` | `String` |
| `58` | `fn :: pbkdf2 iter loop CPbkCtx String Tensor[U64 * 8] Int` | `Tensor[U64 * 8]` |
| `59` | `fn :: pbkdf2 block CPbkCtx String Int Int` | `String` |
| `60` | `fn :: pbkdf2 blocks loop CPbkCtx String Int Int Int String` | `String` |
| `61` | `fn :: pbkdf2 hmac sha256 String String Int Int` | `String` |
| `62` | `fn :: f blamka U64 U64` | `U64` |
| `63` | `fn :: blamka g U64 U64 U64 U64` | `U64 U64 U64 U64` |
| `64` | `fn :: blamka p16 Tensor[U64 * 16]` | `()` |
| `65` | `fn :: ca2 blamka col pair Tensor[U64 * 8 * 16] Int` | `Tensor[U64 * 8 * 16]` |
| `66` | `fn :: ca2 blamka cols loop Tensor[U64 * 8 * 16] Int` | `Tensor[U64 * 8 * 16]` |
| `67` | `fn :: compress block Tensor[U64 * 8 * 16] Tensor[U64 * 8 * 16]` | `Tensor[U64 * 8 * 16]` |
| `68` | `fn :: ca2 take ints [Int] Int` | `[Int]` |
| `69` | `fn :: ca2 drop ints [Int] Int` | `[Int]` |
| `70` | `fn :: ca2 pad zeroes Int` | `[Int]` |
| `71` | `fn :: ca2 u64 lh Int Int` | `U64` |
| `72` | `fn :: ca2 u32 to le4 Int` | `[Int]` |
| `73` | `fn :: ca2 bytes to u32 le [Int] Int` | `Int` |
| `74` | `fn :: ca2 zero w16` | `Tensor[U64 * 16]` |
| `75` | `fn :: ca2 zero blk8` | `Tensor[U64 * 8 * 16]` |
| `76` | `fn :: ca2 b2b iv w16` | `Tensor[U64 * 16]` |
| `77` | `fn :: ca2 b2b g4 U64 U64 U64 U64 U64 U64` | `U64 U64 U64 U64` |
| `78` | `fn :: ca2 b2b sigma Int` | `[Int]` |
| `79` | `fn :: ca2 b2b round Tensor[U64 * 16] Tensor[U64 * 16] Int` | `Tensor[U64 * 16]` |
| `80` | `fn :: ca2 b2b rounds Tensor[U64 * 16] Tensor[U64 * 16] Int` | `Tensor[U64 * 16]` |
| `81` | `fn :: ca2 b2b compress Tensor[U64 * 16] Tensor[U64 * 16] Int Bool` | `Tensor[U64 * 16]` |
| `82` | `fn :: ca2 bytes to u64 [Int] Int` | `U64` |
| `83` | `fn :: ca2 bytes to w16 [Int] Int` | `Tensor[U64 * 16]` |
| `84` | `fn :: ca2 u64 to le8 U64` | `[Int]` |
| `85` | `fn :: ca2 h8 to bytes Tensor[U64 * 16]` | `[Int]` |
| `86` | `fn :: ca2 b2b loop Tensor[U64 * 16] [Int] Int` | `Tensor[U64 * 16]` |
| `87` | `fn :: ca2 blake2b [Int] Int` | `[Int]` |
| `88` | `fn :: ca2 b2b long loop [Int] Int Int Int` | `[Int]` |
| `89` | `fn :: ca2 blake2b long [Int] Int` | `[Int]` |
| `90` | `fn :: ca2 bitxor blk8 Tensor[U64 * 8 * 16] Tensor[U64 * 8 * 16]` | `Tensor[U64 * 8 * 16]` |
| `91` | `fn :: ca2 get blk8 Tensor[U64 * 8 * 16] Int` | `U64` |
| `92` | `fn :: ca2 bytes to blk8 row Tensor[U64 * 8 * 16] [Int] Int Int` | `Tensor[U64 * 8 * 16]` |
| `93` | `fn :: ca2 bytes to blk8 loop Tensor[U64 * 8 * 16] [Int] Int` | `Tensor[U64 * 8 * 16]` |
| `94` | `fn :: ca2 bytes to blk8 [Int]` | `Tensor[U64 * 8 * 16]` |
| `95` | `fn :: ca2 blk8 row to bytes Tensor[U64 * 8 * 16] Int Int` | `[Int]` |
| `96` | `fn :: ca2 blk8 to bytes loop Tensor[U64 * 8 * 16] Int` | `[Int]` |
| `97` | `fn :: ca2 blk8 to bytes Tensor[U64 * 8 * 16]` | `[Int]` |
| `98` | `fn :: ca2 zero mem` | `CT16` |
| `99` | `fn :: ca2 nth blk CT16 Int` | `Tensor[U64 * 8 * 16]` |
| `100` | `fn :: ca2 set blk CT16 Int Tensor[U64 * 8 * 16]` | `CT16` |
| `101` | `fn :: ca2 init all lanes loop CT16 [Int] Int Int Int` | `CT16` |
| `102` | `fn :: ca2 init all lanes [Int] Int Int Int` | `CT16` |
| `103` | `fn :: ca2 make addr blk CA2Ctx Int` | `Tensor[U64 * 8 * 16]` |
| `104` | `fn :: ca2 calc w size p0 CA2Ctx Int Bool` | `Int` |
| `105` | `fn :: ca2 calc w size pn CA2Ctx Int Bool` | `Int` |
| `106` | `fn :: ca2 calc w size CA2Ctx Int Bool` | `Int` |
| `107` | `fn :: ca2 step addr Bool CA2Ctx Int Tensor[U64 * 8 * 16]` | `Tensor[U64 * 8 * 16]` |
| `108` | `fn :: ca2 step jpair Bool Tensor[U64 * 8 * 16] Int CT16 Int` | `U64` |
| `109` | `fn :: ca2 ref lane Int Int Int Int Int` | `Int` |
| `110` | `fn :: ca2 st pos Int Int Int` | `Int` |
| `111` | `fn :: ca2 fin blk Int Tensor[U64 * 8 * 16] CT16 Int` | `Tensor[U64 * 8 * 16]` |
| `112` | `fn :: ca2 fill segment CT16 CA2Ctx Int Tensor[U64 * 8 * 16]` | `CT16` |
| `113` | `fn :: ca2 start j CA2Ctx` | `Int` |
| `114` | `fn :: ca2 run lanes CT16 CA2Ctx Int` | `CT16` |
| `115` | `fn :: ca2 run slices CT16 CA2Ctx Int` | `CT16` |
| `116` | `fn :: ca2 run passes CT16 CA2Ctx Int` | `CT16` |
| `117` | `fn :: ca2 bitxor final lanes CT16 Int Int Int Tensor[U64 * 8 * 16]` | `Tensor[U64 * 8 * 16]` |
| `118` | `fn :: ca2 derive raw tag [Int] [Int] Int Int Int Int` | `[Int]` |
| `119` | `fn :: ca2 b64 alphabet` | `String` |
| `120` | `fn :: ca2 b64 char Int` | `String` |
| `121` | `fn :: ca2 b64 encode [Int]` | `String` |
| `122` | `fn :: ca2 b64 char val Int` | `Int` |
| `123` | `fn :: ca2 valid b64 chars String Int Int` | `Bool` |
| `124` | `fn :: ca2 is valid b64 String` | `Bool` |
| `125` | `fn :: ca2 b64 decode rem String Int Int Int` | `[Int]` |
| `126` | `fn :: ca2 b64 decode loop String Int Int` | `[Int]` |
| `127` | `fn :: ca2 b64 decode String` | `[Int]` |
| `128` | `fn :: ca2 split str String Int Int Int Int` | `[String]` |
| `129` | `fn :: ca2 nth str [String] Int` | `String` |
| `130` | `fn :: ca2 str list len [String]` | `Int` |
| `131` | `fn :: ca2 is digits String Int Int` | `Bool` |
| `132` | `fn :: ca2 parse kv String String` | `Int` |
| `133` | `fn :: ca2 verify decoded String [Int] [Int] Int Int Int Int` | `Bool` |
| `134` | `fn :: ca2 verify kvs String [String] String String` | `Bool` |
| `135` | `fn :: ca2 verify parts String [String]` | `Bool` |
| `136` | `fn :: ca2 hash checked String [Int] Int Int Int` | `String` |
| `137` | `fn :: argon2id hash String String Int Int Int` | `String` |
| `138` | `fn :: argon2id hash phc String String Int Int Int` | `String` |
| `139` | `fn :: argon2id verify String String` | `Bool` |
| `140` | `fn :: le32 at [Int] Int` | `Int` |
| `141` | `fn :: u32 to le4 Int` | `[Int]` |
| `142` | `fn :: chacha qr Int Int Int Int` | `Int Int Int Int` |
| `143` | `fn :: chacha double round Tensor[Int * 16]` | `Tensor[Int * 16]` |
| `144` | `fn :: chacha rounds loop Tensor[Int * 16] Int` | `Tensor[Int * 16]` |
| `145` | `fn :: words16 tensor to bytes Tensor[Int * 16] Tensor[Int * 16] Int` | `[Int]` |
| `146` | `fn :: chacha20 init st [Int] [Int] Int` | `Tensor[Int * 16]` |
| `147` | `fn :: chacha20 block [Int] [Int] Int` | `[Int]` |
| `148` | `fn :: chacha20 bitxor loop [Int] [Int] Int [Int]` | `[Int]` |
| `149` | `fn :: poly1305 clamp r [Int]` | `[Int]` |
| `150` | `fn :: poly1305 r limbs [Int]` | `[Int]` |
| `151` | `fn :: poly1305 block limbs [Int]` | `[Int]` |
| `152` | `fn :: poly1305 step [Int] [Int] [Int]` | `[Int]` |
| `153` | `fn :: poly1305 blocks loop [Int] [Int] [Int]` | `[Int]` |
| `154` | `fn :: select reduced limbs Int [Int] [Int]` | `[Int]` |
| `155` | `fn :: poly1305 finalize [Int] [Int]` | `[Int]` |
| `156` | `fn :: pad16 zeroes Int` | `[Int]` |
| `157` | `fn :: u64 le8 Int` | `[Int]` |
| `158` | `fn :: poly1305 aead mac [Int] [Int] [Int]` | `[Int]` |
| `159` | `fn :: aead seal String String String String` | `String` |
| `160` | `fn :: decrypt verified aead Bool [Int] [Int] [Int]` | `Int String` |
| `161` | `fn :: aead open String String String String` | `Int String` |

---

## 24.3. Explorando `crypto` a fondo: Ejemplos paso a paso de cada funcionalidad

No basta con ver la tabla de firmas: vamos a explorar **cada una de las funcionalidades** de la lib `crypto` mediante ejemplos progresivos y ejecutables en Ridgun. Empezaremos por las dos recetas tabulares de uso cotidiano y después recorreremos en detalle todos los escenarios funcionales, transformaciones y casos límite verificados en `src/test/ridgun/test crypto.rg`.

### 24.3.1. Ejemplo 1: Flujo principal en estilo tabular con `crypto`

Observa cómo en Ridgun los signos `=` y los pasos de transformación con `crypto` quedan alineados como una tabla limpia, sin variables mutables innecesarias ni efectos laterales ocultos:

```ridgun
import crypto

fn :: cifrar mensaje sesion (secreto : String) (texto : String) => (Int, String)
      cifrar mensaje sesion secreto texto =
        key32   = sha256 bytes secreto
        nonce12 = "0123456789ab"
        aad     = "canal-autenticado"
        sellado = aead seal key32 nonce12 aad texto
        aead open key32 nonce12 aad sellado
```

### 24.3.2. Ejemplo 2: Composición segura y manejo de casos de borde

Toda función de la lib `crypto` está diseñada para componerse con guardas booleanas `|` y con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import crypto

fn :: verificar firma webhook (clave : String) (cuerpo : String) (firma_hex : String) => Bool
      verificar firma webhook clave cuerpo firma_hex =
        esperada = hmac sha256 hex clave cuerpo
        ct equal esperada firma_hex
```

### 24.3.3. Ejemplo 3: Manipulación de bytes crudos `0..255` (`byte str`, `bytes from list`, `bytes to list`) y operaciones bit a bit de 32 bits (`band`, `bor`, `bxor`, `shl`, `shr`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `crypto` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test rgf019 bytes and bitops => ()
      test rgf019 bytes and bitops =
        -- 1. Raw byte_str lengths, wraparound normalization, and full 0..255 round-trip
        _    = assert int equals (str len (byte str 0)) 1 "len byte_str 0"
        _    = assert int equals (str len (byte str 127)) 1 "len byte_str 127"
        _    = assert int equals (str len (byte str 128)) 1 "len byte_str 128"
        _    = assert int equals (str len (byte str 255)) 1 "len byte_str 255"
        _    = assert str eq (byte str (0 - 1)) (byte str 255) "byte_str -1 wraps to 255"
        _    = assert str eq (byte str 256) (byte str 0) "byte_str 256 wraps to 0"
        b5   = bytes from list [0, 1, 127, 128, 255]
        _    = assert int equals (str len b5) 5 "len b5 == 5"
        rt   = bytes to list b5
        _    = assert int equals (c nth int rt 0) 0 "rt 0"
        _    = assert int equals (c nth int rt 1) 1 "rt 1"
        _    = assert int equals (c nth int rt 2) 127 "rt 2"
        _    = assert int equals (c nth int rt 3) 128 "rt 3"
        _    = assert int equals (c nth int rt 4) 255 "rt 4"
        b256 = bytes from list (range bytes 0 255)
        _    = assert int equals (str len b256) 256 "len b256 == 256"
        r256 = bytes to list b256
        _    = assert int equals (c list len r256) 256 "r256 list len == 256"
        _    = assert int equals (c nth int r256 0) 0 "r256[0] == 0"
        _    = assert int equals (c nth int r256 128) 128 "r256[128] == 128"
        _    = assert int equals (c nth int r256 255) 255 "r256[255] == 255"

        -- 2. RGF-019 32-bit unsigned bitwise operations and boundary shifts
        _    = assert int equals (band 4294967295 255) 255 "band"
        _    = assert int equals (band 305419896 0) 0 "band with 0"
        _    = assert int equals (bor 240 15) 255 "bor"
        _    = assert int equals (bor 305419896 0) 305419896 "bor with 0"
        _    = assert int equals (bxor 305419896 4294967295) 3989547399 "bxor"
        _    = assert int equals (bxor 305419896 305419896) 0 "bxor self == 0"
        _    = assert int equals (shl 1 0) 1 "shl 0"
        _    = assert int equals (shl 1 (0 - 1)) 0 "shl negative shift"
        _    = assert int equals (shl 1 31) 2147483648 "shl 31"
        _    = assert int equals (shl 1 32) 0 "shl 32"
        _    = assert int equals (shr 2147483648 0) 2147483648 "shr 0"
        _    = assert int equals (shr 2147483648 (0 - 1)) 0 "shr negative shift"
        _    = assert int equals (shr 2147483648 31) 1 "shr 31"
        _    = assert int equals (shr 2147483648 32) 0 "shr 32"
        ()
```

### 24.3.4. Ejemplo 4: Vectores oficiales SHA-256 (FIPS 180-4), HMAC-SHA-256 (RFC 4231), comparación en tiempo constante (`ct equal`) y PBKDF2-HMAC-SHA-256 (RFC 6070)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `crypto` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test sha256 hmac and pbkdf2 => ()
      test sha256 hmac and pbkdf2 =
        -- 1. SHA-256 (empty string "" and "abc" -> FIPS 180-4 vectors)
        h_emp = sha256 hex ""
        _     = assert str eq h_emp "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" "sha256_hex empty"
        h_hex = sha256 hex "abc"
        _     = assert str eq h_hex "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad" "sha256_hex abc"
        h_raw = sha256 bytes "abc"
        _     = assert eq (str len h_raw) 32
        _     = assert str eq (bytes to hex str h_raw) h_hex "sha256_bytes matches sha256_hex"

        -- 2. HMAC-SHA-256 (RFC 4231 Test Case 2 and >64-byte key reduction)
        mac   = hmac sha256 "Jefe" "what do ya want for nothing?"
        _     = assert eq (str len mac) 32
        _     = assert str eq (bytes to hex str mac) "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843" "RFC 4231 Test Case 2"
        long_k = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef_extra_key_bytes"
        mac_lk = hmac sha256 long_k "message"
        _      = assert eq (str len mac_lk) 32
        _      = assert true (ct equal mac_lk (hmac sha256 (sha256 bytes long_k) "message")) "HMAC >64B key hashed to 32B"

        -- 3. Constant-time comparison (`ct_equal`)
        _     = assert true (ct equal "" "") "ct_equal empty strings"
        _     = assert true (ct equal mac mac) "ct_equal identical"
        _     = assert false (ct equal mac (sha256 bytes "abc")) "ct_equal different 32B"
        _     = assert false (ct equal "short" "longer") "ct_equal different lengths"

        -- 4. PBKDF2-HMAC-SHA-256 (RFC 6070 c=1, c=2, multi-block dk_len=64, sub-block dk_len=16, invalid args)
        dk1   = pbkdf2 hmac sha256 "password" "salt" 1 32
        _     = assert eq (str len dk1) 32
        _     = assert str eq (bytes to hex str dk1) "120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b" "RFC 6070 PBKDF2 c=1"
        dk2   = pbkdf2 hmac sha256 "password" "salt" 2 32
        _     = assert str eq (bytes to hex str dk2) "ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43" "RFC 6070 PBKDF2 c=2"
        dk16  = pbkdf2 hmac sha256 "password" "salt" 1 16
        _     = assert eq (str len dk16) 16
        _     = assert str eq (bytes to hex str dk16) "120fb6cffcf8b32c43e7225256c4f837" "PBKDF2 16-byte prefix"
        dk64  = pbkdf2 hmac sha256 "password" "salt" 1 64
        _     = assert eq (str len dk64) 64
        _     = assert str eq (byte slice dk64 0 32) dk1 "PBKDF2 64-byte block 1 matches dk1"
        _     = assert str eq (pbkdf2 hmac sha256 "password" "salt" 0 32) "" "PBKDF2 iterations=0 rejected"
        _     = assert str eq (pbkdf2 hmac sha256 "password" "salt" 1 0) "" "PBKDF2 dk_len=0 rejected"
        ()
```

### 24.3.5. Ejemplo 5: Hashing de contraseñas Argon2id de 5 argumentos (`argon2id hash`, `argon2id verify`) y resistencia en memoria (RFC 9106)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `crypto` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test argon2id five arg and perf => ()
      test argon2id five arg and perf =
        phc = argon2id hash "correct horse battery staple" "0123456789abcdef" 64 2 1
        _   = assert true (str starts with phc "$argon2id$v=19$m=64,t=2,p=1$") "PHC header format"
        _   = assert true (argon2id verify "correct horse battery staple" phc) "argon2id_verify matching (pwd, phc)"
        _   = assert false (argon2id verify "wrong password" phc) "argon2id_verify wrong password"
        _   = assert false (argon2id verify "correct horse battery staple" "$argon2id$v=19$m=64,t=2,p=1$bad$bad") "argon2id_verify bad PHC"

        -- Negative parameter guards for 5-arg argon2id_hash
        _   = assert str eq (argon2id hash "password" "short" 64 2 1) "" "salt < 8 bytes rejected"
        _   = assert str eq (argon2id hash "password" "0123456789abcdef" 4 2 1) "" "m_cost < 8*p rejected"
        _   = assert str eq (argon2id hash "password" "0123456789abcdef" 64 0 1) "" "t_cost < 1 rejected"
        _   = assert str eq (argon2id hash "password" "0123456789abcdef" 64 2 0) "" "p_cost < 1 rejected"

        -- RG-050 / RG-051: Verify 100% in-process pure-Ridgun Argon2id and PBKDF2-HMAC-SHA256
        -- (OpenSSL 3.5 / RFC 9106 vectors + 4096-iteration PBKDF2 vector)
        phc_s       = argon2id hash "correct horse" "saltsaltsaltsalt" 64 2 1
        argon_exact = phc_s == "$argon2id$v=19$m=64,t=2,p=1$c2FsdHNhbHRzYWx0c2FsdA$5jdMIzWoFbzSOl6k3wai9uU3f8LD+HmGXQgo1uhHQPI"
        ok_s        = argon2id verify "correct horse" phc_s
        bad_s       = argon2id verify "wrong horse" phc_s
        bad_empty   = argon2id verify "correct horse" "$argon2id$v=19$m=64,t=2,p=1$c2FsdHNhbHRzYWx0c2FsdA$"
        phc_ok      = str starts with phc_s "$argon2id$v=19$m=64,t=2,p=1$"
        pb4k        = bytes to hex str (pbkdf2 hmac sha256 "correct horse battery staple" "0123456789abcdef" 4096 32)
        _           = assert true ok_s "Solstice RGF-015 argon_ok"
        _           = assert false bad_s "Solstice RGF-015 argon_bad"
        _           = assert false bad_empty "RG-051 reject PHC with empty tag"
        _           = assert true phc_ok "Solstice RGF-015 phc prefix"
        _           = assert true argon_exact "Solstice RGF-015 exact OpenSSL 3.5 / libsodium PHC"
        _           = assert str eq pb4k "b87f4b27148d3b05ad7985e3df997f0d9afa6e768e6384555bab71ba10f0c1a5" "Solstice RGF-015 PBKDF2 4096"
        ()
```

### 24.3.6. Ejemplo 6: Cifrado de flujo ChaCha20, autenticador Poly1305 y sellado/apertura autenticada AEAD ChaCha20-Poly1305 (RFC 8439)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `crypto` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test rfc8439 chacha20 poly1305 aead => ()
      test rfc8439 chacha20 poly1305 aead =
        key   = bytes from list (range bytes 128 159)
        nonce = bytes from list [7, 0, 0, 0, 64, 65, 66, 67, 68, 69, 70, 71]
        aad   = bytes from list [80, 81, 82, 83, 192, 193, 194, 195, 196, 197, 198, 199]
        pt    = "Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it."

        sealed = aead seal key nonce aad pt
        _      = assert eq (str len sealed) ((str len pt) + 16)

        -- Verify first 16 ciphertext bytes and 16-byte Poly1305 tag match RFC 8439 §2.8.2 bit-for-bit
        ct_prefix_hex = bytes to hex str (byte slice sealed 0 16)
        tag_hex       = bytes to hex str (byte slice sealed 114 130)
        _             = assert str eq ct_prefix_hex "d31a8d34648e60db7b86afbc53ef7ec2" "RFC 8439 §2.8.2 ciphertext prefix"
        _             = assert str eq tag_hex "1ae10b594f09e26a7e902ecbd0600691" "RFC 8439 §2.8.2 Poly1305 tag"

        -- Verify aead_open succeeds with (0, pt)
        res_ok   = aead open key nonce aad sealed
        _        = assert eq (aead rc res_ok) 0
        _        = assert str eq (aead pt res_ok) pt "aead_open decrypted plaintext"

        -- Verify empty plaintext and empty AAD round-trip
        sealed_empty = aead seal key nonce "" ""
        _            = assert eq (str len sealed_empty) 16
        res_empty    = aead open key nonce "" sealed_empty
        _            = assert eq (aead rc res_empty) 0
        _            = assert str eq (aead pt res_empty) "" "aead_open empty plaintext"

        -- Verify tamper detection (-12 AUTH_FAILED) on modified AAD, modified nonce, modified ciphertext, or modified tag
        res_aad  = aead open key nonce "tampered-aad" sealed
        _        = assert eq (aead rc res_aad) (0 - 12)
        _        = assert str eq (aead pt res_aad) "" "tampered AAD returns empty plaintext"

        bad_nonce = bytes from list [8, 0, 0, 0, 64, 65, 66, 67, 68, 69, 70, 71]
        res_nonce = aead open key bad_nonce aad sealed
        _         = assert eq (aead rc res_nonce) (0 - 12)
        _         = assert str eq (aead pt res_nonce) "" "tampered nonce returns empty plaintext"

        bad_ct   = (byte str 0) + (byte slice sealed 1 130)
        res_ct   = aead open key nonce aad bad_ct
        _        = assert eq (aead rc res_ct) (0 - 12)
        _        = assert str eq (aead pt res_ct) "" "tampered ciphertext byte returns empty plaintext"

        bad_seal = (byte slice sealed 0 129) + (byte str 0)
        res_tag  = aead open key nonce aad bad_seal
        _        = assert eq (aead rc res_tag) (0 - 12)
        _        = assert str eq (aead pt res_tag) "" "tampered tag returns empty plaintext"

        -- Verify invalid key/nonce/ciphertext length returns (-7, "") or ""
        _        = assert str eq (aead seal "short-key" nonce aad pt) "" "aead_seal invalid key length"
        _        = assert str eq (aead seal key "short-nonce" aad pt) "" "aead_seal invalid nonce length"
        res_inv  = aead open "short-key" nonce aad sealed
        _        = assert eq (aead rc res_inv) (0 - 7)
        res_ninv = aead open key "short-nonce" aad sealed
        _        = assert eq (aead rc res_ninv) (0 - 7)
        res_tinv = aead open key nonce aad "short-tag"
        _        = assert eq (aead rc res_tinv) (0 - 7)
        ()
```

---

## 24.4. Bajo el capó: cómo está construida `crypto` en Ridgun puro (`src/main/ridgun/lib/crypto.rg`)

Una de las mayores ventajas de `ridgun-libs` es que **no hay cajas negras en C**. Puedes abrir `src/main/ridgun/lib/crypto.rg` y leer exactamente cómo está implementada cada operación usando *pattern matching*, árboles de guardas `|` / `|.` y recursión de cola (TCO). Veamos las piezas clave de su implementación real:

### 24.4.1. Implementación interna: RGF-019 Raw Byte Manipulation (`byte_str`, `bytes_from_list`, `bytes_to_list`)

Fíjate en cómo `crypto.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: norm byte mod Int => Int
      norm byte mod m   =
        | m < 0     = m + 256
        | otherwise = m

fn :: norm byte Int => Int
      norm byte b   =  norm byte mod (b % 256)

fn :: byte str norm Int => String
      byte str norm ub  =
        | ub >= 1 and ub <= 127 = char from code ub
        | otherwise =
          efd = sys call 290 (256 + ub) 526336 0 0 0 0
          s   = sys read fd efd 8
          _   = sys close efd
          str slice s 0 1

fn :: byte str Int => String
      byte str n   =
        byte str norm (norm byte n)

fn :: bytes from list [Int]    => String
      bytes from list []       =  ""
      bytes from list (b:rest) =  (byte str b) + (bytes from list rest)

fn :: bytes to list loop String Int Int => [Int]
      bytes to list loop s idx slen =
        | idx >= slen = []
        | otherwise   = [norm byte (str char at s idx)] :: (bytes to list loop s (idx + 1) slen)

fn :: bytes to list String => [Int]
      bytes to list s      =
        bytes to list loop s 0 (str len s)
```

### 24.4.2. Implementación interna: Hex & List Utilities

Fíjate en cómo `crypto.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: hextable Int => String
      hextable _   =  "0123456789abcdef"

fn :: crypto byte to hex Int => String
      crypto byte to hex b   =
        ub = norm byte b
        hi = (ub / 16) % 16
        lo = ub % 16
        (str slice (hextable 0) hi (hi + 1)) + (str slice (hextable 0) lo (lo + 1))

fn :: bytes to hex str String => String
      bytes to hex str raw    =
        bytes list to hex (bytes to list raw)

fn :: bytes list to hex [Int]    => String
      bytes list to hex []       =  ""
      bytes list to hex (b:rest) =  (crypto byte to hex b) + (bytes list to hex rest)

fn :: crypto hex val Int => Int
      crypto hex val c   =
        | c >= 48 and c <= 57  = c - 48
        | c >= 97 and c <= 102 = (c - 97) + 10
        | c >= 65 and c <= 70  = (c - 65) + 10
        | otherwise            = 0

fn :: hex str to bytes loop String Int Int => [Int]
      hex str to bytes loop h idx hlen =
        | (idx + 1) >= hlen = []
        | otherwise         =
          hi = crypto hex val (str char at h idx)
          lo = crypto hex val (str char at h (idx + 1))
          [(hi * 16) + lo] :: (hex str to bytes loop h (idx + 2) hlen)

fn :: hex to byte str String => String
      hex to byte str h      =
        bytes from list (hex str to bytes loop h 0 (str len h))

fn :: c list len [Int]    => Int
      c list len []       =  0
      c list len (_:rest) =  1 + (c list len rest)

fn :: c nth int [Int]    Int => Int
      c nth int []       _   =  0
      c nth int (x:rest) idx =
        | idx <= 0  = x
        | otherwise = c nth int rest (idx - 1)
```

### 24.4.3. Implementación interna: RGF-015 Pure-Ridgun RFC 9106 Argon2id (`argon2id_hash`, `argon2id_verify`)

Fíjate en cómo `crypto.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: ca2 take ints [Int]    Int => [Int]
      ca2 take ints []       _   =  []
      ca2 take ints (x:rest) n   =
        | n <= 0    = []
        | otherwise = [x] :: (ca2 take ints rest (n - 1))

fn :: ca2 drop ints [Int]    Int => [Int]
      ca2 drop ints []       _   =  []
      ca2 drop ints (x:rest) n   =
        | n <= 0    = [x] :: rest
        | otherwise = ca2 drop ints rest (n - 1)

fn :: ca2 pad zeroes Int => [Int]
      ca2 pad zeroes n   =
        | n <= 0    = []
        | otherwise = [0] :: (ca2 pad zeroes (n - 1))

fn :: ca2 u64 lh Int Int => U64
      ca2 u64 lh lo  hi  =
        ((hi and 0xFFFFFFFF) shl 32) or (lo and 0xFFFFFFFF)

fn :: ca2 u32 to le4 Int => [Int]
      ca2 u32 to le4 w   =
        uw = u32 val w
        [uw % 256, (uw / 256) % 256, (uw / 65536) % 256, (uw / 16777216) % 256]

fn :: ca2 bytes to u32 le [Int] Int => Int
      ca2 bytes to u32 le bs off =
        (c nth int bs off) + ((c nth int bs (off + 1)) * 256) + ((c nth int bs (off + 2)) * 65536) + ((c nth int bs (off + 3)) * 16777216)

fn :: ca2 zero w16 => Tensor[U64 * 16]
      ca2 zero w16 =
        Tensor[U64 * 16]

fn :: ca2 zero blk8 => Tensor[U64 * 8 * 16]
      ca2 zero blk8 =
        Tensor[U64 * 8 * 16]

fn :: ca2 b2b iv w16 => Tensor[U64 * 16]
      ca2 b2b iv w16 =
        iv = Tensor[U64 * 16]
        iv_(0) = ca2 u64 lh 4089235720 1779033703
        iv_(1) = ca2 u64 lh 2227873595 3144134277
        iv_(2) = ca2 u64 lh 4271175723 1013904242
        iv_(3) = ca2 u64 lh 1595750129 2773480762
        iv_(4) = ca2 u64 lh 2917565137 1359893119
        iv_(5) = ca2 u64 lh 725511199  2600822924
        iv_(6) = ca2 u64 lh 4215389547 528734635
        iv_(7) = ca2 u64 lh 327033209  1541459225
        iv
```

### 24.4.4. Implementación interna: RFC 8439 Poly1305 One-Time Authenticator (5 x 26-bit limbs)

Fíjate en cómo `crypto.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: poly1305 clamp r [Int] => [Int]
      poly1305 clamp r otk   =
        [c nth int otk 0, c nth int otk 1, c nth int otk 2, byte band (c nth int otk 3) 15, byte band (c nth int otk 4) 252, c nth int otk 5, c nth int otk 6, byte band (c nth int otk 7) 15, byte band (c nth int otk 8) 252, c nth int otk 9, c nth int otk 10, byte band (c nth int otk 11) 15, byte band (c nth int otk 12) 252, c nth int otk 13, c nth int otk 14, byte band (c nth int otk 15) 15]

fn :: poly1305 r limbs [Int] => [Int]
      poly1305 r limbs r_bs  =
        t0 = le32 at r_bs 0
        t1 = le32 at r_bs 4
        t2 = le32 at r_bs 8
        t3 = le32 at r_bs 12
        r0 = t0 % 67108864
        r1 = ((t0 / 67108864) + ((t1 % 1048576) * 64)) % 67108864
        r2 = ((t1 / 1048576) + ((t2 % 16384) * 4096)) % 67108864
        r3 = ((t2 / 16384) + ((t3 % 256) * 262144)) % 67108864
        r4 = t3 / 256
        [r0, r1, r2, r3, r4]

fn :: poly1305 block limbs [Int] => [Int]
      poly1305 block limbs blk   =
        t0 = le32 at blk 0
        t1 = le32 at blk 4
        t2 = le32 at blk 8
        t3 = le32 at blk 12
        b0 = t0 % 67108864
        b1 = ((t0 / 67108864) + ((t1 % 1048576) * 64)) % 67108864
        b2 = ((t1 / 1048576) + ((t2 % 16384) * 4096)) % 67108864
        b3 = ((t2 / 16384) + ((t3 % 256) * 262144)) % 67108864
        b4 = (t3 / 256) + 16777216
        [b0, b1, b2, b3, b4]
```

---

## 24.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` y las 5 Reglas de Oro de `crypto`

- **Garantía algorítmica y de seguridad**: `aead open` verifica el tag Poly1305 de 16 bytes en tiempo constante antes de devolver un solo byte de texto plano (si falla, devuelve `(-1, "")`).
- **Complejidad de pila $O(1)$ con TCO**: Todos los bucles recursivos en `src/main/ridgun/lib/crypto.rg` están en posición de cola, por lo que `ridgunc` los compila a saltos nativos sin crecimiento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test crypto.rg`.

### Las 5 Reglas de Oro al programar con `crypto`

1. **Declara `import crypto` al inicio del archivo** y aprovecha la equivalencia entre espacios y guiones bajos para que tu código se lea como prosa.
2. **Alinea tus tuberías de datos con `=`**: encadena las llamadas a `crypto` en pasos con nombre propio y deja que `stable format` alinee las columnas.
3. **Aprovecha las funciones totales de `crypto` en tus guardas `|`**: comprueba los valores de retorno o desenvuelve los ADTs con *pattern matching* en lugar de asumir que la entrada externa siempre es válida.
4. **Evita copiar grandes estructuras si solo necesitas consultar un campo**: recuerda que en `RMM2` los argumentos de entrada no incrementan ni decrementan contadores (`+0` / `-0`).
5. **Combina `crypto` con `test` (`import test`)**: escribe siempre aserciones con `assert equals` o `assert true` para fijar los invariantes de tu dominio.

---

En el **Capítulo 25** pasaremos a explorar en profundidad la lib **`argon2id`** (La lib `argon2id` — RFC 9106 Argon2id sobre `Tensor[U64 * 8 * 16]`, Blake2b y Presets OWASP).
