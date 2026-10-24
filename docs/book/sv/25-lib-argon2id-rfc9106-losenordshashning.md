# Kapitel 25: Lib:en `argon2id` — RFC 9106 Argon2id över `Tensor[U64 * 8 * 16]`, Blake2b och OWASP-profiler

## 1. Varför finns lib:en `argon2id`?

Låt oss vara ärliga: att hasha lösenord med enkel SHA-256 låter en modern GPU prova miljarder gissningar per sekund, men att länka in externa C-bibliotek för Argon2id leder ofta till kompileringsproblem.

Lib:en **`argon2id`** implementerar **RFC 9106 Argon2id** och **RFC 7693 Blake2b-512** i 100 % ren Ridgun direkt över inbyggda `Tensor[U64 * 8 * 16]`-block (1 024 byte per block i sammanhängande RMM2-minne), med **PHC**-stränggenerering (`$argon2id$v=19$m=...,t=...,p=...$`), **OWASP**-profiler (`owaspfirst`, `owaspsecond`), *pepper*-stöd (`argon2id hash ctx`), nyckelhärledning (`argon2id derive key`) och detektering av parameteruppgradering (`argon2id needs rehash`).

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`argon2id`** en förstklassig **lib** placerad i `src/main/ridgun/lib/argon2id.rg` (domän `CRYPTO`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/argon2id.rglib` | Portabel distribution och direkt import med `import argon2id` |
| **Kompilerat arkiv** | `target/argon2id.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libargon2id.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import argon2id` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `argon2id`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `argon2id hash / argon2id verify` | 6-arguments RFC 9106 PHC-hashning (`pwd, salt, m_kib, t, p, tag_len`) och konstanttidsverifiering |
| `argon2id hash with preset / argon2id params preset` | Namngivna profiler: `"interactive"`, `"owaspfirst"` (`19456 KiB, t=2`), `"owaspsecond"` (`47104 KiB, t=1`), `"moderate"`, `"sensitive"` |
| `argon2id hash ctx / argon2id verify ctx` | RFC 9106-hashning med hemlig `pepper` ($K$) och associerad data ($X$) |
| `argon2id derive key / argon2id needs rehash` | Rå binär nyckelhärledning och detektering av rehash-behov för lagrade PHC-strängar |
| `blake2b / blake2b hex` | Allmän kryptografisk RFC 7693 Blake2b-digest (`1..64` byte) |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `argon2id`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

```ridgun
import argon2id

fn :: proteger clave usuario (clave : String) => (String, Bool, Bool)
      proteger clave usuario clave =
        phc    = argon2id hash clave "sal-unica-16byte" 32 2 1 32
        valido = argon2id verify clave phc
        rehash = argon2id needs rehash phc 19456 2 1 32
        (phc, valido, rehash)
```

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `argon2id` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

```ridgun
import argon2id

fn :: derivar clave maestra (frase : String) (sal : String) => String
      derivar clave maestra frase sal =
        -- Deriva 32 bytes crudos listos para ChaCha20-Poly1305 AEAD
        argon2id derive key frase sal 64 2 1 32
```

---

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: Byte-för-byte-överensstämmelse med de officiella testvektorerna i RFC 9106 §5.3 och OpenSSL 3.5, direkt över `Tensor[U64 * 8 * 16]` utan en enda rad C.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_argon2id.rg`.
