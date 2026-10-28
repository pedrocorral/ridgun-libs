# 11. kapitulua: `regex` lib-a — $O(N \cdot M)$ Denbora Linealeko Thompson NFA Adierazpen Erregularren Motorra

## 11.1. Zergatik existitzen da `regex` lib-a? (Benetako arazoa eta Ridgun filosofia)

> *«Zergatik behar dut `regex` lib bat hutsetik Ridgun hutsean idatzia, betiko C liburutegi bat estekatu beharrean?»*

Hori da edozein sistema-ingeniarik `regex`-era iristean egiten duen lehen galdera. Eta erantzunak `ridgun-libs`-en filosofia osoa laburbiltzen du:

Izan gaitezen zintzoak: *backtracking* bidezko adierazpen erregularren motorrek erorketa global ospetsuak eragin dituzte (Cloudflare edo StackOverflow-n bezala) `(a+)+b` bezalako eredu batek hogeita hamar `a` jarraian jasotzen dituenean eta $O(2^N)$ denbora esponentzialean sartzen denean.

**`regex`** lib-ak zure adierazpen erregularrak (`.`, `*`, `+`, `?`, `|`, `()`, `[a-z]`, `[^...]`, `^`, `$`, `\d`, `\w`, `\s`) **Thompsonen automata finitu ez-determinista (NFA)** batera konpilatzen ditu eta egoera-multzoa urratsez urrats aurreratzen du **$O(N \cdot M)$** denbora lineal zorrotzean, **ReDoS erasoak matematikoki ezinezko** bihurtuz.

Ekosistema tradizional batean, **`REGEX`** domeinuko zereginak ebazteak C-ko kanpo-mendekotasunak arrastatzea, erakusle gordinekin borrokatzea, mota-bihurketa opakuak, egiaztatu gabeko salbuespenak edo zabor-biltzailearen geldialdi ustekabekoak jasatea dakar. Ridgunen, **`regex`** lib-ak (`src/main/ridgun/lib/regex.rg`) lau printzipio negoziatu ezinekin heltzen dio arazoari:

1. **Deklaratu `import regex` (edo `import regex as alias`) fitxategiaren hasieran**: lib bakoitzak `module :: regex` izen-espazioa definitzen du eta `--strict` moduan hitz anitzeko funtzioei zuriune naturalekin deitzen zaie beti.
2. **Kateatu zure datu-hodiak ezkerretik eskuinera `->` bidez**: idatzi `sarrera lehen urratsa -> bigarren urratsa -> emaitza`, erabili `(+ _ _ +)` maskarak sekuentziak desegituratzeko eta kendu `_ =` sententzia sekuentzialetan (edo baztertu `-> ()` bidez).
3. **Isats-errekurtsioa TCOrekin (*Tail-Call Optimization*)**: `regex`-eko barne-ibilbide guztiak $O(1)$ pila-espazioko begizta natiboetara konpilatzen dira.
4. **Memoria determinista (`RMM1` / `RMM2`)**: tarteko egitura bakoitza bere azken irakurketa amaitzen den une zehatzean askatzen da, *Garbage Collector* gabe.

---

## 11.2. Artefaktu natiboak, inportazioa eta `regex` APIaren katalogo osoa

