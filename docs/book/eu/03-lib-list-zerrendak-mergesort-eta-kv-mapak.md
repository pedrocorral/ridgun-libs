# 03. kapitulua: `list` lib-a — Zerrendak, $O(N \log N)$ Mergesort eta Gako-Balio Mapak

## 03.1. Zergatik existitzen da `list` lib-a? (Benetako arazoa eta Ridgun filosofia)

> *«Zergatik behar dut `list` lib bat hutsetik Ridgun hutsean idatzia, betiko C liburutegi bat estekatu beharrean?»*

Hori da edozein sistema-ingeniarik `list`-era iristean egiten duen lehen galdera. Eta erantzunak `ridgun-libs`-en filosofia osoa laburbiltzen du:

Izan gaitezen zintzoak: tartetik kanpoko indize batera sartzea (`IndexError` / `panic!`) edo partekatutako zerrenda bat ustekabean mutatzea bildumak prozesatzeko orduan gertatzen diren akats ohikoenetako bi dira.

**`list`** lib-ak lehenetsitako balio bidezko indexazioa, zatitzea (`take`, `drop`, `slice`), urrats bidezko tarteak, deduplikazio egonkorra, `[Int]` eta `[String]`-entzako **$O(N \log N)$ mergesort** ordenazioa eta `[String String]` hiztegi elkartu aldaezinak eskaintzen ditu.

Ekosistema tradizional batean, **`LIST`** domeinuko zereginak ebazteak C-ko kanpo-mendekotasunak arrastatzea, erakusle gordinekin borrokatzea, mota-bihurketa opakuak, egiaztatu gabeko salbuespenak edo zabor-biltzailearen geldialdi ustekabekoak jasatea dakar. Ridgunen, **`list`** lib-ak (`src/main/ridgun/lib/list.rg`) lau printzipio negoziatu ezinekin heltzen dio arazoari:

1. **Deklaratu `import list` (edo `import list as alias`) fitxategiaren hasieran**: lib bakoitzak `module :: list` izen-espazioa definitzen du eta `--strict` moduan hitz anitzeko funtzioei zuriune naturalekin deitzen zaie beti.
2. **Kateatu zure datu-hodiak ezkerretik eskuinera `->` bidez**: idatzi `sarrera lehen urratsa -> bigarren urratsa -> emaitza`, erabili `(+ _ _ +)` maskarak sekuentziak desegituratzeko eta kendu `_ =` sententzia sekuentzialetan (edo baztertu `-> ()` bidez).
3. **Isats-errekurtsioa TCOrekin (*Tail-Call Optimization*)**: `list`-eko barne-ibilbide guztiak $O(1)$ pila-espazioko begizta natiboetara konpilatzen dira.
4. **Memoria determinista (`RMM1` / `RMM2`)**: tarteko egitura bakoitza bere azken irakurketa amaitzen den une zehatzean askatzen da, *Garbage Collector* gabe.

---

## 03.2. Artefaktu natiboak, inportazioa eta `list` APIaren katalogo osoa

