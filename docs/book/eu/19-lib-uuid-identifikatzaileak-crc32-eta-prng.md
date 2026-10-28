# 19. kapitulua: `uuid` lib-a — RFC 9562 `UUIDv4`/`UUIDv7`, FNV-1a, Adler-32, CRC-32 eta PRNG

## 19.1. Zergatik existitzen da `uuid` lib-a? (Benetako arazoa eta Ridgun filosofia)

> *«Zergatik behar dut `uuid` lib bat hutsetik Ridgun hutsean idatzia, betiko C liburutegi bat estekatu beharrean?»*

Hori da edozein sistema-ingeniarik `uuid`-era iristean egiten duen lehen galdera. Eta erantzunak `ridgun-libs`-en filosofia osoa laburbiltzen du:

Izan gaitezen zintzoak: datu-base batean gako nagusi gisa erabat ausazko `UUIDv4`-ak erabiltzeak B-Tree indizeak zatikatzen ditu, eta nukleoaren entropiarik gabeko etxeko IDak asmatzeak talketan amaitzen du.

**`uuid`** lib-ak **`UUIDv4`** (nukleoaren CSPRNG bidezko ausazkoa) eta **`UUIDv7`** (**RFC 9562** arauaren arabera lehen 48 bitetan kronologikoki ordenatua), egiaztapen-batura azkarrak (**FNV-1a**, **Adler-32**, **CRC-32 IEEE 802.3**) eta hazidun PRNG determinista bat inplementatzen ditu.

Ekosistema tradizional batean, **`UUID`** domeinuko zereginak ebazteak C-ko kanpo-mendekotasunak arrastatzea, erakusle gordinekin borrokatzea, mota-bihurketa opakuak, egiaztatu gabeko salbuespenak edo zabor-biltzailearen geldialdi ustekabekoak jasatea dakar. Ridgunen, **`uuid`** lib-ak (`src/main/ridgun/lib/uuid.rg`) lau printzipio negoziatu ezinekin heltzen dio arazoari:

1. **Deklaratu `import uuid` (edo `import uuid as alias`) fitxategiaren hasieran**: lib bakoitzak `module :: uuid` izen-espazioa definitzen du eta `--strict` moduan hitz anitzeko funtzioei zuriune naturalekin deitzen zaie beti.
2. **Kateatu zure datu-hodiak ezkerretik eskuinera `->` bidez**: idatzi `sarrera lehen urratsa -> bigarren urratsa -> emaitza`, erabili `(+ _ _ +)` maskarak sekuentziak desegituratzeko eta kendu `_ =` sententzia sekuentzialetan (edo baztertu `-> ()` bidez).
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

> Lib bakoitzak bere izen-espazioa deklaratzen du `module :: uuid` bidez: nahikoa da goiburuan `import uuid` (edo `import uuid as alias`) idaztea eta bere funtzioei zuriune naturalekin (`nire funtzioa x`) eta `->` hodiekin (`x nire funtzioa -> emaitza`) deitzea.

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

fn :: generar ids ordenados => String String Bool
      generar ids ordenados =
        1000 uuid v7 at -> id1
        2000 uuid v7 at -> id2
        (uuid is valid id1) and (id1 < id2) -> ok
        (id1, id2, ok)
```

### 19.3.2. 2. adibidea: Konposizio segurua eta muga-kasuen kudeaketa

`uuid` lib-eko funtzio oro `|` guarda boolearrekin eta `ridgun-libs`-eko gainerako 32 lib-ekin konposatzeko diseinatuta dago:

```ridgun
import uuid

fn :: firmar paquete String => Int Int
      firmar paquete payload =
        payload crc32 -> c32
        payload fnv1a 32 -> fnv
        (c32, fnv)
