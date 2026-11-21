# 35. kapitulua: `hash` lib-a — SipHash-1-3 Gakodun Hashinga Hash-taulentzat

## 35.1. Zergatik existitzen da `hash` lib-a? (Benetako arazoa eta Ridgun filosofia)

> *«Zergatik behar dut `hash` lib bat hutsetik Ridgun hutsean idatzia, betiko C liburutegi bat estekatu beharrean?»*

Hori da edozein sistema-ingeniarik `hash`-era iristean egiten duen lehen galdera. Eta erantzunak `ridgun-libs`-en filosofia osoa laburbiltzen du:

Izan gaitezen zintzoak: hash-taula baten hash funtzioa publikoa denean, gakoak kontrolatzen dituenak gelaxka berean erortzen diren milaka gako bidal ditzake, eta orduan eskaera bakar batek milioi batek kostatu beharko lukeena kostatzen du (hash flooding).

**`hash`** lib-ak **SipHash-1-3** (Aumasson & Bernstein) inplementatzen du, 128 biteko gakoarekin eta 64 biteko emaitzarekin. `siphash13`-k kate oso baten hasha kalkulatzen du; konpilatzailearen `siphash13 range` eta `siphash13 range low` eragiketa natiboek (ridgunc 1.0.44) byte-tarte baten hasha hamarnaka nanosegundotan kalkulatzen dute; `siphash13 reference` hash bera da Ridgun hutsean idatzita, irakurtzeko eta haren aurka probatzeko; eta `siphash new key`-k 16 byteko ausazko gako bat ateratzen du sistematik.

Ekosistema tradizional batean, **`HASH`** domeinuko zereginak ebazteak C-ko kanpo-mendekotasunak arrastatzea, erakusle gordinekin borrokatzea, mota-bihurketa opakuak, egiaztatu gabeko salbuespenak edo zabor-biltzailearen geldialdi ustekabekoak jasatea dakar. Ridgunen, **`hash`** lib-ak (`src/main/ridgun/lib/hash.ridgun`) lau printzipio negoziatu ezinekin heltzen dio arazoari:

1. **Deklaratu `import hash` (edo `import hash as alias`) fitxategiaren hasieran**: lib bakoitzak `module :: hash` izen-espazioa definitzen du eta `--strict` moduan hitz anitzeko funtzioei zuriune naturalekin deitzen zaie beti.
2. **Kateatu zure datu-hodiak ezkerretik eskuinera `->` bidez**: idatzi `sarrera lehen urratsa -> bigarren urratsa -> emaitza`, erabili `(+ _ _ +)` maskarak sekuentziak desegituratzeko eta kendu `_ =` sententzia sekuentzialetan (edo baztertu `-> ()` bidez).
3. **Isats-errekurtsioa TCOrekin (*Tail-Call Optimization*)**: `hash`-eko barne-ibilbide guztiak $O(1)$ pila-espazioko begizta natiboetara konpilatzen dira.
4. **Memoria determinista (`RMM1` / `RMM2`)**: tarteko egitura bakoitza bere azken irakurketa amaitzen den une zehatzean askatzen da, *Garbage Collector* gabe.

---

## 35.2. Artefaktu natiboak, inportazioa eta `hash` APIaren katalogo osoa

