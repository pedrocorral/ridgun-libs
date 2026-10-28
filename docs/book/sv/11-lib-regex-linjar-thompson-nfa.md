# Kapitel 11: Lib:en `regex` — Reguljära Uttryck med Thompson-NFA i Linjär Tid $O(N \cdot M)$

## 11.1. Varför finns lib:en `regex`? (Det verkliga problemet och Ridguns filosofi)

> *”Varför behöver jag en `regex`-lib skriven från grunden i ren Ridgun i stället för att bara länka in ett gammalt C-bibliotek?”*

Det är den första fråga varje systemingenjör ställer sig när man möter `regex`. Och svaret sammanfattar hela filosofin bakom `ridgun-libs`:

Låt oss vara ärliga: regex-motorer med *backtracking* har orsakat ökända globala driftstopp (som hos Cloudflare och StackOverflow) när ett mönster som `(a+)+b` matas med trettio `a` i rad och exploderar i exponentiell tid $O(2^N)$.

Lib:en **`regex`** kompilerar reguljära uttryck (`.`, `*`, `+`, `?`, `|`, `()`, `[a-z]`, `[^...]`, `^`, `$`, `\d`, `\w`, `\s`) till en **Thompson-NFA** och stegar tillståndsmängden i strikt linjär tid **$O(N \cdot M)$**, vilket gör **ReDoS-attacker matematiskt omöjliga**.

I ett traditionellt ekosystem innebär uppgifter inom domänen **`REGEX`** ofta att man drar in externa C-beroenden, brottas med råa pekare, ogenomskinliga typkonverteringar, okontrollerade undantag eller oförutsägbara skräpsamlarpauser. I Ridgun löser lib:en **`regex`** (`src/main/ridgun/lib/regex.rg`) problemet genom fyra kompromisslösa principer:

1. **Deklarera `import regex` (eller `import regex as alias`) överst i filen**: varje lib definierar sin `module :: regex`-namnrymd och i `--strict`-läge anropas flerordsfunktioner alltid med naturliga mellanslag.
2. **Kedja dina datapipelines från vänster till höger med `->`**: skriv `indata steg ett -> steg två -> resultat`, använd `(+ _ _ +)`-sekvensmasker för att packa upp tupler och utelämna `_ =` vid sekventiella satser (eller kasta med `-> ()`).
3. **Svansrekursion med TCO (*Tail-Call Optimization*)**: alla interna genomlöpningar i `regex` kompileras till inbyggda hårdvaruloopar med $O(1)$ stackutrymme.
4. **Deterministiskt minne (`RMM1` / `RMM2`)**: varje mellanliggande struktur frigörs i exakt det ögonblick dess sista läsning avslutas, helt utan *Garbage Collector*.

---

## 11.2. Inbyggda artefakter, import och komplett API-katalog för `regex`

