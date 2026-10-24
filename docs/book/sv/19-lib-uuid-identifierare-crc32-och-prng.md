# Kapitel 19: Lib:en `uuid` — RFC 9562 `UUIDv4`/`UUIDv7`, Kontrollsummor (`CRC-32`) och PRNG

## 19.1. Varför finns lib:en `uuid`? (Det verkliga problemet och Ridguns filosofi)

> *”Varför behöver jag en `uuid`-lib skriven från grunden i ren Ridgun i stället för att bara länka in ett gammalt C-bibliotek?”*

Det är den första fråga varje systemingenjör ställer sig när man möter `uuid`. Och svaret sammanfattar hela filosofin bakom `ridgun-libs`:

Låt oss vara ärliga: att använda helt slumpmässiga `UUIDv4` som primärnycklar i en databas fragmenterar B-Tree-index, medan hemmasnickrade ID:n utan kärnentropi leder till kollisioner.

Lib:en **`uuid`** implementerar **RFC 9562 `UUIDv4`** (kärn-CSPRNG) och tidsordnade **`UUIDv7`** (48-bitars millisekundprefix för B-Tree-lokalitet), snabba kontrollsummor (**FNV-1a**, **Adler-32**, **IEEE 802.3 CRC-32**) samt en deterministisk PRNG.

I ett traditionellt ekosystem innebär uppgifter inom domänen **`UUID`** ofta att man drar in externa C-beroenden, brottas med råa pekare, ogenomskinliga typkonverteringar, okontrollerade undantag eller oförutsägbara skräpsamlarpauser. I Ridgun löser lib:en **`uuid`** (`src/main/ridgun/lib/uuid.rg`) problemet genom fyra kompromisslösa principer:

1. **Totala funktioner och explicita kontrakt (`=>`)**: ingen funktion i `uuid` kastar dolda undantag eller förlitar sig på `null`. Varje gränsfall returnerar ett dokumenterat sentinelvärde eller en algebraisk summatyp (`Option`, `Result`).
2. **Noll C-kod och noll `libc`**: varje rad i `uuid` kompileras direkt till inbyggd ELF64-maskinkod verifierad av `ridgunc`.
3. **Svansrekursion med TCO (*Tail-Call Optimization*)**: alla interna genomlöpningar i `uuid` kompileras till inbyggda hårdvaruloopar med $O(1)$ stackutrymme.
4. **Deterministiskt minne (`RMM1` / `RMM2`)**: varje mellanliggande struktur frigörs i exakt det ögonblick dess sista läsning avslutas, helt utan *Garbage Collector*.

---

## 19.2. Inbyggda artefakter, import och komplett API-katalog för `uuid`

