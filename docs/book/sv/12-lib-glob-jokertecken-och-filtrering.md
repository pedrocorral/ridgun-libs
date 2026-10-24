# Kapitel 12: Lib:en `glob` — Jokerteckenmönster (`*`, `?`, `[a-z]`) och Listfiltrering

## 12.1. Varför finns lib:en `glob`? (Det verkliga problemet och Ridguns filosofi)

> *”Varför behöver jag en `glob`-lib skriven från grunden i ren Ridgun i stället för att bara länka in ett gammalt C-bibliotek?”*

Det är den första fråga varje systemingenjör ställer sig när man möter `glob`. Och svaret sammanfattar hela filosofin bakom `ridgun-libs`:

Låt oss vara ärliga: att dra igång en hel regex-motor bara för att kontrollera om ett filnamn matchar `*.rg` eller `test_[0-9]*.rg` är att skjuta mygg med kanon.

Lib:en **`glob`** implementerar exakt matchning av skal-jokertecken (`*`, `?`, `[a-z]`-intervall, negerade `[!0-9]` / `[^a-z]`-klasser), skiftlägesokänslig matchning (`glob match ci`) och listfiltrering.

I ett traditionellt ekosystem innebär uppgifter inom domänen **`GLOB`** ofta att man drar in externa C-beroenden, brottas med råa pekare, ogenomskinliga typkonverteringar, okontrollerade undantag eller oförutsägbara skräpsamlarpauser. I Ridgun löser lib:en **`glob`** (`src/main/ridgun/lib/glob.rg`) problemet genom fyra kompromisslösa principer:

1. **Totala funktioner och explicita kontrakt (`=>`)**: ingen funktion i `glob` kastar dolda undantag eller förlitar sig på `null`. Varje gränsfall returnerar ett dokumenterat sentinelvärde eller en algebraisk summatyp (`Option`, `Result`).
2. **Noll C-kod och noll `libc`**: varje rad i `glob` kompileras direkt till inbyggd ELF64-maskinkod verifierad av `ridgunc`.
3. **Svansrekursion med TCO (*Tail-Call Optimization*)**: alla interna genomlöpningar i `glob` kompileras till inbyggda hårdvaruloopar med $O(1)$ stackutrymme.
4. **Deterministiskt minne (`RMM1` / `RMM2`)**: varje mellanliggande struktur frigörs i exakt det ögonblick dess sista läsning avslutas, helt utan *Garbage Collector*.

---

## 12.2. Inbyggda artefakter, import och komplett API-katalog för `glob`

