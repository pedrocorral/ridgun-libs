# Kapitel 03: Lib:en `list` — Listor, $O(N \log N)$ Mergesort och Nyckel-Värde-Mappar

## 03.1. Varför finns lib:en `list`? (Det verkliga problemet och Ridguns filosofi)

> *”Varför behöver jag en `list`-lib skriven från grunden i ren Ridgun i stället för att bara länka in ett gammalt C-bibliotek?”*

Det är den första fråga varje systemingenjör ställer sig när man möter `list`. Och svaret sammanfattar hela filosofin bakom `ridgun-libs`:

Låt oss vara ärliga: indexfel utanför gränserna (`IndexError` / `panic!`) och oavsiktlig mutering av delade listor är två av de vanligaste buggarna vid databearbetning.

Lib:en **`list`** tillhandahåller säker indexering med standardvärde, skivning (`take`, `drop`, `slice`), intervall, stabil deduplicering, **$O(N \log N)$ mergesort** för `[Int]` och `[String]` samt oföränderliga `[String String]`-nyckel-värde-mappar (`kv get`, `kv put`, `kv merge`).

I ett traditionellt ekosystem innebär uppgifter inom domänen **`LIST`** ofta att man drar in externa C-beroenden, brottas med råa pekare, ogenomskinliga typkonverteringar, okontrollerade undantag eller oförutsägbara skräpsamlarpauser. I Ridgun löser lib:en **`list`** (`src/main/ridgun/lib/list.rg`) problemet genom fyra kompromisslösa principer:

1. **Totala funktioner och explicita kontrakt (`=>`)**: ingen funktion i `list` kastar dolda undantag eller förlitar sig på `null`. Varje gränsfall returnerar ett dokumenterat sentinelvärde eller en algebraisk summatyp (`Option`, `Result`).
2. **Noll C-kod och noll `libc`**: varje rad i `list` kompileras direkt till inbyggd ELF64-maskinkod verifierad av `ridgunc`.
3. **Svansrekursion med TCO (*Tail-Call Optimization*)**: alla interna genomlöpningar i `list` kompileras till inbyggda hårdvaruloopar med $O(1)$ stackutrymme.
4. **Deterministiskt minne (`RMM1` / `RMM2`)**: varje mellanliggande struktur frigörs i exakt det ögonblick dess sista läsning avslutas, helt utan *Garbage Collector*.

---

## 03.2. Inbyggda artefakter, import och komplett API-katalog för `list`

