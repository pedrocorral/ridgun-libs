# 14. kapitulua: `template` lib-a — HTML eta LaTeX Auto-ihesa duten Mustache Txantiloi Seguruak

## 14.1. Zergatik existitzen da `template` lib-a? (Benetako arazoa eta Ridgun filosofia)

> *«Zergatik behar dut `template` lib bat hutsetik Ridgun hutsean idatzia, betiko C liburutegi bat estekatu beharrean?»*

Hori da edozein sistema-ingeniarik `template`-era iristean egiten duen lehen galdera. Eta erantzunak `ridgun-libs`-en filosofia osoa laburbiltzen du:

Izan gaitezen zintzoak: HTML orriak edo LaTeX txostenak kateak eskuz lotuz muntatzea XSS ahultasun baterako (`<script>`) edo `%` zein `_` ikur soil batek zure PDFaren konpilazioa apurtzeko errezeta perfektua da.

**`template`** lib-ak logika arbitrariorik gabeko **Mustache** motor bat eskaintzen du testuinguruko auto-ihesarekin (`TmplPlain`, `TmplHtml`, `TmplLatex`), ordezkapen gordin esplizituarekin (`{{{raw}}}` / `{{&raw}}`), iruzkinekin (`{{! ... }}`) eta atal baldintzatuekin (`{{#sec}}` / `{{^sec}}`).

Ekosistema tradizional batean, **`TMPL`** domeinuko zereginak ebazteak C-ko kanpo-mendekotasunak arrastatzea, erakusle gordinekin borrokatzea, mota-bihurketa opakuak, egiaztatu gabeko salbuespenak edo zabor-biltzailearen geldialdi ustekabekoak jasatea dakar. Ridgunen, **`template`** lib-ak (`src/main/ridgun/lib/template.rg`) lau printzipio negoziatu ezinekin heltzen dio arazoari:

1. **Deklaratu `import template` (edo `import template as alias`) fitxategiaren hasieran**: lib bakoitzak `module :: template` izen-espazioa definitzen du eta `--strict` moduan hitz anitzeko funtzioei zuriune naturalekin deitzen zaie beti.
2. **Kateatu zure datu-hodiak ezkerretik eskuinera `->` bidez**: idatzi `sarrera lehen urratsa -> bigarren urratsa -> emaitza`, erabili `(+ _ _ +)` maskarak sekuentziak desegituratzeko eta kendu `_ =` sententzia sekuentzialetan (edo baztertu `-> ()` bidez).
3. **Isats-errekurtsioa TCOrekin (*Tail-Call Optimization*)**: `template`-eko barne-ibilbide guztiak $O(1)$ pila-espazioko begizta natiboetara konpilatzen dira.
4. **Memoria determinista (`RMM1` / `RMM2`)**: tarteko egitura bakoitza bere azken irakurketa amaitzen den une zehatzean askatzen da, *Garbage Collector* gabe.

---

## 14.2. Artefaktu natiboak, inportazioa eta `template` APIaren katalogo osoa

