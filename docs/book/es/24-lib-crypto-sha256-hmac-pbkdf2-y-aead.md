# Capítulo 24: La lib `crypto` — SHA-256, HMAC, PBKDF2, Argon2id y ChaCha20-Poly1305 AEAD

## 1. ¿Por qué existe la lib `crypto`?

Seamos sinceros: comparar un HMAC con `==` abre la puerta a ataques de temporización (*timing attacks*), y depender de `libssl.so` para calcular un `SHA-256` o cifrar con `ChaCha20-Poly1305` rompe la portabilidad estática de cualquier binario.

La lib **`crypto`** implementa al 100 % en Ridgun puro sobre `Tensor[Int]` preasignado: operaciones de bytes/bits (`RGF-019`), **FIPS 180-4 SHA-256**, **RFC 2104 HMAC-SHA-256**, igualdad en tiempo constante (`ct equal`), **RFC 8018 PBKDF2-HMAC-SHA-256** con precomputación del estado intermedio SHA-256, fachada **Argon2id** de 5 argumentos y cifrado autenticado **RFC 8439 ChaCha20-Poly1305 AEAD** (`aead seal` / `aead open`).

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`crypto`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/crypto.rg` (dominio `CRYPTO`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/crypto.rglib` | Distribución e importación directa con `import crypto` |
| **Archivo compilado** | `target/crypto.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libcrypto.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import crypto` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `crypto`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `sha256 bytes / sha256 hex` | Resumen binario de 32 bytes o hexadecimal de 64 caracteres FIPS 180-4 SHA-256 |
| `hmac sha256 / hmac sha256 hex / ct equal` | MAC con clave RFC 2104 y comparación de acumulador en tiempo constante |
| `pbkdf2 hmac sha256 : String -> String -> Int -> Int -> String` | Derivación de claves RFC 8018 con estados intermedios SHA-256 precomputados |
| `argon2id hash / argon2id verify` | Hashing de contraseñas PHC RFC 9106 de 5 argumentos y verificación en tiempo constante |
| `aead seal / aead open` | Cifrado autenticado RFC 8439 ChaCha20-Poly1305 y descifrado con verificación de tag |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `crypto`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

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

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `crypto` es componible con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import crypto

fn :: verificar firma webhook (clave : String) (cuerpo : String) (firma_hex : String) => Bool
      verificar firma webhook clave cuerpo firma_hex =
        esperada = hmac sha256 hex clave cuerpo
        ct equal esperada firma_hex
```

---

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: `aead open` verifica el tag Poly1305 de 16 bytes en tiempo constante antes de devolver un solo byte de texto plano (si falla, devuelve `(-1, "")`).
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_crypto.rg`.