`ridgun-libs`-en, **`hash`** lehen mailako **lib** bat da, `src/main/ridgun/lib/hash.ridgun` bidean kokatua (`HASH` domeinua). `stable bundle`-ekin konpilatzean, formatu natibo bakarrean paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/hash.ridgunlib` | Banaketa eta inportazio zuzena `import hash` bidez |

> Lib bakoitzak bere izen-espazioa deklaratzen du `module :: hash` bidez: nahikoa da goiburuan `import hash` (edo `import hash as alias`) idaztea eta bere funtzioei zuriune naturalekin (`nire funtzioa x`) eta `->` hodiekin (`x nire funtzioa -> emaitza`) deitzea.

### 35.2.1. `hash`-eko familia funtzionalen laburpena

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `siphash13` | Kate oso baten SipHash-1-3, 16 byteko gako batekin, 64 biteko `Int` gisa |
| `siphash13 range / siphash13 range low` | Konpilatzailearen eragiketa natiboak: byte-tarte baten hasharen 64 bitak, edo beheko 32 bitak |
| `siphash13 reference` | Hash bera Ridgun hutsean, 32 biteko erdien gainean: eragiketa natiboa probatzeko erabiltzen den definizioa |
| `siphash new key` | 16 byteko ausazko gako bat sistemaren ausazkotasun-iturritik (`""` irakurri ezin denean) |

### 35.2.2. `src/main/ridgun/lib/hash.ridgun`-eko mota eta sinadura guztien katalogoa

Jarraian duzu `src/main/ridgun/lib/hash.ridgun` fitxategian definitutako mota aljebraiko (`type`), eragile (`op ::`) eta funtzio-sinadura (`fn ::`) guztien inbentario osoa (`0` mota, `0` eragile eta `11` funtzio):

| # | Funtzioa / Sinadura (`fn ::`) | Itzulera-mota |
|---|---|---|
| `1` | `fn :: hs byte String Int` | `Int` |
| `2` | `fn :: hs tail String Int Int` | `Int` |
| `3` | `fn :: hs pick Int Int Int` | `Int` |
| `4` | `fn :: hs key word String Int` | `Int` |
| `5` | `fn :: siphash13 loop String Int Int Int Int Int Int Int Int Int Int Int Int Int` | `Int` |
| `6` | `fn :: siphash13 last String Int Int Int Int Int Int Int Int Int Int Int Int` | `Int` |
| `7` | `fn :: siphash13 start String String Int Int Int` | `Int` |
| `8` | `fn :: siphash13 String String` | `Int` |
| `9` | `fn :: siphash13 reference String String Int Int Int` | `Int` |
| `10` | `fn :: siphash new key` | `String` |
| `11` | `fn :: hs key of (Int String)` | `String` |

---

## 35.3. `hash` sakonki esploratzen: Funtzionalitate bakoitzaren urratsez urratseko adibideak

Ez da nahikoa sinadura-taula ikustea: `hash` lib-aren **funtzionalitate bakoitza** Ridgunen exekutagarriak diren adibide progresiboen bidez esploratuko dugu. Eguneroko bi errezeta taularatuekin hasiko gara eta ondoren xehetasunez ikusiko ditugu `src/test/ridgun/test hash.ridgun`-en egiaztatutako agertoki funtzional eta muga-kasu guztiak.

### 35.3.1. 1. adibidea: Fluxu nagusia estilo taularatuan `hash` erabiliz

Ikusi nola Ridgunen `=` ikurrak eta `hash` bidezko eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren, beharrezkoak ez diren aldagai aldakorrik edo ezkutuko albo-ondoriorik gabe:

```ridgun
import hash

fn :: cubo de clave String String Int => Int
      cubo de clave semilla clave cubos =
        siphash13 range low semilla clave 0 (str len clave) -> h
        h % cubos
```

### 35.3.2. 2. adibidea: Konposizio segurua eta muga-kasuen kudeaketa

`hash` lib-eko funtzio oro `|` guarda boolearrekin eta `ridgun-libs`-eko gainerako 38 lib-ekin konposatzeko diseinatuta dago:

```ridgun
import hash

fn :: huella segura String String => Int
      huella segura semilla dato =
        | (str len semilla) != 16 = 0
        | otherwise               = siphash13 semilla dato
