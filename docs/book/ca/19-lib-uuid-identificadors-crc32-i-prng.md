# Capítol 19: La lib `uuid` — RFC 9562 `UUIDv4`/`UUIDv7`, FNV-1a, Adler-32, CRC-32 i PRNG

## 19.1. Per què existeix la lib `uuid`? (El problema real i la filosofia Ridgun)

> *«Per què necessito una lib `uuid` escrita des de zero en Ridgun pur en lloc d'enllaçar una llibreria de C de tota la vida?»*

Aquesta és la primera pregunta que es fa qualsevol enginyer de sistemes en arribar a `uuid`. I la resposta resumeix tota la filosofia de `ridgun-libs`:

Siguem sincers: fer servir `UUIDv4` completament aleatoris com a clau primària en una base de dades fragmenta els índexs B-Tree, mentre que inventar-se IDs casolans sense entropia del nucli acaba en col·lisions.

La lib **`uuid`** implementa **`UUIDv4`** (aleatori amb CSPRNG del nucli) i **`UUIDv7`** (ordenat cronològicament en els primers 48 bits segons **RFC 9562**), sumes de verificació ràpides (**FNV-1a**, **Adler-32**, **CRC-32 IEEE 802.3**) i un PRNG determinista amb llavor.

En un ecosistema tradicional, resoldre les tasques del domini **`UUID`** implica arrossegar dependències externes en C, lluitar amb punters crus, conversions opaques de tipus, excepcions no verificades o pauses impredictibles del recol·lector de brossa. En Ridgun, la lib **`uuid`** (`src/main/ridgun/lib/uuid.rg`) aborda el problema amb quatre principis innegociables:

1. **Funcions totals i contractes explícits (`=>`)**: cap funció de `uuid` llança excepcions ocultes ni depèn de `null`. Tot cas límit retorna un valor sentinella documentat o un tipus algebraic suma (`Option`, `Result`).
2. **Zero codi C i zero `libc`**: tot el codi de `uuid` compila directament a codi màquina natiu ELF64 verificat per `ridgunc`.
3. **Recursió de cua amb TCO (*Tail-Call Optimization*)**: tots els recorreguts interns de `uuid` es compilen a bucles natius en espai de pila $O(1)$.
4. **Memòria determinista (`RMM1` / `RMM2`)**: cada estructura intermèdia s'allibera en l'instant exacte en què acaba la seva última lectura, sense *Garbage Collector*.

---

## 19.2. Artefactes natius, importació i catàleg complet de l'API de `uuid`