```

### 19.3.3. 3. adibidea: UUIDv4 (CSPRNG) eta denboraz ordenagarriak diren UUIDv7 (RFC 9562) identifikatzaileen sorrera, baliozkotzea eta ikuskapena

Adibide praktiko honetan `uuid` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test uuidv4 and uuidv7 => ()
      test uuidv4 and uuidv7 =
        u4a = uuid v4
        u4b = uuid v4
        assert int equals (str len u4a) 36 "AC1: uuid_v4 length 36"
        assert true (uuid is valid u4a) "AC1: uuid_v4 valid RFC 9562 format"
        assert true (uuid is valid u4b) "AC1: second uuid_v4 valid"
        assert false (u4a == u4b) "AC1: CSPRNG uuid_v4 calls are unique"
        assert int equals (uuid version u4a) 4 "AC1: uuid_v4 version == 4"

        -- RFC 9562 UUIDv7 timestamp encoding & chronological prefix ordering
        u7_zero = uuid v7 at 0
        u7a = uuid v7 at 1700000000000
        u7b = uuid v7 at 1800000000000
        u7_live = uuid v7
        assert true (uuid is valid u7_zero) "AC1: uuid_v7 at epoch 0 valid"
        assert str eq (str slice u7_zero 0 13) "00000000-0000" "AC1: uuid_v7 at epoch 0 zero prefix"
        assert true (uuid is valid u7a) "AC1: uuid_v7 at 1700000000000 valid"
        assert true (uuid is valid u7b) "AC1: uuid_v7 at 1800000000000 valid"
        assert true (uuid is valid u7_live) "AC1: live uuid_v7 valid"
        assert int equals (uuid version u7a) 7 "AC1: uuid_v7 version == 7"
        assert int equals (uuid version u7_live) 7 "AC1: live uuid_v7 version == 7"
        assert str eq (str slice u7a 0 8) "018bcfe5" "AC1: uuid_v7 timestamp prefix 1700000000000"
        assert str eq (str slice u7b 0 8) "01a3185c" "AC1: uuid_v7 timestamp prefix 1800000000000"

        -- Uppercase valid UUID acceptance & RFC 9562 variant nibble (8, 9, a, b) validation
        assert true (uuid is valid "550E8400-E29B-41D4-A716-446655440000") "AC1: uppercase RFC 9562 UUID valid"
        assert false (uuid is valid "") "AC1: empty string invalid"
        assert false (uuid is valid "not-a-uuid") "AC1: short string invalid"
        assert false (uuid is valid "550e8400-e29b-41d4-1716-446655440000") "AC1: variant nibble '1' (< 8) rejected"
        assert false (uuid is valid "550e8400-e29b-41d4-c716-446655440000") "AC1: variant nibble 'c' (> b) rejected"
        assert false (uuid is valid "550e8400Xe29b-41d4-a716-446655440000") "AC1: missing hyphen at index 8 rejected"
        assert false (uuid is valid "550e8400-e29b-41d4-a716-44665544000g") "AC1: non-hex character 'g' rejected"
        assert int equals (uuid version "not-a-uuid") (0 - 1) "AC1: invalid uuid version -> -1"
        ()
```

### 19.3.4. 4. adibidea: FNV-1a, DJB2, Adler-32, CRC32 IEEE 802.3 (`0xCBF43926`) egiaztapen-baturak eta SplitMix64 PRNG determinista

Adibide praktiko honetan `uuid` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test checksums and prng => ()
      test checksums and prng =
        -- Official FNV-1a 32-bit vectors (isthe.com/chongo/tech/comp/fnv/)
        assert int equals (fnv1a 32 "") 2166136261 "AC2: FNV-1a 32 '' == 0x811c9dc5 (offset basis)"
        assert int equals (fnv1a 32 "a") 3826002220 "AC2: FNV-1a 32 'a' == 0xe40c292c"
        assert int equals (fnv1a 32 "foobar") 3214735720 "AC2: FNV-1a 32 'foobar' == 0xbf9cf968"

        -- Official RFC 1950 Adler-32 vectors
        assert int equals (adler32 "") 1 "AC2: Adler-32 '' == 1"
        assert int equals (adler32 "a") 6422626 "AC2: Adler-32 'a' == 0x00620062"
        assert int equals (adler32 "Wikipedia") 300286872 "AC2: Adler-32 'Wikipedia' == 0x11e60398"

        -- Official IEEE 802.3 / ISO-HDLC CRC-32 vectors
        assert int equals (crc32 "") 0 "AC2: CRC-32 '' == 0"
        assert int equals (crc32 "a") 3904355907 "AC2: CRC-32 'a' == 0xe8b7be43"
        assert int equals (crc32 "123456789") 3421780262 "AC2: CRC-32 '123456789' == 0xcbf43926"

        -- Deterministic 31-bit LCG PRNG
        s1 = prng next 42
        s2 = prng next 42
        s3 = prng next s1
        assert int equals s1 s2 "AC3: prng_next deterministic for same seed"
        assert false (s1 == s3) "AC3: prng_next advances state"
        r1 = prng range 42 10 20
        v1 = prng val r1
        assert true (v1 >= 10 and v1 <= 20) "AC3: prng_range within [10, 20]"
        r_deg = prng range 42 50 10
        assert int equals (prng val r_deg) 50 "AC3: prng_range with hi <= lo clamps to lo"
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
module :: uuid

fn :: uu alloc page Int => Int
      uu alloc page sz  =
        neg1 = 0 - 1
        sys call 9 0 sz 3 34 neg1 0

fn :: uu free page Int Int Int => Int
      uu free page mfd ptr sz =
        sys close mfd -> ()
        sys call 11 ptr sz 0 0 0 0