```

### 35.3.3. 3. adibidea: SipHash-1-3 bektoreak 0tik 64 bytera bitarteko sarreretarako: beheko eta goiko 32 biteko erdiak

Adibide praktiko honetan `hash` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test siphash13 vectors => ()
      test siphash13 vectors =
        key = tensor to str (seq bytes (Tensor[U8 * 16]) 0 16)
        msg = tensor to str (seq bytes (Tensor[U8 * 64]) 0 64)
        siphash13 range low key msg 0 0 -> assert int equals 84919516 "low 32 bits, 0 bytes"
        (siphash13 range key msg 0 0) shr 32 -> assert int equals 2880176472 "high 32 bits, 0 bytes"
        siphash13 range low key msg 0 1 -> assert int equals 2102905491 "low 32 bits, 1 bytes"
        (siphash13 range key msg 0 1) shr 32 -> assert int equals 3388251123 "high 32 bits, 1 bytes"
        siphash13 range low key msg 0 7 -> assert int equals 2612072768 "low 32 bits, 7 bytes"
        (siphash13 range key msg 0 7) shr 32 -> assert int equals 3549592984 "high 32 bits, 7 bytes"
        siphash13 range low key msg 0 8 -> assert int equals 2368313998 "low 32 bits, 8 bytes"
        (siphash13 range key msg 0 8) shr 32 -> assert int equals 915445009 "high 32 bits, 8 bytes"
        siphash13 range low key msg 0 9 -> assert int equals 1812348388 "low 32 bits, 9 bytes"
        (siphash13 range key msg 0 9) shr 32 -> assert int equals 631541427 "high 32 bits, 9 bytes"
        siphash13 range low key msg 0 15 -> assert int equals 709990742 "low 32 bits, 15 bytes"
        (siphash13 range key msg 0 15) shr 32 -> assert int equals 3542145133 "high 32 bits, 15 bytes"
        siphash13 range low key msg 0 16 -> assert int equals 2106624870 "low 32 bits, 16 bytes"
        (siphash13 range key msg 0 16) shr 32 -> assert int equals 3427786010 "high 32 bits, 16 bytes"
        siphash13 range low key msg 0 17 -> assert int equals 1675352076 "low 32 bits, 17 bytes"
        (siphash13 range key msg 0 17) shr 32 -> assert int equals 2633132176 "high 32 bits, 17 bytes"
        siphash13 range low key msg 0 25 -> assert int equals 1885014393 "low 32 bits, 25 bytes"
        (siphash13 range key msg 0 25) shr 32 -> assert int equals 1171085608 "high 32 bits, 25 bytes"
        siphash13 range low key msg 0 63 -> assert int equals 3082531752 "low 32 bits, 63 bytes"
        (siphash13 range key msg 0 63) shr 32 -> assert int equals 2635698274 "high 32 bits, 63 bytes"
        siphash13 range low key msg 0 64 -> assert int equals 1263165541 "low 32 bits, 64 bytes"
        (siphash13 range key msg 0 64) shr 32 -> assert int equals 4051277804 "high 32 bits, 64 bytes"
        (siphash13 range key msg 0 15) == (siphash13 key (str slice msg 0 15)) -> assert true "whole data equals the range"
        siphash13 range low key ("xx" + msg) 2 27 -> assert int equals 1885014393 "a range inside a longer string"
        siphash13 range low "0123456789abcdef" "abc" 0 3 -> assert int equals 1783201848 "printable key"
        siphash13 range "short" msg 0 8 -> assert int equals 0 "a key that is not 16 bytes gives 0"
        siphash13 range key msg 9 8 -> assert int equals 0 "a reversed range gives 0"
        siphash13 range key msg 0 65 -> assert int equals 0 "a range past the data gives 0"
        (siphash13 range low key msg 0 8) != (siphash13 range low "0123456789abcdef" msg 0 8) -> assert true "another key, another hash"
        k1 = siphash new key
        k2 = siphash new key
        str len k1 -> assert int equals 16 "a new key has 16 bytes"
        k1 != k2 -> assert true "two new keys differ"
```

### 35.3.4. 4. adibidea: Eragiketa natiboa Ridgun hutseko erreferentziaren aurka edozein desplazamendutan

Adibide praktiko honetan `hash` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test native matches reference => ()
      test native matches reference =
        key = "0123456789abcdef"
        msg = tensor to str (seq bytes (Tensor[U8 * 96]) 0 96)
        same as reference key msg 0 0 0 -> assert int equals 0 "native equals reference, offset 0"
        same as reference key msg 3 0 0 -> assert int equals 0 "native equals reference, offset 3"
        same as reference key msg 25 0 0 -> assert int equals 0 "native equals reference, offset 25"
