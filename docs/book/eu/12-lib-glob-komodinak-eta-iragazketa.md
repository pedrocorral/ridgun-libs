# 12. kapitulua: `glob` lib-a — Komodin-ereduak (`*`, `?`, `[a-z]`) eta Zerrenden Iragazketa

## 12.1. Zergatik existitzen da `glob` lib-a? (Benetako arazoa eta Ridgun filosofia)

> *«Zergatik behar dut `glob` lib bat hutsetik Ridgun hutsean idatzia, betiko C liburutegi bat estekatu beharrean?»*

Hori da edozein sistema-ingeniarik `glob`-era iristean egiten duen lehen galdera. Eta erantzunak `ridgun-libs`-en filosofia osoa laburbiltzen du:

Izan gaitezen zintzoak: fitxategi bat `*.rg`-rekin amaitzen den edo `test_[0-9]*.rg`-rekin hasten den egiaztatzeko adierazpen erregular oso bat erabiltzea euliak kanoikadaka hiltzea da.

**`glob`** lib-ak shell komodinen bat-etortze zehatza (`*`, `?`, `[a-z]` klaseak, `[!0-9]` / `[^a-z]` klase ukatuak), letra larri/xeheekiko aldaera sentikorrak (`glob match ci`) eta bide-zerrenden iragazketa zuzena inplementatzen ditu.

Ekosistema tradizional batean, **`GLOB`** domeinuko zereginak ebazteak C-ko kanpo-mendekotasunak arrastatzea, erakusle gordinekin borrokatzea, mota-bihurketa opakuak, egiaztatu gabeko salbuespenak edo zabor-biltzailearen geldialdi ustekabekoak jasatea dakar. Ridgunen, **`glob`** lib-ak (`src/main/ridgun/lib/glob.rg`) lau printzipio negoziatu ezinekin heltzen dio arazoari:

1. **Funtzio osoak eta kontratu esplizituak (`=>`)**: `glob`-eko funtzio bakar batek ere ez du ezkutuko salbuespenik jaurtitzen, ezta `null` erabiltzen ere. Muga-kasu orok dokumentatutako balio bat edo batura-mota aljebraiko bat (`Option`, `Result`) itzultzen du.
2. **Zero C kode eta zero `libc`**: `glob`-eko kode guztia zuzenean ELF64 makina-kode natibora konpilatzen da, `ridgunc`-ek egiaztatuta.
3. **Isats-errekurtsioa TCOrekin (*Tail-Call Optimization*)**: `glob`-eko barne-ibilbide guztiak $O(1)$ pila-espazioko begizta natiboetara konpilatzen dira.
4. **Memoria determinista (`RMM1` / `RMM2`)**: tarteko egitura bakoitza bere azken irakurketa amaitzen den une zehatzean askatzen da, *Garbage Collector* gabe.

---

## 12.2. Artefaktu natiboak, inportazioa eta `glob` APIaren katalogo osoa

