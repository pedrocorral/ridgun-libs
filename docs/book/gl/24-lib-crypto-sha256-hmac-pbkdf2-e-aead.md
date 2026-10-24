# Capítulo 24: A lib `crypto` — SHA-256, HMAC, PBKDF2, Argon2id e ChaCha20-Poly1305 AEAD

## 1. Por que existe a lib `crypto`?

Sexamos sinceros: comparar un HMAC con `==` abre a porta a ataques de temporización (*timing attacks*), e depender de `libssl.so` para calcular un `SHA-256` ou cifrar con `ChaCha20-Poly1305` rompe a portabilidade estática de calquera binario.

A lib **`crypto`** implementa ao 100 % en Ridgun puro sobre `Tensor[Int]` preasignado: operacións de bytes/bits (`RGF-019`), **FIPS 180-4 SHA-256**, **RFC 2104 HMAC-SHA-256**, igualdade en tempo constante (`ct equal`), **RFC 8018 PBKDF2-HMAC-SHA-256** con precomputación do estado intermedio SHA-256, fachada **Argon2id** de 5 argumentos e cifrado autenticado **RFC 8439 ChaCha20-Poly1305 AEAD** (`aead seal` / `aead open`).

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`crypto`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/crypto.rg` (dominio `CRYPTO`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/crypto.rglib` | Distribución e importación directa con `import crypto` |
| **Ficheiro compilado** | `target/crypto.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libcrypto.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import crypto` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `crypto`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `sha256 bytes / sha256 hex` | Resumo binario de 32 bytes ou hexadecimal de 64 caracteres FIPS 180-4 SHA-256 |
| `hmac sha256 / hmac sha256 hex / ct equal` | MAC con chave RFC 2104 e comparación de acumulador en tempo constante |
| `pbkdf2 hmac sha256 : String -> String -> Int -> Int -> String` | Derivación de chaves RFC 8018 con estados intermedios SHA-256 precomputados |
| `argon2id hash / argon2id verify` | Hashing de contrasinais PHC RFC 9106 de 5 argumentos e verificación en tempo constante |
| `aead seal / aead open` | Cifrado autenticado RFC 8439 ChaCha20-Poly1305 e descifrado con verificación de tag |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `crypto`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

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

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `crypto` é compoñible co resto das 32 libs de `ridgun-libs`:

```ridgun
import crypto

fn :: verificar firma webhook (clave : String) (cuerpo : String) (firma_hex : String) => Bool
      verificar firma webhook clave cuerpo firma_hex =
        esperada = hmac sha256 hex clave cuerpo
        ct equal esperada firma_hex
```

---

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: `aead open` verifica o tag Poly1305 de 16 bytes en tempo constante antes de devolver un só byte de texto plano (se falla, devolve `(-1, "")`).
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_crypto.rg`.