I `ridgun-libs` är **`uuid`** en förstklassig **lib** placerad i `src/main/ridgun/lib/uuid.rg` (domän `UUID`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/uuid.rglib` | Portabel distribution och direkt import med `import uuid` |
| **Kompilerat arkiv** | `target/uuid.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libuuid.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import uuid` överst och anropar funktionerna med mellanslag eller understreck.

### 19.2.1. Översikt över funktionella familjer i `uuid`

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `uuid v4 / uuid v7 / uuid v7 at` | Genererar kanoniska 36-teckens UUID enligt RFC 9562 v4 (slump) och v7 (tidsordnad) |
| `uuid is valid / uuid version` | Validerar 8-4-4-4-12-formatet och RFC 9562-variantbitar (`8, 9, a, b`) |
| `fnv1a 32 / adler32 / crc32 / crc32 hex` | Snabba 32-bitars icke-kryptografiska hashar och kontrollsummor |
| `prng next / prng range` | Ren funktionell linjär kongruens-PRNG för reproducerbara tester och simuleringar |

### 19.2.2. Komplett katalog över typer och signaturer i `src/main/ridgun/lib/uuid.rg`

Nedan följer hela förteckningen över algebraiska datatyper (`type`), mixfix-operatorer (`op ::`) och funktionssignaturer (`fn ::`) som definieras i `src/main/ridgun/lib/uuid.rg` (`0` typer, `0` operatorer och `33` funktioner):

| # | Funktion / Signatur (`fn ::`) | Returtyp |
|---|---|---|
| `1` | `fn :: uu hex lut Int` | `String` |
| `2` | `fn :: uu u32 Int` | `Int` |
| `3` | `fn :: uu bxor loop Int Int Int Int` | `Int` |
| `4` | `fn :: uu bxor32 Int Int` | `Int` |
| `5` | `fn :: uu fnv loop String Int Int Int` | `Int` |
| `6` | `fn :: fnv1a 32 String` | `Int` |
| `7` | `fn :: uu adler loop String Int Int Int Int` | `Int` |
| `8` | `fn :: adler32 String` | `Int` |
| `9` | `fn :: uu crc bit loop Int Int` | `Int` |
| `10` | `fn :: uu crc byte loop String Int Int Int` | `Int` |
| `11` | `fn :: crc32 String` | `Int` |
| `12` | `fn :: uu abs Int` | `Int` |
| `13` | `fn :: prng next Int` | `Int` |
| `14` | `fn :: uu prng range step Int Int Int` | `Int Int` |
| `15` | `fn :: prng range Int Int Int` | `Int Int` |
| `16` | `fn :: uu alloc page Int` | `Int` |
| `17` | `fn :: uu free page Int Int Int` | `Int` |
| `18` | `fn :: uu alloc mfd` | `Int` |
| `19` | `fn :: uu peek Int Int Int` | `String` |
| `20` | `fn :: uu decode u32 le String Int` | `Int` |
| `21` | `fn :: uu decode u64 le String Int` | `Int` |
| `22` | `fn :: uu wall time ms` | `Int` |
| `23` | `fn :: uu bytes to hex loop String Int Int` | `String` |
| `24` | `fn :: uu random hex16` | `String` |
| `25` | `fn :: uu hex val Int` | `Int` |
| `26` | `fn :: uu variant char String` | `String` |
| `27` | `fn :: uuid v4` | `String` |
| `28` | `fn :: uu hex48 loop Int Int` | `String` |
| `29` | `fn :: uuid v7 at Int` | `String` |
| `30` | `fn :: uuid v7` | `String` |
| `31` | `fn :: uu is hex range String Int Int` | `Bool` |
| `32` | `fn :: uuid is valid String` | `Bool` |
| `33` | `fn :: uuid version String` | `Int` |

---

## 19.3. Djupdykning i `uuid`: Steg-för-steg-exempel för varje funktion

Det räcker inte med en signaturtabell: låt oss utforska **varje funktionalitet** i lib:en `uuid` genom progressiva, körbara Ridgun-exempel. Vi börjar med två tabellbaserade vardagsrecept och går därefter igenom alla funktionella scenarier, transformationer och gränsfall som verifieras i `src/test/ridgun/test uuid.rg`.

### 19.3.1. Exempel 1: Huvudflöde i tabellform med `uuid`

Lägg märke till hur `=`-tecknen och transformationsstegen med `uuid` linjeras som en ren tabell utan onödiga muterbara variabler eller dolda sidoeffekter:

```ridgun
import uuid

fn :: generar ids ordenados () => (String, String, Bool)
      generar ids ordenados =
        id1 = uuid v7 at 1000
        id2 = uuid v7 at 2000
        ok  = (uuid is valid id1) and (id1 < id2)
        (id1, id2, ok)
```

### 19.3.2. Exempel 2: Säker komposition och hantering av gränsfall

Varje funktion i lib:en `uuid` är utformad för att kombineras sömlöst med booleska vakter `|` och med övriga 32 libs i `ridgun-libs`:

```ridgun
import uuid

fn :: firmar paquete (payload : String) => (String, Int)
      firmar paquete payload =
         (crc32 hex payload, fnv1a 32 payload)
```

### 19.3.3. Exempel 3: Generering, validering och inspektion av UUIDv4 (CSPRNG) och tidsordnade UUIDv7 (RFC 9562)

I detta praktiska exempel undersöker vi grundligt hur `uuid` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test uuidv4 and uuidv7 => ()
      test uuidv4 and uuidv7 =
        u4a = uuid v4
        u4b = uuid v4
        _ = assert int equals (str len u4a) 36 "AC1: uuid_v4 length 36"
        _ = assert true (uuid is valid u4a) "AC1: uuid_v4 valid RFC 9562 format"
        _ = assert true (uuid is valid u4b) "AC1: second uuid_v4 valid"
        _ = assert false (u4a == u4b) "AC1: CSPRNG uuid_v4 calls are unique"
        _ = assert int equals (uuid version u4a) 4 "AC1: uuid_v4 version == 4"

        -- RFC 9562 UUIDv7 timestamp encoding & chronological prefix ordering
        u7_zero = uuid v7 at 0
        u7a = uuid v7 at 1700000000000
        u7b = uuid v7 at 1800000000000
        u7_live = uuid v7
        _ = assert true (uuid is valid u7_zero) "AC1: uuid_v7 at epoch 0 valid"
        _ = assert str eq (str slice u7_zero 0 13) "00000000-0000" "AC1: uuid_v7 at epoch 0 zero prefix"
        _ = assert true (uuid is valid u7a) "AC1: uuid_v7 at 1700000000000 valid"
        _ = assert true (uuid is valid u7b) "AC1: uuid_v7 at 1800000000000 valid"
        _ = assert true (uuid is valid u7_live) "AC1: live uuid_v7 valid"
        _ = assert int equals (uuid version u7a) 7 "AC1: uuid_v7 version == 7"
        _ = assert int equals (uuid version u7_live) 7 "AC1: live uuid_v7 version == 7"
        _ = assert str eq (str slice u7a 0 8) "018bcfe5" "AC1: uuid_v7 timestamp prefix 1700000000000"
        _ = assert str eq (str slice u7b 0 8) "01a3185c" "AC1: uuid_v7 timestamp prefix 1800000000000"

        -- Uppercase valid UUID acceptance & RFC 9562 variant nibble (8, 9, a, b) validation
        _ = assert true (uuid is valid "550E8400-E29B-41D4-A716-446655440000") "AC1: uppercase RFC 9562 UUID valid"
        _ = assert false (uuid is valid "") "AC1: empty string invalid"
        _ = assert false (uuid is valid "not-a-uuid") "AC1: short string invalid"
        _ = assert false (uuid is valid "550e8400-e29b-41d4-1716-446655440000") "AC1: variant nibble '1' (< 8) rejected"
        _ = assert false (uuid is valid "550e8400-e29b-41d4-c716-446655440000") "AC1: variant nibble 'c' (> b) rejected"
        _ = assert false (uuid is valid "550e8400Xe29b-41d4-a716-446655440000") "AC1: missing hyphen at index 8 rejected"
        _ = assert false (uuid is valid "550e8400-e29b-41d4-a716-44665544000g") "AC1: non-hex character 'g' rejected"
        _ = assert int equals (uuid version "not-a-uuid") (0 - 1) "AC1: invalid uuid version -> -1"
        ()
```

### 19.3.4. Exempel 4: Kontrollsummorna FNV-1a, DJB2, Adler-32, IEEE 802.3 CRC32 (`0xCBF43926`) och deterministisk SplitMix64-PRNG

I detta praktiska exempel undersöker vi grundligt hur `uuid` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test checksums and prng => ()
      test checksums and prng =
        -- Official FNV-1a 32-bit vectors (isthe.com/chongo/tech/comp/fnv/)
        _ = assert int equals (fnv1a 32 "") 2166136261 "AC2: FNV-1a 32 '' == 0x811c9dc5 (offset basis)"
        _ = assert int equals (fnv1a 32 "a") 3826002220 "AC2: FNV-1a 32 'a' == 0xe40c292c"
        _ = assert int equals (fnv1a 32 "foobar") 3214735720 "AC2: FNV-1a 32 'foobar' == 0xbf9cf968"

        -- Official RFC 1950 Adler-32 vectors
        _ = assert int equals (adler32 "") 1 "AC2: Adler-32 '' == 1"
        _ = assert int equals (adler32 "a") 6422626 "AC2: Adler-32 'a' == 0x00620062"
        _ = assert int equals (adler32 "Wikipedia") 300286872 "AC2: Adler-32 'Wikipedia' == 0x11e60398"

        -- Official IEEE 802.3 / ISO-HDLC CRC-32 vectors
        _ = assert int equals (crc32 "") 0 "AC2: CRC-32 '' == 0"
        _ = assert int equals (crc32 "a") 3904355907 "AC2: CRC-32 'a' == 0xe8b7be43"
        _ = assert int equals (crc32 "123456789") 3421780262 "AC2: CRC-32 '123456789' == 0xcbf43926"

        -- Deterministic 31-bit LCG PRNG
        s1 = prng next 42
        s2 = prng next 42
        s3 = prng next s1
        _ = assert int equals s1 s2 "AC3: prng_next deterministic for same seed"
        _ = assert false (s1 == s3) "AC3: prng_next advances state"
        r1 = prng range 42 10 20
        v1 = prng val r1
        _ = assert true (v1 >= 10 and v1 <= 20) "AC3: prng_range within [10, 20]"
        r_deg = prng range 42 50 10
        _ = assert int equals (prng val r_deg) 50 "AC3: prng_range with hi <= lo clamps to lo"
        ()
```

### 19.3.5. Exempel 5: Distribuerad spårning med tidsordnade UUIDv7 och paketintegritet via CRC32 och FNV-1a (`uuid v7`, `uuid v7 timestamp ms`, `crc32 hex`)

I detta praktiska exempel undersöker vi grundligt hur `uuid` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
import uuid

fn :: sellar paquete trazado (ahora_ms : Int) (payload : String) => (String, Int, String, Int)
      sellar paquete trazado ahora_ms payload =
        trace_id = uuid v7 ahora_ms
        ts_extra = uuid v7 timestamp ms trace_id
        crc_hex  = crc32 hex payload
        hash_fnv = fnv1a 64 payload
        (trace_id, ts_extra, crc_hex, hash_fnv)
```

---

## 19.4. Under huven: hur `uuid` är byggd i ren Ridgun (`src/main/ridgun/lib/uuid.rg`)

En av de största fördelarna med `ridgun-libs` är att **det inte finns några svarta lådor i C**. Du kan öppna `src/main/ridgun/lib/uuid.rg` och läsa exakt hur varje operation är implementerad med mönstermatchning, `|` / `|.`-vaktträd och svansrekursion (TCO). Låt oss titta på nyckeldelarna i den faktiska implementationen:

### 19.4.1. Intern implementation: RFC 9562 UUIDv4 & UUIDv7 Generation & Validation (CSPRNG + clock_gettime)

Se hur `uuid.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: uu alloc page Int => Int
      uu alloc page sz  =
        neg1 = 0 - 1
        sys call 9 0 sz 3 34 neg1 0

fn :: uu free page Int Int Int => Int
      uu free page mfd ptr sz =
        _ = sys close mfd
        sys call 11 ptr sz 0 0 0 0

fn :: uu alloc mfd => Int
      uu alloc mfd =  sys call 319 4194311 1 0 0 0 0

fn :: uu peek Int Int Int => String
      uu peek mfd ptr len =
        _ = sys call 18 mfd ptr len 0 0 0
        _ = sys call 8 mfd 0 0 0 0 0
        sys read fd mfd len

fn :: uu decode u32 le String Int => Int
      uu decode u32 le s off =
        b0 = str char at s off
        b1 = str char at s (off + 1)
        b2 = str char at s (off + 2)
        b3 = str char at s (off + 3)
        b0 + (b1 * 256) + (b2 * 65536) + (b3 * 16777216)

fn :: uu decode u64 le String Int => Int
      uu decode u64 le s off =
        lo = uu decode u32 le s off
        hi = uu decode u32 le s (off + 4)
        lo + (hi * 4294967296)

fn :: uu wall time ms => Int
      uu wall time ms =
        ptr  = uu alloc page 4096
        mfd  = uu alloc mfd
        _    = sys call 228 0 ptr 0 0 0 0
        raw  = uu peek mfd ptr 16
        _    = uu free page mfd ptr 4096
        sec  = uu decode u64 le raw 0
        nsec = uu decode u64 le raw 8
        (sec * 1000) + (nsec / 1000000)
```

---

## 19.5. Algoritmiska garantier, `RMM1`/`RMM2`-minne och de 5 Gyllene Reglerna för `uuid`

- **Algoritmisk garanti och säkerhet**: `uuid v7 at t1 < uuid v7 at t2` garanterar monotont stigande lexikografisk ordning över tid, perfekt för `btree`-index och databaser.
- **$O(1)$ stackkomplexitet med TCO**: Alla rekursiva loopar i `src/main/ridgun/lib/uuid.rg` ligger i svansposition, så `ridgunc` kompilerar dem till inbyggda hopp utan stacktillväxt.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test uuid.rg`.

### De 5 Gyllene Reglerna när du programmerar med `uuid`

1. **Deklarera `import uuid` överst i filen** och utnyttja att mellanslag och understreck är utbytbara så att koden läses som naturlig prosa.
2. **Linjera dina datapipelines med `=`**: kedja samman `uuid`-anrop i namngivna mellansteg och låt `stable format` linjera kolumnerna.
3. **Utnyttja `uuid`:s totala funktioner i dina `|`-vakter**: kontrollera returvärden eller packa upp ADT:er med mönstermatchning i stället för att anta att extern indata alltid är giltig.
4. **Undvik att kopiera stora strukturer när du bara läser ett fält**: kom ihåg att i `RMM2` medför inargument noll referensräkningskostnad (`+0` / `-0`).
5. **Kombinera `uuid` med `test` (`import test`)**: lås alltid fast dina domäninvarianter med `assert equals` eller `assert true`.

---

I **Kapitel 20** går vi vidare och utforskar lib:en **`log`** på djupet (Lib:en `log` — Strukturerad NDJSON-loggning och Automatisk Sekretessmaskering).
