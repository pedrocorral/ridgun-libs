# 24. kapitulua: `crypto` lib-a — SHA-256, HMAC, PBKDF2, Argon2id eta ChaCha20-Poly1305 AEAD

## 1. Zergatik existitzen da `crypto` lib-a?

Izan gaitezen zintzoak: HMAC bat `==`-rekin konparatzeak denbora-erasoei (*timing attacks*) atea irekitzen die, eta `SHA-256` bat kalkulatzeko edo `ChaCha20-Poly1305`-ekin zifratzeko `libssl.so`-ren menpe egoteak edozein bitarren eramangarritasun estatikoa apurtzen du.

**`crypto`** lib-ak % 100ean Ridgun hutsean eta aurrez esleitutako `Tensor[Int]` gainean inplementatzen ditu: byte/bit eragiketak (`RGF-019`), **FIPS 180-4 SHA-256**, **RFC 2104 HMAC-SHA-256**, denbora konstanteko berdintasuna (`ct equal`), **RFC 8018 PBKDF2-HMAC-SHA-256**, 5 argumentuko **Argon2id** fatxada eta **RFC 8439 ChaCha20-Poly1305 AEAD** zifraketa autentifikatua (`aead seal` / `aead open`).

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`crypto`** lehen mailako **lib** bat da, `src/main/ridgun/lib/crypto.rg` bidean kokatua (`CRYPTO` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/crypto.rglib` | Banaketa eta inportazio zuzena `import crypto` bidez |
| **Fitxategi konpilatua** | `target/crypto.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libcrypto.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import crypto` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `crypto` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `sha256 bytes / sha256 hex` | FIPS 180-4 SHA-256 32 byteko laburpen bitarra edo 64 karaktereko hamaseitarra |
| `hmac sha256 / hmac sha256 hex / ct equal` | RFC 2104 gakodun MACa eta denbora konstanteko metagailu-konparazioa |
| `pbkdf2 hmac sha256 : String -> String -> Int -> Int -> String` | RFC 8018 gako-eratorpena aurrez kalkulatutako SHA-256 tarteko egoerekin |
| `argon2id hash / argon2id verify` | 5 argumentuko RFC 9106 PHC pasahitz-hashinga eta denbora konstanteko egiaztapena |
| `aead seal / aead open` | RFC 8439 ChaCha20-Poly1305 zifraketa autentifikatua eta etiketa egiaztatuko deszifraketa |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `crypto` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

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

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`crypto` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

```ridgun
import crypto

fn :: verificar firma webhook (clave : String) (cuerpo : String) (firma_hex : String) => Bool
      verificar firma webhook clave cuerpo firma_hex =
        esperada = hmac sha256 hex clave cuerpo
        ct equal esperada firma_hex
```

---

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: `aead open`-ek 16 byteko Poly1305 etiketa denbora konstantean egiaztatzen du testu lauko byte bakar bat itzuli aurretik (huts egiten badu, `(-1, "")` itzultzen du).
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_crypto.rg` suite automatizatuaren bidez.
