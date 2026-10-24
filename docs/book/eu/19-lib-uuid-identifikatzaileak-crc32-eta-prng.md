# 19. kapitulua: `uuid` lib-a — RFC 9562 `UUIDv4`/`UUIDv7`, FNV-1a, Adler-32, CRC-32 eta PRNG

## 19.1. Zergatik existitzen da `uuid` lib-a? (Benetako arazoa eta Ridgun filosofia)

> *«Zergatik behar dut `uuid` lib bat hutsetik Ridgun hutsean idatzia, betiko C liburutegi bat estekatu beharrean?»*

Hori da edozein sistema-ingeniarik `uuid`-era iristean egiten duen lehen galdera. Eta erantzunak `ridgun-libs`-en filosofia osoa laburbiltzen du:

Izan gaitezen zintzoak: datu-base batean gako nagusi gisa erabat ausazko `UUIDv4`-ak erabiltzeak B-Tree indizeak zatikatzen ditu, eta nukleoaren entropiarik gabeko etxeko IDak asmatzeak talketan amaitzen du.

**`uuid`** lib-ak **`UUIDv4`** (nukleoaren CSPRNG bidezko ausazkoa) eta **`UUIDv7`** (**RFC 9562** arauaren arabera lehen 48 bitetan kronologikoki ordenatua), egiaztapen-batura azkarrak (**FNV-1a**, **Adler-32**, **CRC-32 IEEE 802.3**) eta hazidun PRNG determinista bat inplementatzen ditu.

Ekosistema tradizional batean, **`UUID`** domeinuko zereginak ebazteak C-ko kanpo-mendekotasunak arrastatzea, erakusle gordinekin borrokatzea, mota-bihurketa opakuak, egiaztatu gabeko salbuespenak edo zabor-biltzailearen geldialdi ustekabekoak jasatea dakar. Ridgunen, **`uuid`** lib-ak (`src/main/ridgun/lib/uuid.rg`) lau printzipio negoziatu ezinekin heltzen dio arazoari:

1. **Funtzio osoak eta kontratu esplizituak (`=>`)**: `uuid`-eko funtzio bakar batek ere ez du ezkutuko salbuespenik jaurtitzen, ezta `null` erabiltzen ere. Muga-kasu orok dokumentatutako balio bat edo batura-mota aljebraiko bat (`Option`, `Result`) itzultzen du.
2. **Zero C kode eta zero `libc`**: `uuid`-eko kode guztia zuzenean ELF64 makina-kode natibora konpilatzen da, `ridgunc`-ek egiaztatuta.
3. **Isats-errekurtsioa TCOrekin (*Tail-Call Optimization*)**: `uuid`-eko barne-ibilbide guztiak $O(1)$ pila-espazioko begizta natiboetara konpilatzen dira.
4. **Memoria determinista (`RMM1` / `RMM2`)**: tarteko egitura bakoitza bere azken irakurketa amaitzen den une zehatzean askatzen da, *Garbage Collector* gabe.

---

## 19.2. Artefaktu natiboak, inportazioa eta `uuid` APIaren katalogo osoa