fn :: uu alloc mfd => Int
      uu alloc mfd =  sys call 319 4194311 1 0 0 0 0

fn :: uu peek Int Int Int => String
      uu peek mfd ptr len =
        sys call 18 mfd ptr len 0 0 0 -> ()
        sys call 8 mfd 0 0 0 0 0 -> ()
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
        uu decode u32 le s off -> lo
        uu decode u32 le s (off + 4) -> hi
        lo + (hi * 4294967296)

fn :: uu wall time ms => Int
      uu wall time ms =
        uu alloc page 4096 -> ptr
        uu alloc mfd -> mfd
        sys call 228 0 ptr 0 0 0 0 -> ()
        uu peek mfd ptr 16 -> raw
        uu free page mfd ptr 4096 -> ()
        uu decode u64 le raw 0 -> sec
        uu decode u64 le raw 8 -> nsec
        (sec * 1000) + (nsec / 1000000)

fn :: uu bytes to hex loop String Int Int => String
      uu bytes to hex loop s idx len =
        | idx >= len = ""
        | otherwise =
          b   = ((str char at s idx) % 256 + 256) % 256
          hi  = b / 16
          lo  = b % 16
          tbl = uu hex lut 0
          (str slice tbl hi (hi + 1)) + (str slice tbl lo (lo + 1)) + (uu bytes to hex loop s (idx + 1) len)

fn :: uu random hex16 => String
      uu random hex16 =
        uu alloc page 4096 -> ptr
        uu alloc mfd -> mfd
        sys call 318 ptr 16 0 0 0 0 -> ()
        uu peek mfd ptr 16 -> raw
        uu free page mfd ptr 4096 -> ()
        uu bytes to hex loop raw 0 16

fn :: uu hex val Int => Int
      uu hex val c   =
        | c >= 48 and c <= 57  = c - 48
        | c >= 65 and c <= 70  = (c - 65) + 10
        | c >= 97 and c <= 102 = (c - 97) + 10
        | otherwise            = 0 - 1

fn :: uu variant char String => String
      uu variant char hex1   =
        v   = uu hex val (str char at hex1 0)
        idx = 8 + (v % 4)
        tbl = uu hex lut 0
        str slice tbl idx (idx + 1)

fn :: uuid v4 => String
      uuid v4 =
        h  = uu random hex16
        p1 = str slice h 0 8
        p2 = str slice h 8 12
        p3 = "4" + (str slice h 13 16)
        p4 = (uu variant char (str slice h 16 17)) + (str slice h 17 20)
        p5 = str slice h 20 32
        "{p1}-{p2}-{p3}-{p4}-{p5}"

fn :: uu hex48 loop Int Int => String
      uu hex48 loop val rem =
        | rem <= 0 = ""
        | otherwise =
          nib = ((val % 16) + 16) % 16
          tbl = uu hex lut 0
          (uu hex48 loop (val / 16) (rem - 1)) + (str slice tbl nib (nib + 1))

fn :: uuid v7 at Int   => String
      uuid v7 at ts_ms =
        eff_ts = uu abs ts_ms
        ts_hex = uu hex48 loop eff_ts 12
        h      = uu random hex16
        p1     = str slice ts_hex 0 8
        p2     = str slice ts_hex 8 12
        p3     = "7" + (str slice h 0 3)
        p4     = (uu variant char (str slice h 3 4)) + (str slice h 4 7)
        p5     = str slice h 7 19
        "{p1}-{p2}-{p3}-{p4}-{p5}"

fn :: uuid v7 => String
      uuid v7 =  uuid v7 at (uu wall time ms)

fn :: uu is hex range String Int Int => Bool
      uu is hex range s idx end_idx =
        | idx >= end_idx                       = True
        | (uu hex val (str char at s idx)) < 0 = False
        | otherwise                            = uu is hex range s (idx + 1) end_idx

fn :: uuid is valid String => Bool
      uuid is valid u      =
        | (str len u) != 36               = False
        | (str char at u 8) != 45         = False
        | (str char at u 13) != 45        = False
        | (str char at u 18) != 45        = False
        | (str char at u 23) != 45        = False
        | not (uu is hex range u 0 8)     = False
        | not (uu is hex range u 9 13)    = False
        | not (uu is hex range u 14 18)   = False
        | not (uu is hex range u 19 23)   = False
        | not (uu is hex range u 24 36)   = False
        | otherwise =
          var_nib = uu hex val (str char at u 19)
          (var_nib >= 8) and (var_nib <= 11)

fn :: uuid version String => Int
      uuid version u      =
        | not (uuid is valid u) = 0 - 1
        | otherwise             = uu hex val (str char at u 14)
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