`ridgun-libs`-en, **`regex`** lehen mailako **lib** bat da, `src/main/ridgun/lib/regex.rg` bidean kokatua (`REGEX` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/regex.rglib` | Banaketa eta inportazio zuzena `import regex` bidez |
| **Fitxategi konpilatua** | `target/regex.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libregex.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib bakoitzak bere izen-espazioa deklaratzen du `module :: regex` bidez: nahikoa da goiburuan `import regex` (edo `import regex as alias`) idaztea eta bere funtzioei zuriune naturalekin (`nire funtzioa x`) eta `->` hodiekin (`x nire funtzioa -> emaitza`) deitzea.

### 11.2.1. `regex`-eko familia funtzionalen laburpena

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `regex match / regex is match` | Kate osoaren bat-etortzea eta azpikate-bilaketa $O(N \cdot M)$ denbora linealean |
| `regex find / regex find all` | Bat datorren lehen azpikatea edo gainjartzerik gabeko guztiak erauzten ditu |
| `regex replace / regex replace all` | Adierazpen erregularraren lehen bat-etortzea edo guztiak ordezkatzen ditu |
| `regex split / regex escape` | Testua regex bereizle baten arabera zatitzen du eta metakaraktereak ihes egiten ditu |

### 11.2.2. `src/main/ridgun/lib/regex.rg`-eko mota eta sinadura guztien katalogoa

Jarraian duzu `src/main/ridgun/lib/regex.rg` fitxategian definitutako mota aljebraiko (`type`), eragile (`op ::`) eta funtzio-sinadura (`fn ::`) guztien inbentario osoa (`4` mota, `0` eragile eta `70` funtzio):

**`regex`-eko mota aljebraikoak eta erregistroak (`type`):**

```ridgun
type RegexMatch = matched: Bool, match_start: Int, match_end: Int, text: String
type ReNode = ReEmpty | ReChar Int | ReAny | ReClass Bool [Int] | ReShort Int | ReBol | ReEol | ReStar ReNode | RePlus ReNode | ReOpt ReNode | ReSeq ReNode ReNode | ReAlt ReNode ReNode
type ReParseRes = ReParseRes ReNode Int
type NfaInst = InstChar Int Int | InstAny Int | InstClass Bool [Int] Int | InstShort Int Int | InstBol Int | InstEol Int | InstSplit Int Int | InstJump Int | InstMatch
```

| # | Funtzioa / Sinadura (`fn ::`) | Itzulera-mota |
|---|---|---|
| `1` | `fn :: re_is_digit Int` | `Bool` |
| `2` | `fn :: re_is_word Int` | `Bool` |
| `3` | `fn :: re_is_space Int` | `Bool` |
| `4` | `fn :: re_match_short Int Int` | `Bool` |
| `5` | `fn :: re_in_ranges Int [Int]` | `Bool` |
| `6` | `fn :: re_escape_char Int` | `ReNode` |
| `7` | `fn :: re_class_char String Int Int` | `(Int Int)` |
| `8` | `fn :: re_fst_int (Int Int)` | `Int` |
| `9` | `fn :: re_snd_int (Int Int)` | `Int` |
| `10` | `fn :: re_parse_class_items String Int Int [Int]` | `([Int] Int)` |
| `11` | `fn :: re_parse_class_item_step String Int Int [Int]` | `([Int] Int)` |
| `12` | `fn :: re_parse_class_range_check String Int Int Int [Int]` | `([Int] Int)` |
| `13` | `fn :: re_parse_class_range_hi String Int Int Int [Int]` | `([Int] Int)` |
| `14` | `fn :: re_fst_ranges ([Int] Int)` | `[Int]` |
| `15` | `fn :: re_snd_pos ([Int] Int)` | `Int` |
| `16` | `fn :: re_parse_class String Int Int` | `ReParseRes` |
| `17` | `fn :: re_finish_class Bool ([Int] Int)` | `ReParseRes` |
| `18` | `fn :: re_res_node ReParseRes` | `ReNode` |
| `19` | `fn :: re_res_pos ReParseRes` | `Int` |
| `20` | `fn :: re_parse_group String Int Int` | `ReParseRes` |
| `21` | `fn :: re_close_group ReNode String Int Int` | `ReParseRes` |
| `22` | `fn :: re_parse_atom String Int Int` | `ReParseRes` |
| `23` | `fn :: re_parse_postfix ReNode String Int Int` | `ReParseRes` |
| `24` | `fn :: re_parse_factor String Int Int` | `ReParseRes` |
| `25` | `fn :: re_is_seq_stop Int` | `Bool` |
| `26` | `fn :: re_parse_seq_loop ReNode String Int Int` | `ReParseRes` |
| `27` | `fn :: re_parse_seq_step ReNode String Int Int` | `ReParseRes` |
| `28` | `fn :: re_parse_seq String Int Int` | `ReParseRes` |
| `29` | `fn :: re_parse_seq_first String Int Int` | `ReParseRes` |
| `30` | `fn :: re_parse_alt_loop ReNode String Int Int` | `ReParseRes` |
| `31` | `fn :: re_parse_alt_branch ReNode String Int Int` | `ReParseRes` |
| `32` | `fn :: re_parse_alt String Int Int` | `ReParseRes` |
| `33` | `fn :: nfa_len [NfaInst]` | `Int` |
| `34` | `fn :: re_compile_seq ReNode ReNode Int` | `[NfaInst]` |
| `35` | `fn :: re_compile_opt ReNode Int` | `[NfaInst]` |
| `36` | `fn :: re_compile_star ReNode Int` | `[NfaInst]` |
| `37` | `fn :: re_compile_plus ReNode Int` | `[NfaInst]` |
| `38` | `fn :: re_compile_alt ReNode ReNode Int` | `[NfaInst]` |
| `39` | `fn :: re_compile_node ReNode Int` | `[NfaInst]` |
| `40` | `fn :: re_compile String` | `[NfaInst]` |
| `41` | `fn :: nfa_inst_at [NfaInst] Int` | `NfaInst` |
| `42` | `fn :: nfa_set_has [Int] Int` | `Bool` |
| `43` | `fn :: nfa_closure [NfaInst] [Int] Int Int [Int]` | `[Int]` |
| `44` | `fn :: nfa_closure_inst [NfaInst] Int [Int] Int Int [Int] NfaInst` | `[Int]` |
| `45` | `fn :: nfa_step_one NfaInst Int` | `[Int]` |
| `46` | `fn :: nfa_step [NfaInst] [Int] Int` | `[Int]` |
| `47` | `fn :: nfa_is_match_inst NfaInst` | `Bool` |
| `48` | `fn :: nfa_has_match [NfaInst] [Int]` | `Bool` |
| `49` | `fn :: nfa_update_last [NfaInst] [Int] Int Int` | `Int` |
| `50` | `fn :: nfa_sim_loop [NfaInst] String Int Int [Int] Int` | `Int` |
| `51` | `fn :: nfa_sim_step [NfaInst] String Int Int [Int] Int` | `Int` |
| `52` | `fn :: nfa_longest_from [NfaInst] String Int Int` | `Int` |
| `53` | `fn :: nfa_full_loop [NfaInst] String Int Int [Int]` | `Bool` |
| `54` | `fn :: nfa_full_step [NfaInst] String Int Int [Int]` | `Bool` |
| `55` | `fn :: regex match String String` | `Bool` |
| `56` | `fn :: nfa_find_from [NfaInst] String Int Int` | `RegexMatch` |
| `57` | `fn :: nfa_find_check [NfaInst] String Int Int Int` | `RegexMatch` |
| `58` | `fn :: regex find String String` | `RegexMatch` |
| `59` | `fn :: regex is match String String` | `Bool` |
| `60` | `fn :: nfa_find_all_loop [NfaInst] String Int Int [RegexMatch]` | `[RegexMatch]` |
| `61` | `fn :: nfa_find_all_step [NfaInst] String Int Int [RegexMatch] Int` | `[RegexMatch]` |
| `62` | `fn :: regex find all String String` | `[RegexMatch]` |
| `63` | `fn :: regex replace String String String` | `String` |
| `64` | `fn :: re_apply_replace RegexMatch String String` | `String` |
| `65` | `fn :: nfa_replace_all_loop [NfaInst] String String Int Int String` | `String` |
| `66` | `fn :: nfa_replace_all_step [NfaInst] String String Int Int String Int` | `String` |
| `67` | `fn :: regex replace all String String String` | `String` |
| `68` | `fn :: nfa_split_loop [NfaInst] String Int Int Int [String]` | `[String]` |
| `69` | `fn :: nfa_split_step [NfaInst] String Int Int Int [String] Int` | `[String]` |
| `70` | `fn :: regex split String String` | `[String]` |

---

## 11.3. `regex` sakonki esploratzen: Funtzionalitate bakoitzaren urratsez urratseko adibideak

Ez da nahikoa sinadura-taula ikustea: `regex` lib-aren **funtzionalitate bakoitza** Ridgunen exekutagarriak diren adibide progresiboen bidez esploratuko dugu. Eguneroko bi errezeta taularatuekin hasiko gara eta ondoren xehetasunez ikusiko ditugu `src/test/ridgun/test regex.rg`-en egiaztatutako agertoki funtzional eta muga-kasu guztiak.

### 11.3.1. 1. adibidea: Fluxu nagusia estilo taularatuan `regex` erabiliz

Ikusi nola Ridgunen `=` ikurrak eta `regex` bidezko eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren, beharrezkoak ez diren aldagai aldakorrik edo ezkutuko albo-ondoriorik gabe:

```ridgun
import regex

fn :: extraer codigos postales String => [String]
      extraer codigos postales texto =
        regex find all "\d+" texto
```

### 11.3.2. 2. adibidea: Konposizio segurua eta muga-kasuen kudeaketa

`regex` lib-eko funtzio oro `|` guarda boolearrekin eta `ridgun-libs`-eko gainerako 32 lib-ekin konposatzeko diseinatuta dago:

```ridgun
import regex

fn :: censurar telefonos String => Bool String
      censurar telefonos comentario =
        regex is match "\d+-\d+" comentario -> tiene
        regex replace all "\d+-\d+" comentario "[TELEFONO]" -> limpio
        (tiene, limpio)
```

### 11.3.3. 3. adibidea: Aingurak (`^`, `$`), zenbatzaileak (`*`, `+`, `?`), txandakatzea (`|`), taldeak `(...)`, klaseak `[a-z0-9]` eta lasterbideak (`\d`, `\w`, `\s`)

Adibide praktiko honetan `regex` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test_regex_operators_and_classes => ()
      test_regex_operators_and_classes =
        assert true (regex match "" "") "AC1: empty pattern matches empty string"
        assert false (regex match "" "nonempty") "AC1: empty pattern rejects non-empty on full match"
        assert true (regex match 'a(b|c)+d?e*' "abcbdeee") "AC1: alternation group plus opt star"
        assert true (regex match 'a(b|c)+d?e*' "ac") "AC1: opt and star match zero occurrences"
        assert false (regex match 'a(b|c)+d?e*' "ade") "AC1: plus requires at least one"
        assert true (regex match '(foo|bar|baz)+' "barfoobazbar") "AC1: multi-branch alternation with plus"
        assert false (regex match '(foo|bar|baz)+' "barquxfoo") "AC1: multi-branch alternation rejects unknown"
        assert true (regex match '[a-zA-Z_][a-zA-Z0-9_]*' "_valid_Identifier_99") "AC1: identifier character class"
        assert false (regex match '[a-zA-Z_][a-zA-Z0-9_]*' "9invalid") "AC1: identifier rejects leading digit"
        assert true (regex match '[^0-9]+' "hello_world") "AC1: negated char class"
        assert false (regex match '[^0-9]+' "hello42") "AC1: negated char class rejects digits"
        assert true (regex match '\w+\s+\d+' "agent   007") "AC1: shorthand escapes \\w \\s \\d"
        assert true (regex match '\D+\S+' "abc_123") "AC1: negated shorthand escapes \\D \\S"
        assert true (regex match 'v\d+\.\d+\.\d+' "v0.9.16") "AC1: escaped dot literal"
        assert false (regex match 'v\d+\.\d+\.\d+' "v0X9Y16") "AC1: escaped dot rejects non-dot"
        assert true (regex is match '^hello' "hello world") "AC1: bol anchor matches start"
        assert false (regex is match '^world' "hello world") "AC1: bol anchor rejects middle"
        assert true (regex is match 'world$' "hello world") "AC1: eol anchor matches end"
        assert false (regex is match 'hello$' "hello world") "AC1: eol anchor rejects prefix"
        assert true (regex is match '^exact$' "exact") "AC1: anchored ^exact$ matches full string"
        assert false (regex is match '^exact$' "not exact") "AC1: anchored ^exact$ rejects extra chars"
        -- Russ Cox pathological backtracking benchmarks (exponential in backtracking engines, O(N*M) in Thompson NFA)
        assert false (regex match '(a+)+b' "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaac") "AC1: Thompson NFA immune to (a+)+b ReDoS"
        assert false (regex match '(a|aa)+b' "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaac") "AC1: Thompson NFA immune to (a|aa)+b ReDoS"
        assert true (regex match 'a?a?a?a?a?a?a?a?aaaaaaaa' "aaaaaaaa") "AC1: Russ Cox a?^n a^n vector"
        ()
```

### 11.3.4. 4. adibidea: Bat-etortzeen erauzketa (`regex find`, `regex find all`), ordezkapena (`regex replace`, `regex replace all`) eta zatiketa (`regex split`)

Adibide praktiko honetan `regex` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test_regex_find_replace_split => ()
      test_regex_find_replace_split =
        m1 = regex find '\d+' "item #42 and #99"
        assert true (matched m1) "AC2: find matched"
        assert int equals (match_start m1) 6 "AC2: find start"
        assert int equals (match_end m1) 8 "AC2: find end"
        assert str eq (text m1) "42" "AC2: find text"

        m_none = regex find '\d+' "no digits here"
        assert false (matched m_none) "AC2: find returns matched=False when absent"

        all_m = regex find all '[a-z]+=\d+' "id=10, port=8080, ttl=60"
        assert int equals (re_match_count all_m) 3 "AC2: find all key=val count"
        assert str eq (text (re_match_at all_m 0)) "id=10" "AC2: find all first match"
        assert str eq (text (re_match_at all_m 1)) "port=8080" "AC2: find all second match"
        assert str eq (text (re_match_at all_m 2)) "ttl=60" "AC2: find all third match"

        r1 = regex replace '\d+' "X" "v1.2.3"
        assert str eq r1 "vX.2.3" "AC3: replace first"
        r_no = regex replace '\d+' "X" "abc"
        assert str eq r_no "abc" "AC3: replace with no match returns original"
        r2 = regex replace all '\d+' "X" "v1.22.333"
        assert str eq r2 "vX.X.X" "AC3: replace all"

        parts = regex split '\s*[,;]\s*' "alpha, beta ;  gamma,delta"
        assert int equals (re_str_count parts) 4 "AC3: split count"
        assert str eq (re_str_at parts 0) "alpha" "AC3: split[0]"
        assert str eq (re_str_at parts 1) "beta" "AC3: split[1]"
        assert str eq (re_str_at parts 2) "gamma" "AC3: split[2]"
        assert str eq (re_str_at parts 3) "delta" "AC3: split[3]"
        ()
```

### 11.3.5. 5. adibidea: Identifikatzaileen baliozkotzailea eta aztarnen anonimizatzailea $O(N \cdot M)$ denbora linealean Thompson NFA bidez (`regex is match`, `regex replace all`, `regex split`)

Adibide praktiko honetan `regex` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
import regex

fn :: limpiar traza y validar id (usuario_id : String) (linea_log : String) => (Bool, String, [String])
      limpiar traza y validar id usuario_id linea_log =
        id_valido = regex is match "^usr_[a-z0-9]+$" usuario_id
        sin_ips   = regex replace all "\d+\.\d+\.\d+\.\d+" linea_log "[IP-REDACTADA]"
        tokens    = regex split "\s+" sin_ips
        (id_valido, sin_ips, tokens)
```

---

## 11.4. Kaputaren azpian: nola dagoen eraikia `regex` Ridgun hutsean (`src/main/ridgun/lib/regex.rg`)

`ridgun-libs`-en abantaila handienetako bat **C-ko kutxa beltzik ez egotea** da. `src/main/ridgun/lib/regex.rg` ireki dezakezu eta eragiketa bakoitza *pattern matching*, `|` / `|.` guarda-zuhaitzak eta isats-errekurtsioa (TCO) erabiliz nola inplementatuta dagoen irakurri. Ikus ditzagun bere benetako inplementazioaren funtsezko piezak:

### 11.4.1. Barne-inplementazioa: Character Class & Shorthand Helpers

Ikusi nola `regex.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
module :: regex

fn :: re is digit Int => Bool
      re is digit c = c >= 48 and c <= 57

fn :: re is word Int => Bool
      re is word c = (c >= 48 and c <= 57) or (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or c == 95

fn :: re is space Int => Bool
      re is space c = c == 32 or c == 9 or c == 10 or c == 13 or c == 11 or c == 12

fn :: re match short Int Int => Bool
      re match short 100 c = re is digit c
      re match short 68 c = not (re is digit c)
      re match short 119 c = re is word c
      re match short 87 c = not (re is word c)
      re match short 115 c = re is space c
      re match short 83 c = not (re is space c)
      re match short _ _ = False

fn :: re in ranges Int [Int] => Bool
      re in ranges _ [] = False
      re in ranges _ (_:[]) = False
      re in ranges c (lo:hi:rs) =
        | c >= lo and c <= hi = True
        | otherwise = re in ranges c rs
```

### 11.4.2. Barne-inplementazioa: Thompson NFA Compiler (`ReNode` -> `[NfaInst]`)

Ikusi nola `regex.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: nfa len [NfaInst] => Int
      nfa len [] = 0
      nfa len (_:rest) = 1 + (nfa len rest)

fn :: re compile seq ReNode ReNode Int => [NfaInst]
      re compile seq a b start_id =
        insts_a = re compile node a start_id
        mid_id = start_id + (nfa len insts_a)
        insts_b = re compile node b mid_id
        insts_a :: insts_b

fn :: re compile opt ReNode Int => [NfaInst]
      re compile opt a start_id =
        body = re compile node a (start_id + 1)
        end_id = start_id + 1 + (nfa len body)
        [InstSplit (start_id + 1) end_id] :: body

fn :: re compile star ReNode Int => [NfaInst]
      re compile star a start_id =
        body = re compile node a (start_id + 1)
        end_id = start_id + 2 + (nfa len body)
        ([InstSplit (start_id + 1) end_id] :: body) :: [InstJump start_id]

fn :: re compile plus ReNode Int => [NfaInst]
      re compile plus a start_id =
        body = re compile node a start_id
        split_id = start_id + (nfa len body)
        body :: [InstSplit start_id (split_id + 1)]

fn :: re compile alt ReNode ReNode Int => [NfaInst]
      re compile alt a b start_id =
        body_a = re compile node a (start_id + 1)
        jump_id = start_id + 1 + (nfa len body_a)
        start_b = jump_id + 1
        body_b = re compile node b start_b
        end_id = start_b + (nfa len body_b)
        (([InstSplit (start_id + 1) start_b] :: body_a) :: [InstJump end_id]) :: body_b

fn :: re compile node ReNode Int => [NfaInst]
      re compile node ReEmpty _ = []
      re compile node (ReChar c) start_id = [InstChar c (start_id + 1)]
      re compile node ReAny start_id = [InstAny (start_id + 1)]
      re compile node (ReClass neg rngs) start_id = [InstClass neg rngs (start_id + 1)]
      re compile node (ReShort k) start_id = [InstShort k (start_id + 1)]
      re compile node ReBol start_id = [InstBol (start_id + 1)]
      re compile node ReEol start_id = [InstEol (start_id + 1)]
      re compile node (ReOpt a) start_id = re compile opt a start_id
      re compile node (ReStar a) start_id = re compile star a start_id
      re compile node (RePlus a) start_id = re compile plus a start_id
      re compile node (ReSeq a b) start_id = re compile seq a b start_id
      re compile node (ReAlt a b) start_id = re compile alt a b start_id

fn :: re compile String => [NfaInst]
      re compile pat =
        re parse alt pat 0 (str len pat) -> parsed
        (re compile node (re res node parsed) 0) :: [InstMatch]
```

### 11.4.3. Barne-inplementazioa: Linear-Time Thompson NFA State-Set Simulation

Ikusi nola `regex.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: nfa inst at [NfaInst] Int => NfaInst
      nfa inst at [] _ = InstMatch
      nfa inst at (i:_) 0 = i
      nfa inst at (_:rest) idx = nfa inst at rest (idx - 1)

fn :: nfa set has [Int] Int => Bool
      nfa set has [] _ = False
      nfa set has (x:xs) v =
        | x == v = True
        | otherwise = nfa set has xs v

fn :: nfa closure [NfaInst] [Int] Int Int [Int] => [Int]
      nfa closure _ [] _ _ visited = visited
      nfa closure prog (s:ss) pos len visited =
        | nfa set has visited s = nfa closure prog ss pos len visited
        | otherwise = nfa closure inst prog s ss pos len (visited :: [s]) (nfa inst at prog s)

fn :: nfa closure inst [NfaInst] Int [Int] Int Int [Int] NfaInst => [Int]
      nfa closure inst prog _ ss pos len vis (InstJump out) = nfa closure prog ([out] :: ss) pos len vis
      nfa closure inst prog _ ss pos len vis (InstSplit o1 o2) = nfa closure prog ([o1, o2] :: ss) pos len vis
      nfa closure inst prog _ ss pos len vis (InstBol out) =
        | pos == 0 = nfa closure prog ([out] :: ss) pos len vis
        | otherwise = nfa closure prog ss pos len vis
      nfa closure inst prog _ ss pos len vis (InstEol out) =
        | pos == len = nfa closure prog ([out] :: ss) pos len vis
        | otherwise = nfa closure prog ss pos len vis
      nfa closure inst prog _ ss pos len vis _ = nfa closure prog ss pos len vis

fn :: nfa step one NfaInst Int => [Int]
      nfa step one (InstChar expected out) c =
        | c == expected = [out]
        | otherwise = []
      nfa step one (InstAny out) c =
        | c != 10 = [out]
        | otherwise = []
      nfa step one (InstClass neg rngs out) c =
        | (re in ranges c rngs) != neg = [out]
        | otherwise = []
      nfa step one (InstShort kind out) c =
        | re match short kind c = [out]
        | otherwise = []
      nfa step one _ _ = []

fn :: nfa step [NfaInst] [Int] Int => [Int]
      nfa step _ [] _ = []
      nfa step prog (s:ss) c = (nfa step one (nfa inst at prog s) c) :: (nfa step prog ss c)

fn :: nfa is match inst NfaInst => Bool
      nfa is match inst InstMatch = True
      nfa is match inst _ = False

fn :: nfa has match [NfaInst] [Int] => Bool
      nfa has match _ [] = False
      nfa has match prog (s:ss) =
        | nfa is match inst (nfa inst at prog s) = True
        | otherwise = nfa has match prog ss

fn :: nfa update last [NfaInst] [Int] Int Int => Int
      nfa update last prog active cand cur =
        | nfa has match prog active = cand
        | otherwise = cur

fn :: nfa sim loop [NfaInst] String Int Int [Int] Int => Int
      nfa sim loop _ _ _ _ [] last_m = last_m
      nfa sim loop prog input pos len active last_m =
        | pos >= len = last_m
        | otherwise = nfa sim step prog input pos len active last_m

fn :: nfa sim step [NfaInst] String Int Int [Int] Int => Int
      nfa sim step prog input pos len active last_m =
        str char at input pos -> c
        nfa closure prog (nfa step prog active c) (pos + 1) len [] -> next_act
        nfa update last prog next_act (pos + 1) last_m -> next_last
        nfa sim loop prog input (pos + 1) len next_act next_last

fn :: nfa longest from [NfaInst] String Int Int => Int
      nfa longest from prog input pos len =
        nfa closure prog [0] pos len [] -> init_act
        nfa update last prog init_act pos (0 - 1) -> init_last
        nfa sim loop prog input pos len init_act init_last

fn :: nfa full loop [NfaInst] String Int Int [Int] => Bool
      nfa full loop _ _ _ _ [] = False
      nfa full loop prog input pos len active =
        | pos >= len = nfa has match prog active
        | otherwise = nfa full step prog input pos len active

fn :: nfa full step [NfaInst] String Int Int [Int] => Bool
      nfa full step prog input pos len active =
        str char at input pos -> c
        nfa closure prog (nfa step prog active c) (pos + 1) len [] -> next_act
        nfa full loop prog input (pos + 1) len next_act
```

### 11.4.4. Barne-inplementazioa: Public Regex API (`API-REGEX-001`)

Ikusi nola `regex.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: regex match String String => Bool
      regex match pat input =
        pat re compile -> prog
        input str len -> len
        nfa closure prog [0] 0 len [] -> init_act
        nfa full loop prog input 0 len init_act

fn :: nfa find from [NfaInst] String Int Int => RegexMatch
      nfa find from prog input pos len =
        | pos > len = RegexMatch False (0 - 1) (0 - 1) ""
        | otherwise = nfa find check prog input pos len (nfa longest from prog input pos len)

fn :: nfa find check [NfaInst] String Int Int Int => RegexMatch
      nfa find check prog input pos len end_pos =
        | end_pos >= pos = RegexMatch True pos end_pos (str slice input pos end_pos)
        | otherwise = nfa find from prog input (pos + 1) len

fn :: regex find String String => RegexMatch
      regex find pat input =
        pat re compile -> prog
        nfa find from prog input 0 (str len input)

fn :: regex is match String String => Bool
      regex is match pat input = regex find pat input -> matched

fn :: nfa find all loop [NfaInst] String Int Int [RegexMatch] => [RegexMatch]
      nfa find all loop prog input pos len acc =
        | pos > len = acc
        | otherwise = nfa find all step prog input pos len acc (nfa longest from prog input pos len)

fn :: nfa find all step [NfaInst] String Int Int [RegexMatch] Int => [RegexMatch]
      nfa find all step prog input pos len acc end_pos =
        | end_pos > pos = nfa find all loop prog input end_pos len (acc :: [RegexMatch True pos end_pos (str slice input pos end_pos)])
        | end_pos == pos = nfa find all loop prog input (pos + 1) len (acc :: [RegexMatch True pos pos ""])
        | otherwise = nfa find all loop prog input (pos + 1) len acc

fn :: regex find all String String => [RegexMatch]
      regex find all pat input =
        pat re compile -> prog
        nfa find all loop prog input 0 (str len input) []

fn :: regex replace String String String => String
      regex replace pat repl input =
        regex find pat input -> m
        re apply replace m repl input

fn :: re apply replace RegexMatch String String => String
      re apply replace m repl input =
        | not (matched m) = input
        | otherwise = (str slice input 0 (match_start m)) + repl + (str slice input (match_end m) (str len input))

fn :: nfa replace all loop [NfaInst] String String Int Int String => String
      nfa replace all loop prog repl input pos len acc =
        | pos >= len = acc
        | otherwise = nfa replace all step prog repl input pos len acc (nfa longest from prog input pos len)

fn :: nfa replace all step [NfaInst] String String Int Int String Int => String
      nfa replace all step prog repl input pos len acc end_pos =
        | end_pos > pos = nfa replace all loop prog repl input end_pos len (acc + repl)
        | otherwise = nfa replace all loop prog repl input (pos + 1) len (acc + (str slice input pos (pos + 1)))

fn :: regex replace all String String String => String
      regex replace all pat repl input =
        pat re compile -> prog
        nfa replace all loop prog repl input 0 (str len input) ""

fn :: nfa split loop [NfaInst] String Int Int Int [String] => [String]
      nfa split loop prog input pos len last_s acc =
        | pos >= len = acc :: [str slice input last_s len]
        | otherwise = nfa split step prog input pos len last_s acc (nfa longest from prog input pos len)

fn :: nfa split step [NfaInst] String Int Int Int [String] Int => [String]
      nfa split step prog input pos len last_s acc end_pos =
        | end_pos > pos = nfa split loop prog input end_pos len end_pos (acc :: [str slice input last_s pos])
        | otherwise = nfa split loop prog input (pos + 1) len last_s acc

fn :: regex split String String => [String]
      regex split pat input =
        pat re compile -> prog
        nfa split loop prog input 0 (str len input) 0 []
```

---

## 11.5. Berme algoritmikoak, `RMM1`/`RMM2` memoria eta `regex`-en Urrezko 5 Arauak

- **Berme algoritmikoa eta segurtasunekoa**: NFA egoera-multzoaren simulazioa pilaren errekurtsio kontrolatu gaberik gabe eta $O(N \cdot M)$ denbora bermatua baita `(a+)+b` eredu patologikoen aurrean ere.
- **$O(1)$ pila-konplexutasuna TCOrekin**: `src/main/ridgun/lib/regex.rg`-eko begizta errekurtsibo guztiak isats-posizioan daude; beraz, `ridgunc`-ek pila-hazkuntzarik gabeko jauzi natiboetara konpilatzen ditu.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test regex.rg` suite automatizatuaren bidez.

### `regex`-ekin programatzeko Urrezko 5 Arauak

1. **Deklaratu `import regex` fitxategiaren hasieran** eta baliatu zuriuneen eta azpimarren arteko baliokidetasuna zure kodea prosa bezala irakur dadin.
2. **Lerrokatu zure datu-hodiak `=` ikurrarekin**: kateatu `regex`-erako deiak izen propioko urratsetan eta utzi `stable format`-i zutabeak lerrokatzen.
3. **Baliatu `regex`-eko funtzio osoak zure `|` guardetan**: egiaztatu itzulera-balioak edo askatu ADTak *pattern matching* bidez, kanpoko sarrera beti baliozkoa dela suposatu beharrean.
4. **Saihestu egitura handiak kopiatzea eremu bat kontsultatu besterik behar ez baduzu**: gogoratu `RMM2`-n sarrerako argumentuek ez dituztela kontagailuak handitzen edo txikitzen (`+0` / `-0`).
5. **Konbinatu `regex` eta `test` (`import test`)**: idatzi beti asertzioak `assert equals` edo `assert true` erabiliz zure domeinuaren inbarianteak finkatzeko.

---

**12. kapituluan** **`glob`** lib-a sakonki esploratuko dugu (`glob` lib-a — Komodin-ereduak (`*`, `?`, `[a-z]`) eta Zerrenden Iragazketa).