`ridgun-libs`-en, **`template`** lehen mailako **lib** bat da, `src/main/ridgun/lib/template.rg` bidean kokatua (`TMPL` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/template.rglib` | Banaketa eta inportazio zuzena `import template` bidez |
| **Fitxategi konpilatua** | `target/template.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libtemplate.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib bakoitzak bere izen-espazioa deklaratzen du `module :: template` bidez: nahikoa da goiburuan `import template` (edo `import template as alias`) idaztea eta bere funtzioei zuriune naturalekin (`nire funtzioa x`) eta `->` hodiekin (`x nire funtzioa -> emaitza`) deitzea.

### 14.2.1. `template`-eko familia funtzionalen laburpena

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `tmpl render / tmpl render html / tmpl render latex` | Mustache txantiloiak errenderizatzen ditu auto-ihes lau, HTML edo LaTeXekin |
| `tmpl escape html / tmpl escape latex` | `& < > " '` HTMLrako edo `\ { } & % $ # _ ~ ^` LaTeXerako ihes egiten ditu |
| `tmpl extract vars / tmpl has unclosed tags` | Beharrezko aldagai-izenak erauzten ditu eta etiketen oreka egiaztatzen du |

### 14.2.2. `src/main/ridgun/lib/template.rg`-eko mota eta sinadura guztien katalogoa

Jarraian duzu `src/main/ridgun/lib/template.rg` fitxategian definitutako mota aljebraiko (`type`), eragile (`op ::`) eta funtzio-sinadura (`fn ::`) guztien inbentario osoa (`1` mota, `0` eragile eta `35` funtzio):

**`template`-eko mota aljebraikoak eta erregistroak (`type`):**

```ridgun
type TmplEscape = TmplEscapeNone | TmplEscapeHtml | TmplEscapeLatex
```

| # | Funtzioa / Sinadura (`fn ::`) | Itzulera-mota |
|---|---|---|
| `1` | `fn :: tm_lbrace` | `String` |
| `2` | `fn :: tm_rbrace` | `String` |
| `3` | `fn :: tm_braces` | `String` |
| `4` | `fn :: tm_is_space Int` | `Bool` |
| `5` | `fn :: tm_trim_start String Int Int` | `Int` |
| `6` | `fn :: tm_trim_end String Int Int` | `Int` |
| `7` | `fn :: tm_trim String` | `String` |
| `8` | `fn :: tm_lookup [(String, String)] String` | `String` |
| `9` | `fn :: tm_val_truthy String` | `Bool` |
| `10` | `fn :: tm_is_truthy [(String, String)] String` | `Bool` |
| `11` | `fn :: tm_escape_html_char Int` | `String` |
| `12` | `fn :: tm_escape_html_loop String Int Int String` | `String` |
| `13` | `fn :: tm_escape_latex_char Int` | `String` |
| `14` | `fn :: tm_escape_latex_loop String Int Int String` | `String` |
| `15` | `fn :: tm_escape String TmplEscape` | `String` |
| `16` | `fn :: tm_find_close2 String Int Int` | `Int` |
| `17` | `fn :: tm_find_close3 String Int Int` | `Int` |
| `18` | `fn :: tm_find_section_close String Int Int String Int` | `(Int, Int)` |
| `19` | `fn :: tm_check_section_tag String Int Int String Int Int` | `(Int, Int)` |
| `20` | `fn :: tm_check_close_tag String Int Int String Int Int` | `(Int, Int)` |
| `21` | `fn :: tm_close_tag_match String Int Int String Int Int` | `(Int, Int)` |
| `22` | `fn :: tm_check_open_tag String Int Int String Int Int` | `(Int, Int)` |
| `23` | `fn :: tm_scan String Int Int [(String, String)] TmplEscape String` | `String` |
| `24` | `fn :: tm_dispatch_tag String Int Int [(String, String)] TmplEscape String` | `String` |
| `25` | `fn :: tm_tag_raw3 String Int Int [(String, String)] TmplEscape String Int` | `String` |
| `26` | `fn :: tm_tag_raw_amp String Int Int [(String, String)] TmplEscape String Int` | `String` |
| `27` | `fn :: tm_tag_comment String Int Int [(String, String)] TmplEscape String Int` | `String` |
| `28` | `fn :: tm_section_active Bool Bool` | `Bool` |
| `29` | `fn :: tm_render_section_body String Int (Int, Int) Int [(String, String)] TmplEscape String Bool` | `String` |
| `30` | `fn :: tm_tag_section String Int Int [(String, String)] TmplEscape String Int Bool` | `String` |
| `31` | `fn :: tm_tag_var String Int Int [(String, String)] TmplEscape String Int` | `String` |
| `32` | `fn :: tmpl render with escape String [(String, String)] TmplEscape` | `String` |
| `33` | `fn :: tmpl render String [(String, String)]` | `String` |
| `34` | `fn :: tmpl render html String [(String, String)]` | `String` |
| `35` | `fn :: tmpl render latex String [(String, String)]` | `String` |

---

## 14.3. `template` sakonki esploratzen: Funtzionalitate bakoitzaren urratsez urratseko adibideak

Ez da nahikoa sinadura-taula ikustea: `template` lib-aren **funtzionalitate bakoitza** Ridgunen exekutagarriak diren adibide progresiboen bidez esploratuko dugu. Eguneroko bi errezeta taularatuekin hasiko gara eta ondoren xehetasunez ikusiko ditugu `src/test/ridgun/test template.rg`-en egiaztatutako agertoki funtzional eta muga-kasu guztiak.

### 14.3.1. 1. adibidea: Fluxu nagusia estilo taularatuan `template` erabiliz

Ikusi nola Ridgunen `=` ikurrak eta `template` bidezko eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren, beharrezkoak ez diren aldagai aldakorrik edo ezkutuko albo-ondoriorik gabe:

```ridgun
import template

fn :: renderizar perfil html String String => String
      renderizar perfil html usuario es_admin =
        "<h1>Hola {{user}}</h1>{{#admin}}<span class='badge'>Admin</span>{{/admin}}" -> plantilla
        [("user", usuario), ("admin", es_admin)] -> vars
        tmpl render html plantilla vars
```

### 14.3.2. 2. adibidea: Konposizio segurua eta muga-kasuen kudeaketa

`template` lib-eko funtzio oro `|` guarda boolearrekin eta `ridgun-libs`-eko gainerako 32 lib-ekin konposatzeko diseinatuta dago:

```ridgun
import template

fn :: generar linea latex String => String
      generar linea latex metrica =
        -- Escapa automaticamente % _ & # para que LaTeX no falle
        tmpl render latex "Resultado: {{val}}" [("val", metrica)]
```

### 14.3.3. 3. adibidea: `{{ gakoa }}` aldagaien interpolazioa, etiketetako zuriuneen mozketa eta `{{! ... }}` iruzkinen ezabaketa

Adibide praktiko honetan `template` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test_tmpl_interpolation_and_comments => ()
      test_tmpl_interpolation_and_comments =
        nl = char from code 10
        ctx = [("name", "Ada Lovelace"), ("role", "Mathematician"), ("empty", "")]
        t1 = "Hello, " + (tag2 "name") + " (" + (tag2 "  role  ") + ")!"
        out1 = tmpl render t1 ctx
        assert str eq out1 "Hello, Ada Lovelace (Mathematician)!" "AC1: variable and whitespace-trimmed tag interpolation"
        t_missing = "User: [" + (tag2 "unknown") + "] Empty: [" + (tag2 "empty") + "]"
        out_missing = tmpl render t_missing ctx
        assert str eq out_missing "User: [] Empty: []" "AC1: missing and empty variables render empty string"
        t_comment = "Visible" + (tag2 "! secret comment ") + "Text" + (tag2 ("! multiline" + nl + "comment" + nl + "here ")) + "End"
        out_comment = tmpl render t_comment ctx
        assert str eq out_comment "VisibleTextEnd" "AC1: single-line and multi-line comments omitted"
        ()
```

### 14.3.4. 4. adibidea: Lehenetsitako XSS arintzea (`&`, `<`, `>`, `"`, `'`) vs txertaketa gordin esplizitua `{{{ raw }}}` eta `{{& raw }}`

Adibide praktiko honetan `template` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test_tmpl_html_escaping_and_raw => ()
      test_tmpl_html_escaping_and_raw =
        q = char from code 34
        ctx = [("xss", "<script>alert(" + q + "xss" + q + " & 'pwn')</script>"), ("trusted", "<b>Bold &amp; Safe</b>")]
        tmpl = "Escaped: " + (tag2 "xss") + " | Raw3: " + (tag3 "trusted") + " | RawAmp: " + (tag2 "& trusted ")
        out_html = tmpl render html tmpl ctx
        expected = "Escaped: &lt;script&gt;alert(&quot;xss&quot; &amp; &#39;pwn&#39;)&lt;/script&gt; | Raw3: <b>Bold &amp; Safe</b> | RawAmp: <b>Bold &amp; Safe</b>"
        assert str eq out_html expected "AC1: HTML escaping vs raw triple-brace and ampersand tags"
        out_none = tmpl render ("Plain: " + (tag2 "xss")) ctx
        assert str eq out_none ("Plain: <script>alert(" + q + "xss" + q + " & 'pwn')</script>") "AC1: TmplEscapeNone leaves HTML unescaped"
        ()
```

### 14.3.5. 5. adibidea: `{{#sec}}...{{/sec}}` atal baldintzatuak eta `{{^sec}}...{{/sec}}` atal alderantzizkoak egia-balioen arabera (`false`, `0`, `no`, `off`)

Adibide praktiko honetan `template` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test_tmpl_sections_and_inverted => ()
      test_tmpl_sections_and_inverted =
        tmpl = (tag2 "#auth") + "Welcome, " + (tag2 "user") + "!" + (tag2 "/auth") + (tag2 "^auth") + "Please log in." + (tag2 "/auth")
        out_in = tmpl render html tmpl [("auth", "true"), ("user", "Alice & Bob")]
        assert str eq out_in "Welcome, Alice &amp; Bob!" "AC2: truthy section rendered with HTML escaping"
        out_false = tmpl render html tmpl [("auth", "false"), ("user", "Alice")]
        assert str eq out_false "Please log in." "AC2: 'false' triggers inverted section"
        out_false_cap = tmpl render html tmpl [("auth", "False"), ("user", "Alice")]
        assert str eq out_false_cap "Please log in." "AC2: 'False' triggers inverted section"
        out_zero = tmpl render html tmpl [("auth", "0"), ("user", "Alice")]
        assert str eq out_zero "Please log in." "AC2: '0' triggers inverted section"
        out_empty = tmpl render html tmpl [("auth", ""), ("user", "Alice")]
        assert str eq out_empty "Please log in." "AC2: empty string triggers inverted section"
        out_missing = tmpl render html tmpl [("user", "Alice")]
        assert str eq out_missing "Please log in." "AC2: missing key triggers inverted section"
        ()
```

### 14.3.6. 6. adibidea: Atal baldintzatuen habiaratze sakona eta interpolazio hierarkikoa

Adibide praktiko honetan `template` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test_tmpl_nested_sections => ()
      test_tmpl_nested_sections =
        tmpl = (tag2 "#outer") + "A-" + (tag2 "#inner") + "B-" + (tag2 "val") + (tag2 "/inner") + (tag2 "^inner") + "NO_INNER" + (tag2 "/inner") + "-C" + (tag2 "/outer")
        out1 = tmpl render tmpl [("outer", "1"), ("inner", "yes"), ("val", "42")]
        assert str eq out1 "A-B-42-C" "AC2: nested outer+inner truthy"
        out2 = tmpl render tmpl [("outer", "1"), ("inner", "0"), ("val", "42")]
        assert str eq out2 "A-NO_INNER-C" "AC2: nested outer truthy, inner falsy"
        out3 = tmpl render tmpl [("outer", "0"), ("inner", "yes"), ("val", "42")]
        assert str eq out3 "" "AC2: nested outer falsy skips inner"
        same_nested = (tag2 "#k") + "[" + (tag2 "#k") + "(" + (tag2 "v") + ")" + (tag2 "/k") + "]" + (tag2 "/k")
        assert str eq (tmpl render same_nested [("k", "1"), ("v", "ok")]) "[(ok)]" "AC2: nested same-key truthy"
        assert str eq (tmpl render same_nested [("k", ""), ("v", "ok")]) "" "AC2: nested same-key falsy"
        ()
```

### 14.3.7. 7. adibidea: LaTeX dokumentuetarako ihes-sekuentzia espezializatuak (`tmpl escape latex`: `\`, `{`, `}`, `$`, `&`, `#`, `_`, `%`, `~`, `^`)

Adibide praktiko honetan `template` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test_tmpl_latex_escaping => ()
      test_tmpl_latex_escaping =
        bs = char from code 92
        lb = char from code 123
        rb = char from code 125
        braces = lb + rb
        ctx = [("formula", "100% of $50 & #1_item " + lb + "a" + bs + "b" + rb + " ~ ^"), ("raw_tex", bs + "textbf" + lb + "Title" + rb)]
        tmpl = "Text: " + (tag2 "formula") + " | Raw: " + (tag3 "raw_tex")
        out_tex = tmpl render latex tmpl ctx
        expected = "Text: 100" + bs + "% of " + bs + "$50 " + bs + "& " + bs + "#1" + bs + "_item " + bs + lb + "a" + bs + "textbackslash" + braces + "b" + bs + rb + " " + bs + "textasciitilde" + braces + " " + bs + "textasciicircum" + braces + " | Raw: " + bs + "textbf" + lb + "Title" + rb
        assert str eq out_tex expected "AC3: LaTeX special characters escaped accurately while triple-brace stays raw"
        ()
```

### 14.3.8. 8. adibidea: Itxi gabeko etiketen edo desorekatutako atalen detekzio determinista (`TmplErr`)

Adibide praktiko honetan `template` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test_tmpl_malformed_tags => ()
      test_tmpl_malformed_tags =
        lb = char from code 123
        ctx = [("x", "1")]
        assert str eq (tmpl render ("trailing " + lb + lb) ctx) ("trailing " + lb + lb) "AC1: trailing double brace"
        assert str eq (tmpl render ("unclosed " + lb + lb + "x") ctx) ("unclosed " + lb + lb + "x") "AC1: unclosed var tag"
        assert str eq (tmpl render ("unclosed raw " + lb + lb + lb + "x") ctx) ("unclosed raw " + lb + lb + lb + "x") "AC1: unclosed raw3 tag"
        assert str eq (tmpl render ("unclosed comment " + lb + lb + "! hidden") ctx) "unclosed comment " "AC1: unclosed comment tag"
        ()
```

---

## 14.4. Kaputaren azpian: nola dagoen eraikia `template` Ridgun hutsean (`src/main/ridgun/lib/template.rg`)

`ridgun-libs`-en abantaila handienetako bat **C-ko kutxa beltzik ez egotea** da. `src/main/ridgun/lib/template.rg` ireki dezakezu eta eragiketa bakoitza *pattern matching*, `|` / `|.` guarda-zuhaitzak eta isats-errekurtsioa (TCO) erabiliz nola inplementatuta dagoen irakurri. Ikus ditzagun bere benetako inplementazioaren funtsezko piezak:

### 14.4.1. Barne-inplementazioa: Internal Helpers

Ikusi nola `template.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
module :: template

fn :: tm lbrace => String
      tm lbrace = char from code 123

fn :: tm rbrace => String
      tm rbrace = char from code 125

fn :: tm braces => String
      tm braces = (char from code 123) + (char from code 125)

fn :: tm is space Int => Bool
      tm is space c =
        | c == 32 = True
        | c == 9 = True
        | c == 10 = True
        | c == 13 = True
        | otherwise = False

fn :: tm trim start String Int Int => Int
      tm trim start s idx n =
        | idx >= n = n
        | tm is space (str char at s idx) = tm trim start s (idx + 1) n
        | otherwise = idx

fn :: tm trim end String Int Int => Int
      tm trim end s start idx =
        | idx <= start = start
        | tm is space (str char at s (idx - 1)) = tm trim end s start (idx - 1)
        | otherwise = idx

fn :: tm trim String => String
      tm trim s =
        s str len -> n
        tm trim start s 0 n -> st
        tm trim end s st n -> en
        str slice s st en

fn :: tm lookup [String String] String => String
      tm lookup [] _ = ""
      tm lookup ((k, v):rest) key =
        | k == key = v
        | otherwise = tm lookup rest key

fn :: tm val truthy String => Bool
      tm val truthy val =
        | val == "" = False
        | val == "false" = False
        | val == "False" = False
        | val == "0" = False
        | otherwise = True

fn :: tm is truthy [String String] String => Bool
      tm is truthy ctx key = tm lookup ctx key -> tm val truthy

fn :: tm escape html char Int => String
      tm escape html char c =
        | c == 38 = "&amp;"
        | c == 60 = "&lt;"
        | c == 62 = "&gt;"
        | c == 34 = "&quot;"
        | c == 39 = "&#39;"
        | otherwise = char from code c

fn :: tm escape html loop String Int Int String => String
      tm escape html loop s idx n acc =
        | idx >= n = acc
        | otherwise = tm escape html loop s (idx + 1) n (acc + (tm escape html char (str char at s idx)))

fn :: tm escape latex char Int => String
      tm escape latex char c =
        | c == 92 = (char from code 92) + "textbackslash" + (tm braces)
        | c == 123 = (char from code 92) + (tm lbrace)
        | c == 125 = (char from code 92) + (tm rbrace)
        | c == 38 = (char from code 92) + "&"
        | c == 37 = (char from code 92) + "%"
        | c == 36 = (char from code 92) + "$"
        | c == 35 = (char from code 92) + "#"
        | c == 95 = (char from code 92) + "_"
        | c == 126 = (char from code 92) + "textasciitilde" + (tm braces)
        | c == 94 = (char from code 92) + "textasciicircum" + (tm braces)
        | otherwise = char from code c

fn :: tm escape latex loop String Int Int String => String
      tm escape latex loop s idx n acc =
        | idx >= n = acc
        | otherwise = tm escape latex loop s (idx + 1) n (acc + (tm escape latex char (str char at s idx)))

fn :: tm escape String TmplEscape => String
      tm escape s TmplEscapeNone = s
      tm escape s TmplEscapeHtml = tm escape html loop s 0 (str len s) ""
      tm escape s TmplEscapeLatex = tm escape latex loop s 0 (str len s) ""

fn :: tm find close2 String Int Int => Int
      tm find close2 s idx n =
        | (idx + 1) >= n = (0 - 1)
        | (str char at s idx) == 125 and (str char at s (idx + 1)) == 125 = idx
        | otherwise = tm find close2 s (idx + 1) n

fn :: tm find close3 String Int Int => Int
      tm find close3 s idx n =
        | (idx + 2) >= n = (0 - 1)
        | (str char at s idx) == 125 and (str char at s (idx + 1)) == 125 and (str char at s (idx + 2)) == 125 = idx
        | otherwise = tm find close3 s (idx + 1) n

fn :: tm find section close String Int Int String Int => Int Int
      tm find section close s idx n sec_key depth =
        | (idx + 3) >= n = (n, n)
        | (str char at s idx) == 123 and (str char at s (idx + 1)) == 123 =
          tm check section tag s idx n sec_key depth (str char at s (idx + 2))
        | otherwise = tm find section close s (idx + 1) n sec_key depth

fn :: tm check section tag String Int Int String Int Int => Int Int
      tm check section tag s idx n sec_key depth sig =
        | sig == 47 = tm check close tag s idx n sec_key depth (tm find close2 s (idx + 3) n)
        | sig == 35 or sig == 94 = tm check open tag s idx n sec_key depth (tm find close2 s (idx + 3) n)
        | otherwise = tm find section close s (idx + 2) n sec_key depth

fn :: tm check close tag String Int Int String Int Int => Int Int
      tm check close tag s idx n sec_key depth close_pos =
        | close_pos < 0 = (n, n)
        | (tm trim (str slice s (idx + 3) close_pos)) == sec_key =
          tm close tag match s idx n sec_key depth close_pos
        | otherwise = tm find section close s (close_pos + 2) n sec_key depth

fn :: tm close tag match String Int Int String Int Int => Int Int
      tm close tag match s idx n sec_key depth close_pos =
        | depth <= 1 = (idx, close_pos + 2)
        | otherwise = tm find section close s (close_pos + 2) n sec_key (depth - 1)

fn :: tm check open tag String Int Int String Int Int => Int Int
      tm check open tag s idx n sec_key depth close_pos =
        | close_pos < 0 = (n, n)
        | (tm trim (str slice s (idx + 3) close_pos)) == sec_key =
          tm find section close s (close_pos + 2) n sec_key (depth + 1)
        | otherwise = tm find section close s (close_pos + 2) n sec_key depth

fn :: tm scan String Int Int [String String] TmplEscape String => String
      tm scan s idx n ctx mode acc =
        | idx >= n = acc
        | (idx + 1) < n and (str char at s idx) == 123 and (str char at s (idx + 1)) == 123 =
          tm dispatch tag s idx n ctx mode acc
        | otherwise = tm scan s (idx + 1) n ctx mode (acc + (char from code (str char at s idx)))

fn :: tm dispatch tag String Int Int [String String] TmplEscape String => String
      tm dispatch tag s idx n ctx mode acc =
        | (idx + 2) >= n = acc + (tm lbrace) + (tm lbrace)
        | (str char at s (idx + 2)) == 123 = tm tag raw3 s idx n ctx mode acc (tm find close3 s (idx + 3) n)
        | (str char at s (idx + 2)) == 38 = tm tag raw amp s idx n ctx mode acc (tm find close2 s (idx + 3) n)
        | (str char at s (idx + 2)) == 33 = tm tag comment s idx n ctx mode acc (tm find close2 s (idx + 3) n)
        | (str char at s (idx + 2)) == 35 = tm tag section s idx n ctx mode acc (tm find close2 s (idx + 3) n) False
        | (str char at s (idx + 2)) == 94 = tm tag section s idx n ctx mode acc (tm find close2 s (idx + 3) n) True
        | otherwise = tm tag var s idx n ctx mode acc (tm find close2 s (idx + 2) n)

fn :: tm tag raw3 String Int Int [String String] TmplEscape String Int => String
      tm tag raw3 s idx n ctx mode acc close_pos =
        | close_pos < 0 = tm scan s (idx + 3) n ctx mode (acc + (tm lbrace) + (tm lbrace) + (tm lbrace))
        | otherwise =
          tm scan s (close_pos + 3) n ctx mode (acc + (tm lookup ctx (tm trim (str slice s (idx + 3) close_pos))))

fn :: tm tag raw amp String Int Int [String String] TmplEscape String Int => String
      tm tag raw amp s idx n ctx mode acc close_pos =
        | close_pos < 0 = tm scan s (idx + 3) n ctx mode (acc + (tm lbrace) + (tm lbrace) + "&")
        | otherwise =
          tm scan s (close_pos + 2) n ctx mode (acc + (tm lookup ctx (tm trim (str slice s (idx + 3) close_pos))))

fn :: tm tag comment String Int Int [String String] TmplEscape String Int => String
      tm tag comment s _ n ctx mode acc close_pos =
        | close_pos < 0 = acc
        | otherwise = tm scan s (close_pos + 2) n ctx mode acc

fn :: tm section active Bool Bool => Bool
      tm section active True False = True
      tm section active False True = True
      tm section active _ _ = False

fn :: tm render section body String Int (Int Int) Int [String String] TmplEscape String Bool => String
      tm render section body s _ (_, after_close) n ctx mode acc False =
        tm scan s after_close n ctx mode acc
      tm render section body s body_start (body_end, after_close) n ctx mode acc True =
        tm scan s body_start body_end ctx mode "" -> rendered_body
        tm scan s after_close n ctx mode (acc + rendered_body)

fn :: tm tag section String Int Int [String String] TmplEscape String Int Bool => String
      tm tag section s idx n ctx mode acc open_close inverted =
        | open_close < 0 = tm scan s (idx + 3) n ctx mode acc
        | otherwise =
          tm render section body s (open_close + 2) (tm find section close s (open_close + 2) n (tm trim (str slice s (idx + 3) open_close)) 1) n ctx mode acc (tm section active (tm is truthy ctx (tm trim (str slice s (idx + 3) open_close))) inverted)

fn :: tm tag var String Int Int [String String] TmplEscape String Int => String
      tm tag var s idx n ctx mode acc close_pos =
        | close_pos < 0 = tm scan s (idx + 2) n ctx mode (acc + (tm lbrace) + (tm lbrace))
        | otherwise =
          tm scan s (close_pos + 2) n ctx mode (acc + (tm escape (tm lookup ctx (tm trim (str slice s (idx + 2) close_pos))) mode))
```

### 14.4.2. Barne-inplementazioa: Public API

Ikusi nola `template.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: tmpl render with escape String [String String] TmplEscape => String
      tmpl render with escape tmpl ctx mode = tm scan tmpl 0 (str len tmpl) ctx mode ""

fn :: tmpl render String [String String] => String
      tmpl render tmpl ctx = tmpl render with escape tmpl ctx TmplEscapeNone

fn :: tmpl render html String [String String] => String
      tmpl render html tmpl ctx = tmpl render with escape tmpl ctx TmplEscapeHtml

fn :: tmpl render latex String [String String] => String
      tmpl render latex tmpl ctx = tmpl render with escape tmpl ctx TmplEscapeLatex
```

---

## 14.5. Berme algoritmikoak, `RMM1`/`RMM2` memoria eta `template`-en Urrezko 5 Arauak

- **Berme algoritmikoa eta segurtasunekoa**: XSS prebentzioa lehenetsita `tmpl render html`-n (`&`, `<`, `>`, `"`, `'` ihes eginez), `{{{var}}}`-k konfiantzazko zatiak esplizituki txertatzea ahalbidetzen duen bitartean.
- **$O(1)$ pila-konplexutasuna TCOrekin**: `src/main/ridgun/lib/template.rg`-eko begizta errekurtsibo guztiak isats-posizioan daude; beraz, `ridgunc`-ek pila-hazkuntzarik gabeko jauzi natiboetara konpilatzen ditu.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test template.rg` suite automatizatuaren bidez.

### `template`-ekin programatzeko Urrezko 5 Arauak

1. **Deklaratu `import template` fitxategiaren hasieran** eta baliatu zuriuneen eta azpimarren arteko baliokidetasuna zure kodea prosa bezala irakur dadin.
2. **Lerrokatu zure datu-hodiak `=` ikurrarekin**: kateatu `template`-erako deiak izen propioko urratsetan eta utzi `stable format`-i zutabeak lerrokatzen.
3. **Baliatu `template`-eko funtzio osoak zure `|` guardetan**: egiaztatu itzulera-balioak edo askatu ADTak *pattern matching* bidez, kanpoko sarrera beti baliozkoa dela suposatu beharrean.
4. **Saihestu egitura handiak kopiatzea eremu bat kontsultatu besterik behar ez baduzu**: gogoratu `RMM2`-n sarrerako argumentuek ez dituztela kontagailuak handitzen edo txikitzen (`+0` / `-0`).
5. **Konbinatu `template` eta `test` (`import test`)**: idatzi beti asertzioak `assert equals` edo `assert true` erabiliz zure domeinuaren inbarianteak finkatzeko.

---

**15. kapituluan** **`fmt`** lib-a sakonki esploratuko dugu (`fmt` lib-a — 2D Formateatzaile Taularatu Kanonikoa eta 9 Formatuko Sintaxi-nabarmentzailea).