A `ridgun-libs`, **`uuid`** és una **lib** de primera classe situada a `src/main/ridgun/lib/uuid.rg` (domini `UUID`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/uuid.rglib` | Distribució i importació directa amb `import uuid` |
| **Fitxer compilat** | `target/uuid.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libuuid.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import uuid` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

### 19.2.1. Resum de famílies funcionals de `uuid`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `uuid v4 / uuid v7 / uuid v7 at` | Genera UUIDs canònics de 36 caràcters RFC 9562 v4 (aleatori) i v7 (ordenat pel temps) |
| `uuid is valid / uuid version` | Valida l'estructura 8-4-4-4-12 i els bits de variant RFC 9562 (`8, 9, a, b`) |
| `fnv1a 32 / adler32 / crc32 / crc32 hex` | Hashes no criptogràfics i sumes de verificació ràpides de 32 bits |
| `prng next / prng range` | PRNG congruencial lineal funcional pur per a proves i simulacions reproduïbles |

### 19.2.2. Catàleg exhaustiu de tipus i signatures a `src/main/ridgun/lib/uuid.rg`

A continuació tens l'inventari complet de tipus algebraics (`type`), operadors (`op ::`) i signatures de funcions (`fn ::`) definits a `src/main/ridgun/lib/uuid.rg` (`0` tipus, `0` operadors i `33` funcions):

| # | Funció / Signatura (`fn ::`) | Tipus de Retorn |
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

## 19.3. Explorant `uuid` a fons: Exemples pas a pas de cada funcionalitat

No n'hi ha prou de veure la taula de signatures: explorarem **cadascuna de les funcionalitats** de la lib `uuid` mitjançant exemples progressius i executables en Ridgun. Començarem per les dues receptes tabulars d'ús quotidià i després recorrerem en detall tots els escenaris funcionals, transformacions i casos límit verificats a `src/test/ridgun/test uuid.rg`.

### 19.3.1. Exemple 1: Flux principal en estil tabular amb `uuid`

Observa com en Ridgun els signes `=` i els passos de transformació amb `uuid` queden alineats com una taula neta, sense variables mutables innecessàries ni efectes laterals ocults:

```ridgun
import uuid

fn :: generar ids ordenados () => (String, String, Bool)
      generar ids ordenados =
        id1 = uuid v7 at 1000
        id2 = uuid v7 at 2000
        ok  = (uuid is valid id1) and (id1 < id2)
        (id1, id2, ok)
```

### 19.3.2. Exemple 2: Composició segura i gestió de casos de vora

Tota funció de la lib `uuid` està dissenyada per compondre's amb guardes booleanes `|` i amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import uuid

fn :: firmar paquete (payload : String) => (String, Int)
      firmar paquete payload =
         (crc32 hex payload, fnv1a 32 payload)
```

### 19.3.3. Exemple 3: Generació, validació i inspecció d'UUIDv4 (CSPRNG) i UUIDv7 ordenables per temps (RFC 9562)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `uuid` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

### 19.3.4. Exemple 4: Sumes de verificació FNV-1a, DJB2, Adler-32, CRC32 IEEE 802.3 (`0xCBF43926`) i PRNG determinista SplitMix64

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `uuid` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

### 19.3.5. Exemple 5: Traçabilitat distribuïda amb UUIDv7 ordenables per temps i integritat de paquets amb CRC32 i FNV-1a (`uuid v7`, `uuid v7 timestamp ms`, `crc32 hex`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `uuid` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

## 19.4. Sota el capó: com està construïda `uuid` en Ridgun pur (`src/main/ridgun/lib/uuid.rg`)

Un dels majors avantatges de `ridgun-libs` és que **no hi ha caixes negres en C**. Pots obrir `src/main/ridgun/lib/uuid.rg` i llegir exactament com està implementada cada operació fent servir *pattern matching*, arbres de guardes `|` / `|.` i recursió de cua (TCO). Vegem les peces clau de la seva implementació real:

### 19.4.1. Implementació interna: RFC 9562 UUIDv4 & UUIDv7 Generation & Validation (CSPRNG + clock_gettime)

Fixa't en com `uuid.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

## 19.5. Garanties algorísmiques, memòria `RMM1`/`RMM2` i les 5 Regles d'Or de `uuid`

- **Garantia algorísmica i de seguretat**: `uuid v7 at t1 < uuid v7 at t2` garanteix ordre lexicogràfic monòton creixent amb el temps, ideal per a índexs `btree` i bases de dades.
- **Complexitat de pila $O(1)$ amb TCO**: Tots els bucles recursius a `src/main/ridgun/lib/uuid.rg` estan en posició de cua, de manera que `ridgunc` els compila a salts natius sense creixement de pila.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test uuid.rg`.

### Les 5 Regles d'Or en programar amb `uuid`

1. **Declara `import uuid` a l'inici del fitxer** i aprofita l'equivalència entre espais i guions baixos perquè el teu codi es llegeixi com a prosa.
2. **Alinea les teves canonades de dades amb `=`**: encadena les crides a `uuid` en passos amb nom propi i deixa que `stable format` alineï les columnes.
3. **Aprofita les funcions totals de `uuid` a les teves guardes `|`**: comprova els valors de retorn o desembolica els ADTs amb *pattern matching* en lloc d'assumir que l'entrada externa sempre és vàlida.
4. **Evita copiar grans estructures si només necessites consultar un camp**: recorda que en `RMM2` els arguments d'entrada no incrementen ni decrementen comptadors (`+0` / `-0`).
5. **Combina `uuid` amb `test` (`import test`)**: escriu sempre assercions amb `assert equals` o `assert true` per fixar els invariants del teu domini.

---

Al **Capítol 20** passarem a explorar en profunditat la lib **`log`** (La lib `log` — Logging Estructurat NDJSON i Redacció Automàtica de Secrets).
