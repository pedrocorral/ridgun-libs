# Kapitel 24: Lib:en `crypto` — SHA-256, HMAC, PBKDF2, Argon2id och ChaCha20-Poly1305 AEAD

## 1. Varför finns lib:en `crypto`?

Låt oss vara ärliga: att jämföra en HMAC med `==` öppnar dörren för sidokanalsattacker (*timing attacks*), och att länka in `libssl.so` för att beräkna `SHA-256` eller kryptera med `ChaCha20-Poly1305` förstör binärens portabilitet.

Lib:en **`crypto`** implementerar i 100 % ren Ridgun över förallokerade `Tensor[Int]`: byte-/bitprimitiver (`RGF-019`), **FIPS 180-4 SHA-256**, **RFC 2104 HMAC-SHA-256**, konstanttidslikhet (`ct equal`), **RFC 8018 PBKDF2-HMAC-SHA-256**, 5-arguments **Argon2id** samt autentiserad kryptering med **RFC 8439 ChaCha20-Poly1305 AEAD** (`aead seal` / `aead open`).

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`crypto`** en förstklassig **lib** placerad i `src/main/ridgun/lib/crypto.rg` (domän `CRYPTO`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/crypto.rglib` | Portabel distribution och direkt import med `import crypto` |
| **Kompilerat arkiv** | `target/crypto.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libcrypto.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import crypto` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `crypto`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `sha256 bytes / sha256 hex` | FIPS 180-4 SHA-256 som 32-bytes binär digest eller 64-teckens hex-sträng |
| `hmac sha256 / hmac sha256 hex / ct equal` | RFC 2104-nycklad MAC och ackumulatorjämförelse i konstant tid |
| `pbkdf2 hmac sha256 : String -> String -> Int -> Int -> String` | RFC 8018-nyckelhärledning med förberäknade inre/yttre SHA-256-mellantillstånd |
| `argon2id hash / argon2id verify` | 5-arguments RFC 9106 PHC-lösenordshashning och konstanttidsverifiering |
| `aead seal / aead open` | RFC 8439 ChaCha20-Poly1305 autentiserad kryptering och taggverifierad dekryptering |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `crypto`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

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

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `crypto` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

```ridgun
import crypto

fn :: verificar firma webhook (clave : String) (cuerpo : String) (firma_hex : String) => Bool
      verificar firma webhook clave cuerpo firma_hex =
        esperada = hmac sha256 hex clave cuerpo
        ct equal esperada firma_hex
```

---

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: `aead open` verifierar Poly1305-autentiseringstaggen på 16 byte i konstant tid innan en enda byte klartext lämnas ut (returnerar `(-1, "")` vid manipulering).
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_crypto.rg`.