`ridgun-libs`-en, **`uuid`** lehen mailako **lib** bat da, `src/main/ridgun/lib/uuid.rg` bidean kokatua (`UUID` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/uuid.rglib` | Banaketa eta inportazio zuzena `import uuid` bidez |
| **Fitxategi konpilatua** | `target/uuid.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libuuid.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import uuid` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

### 19.2.1. `uuid`-eko familia funtzionalen laburpena

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `uuid v4 / uuid v7 / uuid v7 at` | 36 karaktereko RFC 9562 v4 (ausazkoa) eta v7 (denboraz ordenatua) UUID kanonikoak sortzen ditu |
| `uuid is valid / uuid version` | 8-4-4-4-12 egitura eta RFC 9562 aldaera-bitak (`8, 9, a, b`) baliozkotzen ditu |
| `fnv1a 32 / adler32 / crc32 / crc32 hex` | 32 biteko hash ez-kriptografiko eta egiaztapen-batura azkarrak |
| `prng next / prng range` | Proba eta simulazio errepikagarrietarako PRNG kongruentzial lineal funtzional hutsa |

### 19.2.2. `src/main/ridgun/lib/uuid.rg`-eko mota eta sinadura guztien katalogoa

Jarraian duzu `src/main/ridgun/lib/uuid.rg` fitxategian definitutako mota aljebraiko (`type`), eragile (`op ::`) eta funtzio-sinadura (`fn ::`) guztien inbentario osoa (`0` mota, `0` eragile eta `33` funtzio):

| # | Funtzioa / Sinadura (`fn ::`) | Itzulera-mota |
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

## 19.3. `uuid` sakonki esploratzen: Funtzionalitate bakoitzaren urratsez urratseko adibideak

Ez da nahikoa sinadura-taula ikustea: `uuid` lib-aren **funtzionalitate bakoitza** Ridgunen exekutagarriak diren adibide progresiboen bidez esploratuko dugu. Eguneroko bi errezeta taularatuekin hasiko gara eta ondoren xehetasunez ikusiko ditugu `src/test/ridgun/test uuid.rg`-en egiaztatutako agertoki funtzional eta muga-kasu guztiak.

### 19.3.1. 1. adibidea: Fluxu nagusia estilo taularatuan `uuid` erabiliz

Ikusi nola Ridgunen `=` ikurrak eta `uuid` bidezko eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren, beharrezkoak ez diren aldagai aldakorrik edo ezkutuko albo-ondoriorik gabe:

```ridgun
import uuid

fn :: generar ids ordenados () => (String, String, Bool)
      generar ids ordenados =
        id1 = uuid v7 at 1000
        id2 = uuid v7 at 2000
        ok  = (uuid is valid id1) and (id1 < id2)
        (id1, id2, ok)
```

### 19.3.2. 2. adibidea: Konposizio segurua eta muga-kasuen kudeaketa

`uuid` lib-eko funtzio oro `|` guarda boolearrekin eta `ridgun-libs`-eko gainerako 32 lib-ekin konposatzeko diseinatuta dago:

```ridgun
import uuid

fn :: firmar paquete (payload : String) => (String, Int)
      firmar paquete payload =
         (crc32 hex payload, fnv1a 32 payload)
```

### 19.3.3. 3. adibidea: UUIDv4 (CSPRNG) eta denboraz ordenagarriak diren UUIDv7 (RFC 9562) identifikatzaileen sorrera, baliozkotzea eta ikuskapena

Adibide praktiko honetan `uuid` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 19.3.4. 4. adibidea: FNV-1a, DJB2, Adler-32, CRC32 IEEE 802.3 (`0xCBF43926`) egiaztapen-baturak eta SplitMix64 PRNG determinista

Adibide praktiko honetan `uuid` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 19.3.5. 5. adibidea: Trazabilitate banatua denboraz ordenagarriak diren UUIDv7 bidez eta paketeen osotasuna CRC32 eta FNV-1a erabiliz (`uuid v7`, `uuid v7 timestamp ms`, `crc32 hex`)

Adibide praktiko honetan `uuid` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

## 19.4. Kaputaren azpian: nola dagoen eraikia `uuid` Ridgun hutsean (`src/main/ridgun/lib/uuid.rg`)

`ridgun-libs`-en abantaila handienetako bat **C-ko kutxa beltzik ez egotea** da. `src/main/ridgun/lib/uuid.rg` ireki dezakezu eta eragiketa bakoitza *pattern matching*, `|` / `|.` guarda-zuhaitzak eta isats-errekurtsioa (TCO) erabiliz nola inplementatuta dagoen irakurri. Ikus ditzagun bere benetako inplementazioaren funtsezko piezak:

### 19.4.1. Barne-inplementazioa: RFC 9562 UUIDv4 & UUIDv7 Generation & Validation (CSPRNG + clock_gettime)

Ikusi nola `uuid.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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

## 19.5. Berme algoritmikoak, `RMM1`/`RMM2` memoria eta `uuid`-en Urrezko 5 Arauak

- **Berme algoritmikoa eta segurtasunekoa**: `uuid v7 at t1 < uuid v7 at t2`-k denborarekin hazten den ordena lexikografiko monotonoa bermatzen du, `btree` indizeetarako eta datu-baseetarako aproposa.
- **$O(1)$ pila-konplexutasuna TCOrekin**: `src/main/ridgun/lib/uuid.rg`-eko begizta errekurtsibo guztiak isats-posizioan daude; beraz, `ridgunc`-ek pila-hazkuntzarik gabeko jauzi natiboetara konpilatzen ditu.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test uuid.rg` suite automatizatuaren bidez.

### `uuid`-ekin programatzeko Urrezko 5 Arauak

1. **Deklaratu `import uuid` fitxategiaren hasieran** eta baliatu zuriuneen eta azpimarren arteko baliokidetasuna zure kodea prosa bezala irakur dadin.
2. **Lerrokatu zure datu-hodiak `=` ikurrarekin**: kateatu `uuid`-erako deiak izen propioko urratsetan eta utzi `stable format`-i zutabeak lerrokatzen.
3. **Baliatu `uuid`-eko funtzio osoak zure `|` guardetan**: egiaztatu itzulera-balioak edo askatu ADTak *pattern matching* bidez, kanpoko sarrera beti baliozkoa dela suposatu beharrean.
4. **Saihestu egitura handiak kopiatzea eremu bat kontsultatu besterik behar ez baduzu**: gogoratu `RMM2`-n sarrerako argumentuek ez dituztela kontagailuak handitzen edo txikitzen (`+0` / `-0`).
5. **Konbinatu `uuid` eta `test` (`import test`)**: idatzi beti asertzioak `assert equals` edo `assert true` erabiliz zure domeinuaren inbarianteak finkatzeko.

---

**20. kapituluan** **`log`** lib-a sakonki esploratuko dugu (`log` lib-a — NDJSON Erregistro Egituratua eta Sekretuen Ezkutatze Automatikoa).