`ridgun-libs`-en, **`glob`** lehen mailako **lib** bat da, `src/main/ridgun/lib/glob.rg` bidean kokatua (`GLOB` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/glob.rglib` | Banaketa eta inportazio zuzena `import glob` bidez |
| **Fitxategi konpilatua** | `target/glob.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libglob.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import glob` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

### 12.2.1. `glob`-eko familia funtzionalen laburpena

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `glob match / glob match ci` | ASCII letra larri/xeheekiko sentikorra edo ez-sentikorra den glob bat-etortzea |
| `glob filter / glob any match` | `[String]` iragazten du edo zerrenda bateko ereduren bat bat datorren egiaztatzen du |
| `glob has magic` | Kate batek komodin-metakaraktereak (`*`, `?`, `[`) dituen detektatzen du |

### 12.2.2. `src/main/ridgun/lib/glob.rg`-eko mota eta sinadura guztien katalogoa

Jarraian duzu `src/main/ridgun/lib/glob.rg` fitxategian definitutako mota aljebraiko (`type`), eragile (`op ::`) eta funtzio-sinadura (`fn ::`) guztien inbentario osoa (`0` mota, `0` eragile eta `18` funtzio):

| # | Funtzioa / Sinadura (`fn ::`) | Itzulera-mota |
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

## 12.3. `glob` sakonki esploratzen: Funtzionalitate bakoitzaren urratsez urratseko adibideak

Ez da nahikoa sinadura-taula ikustea: `glob` lib-aren **funtzionalitate bakoitza** Ridgunen exekutagarriak diren adibide progresiboen bidez esploratuko dugu. Eguneroko bi errezeta taularatuekin hasiko gara eta ondoren xehetasunez ikusiko ditugu `src/test/ridgun/test glob.rg`-en egiaztatutako agertoki funtzional eta muga-kasu guztiak.

### 12.3.1. 1. adibidea: Fluxu nagusia estilo taularatuan `glob` erabiliz

Ikusi nola Ridgunen `=` ikurrak eta `glob` bidezko eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren, beharrezkoak ez diren aldagai aldakorrik edo ezkutuko albo-ondoriorik gabe:

```ridgun
import glob

fn :: seleccionar fuentes ridgun (archivos : [String]) => [String]
      seleccionar fuentes ridgun archivos =
        glob filter "test_[a-z]*.rg" archivos
```

### 12.3.2. 2. adibidea: Konposizio segurua eta muga-kasuen kudeaketa

`glob` lib-eko funtzio oro `|` guarda boolearrekin eta `ridgun-libs`-eko gainerako 32 lib-ekin konposatzeko diseinatuta dago:

```ridgun
import glob

fn :: es ruta excluida (ruta : String) => Bool
      es ruta excluida ruta =
        glob any match ["*.tmp", "*.bak", "target/*"] ruta
```

### 12.3.3. 3. adibidea: `*` eta `?` komodinak, muturren bat-etortze zehatza eta eredu hutseko muga-kasuak

Adibide praktiko honetan `glob` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 12.3.4. 4. adibidea: `[a-z]` karaktere-klaseak, `[!0-9]` / `[^0-9]` tarte ukatuak eta letra larri/xeheekiko bat-etortze sentiberagabea (`glob match ci`)

Adibide praktiko honetan `glob` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 12.3.5. 5. adibidea: Bide-zerrenden iragazketa masiboa (`glob filter`) eta eredu anitzen aurkako egiaztapena (`glob any match`)

Adibide praktiko honetan `glob` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

## 12.4. Kaputaren azpian: nola dagoen eraikia `glob` Ridgun hutsean (`src/main/ridgun/lib/glob.rg`)

`ridgun-libs`-en abantaila handienetako bat **C-ko kutxa beltzik ez egotea** da. `src/main/ridgun/lib/glob.rg` ireki dezakezu eta eragiketa bakoitza *pattern matching*, `|` / `|.` guarda-zuhaitzak eta isats-errekurtsioa (TCO) erabiliz nola inplementatuta dagoen irakurri. Ikus ditzagun bere benetako inplementazioaren funtsezko piezak:

### 12.4.1. Barne-inplementazioa: Bracket Character Class `[...]` Matching

Ikusi nola `glob.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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

### 12.4.2. Barne-inplementazioa: Wildcard (`*`, `?`, `[...]`) Matcher

Ikusi nola `glob.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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

## 12.5. Berme algoritmikoak, `RMM1`/`RMM2` memoria eta `glob`-en Urrezko 5 Arauak

- **Berme algoritmikoa eta segurtasunekoa**: Ondoz ondoko izarren kolapso automatikoa (`***` $\rightarrow$ `*`) atzera-egite erredundanteak saihesteko eta itxi gabeko `[` kortxeteen kudeaketa segurua.
- **$O(1)$ pila-konplexutasuna TCOrekin**: `src/main/ridgun/lib/glob.rg`-eko begizta errekurtsibo guztiak isats-posizioan daude; beraz, `ridgunc`-ek pila-hazkuntzarik gabeko jauzi natiboetara konpilatzen ditu.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test glob.rg` suite automatizatuaren bidez.

### `glob`-ekin programatzeko Urrezko 5 Arauak

1. **Deklaratu `import glob` fitxategiaren hasieran** eta baliatu zuriuneen eta azpimarren arteko baliokidetasuna zure kodea prosa bezala irakur dadin.
2. **Lerrokatu zure datu-hodiak `=` ikurrarekin**: kateatu `glob`-erako deiak izen propioko urratsetan eta utzi `stable format`-i zutabeak lerrokatzen.
3. **Baliatu `glob`-eko funtzio osoak zure `|` guardetan**: egiaztatu itzulera-balioak edo askatu ADTak *pattern matching* bidez, kanpoko sarrera beti baliozkoa dela suposatu beharrean.
4. **Saihestu egitura handiak kopiatzea eremu bat kontsultatu besterik behar ez baduzu**: gogoratu `RMM2`-n sarrerako argumentuek ez dituztela kontagailuak handitzen edo txikitzen (`+0` / `-0`).
5. **Konbinatu `glob` eta `test` (`import test`)**: idatzi beti asertzioak `assert equals` edo `assert true` erabiliz zure domeinuaren inbarianteak finkatzeko.

---

**13. kapituluan** **`diff`** lib-a sakonki esploratuko dugu (`diff` lib-a — LCS Algoritmoa, Edizio-distantzia, Unified Diff eta Adabakiak).
