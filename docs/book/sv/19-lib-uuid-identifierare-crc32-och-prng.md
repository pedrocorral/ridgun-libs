# Kapitel 19: Lib:en `uuid` — RFC 9562 `UUIDv4`/`UUIDv7`, Kontrollsummor (`CRC-32`) och PRNG

## 1. Varför finns lib:en `uuid`?

Låt oss vara ärliga: att använda helt slumpmässiga `UUIDv4` som primärnycklar i en databas fragmenterar B-Tree-index, medan hemmasnickrade ID:n utan kärnentropi leder till kollisioner.

Lib:en **`uuid`** implementerar **RFC 9562 `UUIDv4`** (kärn-CSPRNG) och tidsordnade **`UUIDv7`** (48-bitars millisekundprefix för B-Tree-lokalitet), snabba kontrollsummor (**FNV-1a**, **Adler-32**, **IEEE 802.3 CRC-32**) samt en deterministisk PRNG.

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`uuid`** en förstklassig **lib** placerad i `src/main/ridgun/lib/uuid.rg` (domän `UUID`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/uuid.rglib` | Portabel distribution och direkt import med `import uuid` |
| **Kompilerat arkiv** | `target/uuid.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libuuid.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import uuid` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `uuid`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `uuid v4 / uuid v7 / uuid v7 at` | Genererar kanoniska 36-teckens UUID enligt RFC 9562 v4 (slump) och v7 (tidsordnad) |
| `uuid is valid / uuid version` | Validerar 8-4-4-4-12-formatet och RFC 9562-variantbitar (`8, 9, a, b`) |
| `fnv1a 32 / adler32 / crc32 / crc32 hex` | Snabba 32-bitars icke-kryptografiska hashar och kontrollsummor |
| `prng next / prng range` | Ren funktionell linjär kongruens-PRNG för reproducerbara tester och simuleringar |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `uuid`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

```ridgun
import uuid

fn :: generar ids ordenados () => (String, String, Bool)
      generar ids ordenados =
        id1 = uuid v7 at 1000
        id2 = uuid v7 at 2000
        ok  = (uuid is valid id1) and (id1 < id2)
        (id1, id2, ok)
```

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `uuid` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

```ridgun
import uuid

fn :: firmar paquete (payload : String) => (String, Int)
      firmar paquete payload =
         (crc32 hex payload, fnv1a 32 payload)
```

---

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: `uuid v7 at t1 < uuid v7 at t2` garanterar monotont stigande lexikografisk ordning över tid, perfekt för `btree`-index och databaser.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_uuid.rg`.
