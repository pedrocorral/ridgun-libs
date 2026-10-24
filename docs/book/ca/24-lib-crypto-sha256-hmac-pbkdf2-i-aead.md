# Capítol 24: La lib `crypto` — SHA-256, HMAC, PBKDF2, Argon2id i ChaCha20-Poly1305 AEAD

## 1. Per què existeix la lib `crypto`?

Siguem sincers: comparar un HMAC amb `==` obre la porta a atacs de temporització (*timing attacks*), i dependre de `libssl.so` per calcular un `SHA-256` o xifrar amb `ChaCha20-Poly1305` trenca la portabilitat estàtica de qualsevol binari.

La lib **`crypto`** implementa al 100 % en Ridgun pur sobre `Tensor[Int]` preassignat: operacions de bytes/bits (`RGF-019`), **FIPS 180-4 SHA-256**, **RFC 2104 HMAC-SHA-256**, igualtat en temps constant (`ct equal`), **RFC 8018 PBKDF2-HMAC-SHA-256** amb precomputació de l'estat intermedi SHA-256, façana **Argon2id** de 5 arguments i xifratge autenticat **RFC 8439 ChaCha20-Poly1305 AEAD** (`aead seal` / `aead open`).

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`crypto`** és una **lib** de primera classe situada a `src/main/ridgun/lib/crypto.rg` (domini `CRYPTO`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/crypto.rglib` | Distribució i importació directa amb `import crypto` |
| **Fitxer compilat** | `target/crypto.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libcrypto.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import crypto` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `crypto`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `sha256 bytes / sha256 hex` | Resum binari de 32 bytes o hexadecimal de 64 caràcters FIPS 180-4 SHA-256 |
| `hmac sha256 / hmac sha256 hex / ct equal` | MAC amb clau RFC 2104 i comparació d'acumulador en temps constant |
| `pbkdf2 hmac sha256 : String -> String -> Int -> Int -> String` | Derivació de claus RFC 8018 amb estats intermedis SHA-256 precomputats |
| `argon2id hash / argon2id verify` | Hashing de contrasenyes PHC RFC 9106 de 5 arguments i verificació en temps constant |
| `aead seal / aead open` | Xifratge autenticat RFC 8439 ChaCha20-Poly1305 i desxifratge amb verificació de tag |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `crypto`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

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

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `crypto` és componible amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import crypto

fn :: verificar firma webhook (clave : String) (cuerpo : String) (firma_hex : String) => Bool
      verificar firma webhook clave cuerpo firma_hex =
        esperada = hmac sha256 hex clave cuerpo
        ct equal esperada firma_hex
```

---

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: `aead open` verifica el tag Poly1305 de 16 bytes en temps constant abans de retornar un sol byte de text pla (si falla, retorna `(-1, "")`).
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_crypto.rg`.