`ridgun-libs`-en, **`list`** lehen mailako **lib** bat da, `src/main/ridgun/lib/list.rg` bidean kokatua (`LIST` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/list.rglib` | Banaketa eta inportazio zuzena `import list` bidez |
| **Fitxategi konpilatua** | `target/list.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/liblist.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib bakoitzak bere izen-espazioa deklaratzen du `module :: list` bidez: nahikoa da goiburuan `import list` (edo `import list as alias`) idaztea eta bere funtzioei zuriune naturalekin (`nire funtzioa x`) eta `->` hodiekin (`x nire funtzioa -> emaitza`) deitzea.

### 03.2.1. `list`-eko familia funtzionalen laburpena

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `list nth or / list str nth or` | Indize bidezko irakurketa segurua, tartetik kanpo `default_val` itzuliz |
| `list take / list drop / list slice / list reverse` | Aurrizkia, atzizkia, `[start, end)` azpitartea eta buztan-errekurtsioko alderantzikatzea |
| `list range / list range step` | Sekuentzia aritmetikoak sortzen ditu (`step == 0`-k `[]` itzultzen du seguru) |
| `list sort / list str sort / list dedup / list str dedup` | $O(N \log N)$ mergesort ordenazio egonkorra eta lehen agerpeneko deduplikazioa |
| `kv empty / kv put / kv get / kv get or / kv remove / kv merge` | `[String String]` hiztegi elkartu ordenatuen gaineko eragiketak |

### 03.2.2. `src/main/ridgun/lib/list.rg`-eko mota eta sinadura guztien katalogoa

Jarraian duzu `src/main/ridgun/lib/list.rg` fitxategian definitutako mota aljebraiko (`type`), eragile (`op ::`) eta funtzio-sinadura (`fn ::`) guztien inbentario osoa (`0` mota, `0` eragile eta `59` funtzio):

| # | Funtzioa / Sinadura (`fn ::`) | Itzulera-mota |
|---|---|---|
| `1` | `fn :: list len [Int]` | `Int` |
| `2` | `fn :: list str len [String]` | `Int` |
| `3` | `fn :: list is empty [Int]` | `Bool` |
| `4` | `fn :: list str is empty [String]` | `Bool` |
| `5` | `fn :: list nth or [Int] Int Int` | `Int` |
| `6` | `fn :: list nth [Int] Int` | `Int` |
| `7` | `fn :: list str nth or [String] Int String` | `String` |
| `8` | `fn :: list str nth [String] Int` | `String` |
| `9` | `fn :: list head [Int] Int` | `Int` |
| `10` | `fn :: list last [Int] Int` | `Int` |
| `11` | `fn :: list take [Int] Int` | `[Int]` |
| `12` | `fn :: list str take [String] Int` | `[String]` |
| `13` | `fn :: list drop [Int] Int` | `[Int]` |
| `14` | `fn :: list str drop [String] Int` | `[String]` |
| `15` | `fn :: l clamp nonneg Int` | `Int` |
| `16` | `fn :: l slice ints from [Int] Int Int` | `[Int]` |
| `17` | `fn :: list slice [Int] Int Int` | `[Int]` |
| `18` | `fn :: l slice strs from [String] Int Int` | `[String]` |
| `19` | `fn :: list str slice [String] Int Int` | `[String]` |
| `20` | `fn :: l rev ints [Int] [Int]` | `[Int]` |
| `21` | `fn :: list reverse [Int]` | `[Int]` |
| `22` | `fn :: l rev strs [String] [String]` | `[String]` |
| `23` | `fn :: list str reverse [String]` | `[String]` |
| `24` | `fn :: list range step Int Int Int` | `[Int]` |
| `25` | `fn :: list range Int Int` | `[Int]` |
| `26` | `fn :: list replicate Int Int` | `[Int]` |
| `27` | `fn :: l idx int [Int] Int Int` | `Int` |
| `28` | `fn :: list index of [Int] Int` | `Int` |
| `29` | `fn :: list contains [Int] Int` | `Bool` |
| `30` | `fn :: l idx str [String] String Int` | `Int` |
| `31` | `fn :: list str index of [String] String` | `Int` |
| `32` | `fn :: list str contains [String] String` | `Bool` |
| `33` | `fn :: list count [Int] Int` | `Int` |
| `34` | `fn :: list str count [String] String` | `Int` |
| `35` | `fn :: l dedup ints [Int] [Int]` | `[Int]` |
| `36` | `fn :: list dedup [Int]` | `[Int]` |
| `37` | `fn :: l dedup strs [String] [String]` | `[String]` |
| `38` | `fn :: list str dedup [String]` | `[String]` |
| `39` | `fn :: l merge ints [Int] [Int]` | `[Int]` |
| `40` | `fn :: l sort ints len [Int] Int` | `[Int]` |
| `41` | `fn :: list sort [Int]` | `[Int]` |
| `42` | `fn :: list is sorted [Int]` | `Bool` |
| `43` | `fn :: l str le loop String String Int Int Int` | `Bool` |
| `44` | `fn :: l str le String String` | `Bool` |
| `45` | `fn :: l merge strs [String] [String]` | `[String]` |
| `46` | `fn :: l sort strs len [String] Int` | `[String]` |
| `47` | `fn :: list str sort [String]` | `[String]` |
| `48` | `fn :: l kv key (String String)` | `String` |
| `49` | `fn :: l kv val (String String)` | `String` |
| `50` | `fn :: list kv empty` | `[String String]` |
| `51` | `fn :: list kv len [String String]` | `Int` |
| `52` | `fn :: list kv has [String String] String` | `Bool` |
| `53` | `fn :: list kv get or [String String] String String` | `String` |
| `54` | `fn :: list kv get [String String] String` | `String` |
| `55` | `fn :: list kv put [String String] String String` | `[String String]` |
| `56` | `fn :: list kv remove [String String] String` | `[String String]` |
| `57` | `fn :: list kv keys [String String]` | `[String]` |
| `58` | `fn :: list kv values [String String]` | `[String]` |
| `59` | `fn :: list kv merge [String String] [String String]` | `[String String]` |

---

## 03.3. `list` sakonki esploratzen: Funtzionalitate bakoitzaren urratsez urratseko adibideak

Ez da nahikoa sinadura-taula ikustea: `list` lib-aren **funtzionalitate bakoitza** Ridgunen exekutagarriak diren adibide progresiboen bidez esploratuko dugu. Eguneroko bi errezeta taularatuekin hasiko gara eta ondoren xehetasunez ikusiko ditugu `src/test/ridgun/test list.rg`-en egiaztatutako agertoki funtzional eta muga-kasu guztiak.

### 03.3.1. 1. adibidea: Fluxu nagusia estilo taularatuan `list` erabiliz

Ikusi nola Ridgunen `=` ikurrak eta `list` bidezko eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren, beharrezkoak ez diren aldagai aldakorrik edo ezkutuko albo-ondoriorik gabe:

```ridgun
import list

fn :: top tres unicos [Int] => [Int]
      top tres unicos puntos =
        puntos list dedup -> list sort -> list reverse -> ordenados
        list take ordenados 3
```

### 03.3.2. 2. adibidea: Konposizio segurua eta muga-kasuen kudeaketa

`list` lib-eko funtzio oro `|` guarda boolearrekin eta `ridgun-libs`-eko gainerako 32 lib-ekin konposatzeko diseinatuta dago:

```ridgun
import list

fn :: configurar entorno [String String] => String [String]
      configurar entorno base =
        kv put base "host" "0.0.0.0" -> cfg1
        kv put cfg1 "port" "8080" -> cfg2
        kv get or cfg2 "host" "127.0.0.1" -> host
        cfg2 kv keys -> claves
        (host, claves)
```

### 03.3.3. 3. adibidea: Indexazio segurua (`nth or`, `head or`, `last or`), zatiketa (`take`, `drop`, `slice`), tarteak (`range`, `iota`, `replicate`) eta bikoiztuen ezabaketa (`dedup`, `count eq`)

Adibide praktiko honetan `list` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test list indexing slicing and ranges => ()
      test list indexing slicing and ranges =
        xs = [10, 20, 30, 40, 50]
        ss = ["aa", "bb", "cc", "dd"]
        assert int equals (list len xs) 5 "AC1: list_len 5"
        assert int equals (list str len ss) 4 "AC1: list_str_len 4"
        assert true (list is empty []) "AC1: list_is_empty []"
        assert false (list is empty xs) "AC1: list_is_empty non-empty"
        assert true (list str is empty []) "AC1: list_str_is_empty []"
        assert false (list str is empty ss) "AC1: list_str_is_empty non-empty"

        assert int equals (list nth xs 0) 10 "AC1: list_nth 0"
        assert int equals (list nth xs 4) 50 "AC1: list_nth 4"
        assert int equals (list nth or xs 99 (0 - 1)) (0 - 1) "AC1: list_nth_or out of bounds"
        assert int equals (list nth or xs (0 - 1) (0 - 1)) (0 - 1) "AC1: list_nth_or negative"
        assert str eq (list str nth ss 2) "cc" "AC1: list_str_nth 2"
        assert str eq (list str nth or ss 99 "oob") "oob" "AC1: list_str_nth_or out of bounds"
        assert int equals (list head xs 0) 10 "AC1: list_head"
        assert int equals (list head [] 99) 99 "AC1: list_head empty fallback"
        assert int equals (list last xs 0) 50 "AC1: list_last"
        assert int equals (list last [] 99) 99 "AC1: list_last empty fallback"

        assert eq (list take xs 3) [10, 20, 30]
        assert eq (list take xs 0) []
        assert eq (list take xs (0 - 2)) []
        assert eq (list take xs 99) [10, 20, 30, 40, 50]
        assert eq (list drop xs 3) [40, 50]
        assert eq (list drop xs 0) xs
        assert eq (list drop xs 99) []
        assert eq (list slice xs 1 4) [20, 30, 40]
        assert eq (list slice xs (0 - 3) 2) [10, 20]
        assert eq (list slice xs 4 2) []
        assert eq (list str slice ss 1 3) ["bb", "cc"]

        assert eq (list reverse xs) [50, 40, 30, 20, 10]
        assert eq (list str reverse ss) ["dd", "cc", "bb", "aa"]

        assert eq (list range 1 5) [1, 2, 3, 4, 5]
        assert eq (list range 3 3) [3]
        assert eq (list range 5 1) []
        assert eq (list range step 0 6 2) [0, 2, 4, 6]
        assert eq (list range step 6 0 (0 - 2)) [6, 4, 2, 0]
        assert eq (list range step 1 5 0) []
        assert eq (list replicate 3 7) [7, 7, 7]
        assert eq (list replicate 0 7) []

        assert true (list contains xs 30) "AC1: list_contains 30"
        assert false (list contains xs 99) "AC1: list_contains 99"
        assert true (list str contains ss "cc") "AC1: list_str_contains cc"
        assert false (list str contains ss "zz") "AC1: list_str_contains zz"
        assert int equals (list index of xs 30) 2 "AC1: list_index_of 30"
        assert int equals (list index of xs 99) (0 - 1) "AC1: list_index_of missing"
        assert int equals (list str index of ss "dd") 3 "AC1: list_str_index_of dd"
        assert int equals (list count [1, 2, 1, 3, 1] 1) 3 "AC1: list_count"
        assert int equals (list str count ["a", "b", "a"] "a") 2 "AC1: list_str_count"
        assert eq (list dedup [3, 1, 3, 2, 1, 3]) [3, 1, 2]
        assert eq (list str dedup ["b", "a", "b", "c", "a"]) ["b", "a", "c"]
        ()
```

### 03.3.4. 4. adibidea: $O(N \log N)$ ordenazio determinista (`list sort int`, `list sort desc`, `list sort str`, `list is sorted`)

Adibide praktiko honetan `list` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test list mergesort => ()
      test list mergesort =
        unsorted = [42, 7, 19, 7, 0, (0 - 5), 100, 3, (0 - 50)]
        sorted = list sort unsorted
        assert eq sorted [(0 - 50), (0 - 5), 0, 3, 7, 7, 19, 42, 100]
        assert true (list is sorted sorted) "AC2: list_is_sorted after sort"
        assert false (list is sorted unsorted) "AC2: list_is_sorted false on unsorted"
        assert true (list is sorted []) "AC2: empty list is sorted"
        assert true (list is sorted [1]) "AC2: singleton list is sorted"
        assert eq (list sort []) []
        assert eq (list sort [1]) [1]
        assert eq (list sort [5, 4, 3, 2, 1]) [1, 2, 3, 4, 5]
        s_strs = list str sort ["delta", "alpha", "charlie", "bravo", "alpha", "al", ""]
        assert eq s_strs ["", "al", "alpha", "alpha", "bravo", "charlie", "delta"]
        ()
```

### 03.3.5. 5. adibidea: Gako-balio mapa asoziatibo aldaezinak (`kv put`, `kv get or`, `kv has`, `kv remove`, `kv keys`, `kv values`, `kv len`)

Adibide praktiko honetan `list` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test kv associative map => ()
      test kv associative map =
        m0 = kv empty
        assert int equals (kv len m0) 0 "AC3: kv_empty len 0"
        m1 = kv put m0 "host" "127.0.0.1"
        m2 = kv put m1 "port" "8080"
        m3 = kv put m2 "port" "9090"
        assert int equals (kv len m3) 2 "AC3: kv_put updates in-place without duplicating key"
        assert true (kv has m3 "host") "AC3: kv_has host"
        assert false (kv has m3 "missing") "AC3: kv_has missing"
        assert str eq (kv get m3 "port") "9090" "AC3: kv_get updated port"
        assert str eq (kv get m3 "missing") "" "AC3: kv_get missing returns empty"
        assert str eq (kv get or m3 "mode" "prod") "prod" "AC3: kv_get_or default"
        assert eq (kv keys m3) ["host", "port"]
        assert eq (kv values m3) ["127.0.0.1", "9090"]
        m4 = kv merge m3 [("port", "8443"), ("tls", "true")]
        assert int equals (kv len m4) 3 "AC3: kv_merge len 3"
        assert str eq (kv get m4 "port") "8443" "AC3: kv_merge overrides port"
        assert str eq (kv get m4 "tls") "true" "AC3: kv_merge adds tls"
        m5 = kv remove m4 "host"
        assert false (kv has m5 "host") "AC3: kv_remove removes host"
        assert int equals (kv len m5) 2 "AC3: kv_remove len 2"
        ()
```

---

## 03.4. Kaputaren azpian: nola dagoen eraikia `list` Ridgun hutsean (`src/main/ridgun/lib/list.rg`)

`ridgun-libs`-en abantaila handienetako bat **C-ko kutxa beltzik ez egotea** da. `src/main/ridgun/lib/list.rg` ireki dezakezu eta eragiketa bakoitza *pattern matching*, `|` / `|.` guarda-zuhaitzak eta isats-errekurtsioa (TCO) erabiliz nola inplementatuta dagoen irakurri. Ikus ditzagun bere benetako inplementazioaren funtsezko piezak:

### 03.4.1. Barne-inplementazioa: List Length & Emptiness

Ikusi nola `list.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
module :: list

fn :: list len [Int]    => Int
      list len []       =  0
      list len (_:rest) =  1 + (list len rest)

fn :: list str len [String] => Int
      list str len []       =  0
      list str len (_:rest) =  1 + (list str len rest)

fn :: list is empty [Int] => Bool
      list is empty []    =  True
      list is empty _     =  False

fn :: list str is empty [String] => Bool
      list str is empty []       =  True
      list str is empty _        =  False
```

### 03.4.2. Barne-inplementazioa: Slicing (`take`, `drop`, `slice`) & Reversal

Ikusi nola `list.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: list take [Int]    Int => [Int]
      list take []       _   =  []
      list take (x:rest) n   =
        | n <= 0    = []
        | otherwise = [x] :: (list take rest (n - 1))

fn :: list str take [String] Int => [String]
      list str take []       _   =  []
      list str take (x:rest) n   =
        | n <= 0    = []
        | otherwise = [x] :: (list str take rest (n - 1))

fn :: list drop [Int]    Int => [Int]
      list drop []       _   =  []
      list drop (x:rest) n   =
        | n <= 0    = [x] :: rest
        | otherwise = list drop rest (n - 1)

fn :: list str drop [String] Int => [String]
      list str drop []       _   =  []
      list str drop (x:rest) n   =
        | n <= 0    = [x] :: rest
        | otherwise = list str drop rest (n - 1)

fn :: l clamp nonneg Int => Int
      l clamp nonneg x   =
        | x < 0     = 0
        | otherwise = x

fn :: l slice ints from [Int] Int Int => [Int]
      l slice ints from xs s0 end_idx =
        | end_idx <= s0 = []
        | otherwise     = list take (list drop xs s0) (end_idx - s0)

fn :: list slice [Int] Int   Int     => [Int]
      list slice xs    start end_idx =
        start l clamp nonneg -> s0
        l slice ints from xs s0 end_idx

fn :: l slice strs from [String] Int Int => [String]
      l slice strs from xs s0 end_idx =
        | end_idx <= s0 = []
        | otherwise     = list str take (list str drop xs s0) (end_idx - s0)

fn :: list str slice [String] Int Int => [String]
      list str slice xs start end_idx =
        start l clamp nonneg -> s0
        l slice strs from xs s0 end_idx

fn :: l rev ints [Int]    [Int] => [Int]
      l rev ints []       acc   =  acc
      l rev ints (x:rest) acc   =  l rev ints rest ([x] :: acc)

fn :: list reverse [Int] => [Int]
      list reverse xs    =  l rev ints xs []

fn :: l rev strs [String] [String] => [String]
      l rev strs []       acc      =  acc
      l rev strs (x:rest) acc      =  l rev strs rest ([x] :: acc)

fn :: list str reverse [String] => [String]
      list str reverse xs       =  l rev strs xs []
```

### 03.4.3. Barne-inplementazioa: Search, Count & Deduplication

Ikusi nola `list.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: l idx int [Int] Int Int => Int
      l idx int [] _ _ = 0 - 1
      l idx int (x:rest) tgt idx =
        | x == tgt  = idx
        | otherwise = l idx int rest tgt (idx + 1)

fn :: list index of [Int] Int => Int
      list index of xs    tgt =  l idx int xs tgt 0

fn :: list contains [Int] Int => Bool
      list contains xs    tgt =  (list index of xs tgt) >= 0

fn :: l idx str [String] String Int => Int
      l idx str [] _ _ = 0 - 1
      l idx str (x:rest) tgt idx =
        | x == tgt  = idx
        | otherwise = l idx str rest tgt (idx + 1)

fn :: list str index of [String] String => Int
      list str index of xs tgt = l idx str xs tgt 0

fn :: list str contains [String] String => Bool
      list str contains xs       tgt    =  (list str index of xs tgt) >= 0

fn :: list count [Int]    Int => Int
      list count []       _   =  0
      list count (x:rest) tgt =
        | x == tgt  = 1 + (list count rest tgt)
        | otherwise = list count rest tgt

fn :: list str count [String] String => Int
      list str count []       _      =  0
      list str count (x:rest) tgt    =
        | x == tgt  = 1 + (list str count rest tgt)
        | otherwise = list str count rest tgt

fn :: l dedup ints [Int]    [Int] => [Int]
      l dedup ints []       seen  =  list reverse seen
      l dedup ints (x:rest) seen  =
        | list contains seen x = l dedup ints rest seen
        | otherwise            = l dedup ints rest ([x] :: seen)

fn :: list dedup [Int] => [Int]
      list dedup xs    =  l dedup ints xs []

fn :: l dedup strs [String] [String] => [String]
      l dedup strs []       seen     =  list str reverse seen
      l dedup strs (x:rest) seen     =
        | list str contains seen x = l dedup strs rest seen
        | otherwise                = l dedup strs rest ([x] :: seen)

fn :: list str dedup [String] => [String]
      list str dedup xs       =  l dedup strs xs []
```

### 03.4.4. Barne-inplementazioa: Associative Key-Value Map (`[(String, String)]`)

Ikusi nola `list.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: l kv key (String String) => String
      l kv key (k, _)          =  k

fn :: l kv val (String String) => String
      l kv val (_, v)          =  v

fn :: kv empty => [String String]
      kv empty =  []

fn :: kv len [String String] => Int
      kv len []              =  0
      kv len (_:rest)        =  1 + (kv len rest)

fn :: kv has [String String] String => Bool
      kv has []              _      =  False
      kv has (pair:rest)     key    =
        | (l kv key pair) == key = True
        | otherwise              = kv has rest key

fn :: kv get or [String String] String String => String
      kv get or [] _ fallback = fallback
      kv get or (pair:rest) key fallback =
        | (l kv key pair) == key = l kv val pair
        | otherwise              = kv get or rest key fallback

fn :: kv get [String String] String => String
      kv get pairs           key    =  kv get or pairs key ""

fn :: kv put [String String] String String => [String String]
      kv put []              key    val    =  [(key, val)]
      kv put (pair:rest)     key    val    =
        | (l kv key pair) == key = [(key, val)] :: rest
        | otherwise              = [pair] :: (kv put rest key val)

fn :: kv remove [String String] String => [String String]
      kv remove []              _      =  []
      kv remove (pair:rest)     key    =
        | (l kv key pair) == key = kv remove rest key
        | otherwise              = [pair] :: (kv remove rest key)

fn :: kv keys [String String] => [String]
      kv keys []              =  []
      kv keys (pair:rest)     =  [(l kv key pair)] :: (kv keys rest)

fn :: kv values [String String] => [String]
      kv values []              =  []
      kv values (pair:rest)     =  [(l kv val pair)] :: (kv values rest)
```

---

## 03.5. Berme algoritmikoak, `RMM1`/`RMM2` memoria eta `list`-en Urrezko 5 Arauak

- **Berme algoritmikoa eta segurtasunekoa**: Kasurik txarreneko $O(N \log N)$ ordenazio determinista (Quicksorten $O(N^2)$ patologikorik gabe) eta txertatze-ordenaren kontserbazioa `kv` mapetan.
- **$O(1)$ pila-konplexutasuna TCOrekin**: `src/main/ridgun/lib/list.rg`-eko begizta errekurtsibo guztiak isats-posizioan daude; beraz, `ridgunc`-ek pila-hazkuntzarik gabeko jauzi natiboetara konpilatzen ditu.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test list.rg` suite automatizatuaren bidez.

### `list`-ekin programatzeko Urrezko 5 Arauak

1. **Deklaratu `import list` fitxategiaren hasieran** eta baliatu zuriuneen eta azpimarren arteko baliokidetasuna zure kodea prosa bezala irakur dadin.
2. **Lerrokatu zure datu-hodiak `=` ikurrarekin**: kateatu `list`-erako deiak izen propioko urratsetan eta utzi `stable format`-i zutabeak lerrokatzen.
3. **Baliatu `list`-eko funtzio osoak zure `|` guardetan**: egiaztatu itzulera-balioak edo askatu ADTak *pattern matching* bidez, kanpoko sarrera beti baliozkoa dela suposatu beharrean.
4. **Saihestu egitura handiak kopiatzea eremu bat kontsultatu besterik behar ez baduzu**: gogoratu `RMM2`-n sarrerako argumentuek ez dituztela kontagailuak handitzen edo txikitzen (`+0` / `-0`).
5. **Konbinatu `list` eta `test` (`import test`)**: idatzi beti asertzioak `assert equals` edo `assert true` erabiliz zure domeinuaren inbarianteak finkatzeko.

---

**04. kapituluan** **`btree`** lib-a sakonki esploratuko dugu (`btree` lib-a — $O(\log N)$ AVL Zuhaitz Iraunkorrak, Multzoak eta Tontorrak).