```

---

## 35.4. Kaputaren azpian: nola dagoen eraikia `hash` Ridgun hutsean (`src/main/ridgun/lib/hash.ridgun`)

`ridgun-libs`-en abantaila handienetako bat **C-ko kutxa beltzik ez egotea** da. `src/main/ridgun/lib/hash.ridgun` ireki dezakezu eta eragiketa bakoitza *pattern matching*, `|` / `|.` guarda-zuhaitzak eta isats-errekurtsioa (TCO) erabiliz nola inplementatuta dagoen irakurri. Ikus ditzagun bere benetako inplementazioaren funtsezko piezak:

### 35.4.1. Barne-inplementazioa: SipRound on 32-Bit Halves: One Message Word per Turn

Ikusi nola `hash.ridgun`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
-- The byte at `i` as 0..255.
fn :: hs byte String Int => Int
      hs byte s i =  (str char at s i) and 255

-- The byte at `i`, or 0 at or after `to`.
fn :: hs tail String Int Int => Int
      hs tail s i to =
        | i >= to   = 0
        | otherwise = (str char at s i) and 255

fn :: hs pick Int Int Int => Int
      hs pick want hi lo =
        | want == 0 = lo
        | otherwise = (hi shl 32) or lo

-- Little-endian 32-bit word of the key at `off`.
fn :: hs key word String Int => Int
      hs key word k off =  (hs byte k off) or ((hs byte k (off + 1)) shl 8) or ((hs byte k (off + 2)) shl 16) or ((hs byte k (off + 3)) shl 24)

-- One message word per turn: v3 ^= m, 1 round(s), v0 ^= m. The 8 state values are the halves of v0..v3.
fn :: siphash13 loop String Int Int Int Int Int Int Int Int Int Int Int Int Int => Int
      siphash13 loop s off full to n want a0 b0 a1 b1 a2 b2 a3 b3 =
        | off >= full = siphash13 last s off to n want a0 b0 a1 b1 a2 b2 a3 b3
        | otherwise   =
          t1 = (hs byte s off) or ((hs byte s (off + 1)) shl 8) or ((hs byte s (off + 2)) shl 16) or ((hs byte s (off + 3)) shl 24)
          t2 = (hs byte s (off + 4)) or ((hs byte s (off + 5)) shl 8) or ((hs byte s (off + 6)) shl 16) or ((hs byte s (off + 7)) shl 24)
          t3 = a3 xor t2
          t4 = b3 xor t1
          t5 = b0 + b1
          t6 = ((a0 + a1) + (t5 shr 32)) and 0xFFFFFFFF
          t7 = t5 and 0xFFFFFFFF
          t8 = ((a1 shl 13) or (b1 shr 19)) and 0xFFFFFFFF
          t9 = ((b1 shl 13) or (a1 shr 19)) and 0xFFFFFFFF
          t10 = t8 xor t6
          t11 = t9 xor t7
          t12 = b2 + t4
          t13 = ((a2 + t3) + (t12 shr 32)) and 0xFFFFFFFF
          t14 = t12 and 0xFFFFFFFF
          t15 = ((t3 shl 16) or (t4 shr 16)) and 0xFFFFFFFF
          t16 = ((t4 shl 16) or (t3 shr 16)) and 0xFFFFFFFF
          t17 = t15 xor t13
          t18 = t16 xor t14
          t19 = t6 + t18
          t20 = ((t7 + t17) + (t19 shr 32)) and 0xFFFFFFFF
          t21 = t19 and 0xFFFFFFFF
          t22 = ((t17 shl 21) or (t18 shr 11)) and 0xFFFFFFFF
          t23 = ((t18 shl 21) or (t17 shr 11)) and 0xFFFFFFFF
          t24 = t22 xor t20
          t25 = t23 xor t21
          t26 = t14 + t11
          t27 = ((t13 + t10) + (t26 shr 32)) and 0xFFFFFFFF
          t28 = t26 and 0xFFFFFFFF
          t29 = ((t10 shl 17) or (t11 shr 15)) and 0xFFFFFFFF
          t30 = ((t11 shl 17) or (t10 shr 15)) and 0xFFFFFFFF
          t31 = t29 xor t27
          t32 = t30 xor t28
          t33 = t20 xor t2
          t34 = t21 xor t1
          siphash13 loop s (off + 8) full to n want t33 t34 t31 t32 t28 t27 t24 t25
```

### 35.4.2. Barne-inplementazioa: Public API: `siphash13`, the Plain-Ridgun Reference, and Random Keys