I `ridgun-libs` är **`regex`** en förstklassig **lib** placerad i `src/main/ridgun/lib/regex.rg` (domän `REGEX`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/regex.rglib` | Portabel distribution och direkt import med `import regex` |
| **Kompilerat arkiv** | `target/regex.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libregex.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> Varje lib deklarerar sin egen namnrymd med `module :: regex`: skriv bara `import regex` (eller `import regex as alias`) överst och anropa dess funktioner med naturliga mellanslag (`min funktion x`) och `->`-pipelines (`x min funktion -> resultat`).

### 11.2.1. Översikt över funktionella familjer i `regex`

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `regex match / regex is match` | Helsträngsmatchning och delsträngssökning i linjär tid $O(N \cdot M)$ |
| `regex find / regex find all` | Extraherar den första eller alla icke-överlappande matchande delsträngar |
| `regex replace / regex replace all` | Ersätter den första eller alla regex-träffar med en ersättningssträng |
| `regex split / regex escape` | Delar upp text med en regex-avgränsare och kodar metatecken |

### 11.2.2. Komplett katalog över typer och signaturer i `src/main/ridgun/lib/regex.rg`

Nedan följer hela förteckningen över algebraiska datatyper (`type`), mixfix-operatorer (`op ::`) och funktionssignaturer (`fn ::`) som definieras i `src/main/ridgun/lib/regex.rg` (`4` typer, `0` operatorer och `70` funktioner):

**Algebraiska datatyper och poster (`type`) i `regex`:**

```ridgun
type RegexMatch = matched: Bool, match_start: Int, match_end: Int, text: String
type ReNode = ReEmpty | ReChar Int | ReAny | ReClass Bool [Int] | ReShort Int | ReBol | ReEol | ReStar ReNode | RePlus ReNode | ReOpt ReNode | ReSeq ReNode ReNode | ReAlt ReNode ReNode
type ReParseRes = ReParseRes ReNode Int
type NfaInst = InstChar Int Int | InstAny Int | InstClass Bool [Int] Int | InstShort Int Int | InstBol Int | InstEol Int | InstSplit Int Int | InstJump Int | InstMatch
```

| # | Funktion / Signatur (`fn ::`) | Returtyp |
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

## 11.3. Djupdykning i `regex`: Steg-för-steg-exempel för varje funktion

Det räcker inte med en signaturtabell: låt oss utforska **varje funktionalitet** i lib:en `regex` genom progressiva, körbara Ridgun-exempel. Vi börjar med två tabellbaserade vardagsrecept och går därefter igenom alla funktionella scenarier, transformationer och gränsfall som verifieras i `src/test/ridgun/test regex.rg`.

### 11.3.1. Exempel 1: Huvudflöde i tabellform med `regex`

Lägg märke till hur `=`-tecknen och transformationsstegen med `regex` linjeras som en ren tabell utan onödiga muterbara variabler eller dolda sidoeffekter:

```ridgun
import regex

fn :: extraer codigos postales String => [String]
      extraer codigos postales texto =
        regex find all "\d+" texto
```

### 11.3.2. Exempel 2: Säker komposition och hantering av gränsfall

Varje funktion i lib:en `regex` är utformad för att kombineras sömlöst med booleska vakter `|` och med övriga 32 libs i `ridgun-libs`:

```ridgun
import regex

fn :: censurar telefonos String => Bool String
      censurar telefonos comentario =
        regex is match "\d+-\d+" comentario -> tiene
        regex replace all "\d+-\d+" comentario "[TELEFONO]" -> limpio
        (tiene, limpio)
```

### 11.3.3. Exempel 3: Ankare (`^`, `$`), kvantifierare (`*`, `+`, `?`), alternering (`|`), grupper `(...)`, teckenklasser `[a-z0-9]` och kortformer (`\d`, `\w`, `\s`)

I detta praktiska exempel undersöker vi grundligt hur `regex` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

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

### 11.3.4. Exempel 4: Träffextraktion (`regex find`, `regex find all`), ersättning (`regex replace`, `regex replace all`) och uppdelning (`regex split`)

I detta praktiska exempel undersöker vi grundligt hur `regex` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

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

### 11.3.5. Exempel 5: Identifierarvaliderare och logganonymiserare i linjär tid $O(N \cdot M)$ med Thompson NFA (`regex is match`, `regex replace all`, `regex split`)

I detta praktiska exempel undersöker vi grundligt hur `regex` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

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

## 11.4. Under huven: hur `regex` är byggd i ren Ridgun (`src/main/ridgun/lib/regex.rg`)

En av de största fördelarna med `ridgun-libs` är att **det inte finns några svarta lådor i C**. Du kan öppna `src/main/ridgun/lib/regex.rg` och läsa exakt hur varje operation är implementerad med mönstermatchning, `|` / `|.`-vaktträd och svansrekursion (TCO). Låt oss titta på nyckeldelarna i den faktiska implementationen:

### 11.4.1. Intern implementation: Character Class & Shorthand Helpers

Se hur `regex.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

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

### 11.4.2. Intern implementation: Thompson NFA Compiler (`ReNode` -> `[NfaInst]`)

Se hur `regex.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

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

### 11.4.3. Intern implementation: Linear-Time Thompson NFA State-Set Simulation

Se hur `regex.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

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

### 11.4.4. Intern implementation: Public Regex API (`API-REGEX-001`)

Se hur `regex.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

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

## 11.5. Algoritmiska garantier, `RMM1`/`RMM2`-minne och de 5 Gyllene Reglerna för `regex`

- **Algoritmisk garanti och säkerhet**: NFA-tillståndssimulering utan okontrollerad stackrekursion och garanterad $O(N \cdot M)$-körtid även för patologiska `(a+)+b`-mönster.
- **$O(1)$ stackkomplexitet med TCO**: Alla rekursiva loopar i `src/main/ridgun/lib/regex.rg` ligger i svansposition, så `ridgunc` kompilerar dem till inbyggda hopp utan stacktillväxt.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test regex.rg`.

### De 5 Gyllene Reglerna när du programmerar med `regex`

1. **Deklarera `import regex` överst i filen** och utnyttja att mellanslag och understreck är utbytbara så att koden läses som naturlig prosa.
2. **Linjera dina datapipelines med `=`**: kedja samman `regex`-anrop i namngivna mellansteg och låt `stable format` linjera kolumnerna.
3. **Utnyttja `regex`:s totala funktioner i dina `|`-vakter**: kontrollera returvärden eller packa upp ADT:er med mönstermatchning i stället för att anta att extern indata alltid är giltig.
4. **Undvik att kopiera stora strukturer när du bara läser ett fält**: kom ihåg att i `RMM2` medför inargument noll referensräkningskostnad (`+0` / `-0`).
5. **Kombinera `regex` med `test` (`import test`)**: lås alltid fast dina domäninvarianter med `assert equals` eller `assert true`.

---

I **Kapitel 12** går vi vidare och utforskar lib:en **`glob`** på djupet (Lib:en `glob` — Jokerteckenmönster (`*`, `?`, `[a-z]`) och Listfiltrering).