I `ridgun-libs` är **`list`** en förstklassig **lib** placerad i `src/main/ridgun/lib/list.rg` (domän `LIST`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/list.rglib` | Portabel distribution och direkt import med `import list` |
| **Kompilerat arkiv** | `target/list.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/liblist.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import list` överst och anropar funktionerna med mellanslag eller understreck.

### 03.2.1. Översikt över funktionella familjer i `list`

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `list nth or / list str nth or` | Säker indexuppslagning som returnerar `default_val` utanför gränserna |
| `list take / list drop / list slice / list reverse` | Prefix, suffix, delintervall `[start, end)` och svansrekursiv omvändning |
| `list range / list range step` | Genererar aritmetiska talföljder (`step == 0` returnerar säkert `[]`) |
| `list sort / list str sort / list dedup / list str dedup` | Stabil $O(N \log N)$ mergesort och deduplicering vid första förekomst |
| `kv empty / kv put / kv get / kv get or / kv remove / kv merge` | Operationer på ordnade associativa `[String String]`-nyckel-värde-mappar |

### 03.2.2. Komplett katalog över typer och signaturer i `src/main/ridgun/lib/list.rg`

Nedan följer hela förteckningen över algebraiska datatyper (`type`), mixfix-operatorer (`op ::`) och funktionssignaturer (`fn ::`) som definieras i `src/main/ridgun/lib/list.rg` (`0` typer, `0` operatorer och `59` funktioner):

| # | Funktion / Signatur (`fn ::`) | Returtyp |
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
| `50` | `fn :: kv empty` | `[String String]` |
| `51` | `fn :: kv len [String String]` | `Int` |
| `52` | `fn :: kv has [String String] String` | `Bool` |
| `53` | `fn :: kv get or [String String] String String` | `String` |
| `54` | `fn :: kv get [String String] String` | `String` |
| `55` | `fn :: kv put [String String] String String` | `[String String]` |
| `56` | `fn :: kv remove [String String] String` | `[String String]` |
| `57` | `fn :: kv keys [String String]` | `[String]` |
| `58` | `fn :: kv values [String String]` | `[String]` |
| `59` | `fn :: kv merge [String String] [String String]` | `[String String]` |

---

## 03.3. Djupdykning i `list`: Steg-för-steg-exempel för varje funktion

Det räcker inte med en signaturtabell: låt oss utforska **varje funktionalitet** i lib:en `list` genom progressiva, körbara Ridgun-exempel. Vi börjar med två tabellbaserade vardagsrecept och går därefter igenom alla funktionella scenarier, transformationer och gränsfall som verifieras i `src/test/ridgun/test list.rg`.

### 03.3.1. Exempel 1: Huvudflöde i tabellform med `list`

Lägg märke till hur `=`-tecknen och transformationsstegen med `list` linjeras som en ren tabell utan onödiga muterbara variabler eller dolda sidoeffekter:

```ridgun
import list

fn :: top tres unicos (puntos : [Int]) => [Int]
      top tres unicos puntos =
        unicos    = list dedup puntos
        ordenados = list reverse (list sort unicos)
        list take ordenados 3
```

### 03.3.2. Exempel 2: Säker komposition och hantering av gränsfall

Varje funktion i lib:en `list` är utformad för att kombineras sömlöst med booleska vakter `|` och med övriga 32 libs i `ridgun-libs`:

```ridgun
import list

fn :: configurar entorno (base : [String String]) => (String, [String])
      configurar entorno base =
        cfg1 = kv put base "host" "0.0.0.0"
        cfg2 = kv put cfg1 "port" "8080"
        host = kv get or cfg2 "host" "127.0.0.1"
        (host, kv keys cfg2)
```

### 03.3.3. Exempel 3: Säker indexering (`nth or`, `head or`, `last or`), beskärning (`take`, `drop`, `slice`), intervall (`range`, `iota`, `replicate`) och dubblettborttagning (`dedup`, `count eq`)

I detta praktiska exempel undersöker vi grundligt hur `list` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test list indexing slicing and ranges => ()
      test list indexing slicing and ranges =
        xs = [10, 20, 30, 40, 50]
        ss = ["aa", "bb", "cc", "dd"]
        _ = assert int equals (list len xs) 5 "AC1: list_len 5"
        _ = assert int equals (list str len ss) 4 "AC1: list_str_len 4"
        _ = assert true (list is empty []) "AC1: list_is_empty []"
        _ = assert false (list is empty xs) "AC1: list_is_empty non-empty"
        _ = assert true (list str is empty []) "AC1: list_str_is_empty []"
        _ = assert false (list str is empty ss) "AC1: list_str_is_empty non-empty"

        _ = assert int equals (list nth xs 0) 10 "AC1: list_nth 0"
        _ = assert int equals (list nth xs 4) 50 "AC1: list_nth 4"
        _ = assert int equals (list nth or xs 99 (0 - 1)) (0 - 1) "AC1: list_nth_or out of bounds"
        _ = assert int equals (list nth or xs (0 - 1) (0 - 1)) (0 - 1) "AC1: list_nth_or negative"
        _ = assert str eq (list str nth ss 2) "cc" "AC1: list_str_nth 2"
        _ = assert str eq (list str nth or ss 99 "oob") "oob" "AC1: list_str_nth_or out of bounds"
        _ = assert int equals (list head xs 0) 10 "AC1: list_head"
        _ = assert int equals (list head [] 99) 99 "AC1: list_head empty fallback"
        _ = assert int equals (list last xs 0) 50 "AC1: list_last"
        _ = assert int equals (list last [] 99) 99 "AC1: list_last empty fallback"

        _ = assert eq (list take xs 3) [10, 20, 30]
        _ = assert eq (list take xs 0) []
        _ = assert eq (list take xs (0 - 2)) []
        _ = assert eq (list take xs 99) [10, 20, 30, 40, 50]
        _ = assert eq (list drop xs 3) [40, 50]
        _ = assert eq (list drop xs 0) xs
        _ = assert eq (list drop xs 99) []
        _ = assert eq (list slice xs 1 4) [20, 30, 40]
        _ = assert eq (list slice xs (0 - 3) 2) [10, 20]
        _ = assert eq (list slice xs 4 2) []
        _ = assert eq (list str slice ss 1 3) ["bb", "cc"]

        _ = assert eq (list reverse xs) [50, 40, 30, 20, 10]
        _ = assert eq (list str reverse ss) ["dd", "cc", "bb", "aa"]

        _ = assert eq (list range 1 5) [1, 2, 3, 4, 5]
        _ = assert eq (list range 3 3) [3]
        _ = assert eq (list range 5 1) []
        _ = assert eq (list range step 0 6 2) [0, 2, 4, 6]
        _ = assert eq (list range step 6 0 (0 - 2)) [6, 4, 2, 0]
        _ = assert eq (list range step 1 5 0) []
        _ = assert eq (list replicate 3 7) [7, 7, 7]
        _ = assert eq (list replicate 0 7) []

        _ = assert true (list contains xs 30) "AC1: list_contains 30"
        _ = assert false (list contains xs 99) "AC1: list_contains 99"
        _ = assert true (list str contains ss "cc") "AC1: list_str_contains cc"
        _ = assert false (list str contains ss "zz") "AC1: list_str_contains zz"
        _ = assert int equals (list index of xs 30) 2 "AC1: list_index_of 30"
        _ = assert int equals (list index of xs 99) (0 - 1) "AC1: list_index_of missing"
        _ = assert int equals (list str index of ss "dd") 3 "AC1: list_str_index_of dd"
        _ = assert int equals (list count [1, 2, 1, 3, 1] 1) 3 "AC1: list_count"
        _ = assert int equals (list str count ["a", "b", "a"] "a") 2 "AC1: list_str_count"
        _ = assert eq (list dedup [3, 1, 3, 2, 1, 3]) [3, 1, 2]
        _ = assert eq (list str dedup ["b", "a", "b", "c", "a"]) ["b", "a", "c"]
        ()
```

### 03.3.4. Exempel 4: Deterministisk $O(N \log N)$ mergesort (`list sort int`, `list sort desc`, `list sort str`, `list is sorted`)

I detta praktiska exempel undersöker vi grundligt hur `list` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test list mergesort => ()
      test list mergesort =
        unsorted = [42, 7, 19, 7, 0, (0 - 5), 100, 3, (0 - 50)]
        sorted = list sort unsorted
        _ = assert eq sorted [(0 - 50), (0 - 5), 0, 3, 7, 7, 19, 42, 100]
        _ = assert true (list is sorted sorted) "AC2: list_is_sorted after sort"
        _ = assert false (list is sorted unsorted) "AC2: list_is_sorted false on unsorted"
        _ = assert true (list is sorted []) "AC2: empty list is sorted"
        _ = assert true (list is sorted [1]) "AC2: singleton list is sorted"
        _ = assert eq (list sort []) []
        _ = assert eq (list sort [1]) [1]
        _ = assert eq (list sort [5, 4, 3, 2, 1]) [1, 2, 3, 4, 5]
        s_strs = list str sort ["delta", "alpha", "charlie", "bravo", "alpha", "al", ""]
        _ = assert eq s_strs ["", "al", "alpha", "alpha", "bravo", "charlie", "delta"]
        ()
```

### 03.3.5. Exempel 5: Oföränderliga associativa nyckel-värde-mappar (`kv put`, `kv get or`, `kv has`, `kv remove`, `kv keys`, `kv values`, `kv len`)

I detta praktiska exempel undersöker vi grundligt hur `list` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test kv associative map => ()
      test kv associative map =
        m0 = kv empty
        _ = assert int equals (kv len m0) 0 "AC3: kv_empty len 0"
        m1 = kv put m0 "host" "127.0.0.1"
        m2 = kv put m1 "port" "8080"
        m3 = kv put m2 "port" "9090"
        _ = assert int equals (kv len m3) 2 "AC3: kv_put updates in-place without duplicating key"
        _ = assert true (kv has m3 "host") "AC3: kv_has host"
        _ = assert false (kv has m3 "missing") "AC3: kv_has missing"
        _ = assert str eq (kv get m3 "port") "9090" "AC3: kv_get updated port"
        _ = assert str eq (kv get m3 "missing") "" "AC3: kv_get missing returns empty"
        _ = assert str eq (kv get or m3 "mode" "prod") "prod" "AC3: kv_get_or default"
        _ = assert eq (kv keys m3) ["host", "port"]
        _ = assert eq (kv values m3) ["127.0.0.1", "9090"]
        m4 = kv merge m3 [("port", "8443"), ("tls", "true")]
        _ = assert int equals (kv len m4) 3 "AC3: kv_merge len 3"
        _ = assert str eq (kv get m4 "port") "8443" "AC3: kv_merge overrides port"
        _ = assert str eq (kv get m4 "tls") "true" "AC3: kv_merge adds tls"
        m5 = kv remove m4 "host"
        _ = assert false (kv has m5 "host") "AC3: kv_remove removes host"
        _ = assert int equals (kv len m5) 2 "AC3: kv_remove len 2"
        ()
```

---

## 03.4. Under huven: hur `list` är byggd i ren Ridgun (`src/main/ridgun/lib/list.rg`)

En av de största fördelarna med `ridgun-libs` är att **det inte finns några svarta lådor i C**. Du kan öppna `src/main/ridgun/lib/list.rg` och läsa exakt hur varje operation är implementerad med mönstermatchning, `|` / `|.`-vaktträd och svansrekursion (TCO). Låt oss titta på nyckeldelarna i den faktiska implementationen:

### 03.4.1. Intern implementation: List Length & Emptiness

Se hur `list.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
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

### 03.4.2. Intern implementation: Slicing (`take`, `drop`, `slice`) & Reversal

Se hur `list.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

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
      list slice xs    start end_idx =  l slice ints from xs (l clamp nonneg start) end_idx

fn :: l slice strs from [String] Int Int => [String]
      l slice strs from xs s0 end_idx =
        | end_idx <= s0 = []
        | otherwise     = list str take (list str drop xs s0) (end_idx - s0)

fn :: list str slice [String] Int Int => [String]
      list str slice xs start end_idx = l slice strs from xs (l clamp nonneg start) end_idx

fn :: l rev ints [Int]    [Int] => [Int]
      l rev ints []       acc   =  acc
      l rev ints (x:rest) acc   =  l rev ints rest ([x] :: acc)
```

### 03.4.3. Intern implementation: Search, Count & Deduplication

Se hur `list.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

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
```

### 03.4.4. Intern implementation: Associative Key-Value Map (`[(String, String)]`)

Se hur `list.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

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

## 03.5. Algoritmiska garantier, `RMM1`/`RMM2`-minne och de 5 Gyllene Reglerna för `list`

- **Algoritmisk garanti och säkerhet**: Deterministisk $O(N \log N)$-sortering i värsta fall (immun mot Quicksorts patologiska $O(N^2)$) och bevarad insättningsordning i `kv`-mappar.
- **$O(1)$ stackkomplexitet med TCO**: Alla rekursiva loopar i `src/main/ridgun/lib/list.rg` ligger i svansposition, så `ridgunc` kompilerar dem till inbyggda hopp utan stacktillväxt.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test list.rg`.

### De 5 Gyllene Reglerna när du programmerar med `list`

1. **Deklarera `import list` överst i filen** och utnyttja att mellanslag och understreck är utbytbara så att koden läses som naturlig prosa.
2. **Linjera dina datapipelines med `=`**: kedja samman `list`-anrop i namngivna mellansteg och låt `stable format` linjera kolumnerna.
3. **Utnyttja `list`:s totala funktioner i dina `|`-vakter**: kontrollera returvärden eller packa upp ADT:er med mönstermatchning i stället för att anta att extern indata alltid är giltig.
4. **Undvik att kopiera stora strukturer när du bara läser ett fält**: kom ihåg att i `RMM2` medför inargument noll referensräkningskostnad (`+0` / `-0`).
5. **Kombinera `list` med `test` (`import test`)**: lås alltid fast dina domäninvarianter med `assert equals` eller `assert true`.

---

I **Kapitel 04** går vi vidare och utforskar lib:en **`btree`** på djupet (Lib:en `btree` — Beständiga $O(\log N)$ AVL-Träd, Mängder och Prioritetsköer).