Ikusi nola `hash.ridgun`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
-- v0..v3 from the key (k0 = bytes 0-7, k1 = bytes 8-15, little-endian) and the constants "somepseudorandomlygeneratedbytes".
fn :: siphash13 start String String Int Int Int => Int
      siphash13 start key s from to want =
        k0l = hs key word key 0
        k0h = hs key word key 4
        k1l = hs key word key 8
        k1h = hs key word key 12
        n   = to - from
        siphash13 loop s from (from + ((n shr 3) shl 3)) to n want (k0h xor 0x736f6d65) (k0l xor 0x70736575) (k1h xor 0x646f7261) (k1l xor 0x6e646f6d) (k0h xor 0x6c796765) (k0l xor 0x6e657261) (k1h xor 0x74656462) (k1l xor 0x79746573)

-- `siphash13 range key data from to` (64 bits) and `siphash13 range low key data from to` (the low 32 bits)
-- are operations of the compiler since ridgunc 1.0.44: native, some tens of ns for a short key. They take
-- a 16-byte key and the bytes `from` (included) to `to` (excluded) of `data`; a key of another length or a
-- range outside `data` gives 0. This lib does not define them, so that the native ones are used.

-- SipHash-1-3 of the whole of `data`.
fn :: siphash13 String String => Int
      siphash13 key data =  siphash13 range key data 0 (str len data)

-- The same hash written in plain Ridgun (about 2 µs for a 25-byte key): the definition the native operation
-- is tested against, and the one to read. `want` 0 gives the low 32 bits, anything else the 64 bits.
fn :: siphash13 reference String String Int Int Int => Int
      siphash13 reference key data from to want =
        | (str len key) != 16 or from < 0 or to < from or to > (str len data) = 0
        | otherwise = siphash13 start key data from to want

-- A new random 16-byte key (from the system random source). "" when it cannot be read.
fn :: siphash new key => String
      siphash new key =  hs key of (sys random bytes 16)

fn :: hs key of (Int String) => String
      hs key of (rc, k) =
        | rc == 0 and (str len k) == 16 = k
        | otherwise                     = ""
```

---

## 35.5. Berme algoritmikoak, `RMM1`/`RMM2` memoria eta `hash`-en Urrezko 5 Arauak

- **Berme algoritmikoa eta segurtasunekoa**: Beste luzera bateko gako batek, edo datuetatik kanpoko tarte batek, `0` ematen du mugetatik kanpo irakurri beharrean, eta eragiketa natiboak Ridgun hutseko erreferentziaren 64 bit berak itzultzen ditu probatutako luzera eta desplazamendu guztietarako.
- **$O(1)$ pila-konplexutasuna TCOrekin**: `src/main/ridgun/lib/hash.ridgun`-eko begizta errekurtsibo guztiak isats-posizioan daude; beraz, `ridgunc`-ek pila-hazkuntzarik gabeko jauzi natiboetara konpilatzen ditu.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test hash.ridgun` suite automatizatuaren bidez.

### `hash`-ekin programatzeko Urrezko 5 Arauak

1. **Deklaratu `import hash` fitxategiaren hasieran** eta deitu bere funtzioei zuriuneekin, deklaratuta dauden bezala, zure kodea prosa bezala irakur dadin.
2. **Lerrokatu zure datu-hodiak `=` ikurrarekin**: kateatu `hash`-erako deiak izen propioko urratsetan eta utzi `stable format`-i zutabeak lerrokatzen.
3. **Baliatu `hash`-eko funtzio osoak zure `|` guardetan**: egiaztatu itzulera-balioak edo askatu ADTak *pattern matching* bidez, kanpoko sarrera beti baliozkoa dela suposatu beharrean.
4. **Saihestu egitura handiak kopiatzea eremu bat kontsultatu besterik behar ez baduzu**: gogoratu `RMM2`-n sarrerako argumentuek ez dituztela kontagailuak handitzen edo txikitzen (`+0` / `-0`).
5. **Konbinatu `hash` eta `test` (`import test`)**: idatzi beti asertzioak `assert equals` edo `assert true` erabiliz zure domeinuaren inbarianteak finkatzeko.

---

**36. kapituluan** **`hashmap`** lib-a sakonki esploratuko dugu (`hashmap` lib-a — `String` Gakoetatik Edozein Baliotarako Hash-mapa, Tentsoreen gainean eta SipHash bidez Hazitua).