I `ridgun-libs` är **`glob`** en förstklassig **lib** placerad i `src/main/ridgun/lib/glob.rg` (domän `GLOB`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/glob.rglib` | Portabel distribution och direkt import med `import glob` |
| **Kompilerat arkiv** | `target/glob.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libglob.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import glob` överst och anropar funktionerna med mellanslag eller understreck.

### 12.2.1. Översikt över funktionella familjer i `glob`

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `glob match / glob match ci` | Skiftlägeskänslig och skiftlägesokänslig glob-mönstermatchning |
| `glob filter / glob any match` | Filtrerar `[String]` till matchande element eller testar om något mönster i en lista matchar |
| `glob has magic` | Detekterar om en sträng innehåller jokertecken (`*`, `?`, `[`) |

### 12.2.2. Komplett katalog över typer och signaturer i `src/main/ridgun/lib/glob.rg`

Nedan följer hela förteckningen över algebraiska datatyper (`type`), mixfix-operatorer (`op ::`) och funktionssignaturer (`fn ::`) som definieras i `src/main/ridgun/lib/glob.rg` (`0` typer, `0` operatorer och `18` funktioner):

| # | Funktion / Signatur (`fn ::`) | Returtyp |
|---|---|---|
| `1` | `fn :: gl lower char String Int Int` | `String` |
| `2` | `fn :: gl to lower loop String Int Int` | `String` |
| `3` | `fn :: gl to lower String` | `String` |
| `4` | `fn :: gl find close bracket String Int Int` | `Int` |
| `5` | `fn :: gl match range String Int Int Int Int Int` | `Bool` |
| `6` | `fn :: gl match class body String Int Int Int` | `Bool` |
| `7` | `fn :: gl eval bracket char String Int Int Int Int` | `Bool` |
| `8` | `fn :: gl eval bracket String Int Int Int` | `Bool` |
| `9` | `fn :: gl skip stars String Int Int` | `Int` |
| `10` | `fn :: gl match star String Int Int String Int Int` | `Bool` |
| `11` | `fn :: gl match star at String Int Int String Int Int` | `Bool` |
| `12` | `fn :: gl match bracket step String Int Int String Int Int Int` | `Bool` |
| `13` | `fn :: gl match step String Int Int String Int Int Int` | `Bool` |
| `14` | `fn :: gl match loop String Int Int String Int Int` | `Bool` |
| `15` | `fn :: glob match String String` | `Bool` |
| `16` | `fn :: glob match ci String String` | `Bool` |
| `17` | `fn :: glob filter String [String]` | `[String]` |
| `18` | `fn :: glob any match [String] String` | `Bool` |

---

## 12.3. Djupdykning i `glob`: Steg-för-steg-exempel för varje funktion

Det räcker inte med en signaturtabell: låt oss utforska **varje funktionalitet** i lib:en `glob` genom progressiva, körbara Ridgun-exempel. Vi börjar med två tabellbaserade vardagsrecept och går därefter igenom alla funktionella scenarier, transformationer och gränsfall som verifieras i `src/test/ridgun/test glob.rg`.

### 12.3.1. Exempel 1: Huvudflöde i tabellform med `glob`

Lägg märke till hur `=`-tecknen och transformationsstegen med `glob` linjeras som en ren tabell utan onödiga muterbara variabler eller dolda sidoeffekter:

```ridgun
import glob

fn :: seleccionar fuentes ridgun (archivos : [String]) => [String]
      seleccionar fuentes ridgun archivos =
        glob filter "test_[a-z]*.rg" archivos
```

### 12.3.2. Exempel 2: Säker komposition och hantering av gränsfall

Varje funktion i lib:en `glob` är utformad för att kombineras sömlöst med booleska vakter `|` och med övriga 32 libs i `ridgun-libs`:

```ridgun
import glob

fn :: es ruta excluida (ruta : String) => Bool
      es ruta excluida ruta =
        glob any match ["*.tmp", "*.bak", "target/*"] ruta
```

### 12.3.3. Exempel 3: Jokertecknen `*` och `?`, exakt gränsmatchning och gränsfall med tomma mönster

I detta praktiska exempel undersöker vi grundligt hur `glob` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test glob wildcards and boundaries => ()
      test glob wildcards and boundaries =
        _ = assert true (glob match "" "") "AC1: empty pattern matches empty string"
        _ = assert false (glob match "" "a") "AC1: empty pattern rejects non-empty"
        _ = assert true (glob match "*" "") "AC1: * matches empty string"
        _ = assert true (glob match "***" "") "AC1: *** matches empty string"
        _ = assert true (glob match "*" "anything.rg") "AC1: * matches full filename"
        _ = assert true (glob match "*.rg" "socket.rg") "AC1: *.rg matches socket.rg"
        _ = assert true (glob match "*.rg" ".rg") "AC1: *.rg matches leading dot .rg"
        _ = assert false (glob match "*.rg" "README.md") "AC1: *.rg rejects README.md"
        _ = assert false (glob match "*.rg" "socket.rg.bak") "AC1: *.rg rejects trailing suffix"
        _ = assert true (glob match "test_?.rg" "test_a.rg") "AC1: ? matches single char"
        _ = assert false (glob match "test_?.rg" "test_.rg") "AC1: ? rejects zero chars"
        _ = assert false (glob match "test_?.rg" "test_ab.rg") "AC1: ? rejects two chars"
        _ = assert true (glob match "???" "abc") "AC1: ??? matches 3 chars"
        _ = assert false (glob match "???" "ab") "AC1: ??? rejects 2 chars"
        _ = assert true (glob match "a*b*c" "abc") "AC1: multiple * matching zero chars"
        _ = assert true (glob match "a*b*c" "axxxbyyyc") "AC1: multiple * matching substrings"
        _ = assert true (glob match "a*b*c" "abbc") "AC1: backtracking * across repeated b"
        _ = assert false (glob match "a*b*c" "axxxbyyy") "AC1: missing trailing literal after *"
        _ = assert true (glob match "a***b" "axyzb") "AC1: collapsed *** matches"
        -- Pathological backtracking immunity via gl_skip_stars
        _ = assert false (glob match "****************a" "bbbbbbbbbbbbbbbbbbbbbbbbbbbb") "AC1: collapsed stars avoid exponential backtracking"
        ()
```

### 12.3.4. Exempel 4: Teckenklasser `[a-z]`, negerade intervall `[!0-9]` / `[^0-9]` och skiftlägesokänslig matchning (`glob match ci`)

I detta praktiska exempel undersöker vi grundligt hur `glob` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test glob classes and case insensitivity => ()
      test glob classes and case insensitivity =
        _ = assert true (glob match "file_[0-9].txt" "file_0.txt") "AC2: [0-9] lower bound 0"
        _ = assert true (glob match "file_[0-9].txt" "file_9.txt") "AC2: [0-9] upper bound 9"
        _ = assert false (glob match "file_[0-9].txt" "file_a.txt") "AC2: [0-9] rejects alpha"
        _ = assert true (glob match "id_[a-zA-Z0-9].rg" "id_Z.rg") "AC2: multi-range [a-zA-Z0-9] matches Z"
        _ = assert true (glob match "id_[a-zA-Z0-9].rg" "id_5.rg") "AC2: multi-range [a-zA-Z0-9] matches 5"
        _ = assert false (glob match "id_[a-zA-Z0-9].rg" "id__.rg") "AC2: multi-range [a-zA-Z0-9] rejects _"
        _ = assert true (glob match "v[135].rg" "v3.rg") "AC2: discrete character set [135]"
        _ = assert false (glob match "v[135].rg" "v2.rg") "AC2: discrete character set rejects 2"
        _ = assert true (glob match "file_[!0-9].txt" "file_a.txt") "AC2: [!0-9] POSIX negated class"
        _ = assert false (glob match "file_[!0-9].txt" "file_7.txt") "AC2: [!0-9] rejects digit"
        _ = assert true (glob match "file_[^0-9].txt" "file_z.txt") "AC2: [^0-9] caret negated class"
        _ = assert false (glob match "file_[^0-9].txt" "file_0.txt") "AC2: [^0-9] rejects digit"
        _ = assert true (glob match "a[b" "a[b") "AC2: unclosed '[' matches literally"
        _ = assert false (glob match "a[b" "axb") "AC2: unclosed '[' rejects non-bracket"

        -- Case-insensitive matching
        _ = assert true (glob match ci "*.RG" "socket.rg") "AC2: glob_match_ci *.RG on lowercase"
        _ = assert true (glob match ci "*.rg" "SOCKET.RG") "AC2: glob_match_ci *.rg on uppercase"
        _ = assert true (glob match ci "src/**/Test_[A-Z]*.rg" "SRC/main/test_crypto.RG") "AC2: glob_match_ci mixed case"
        ()
```

### 12.3.5. Exempel 5: Batchfiltrering av sökvägslistor (`glob filter`) och matchning mot flera mönster (`glob any match`)

I detta praktiska exempel undersöker vi grundligt hur `glob` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test glob filter and any match => ()
      test glob filter and any match =
        files = ["socket.rg", "README.md", "test_socket.rg", "crypto.rg", "build.sh"]
        _ = assert eq (glob filter "*.rg" files) ["socket.rg", "test_socket.rg", "crypto.rg"]
        _ = assert eq (glob filter "test_*.rg" files) ["test_socket.rg"]
        _ = assert eq (glob filter "*.nomatch" files) []
        _ = assert eq (glob filter "*.rg" []) []
        _ = assert true (glob any match ["*.md", "*.txt", "*.sh"] "README.md") "AC3: glob_any_match first pattern"
        _ = assert true (glob any match ["*.md", "*.txt", "*.sh"] "build.sh") "AC3: glob_any_match last pattern"
        _ = assert false (glob any match ["*.md", "*.txt"] "socket.rg") "AC3: glob_any_match no match"
        _ = assert false (glob any match [] "socket.rg") "AC3: glob_any_match empty pattern list"
        ()
```

---

## 12.4. Under huven: hur `glob` är byggd i ren Ridgun (`src/main/ridgun/lib/glob.rg`)

En av de största fördelarna med `ridgun-libs` är att **det inte finns några svarta lådor i C**. Du kan öppna `src/main/ridgun/lib/glob.rg` och läsa exakt hur varje operation är implementerad med mönstermatchning, `|` / `|.`-vaktträd och svansrekursion (TCO). Låt oss titta på nyckeldelarna i den faktiska implementationen:

### 12.4.1. Intern implementation: Bracket Character Class `[...]` Matching

Se hur `glob.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: gl find close bracket String Int Int => Int
      gl find close bracket pat idx plen =
        | idx >= plen                  = 0 - 1
        | (str char at pat idx) == 93  = idx
        | otherwise                    = gl find close bracket pat (idx + 1) plen

fn :: gl match range String Int Int Int Int Int => Bool
      gl match range pat idx end_idx tc lo hi =
        | tc >= lo and tc <= hi = True
        | otherwise             = gl match class body pat (idx + 3) end_idx tc

fn :: gl match class body String Int Int Int => Bool
      gl match class body pat idx end_idx tc =
        | idx >= end_idx = False
        | ((idx + 2) < end_idx) and ((str char at pat (idx + 1)) == 45) =
          gl match range pat idx end_idx tc (str char at pat idx) (str char at pat (idx + 2))
        | (str char at pat idx) == tc = True
        | otherwise                   = gl match class body pat (idx + 1) end_idx tc

fn :: gl eval bracket char String Int Int Int Int => Bool
      gl eval bracket char pat pstart close_idx tc c0 =
        | c0 == 33 or c0 == 94 = not (gl match class body pat (pstart + 1) close_idx tc)
        | otherwise            = gl match class body pat pstart close_idx tc

fn :: gl eval bracket String Int Int Int => Bool
      gl eval bracket pat pstart close_idx tc =
        gl eval bracket char pat pstart close_idx tc (str char at pat pstart)
```

### 12.4.2. Intern implementation: Wildcard (`*`, `?`, `[...]`) Matcher

Se hur `glob.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: gl skip stars String Int Int => Int
      gl skip stars pat pidx plen =
        | pidx >= plen                 = pidx
        | (str char at pat pidx) == 42 = gl skip stars pat (pidx + 1) plen
        | otherwise                    = pidx

fn :: gl match star String Int Int String Int Int => Bool
      gl match star pat pidx plen txt tidx tlen =
        | gl match loop pat pidx plen txt tidx tlen = True
        | tidx >= tlen                              = False
        | otherwise                                 = gl match star pat pidx plen txt (tidx + 1) tlen

fn :: gl match star at String Int Int String Int Int => Bool
      gl match star at pat next_p plen txt tidx tlen =
        | next_p >= plen = True
        | otherwise      = gl match star pat next_p plen txt tidx tlen

fn :: gl match bracket step String Int Int String Int Int Int => Bool
      gl match bracket step pat pidx plen txt tidx tlen close_idx =
        | close_idx < 0 =
          | (str char at txt tidx) == 91 = gl match loop pat (pidx + 1) plen txt (tidx + 1) tlen
          | otherwise                    = False |.
        | gl eval bracket pat (pidx + 1) close_idx (str char at txt tidx) =
          gl match loop pat (close_idx + 1) plen txt (tidx + 1) tlen
        | otherwise = False

fn :: gl match step String Int Int String Int Int Int => Bool
      gl match step pat pidx plen txt tidx tlen pc =
        | pc == 42                     = gl match star at pat (gl skip stars pat (pidx + 1) plen) plen txt tidx tlen
        | tidx >= tlen                 = False
        | pc == 63                     = gl match loop pat (pidx + 1) plen txt (tidx + 1) tlen
        | pc == 91                     = gl match bracket step pat pidx plen txt tidx tlen (gl find close bracket pat (pidx + 1) plen)
        | pc == (str char at txt tidx) = gl match loop pat (pidx + 1) plen txt (tidx + 1) tlen
        | otherwise                    = False

fn :: gl match loop String Int Int String Int Int => Bool
      gl match loop pat pidx plen txt tidx tlen =
        | pidx >= plen = tidx >= tlen
        | otherwise    = gl match step pat pidx plen txt tidx tlen (str char at pat pidx)

fn :: glob match String String => Bool
      glob match pat    txt    =  gl match loop pat 0 (str len pat) txt 0 (str len txt)

fn :: glob match ci String String => Bool
      glob match ci pat    txt    =  glob match (gl to lower pat) (gl to lower txt)
```

---

## 12.5. Algoritmiska garantier, `RMM1`/`RMM2`-minne och de 5 Gyllene Reglerna för `glob`

- **Algoritmisk garanti och säkerhet**: Automatisk sammanslagning av på varandra följande asterisker (`***` $\rightarrow$ `*`) för att undvika onödig backtracking samt säker hantering av oavslutade `[`-klammrar.
- **$O(1)$ stackkomplexitet med TCO**: Alla rekursiva loopar i `src/main/ridgun/lib/glob.rg` ligger i svansposition, så `ridgunc` kompilerar dem till inbyggda hopp utan stacktillväxt.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test glob.rg`.

### De 5 Gyllene Reglerna när du programmerar med `glob`

1. **Deklarera `import glob` överst i filen** och utnyttja att mellanslag och understreck är utbytbara så att koden läses som naturlig prosa.
2. **Linjera dina datapipelines med `=`**: kedja samman `glob`-anrop i namngivna mellansteg och låt `stable format` linjera kolumnerna.
3. **Utnyttja `glob`:s totala funktioner i dina `|`-vakter**: kontrollera returvärden eller packa upp ADT:er med mönstermatchning i stället för att anta att extern indata alltid är giltig.
4. **Undvik att kopiera stora strukturer när du bara läser ett fält**: kom ihåg att i `RMM2` medför inargument noll referensräkningskostnad (`+0` / `-0`).
5. **Kombinera `glob` med `test` (`import test`)**: lås alltid fast dina domäninvarianter med `assert equals` eller `assert true`.

---

I **Kapitel 13** går vi vidare och utforskar lib:en **`diff`** på djupet (Lib:en `diff` — LCS-raddiff, Redigeringsavstånd, Unified Diff och Patchning).
