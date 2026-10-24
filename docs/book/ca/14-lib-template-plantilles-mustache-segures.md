# Capítol 14: La lib `template` — Plantilles Mustache Segures amb Auto-Escapament HTML i LaTeX

## 14.1. Per què existeix la lib `template`? (El problema real i la filosofia Ridgun)

> *«Per què necessito una lib `template` escrita des de zero en Ridgun pur en lloc d'enllaçar una llibreria de C de tota la vida?»*

Aquesta és la primera pregunta que es fa qualsevol enginyer de sistemes en arribar a `template`. I la resposta resumeix tota la filosofia de `ridgun-libs`:

Siguem sincers: muntar pàgines HTML o informes LaTeX concatenant cadenes a mà és la recepta perfecta per a una vulnerabilitat XSS (`<script>`) o perquè un simple símbol `%` o `_` trenqui la compilació del teu PDF.

La lib **`template`** ofereix un motor **Mustache** sense lògica arbitrària amb auto-escapament contextual (`TmplPlain`, `TmplHtml`, `TmplLatex`), substitució crua explícita (`{{{raw}}}` / `{{&raw}}`), comentaris (`{{! ... }}`), seccions condicionals (`{{#sec}}...{{/sec}}`) i invertides (`{{^sec}}...{{/sec}}`).

En un ecosistema tradicional, resoldre les tasques del domini **`TMPL`** implica arrossegar dependències externes en C, lluitar amb punters crus, conversions opaques de tipus, excepcions no verificades o pauses impredictibles del recol·lector de brossa. En Ridgun, la lib **`template`** (`src/main/ridgun/lib/template.rg`) aborda el problema amb quatre principis innegociables:

1. **Funcions totals i contractes explícits (`=>`)**: cap funció de `template` llança excepcions ocultes ni depèn de `null`. Tot cas límit retorna un valor sentinella documentat o un tipus algebraic suma (`Option`, `Result`).
2. **Zero codi C i zero `libc`**: tot el codi de `template` compila directament a codi màquina natiu ELF64 verificat per `ridgunc`.
3. **Recursió de cua amb TCO (*Tail-Call Optimization*)**: tots els recorreguts interns de `template` es compilen a bucles natius en espai de pila $O(1)$.
4. **Memòria determinista (`RMM1` / `RMM2`)**: cada estructura intermèdia s'allibera en l'instant exacte en què acaba la seva última lectura, sense *Garbage Collector*.

---

## 14.2. Artefactes natius, importació i catàleg complet de l'API de `template`

A `ridgun-libs`, **`template`** és una **lib** de primera classe situada a `src/main/ridgun/lib/template.rg` (domini `TMPL`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/template.rglib` | Distribució i importació directa amb `import template` |
| **Fitxer compilat** | `target/template.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libtemplate.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import template` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

### 14.2.1. Resum de famílies funcionals de `template`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `tmpl render / tmpl render html / tmpl render latex` | Renderitza plantilles Mustache amb auto-escapament pla, HTML o LaTeX |
| `tmpl escape html / tmpl escape latex` | Escapa `& < > " '` per a HTML o `\ { } & % $ # _ ~ ^` per a LaTeX |
| `tmpl extract vars / tmpl has unclosed tags` | Extreu els noms de variables requerits i valida que les etiquetes estiguin tancades |

### 14.2.2. Catàleg exhaustiu de tipus i signatures a `src/main/ridgun/lib/template.rg`

A continuació tens l'inventari complet de tipus algebraics (`type`), operadors (`op ::`) i signatures de funcions (`fn ::`) definits a `src/main/ridgun/lib/template.rg` (`1` tipus, `0` operadors i `35` funcions):

**Tipus algebraics i registres (`type`) de `template`:**

```ridgun
type TmplEscape = TmplEscapeNone | TmplEscapeHtml | TmplEscapeLatex
```

| # | Funció / Signatura (`fn ::`) | Tipus de Retorn |
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

## 14.3. Explorant `template` a fons: Exemples pas a pas de cada funcionalitat

No n'hi ha prou de veure la taula de signatures: explorarem **cadascuna de les funcionalitats** de la lib `template` mitjançant exemples progressius i executables en Ridgun. Començarem per les dues receptes tabulars d'ús quotidià i després recorrerem en detall tots els escenaris funcionals, transformacions i casos límit verificats a `src/test/ridgun/test template.rg`.

### 14.3.1. Exemple 1: Flux principal en estil tabular amb `template`

Observa com en Ridgun els signes `=` i els passos de transformació amb `template` queden alineats com una taula neta, sense variables mutables innecessàries ni efectes laterals ocults:

```ridgun
import template

fn :: renderizar perfil html (usuario : String) (es_admin : String) => String
      renderizar perfil html usuario es_admin =
        plantilla = "<h1>Hola {{user}}</h1>{{#admin}}<span class='badge'>Admin</span>{{/admin}}"
        vars      = [("user", usuario), ("admin", es_admin)]
        tmpl render html plantilla vars
```

### 14.3.2. Exemple 2: Composició segura i gestió de casos de vora

Tota funció de la lib `template` està dissenyada per compondre's amb guardes booleanes `|` i amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import template

fn :: generar linea latex (metrica : String) => String
      generar linea latex metrica =
        -- Escapa automaticamente % _ & # para que LaTeX no falle
        tmpl render latex "Resultado: {{val}}" [("val", metrica)]
```

### 14.3.3. Exemple 3: Interpolació de variables `{{ clau }}`, retall d'espais en etiquetes i eliminació de comentaris `{{! ... }}`

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `template` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test_tmpl_interpolation_and_comments => ()
      test_tmpl_interpolation_and_comments =
        nl = char_from_code 10
        ctx = [("name", "Ada Lovelace"), ("role", "Mathematician"), ("empty", "")]
        t1 = "Hello, " + (tag2 "name") + " (" + (tag2 "  role  ") + ")!"
        out1 = tmpl render t1 ctx
        _ = assert str eq out1 "Hello, Ada Lovelace (Mathematician)!" "AC1: variable and whitespace-trimmed tag interpolation"
        t_missing = "User: [" + (tag2 "unknown") + "] Empty: [" + (tag2 "empty") + "]"
        out_missing = tmpl render t_missing ctx
        _ = assert str eq out_missing "User: [] Empty: []" "AC1: missing and empty variables render empty string"
        t_comment = "Visible" + (tag2 "! secret comment ") + "Text" + (tag2 ("! multiline" + nl + "comment" + nl + "here ")) + "End"
        out_comment = tmpl render t_comment ctx
        _ = assert str eq out_comment "VisibleTextEnd" "AC1: single-line and multi-line comments omitted"
        ()
```

### 14.3.4. Exemple 4: Mitigació XSS per defecte (`&`, `<`, `>`, `"`, `'`) enfront d'inserció crua explícita `{{{ raw }}}` i `{{& raw }}`

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `template` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test_tmpl_html_escaping_and_raw => ()
      test_tmpl_html_escaping_and_raw =
        q = char_from_code 34
        ctx = [("xss", "<script>alert(" + q + "xss" + q + " & 'pwn')</script>"), ("trusted", "<b>Bold &amp; Safe</b>")]
        tmpl = "Escaped: " + (tag2 "xss") + " | Raw3: " + (tag3 "trusted") + " | RawAmp: " + (tag2 "& trusted ")
        out_html = tmpl render html tmpl ctx
        expected = "Escaped: &lt;script&gt;alert(&quot;xss&quot; &amp; &#39;pwn&#39;)&lt;/script&gt; | Raw3: <b>Bold &amp; Safe</b> | RawAmp: <b>Bold &amp; Safe</b>"
        _ = assert str eq out_html expected "AC1: HTML escaping vs raw triple-brace and ampersand tags"
        out_none = tmpl render ("Plain: " + (tag2 "xss")) ctx
        _ = assert str eq out_none ("Plain: <script>alert(" + q + "xss" + q + " & 'pwn')</script>") "AC1: TmplEscapeNone leaves HTML unescaped"
        ()
```

### 14.3.5. Exemple 5: Seccions condicionals `{{#sec}}...{{/sec}}` i seccions invertides `{{^sec}}...{{/sec}}` segons valors de veritat (`false`, `0`, `no`, `off`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `template` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test_tmpl_sections_and_inverted => ()
      test_tmpl_sections_and_inverted =
        tmpl = (tag2 "#auth") + "Welcome, " + (tag2 "user") + "!" + (tag2 "/auth") + (tag2 "^auth") + "Please log in." + (tag2 "/auth")
        out_in = tmpl render html tmpl [("auth", "true"), ("user", "Alice & Bob")]
        _ = assert str eq out_in "Welcome, Alice &amp; Bob!" "AC2: truthy section rendered with HTML escaping"
        out_false = tmpl render html tmpl [("auth", "false"), ("user", "Alice")]
        _ = assert str eq out_false "Please log in." "AC2: 'false' triggers inverted section"
        out_false_cap = tmpl render html tmpl [("auth", "False"), ("user", "Alice")]
        _ = assert str eq out_false_cap "Please log in." "AC2: 'False' triggers inverted section"
        out_zero = tmpl render html tmpl [("auth", "0"), ("user", "Alice")]
        _ = assert str eq out_zero "Please log in." "AC2: '0' triggers inverted section"
        out_empty = tmpl render html tmpl [("auth", ""), ("user", "Alice")]
        _ = assert str eq out_empty "Please log in." "AC2: empty string triggers inverted section"
        out_missing = tmpl render html tmpl [("user", "Alice")]
        _ = assert str eq out_missing "Please log in." "AC2: missing key triggers inverted section"
        ()
```

### 14.3.6. Exemple 6: Imbricació profunda de seccions condicionals i interpolació jeràrquica

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `template` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test_tmpl_nested_sections => ()
      test_tmpl_nested_sections =
        tmpl = (tag2 "#outer") + "A-" + (tag2 "#inner") + "B-" + (tag2 "val") + (tag2 "/inner") + (tag2 "^inner") + "NO_INNER" + (tag2 "/inner") + "-C" + (tag2 "/outer")
        out1 = tmpl render tmpl [("outer", "1"), ("inner", "yes"), ("val", "42")]
        _ = assert str eq out1 "A-B-42-C" "AC2: nested outer+inner truthy"
        out2 = tmpl render tmpl [("outer", "1"), ("inner", "0"), ("val", "42")]
        _ = assert str eq out2 "A-NO_INNER-C" "AC2: nested outer truthy, inner falsy"
        out3 = tmpl render tmpl [("outer", "0"), ("inner", "yes"), ("val", "42")]
        _ = assert str eq out3 "" "AC2: nested outer falsy skips inner"
        same_nested = (tag2 "#k") + "[" + (tag2 "#k") + "(" + (tag2 "v") + ")" + (tag2 "/k") + "]" + (tag2 "/k")
        _ = assert str eq (tmpl render same_nested [("k", "1"), ("v", "ok")]) "[(ok)]" "AC2: nested same-key truthy"
        _ = assert str eq (tmpl render same_nested [("k", ""), ("v", "ok")]) "" "AC2: nested same-key falsy"
        ()
```

### 14.3.7. Exemple 7: Escapament especialitzat per a documents LaTeX (`tmpl escape latex`: `\`, `{`, `}`, `$`, `&`, `#`, `_`, `%`, `~`, `^`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `template` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test_tmpl_latex_escaping => ()
      test_tmpl_latex_escaping =
        bs = char_from_code 92
        lb = char_from_code 123
        rb = char_from_code 125
        braces = lb + rb
        ctx = [("formula", "100% of $50 & #1_item " + lb + "a" + bs + "b" + rb + " ~ ^"), ("raw_tex", bs + "textbf" + lb + "Title" + rb)]
        tmpl = "Text: " + (tag2 "formula") + " | Raw: " + (tag3 "raw_tex")
        out_tex = tmpl render latex tmpl ctx
        expected = "Text: 100" + bs + "% of " + bs + "$50 " + bs + "& " + bs + "#1" + bs + "_item " + bs + lb + "a" + bs + "textbackslash" + braces + "b" + bs + rb + " " + bs + "textasciitilde" + braces + " " + bs + "textasciicircum" + braces + " | Raw: " + bs + "textbf" + lb + "Title" + rb
        _ = assert str eq out_tex expected "AC3: LaTeX special characters escaped accurately while triple-brace stays raw"
        ()
```

### 14.3.8. Exemple 8: Detecció determinista d'etiquetes sense tancar o seccions desbalancejades (`TmplErr`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `template` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test_tmpl_malformed_tags => ()
      test_tmpl_malformed_tags =
        lb = char_from_code 123
        ctx = [("x", "1")]
        _ = assert str eq (tmpl render ("trailing " + lb + lb) ctx) ("trailing " + lb + lb) "AC1: trailing double brace"
        _ = assert str eq (tmpl render ("unclosed " + lb + lb + "x") ctx) ("unclosed " + lb + lb + "x") "AC1: unclosed var tag"
        _ = assert str eq (tmpl render ("unclosed raw " + lb + lb + lb + "x") ctx) ("unclosed raw " + lb + lb + lb + "x") "AC1: unclosed raw3 tag"
        _ = assert str eq (tmpl render ("unclosed comment " + lb + lb + "! hidden") ctx) "unclosed comment " "AC1: unclosed comment tag"
        ()
```

---

## 14.4. Sota el capó: com està construïda `template` en Ridgun pur (`src/main/ridgun/lib/template.rg`)

Un dels majors avantatges de `ridgun-libs` és que **no hi ha caixes negres en C**. Pots obrir `src/main/ridgun/lib/template.rg` i llegir exactament com està implementada cada operació fent servir *pattern matching*, arbres de guardes `|` / `|.` i recursió de cua (TCO). Vegem les peces clau de la seva implementació real:

### 14.4.1. Implementació interna: Internal Helpers

Fixa't en com `template.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

```ridgun
fn :: tm_lbrace => String
      tm_lbrace =  char_from_code 123

fn :: tm_rbrace => String
      tm_rbrace =  char_from_code 125

fn :: tm_braces => String
      tm_braces =  (char_from_code 123) + (char_from_code 125)

fn :: tm_is_space Int => Bool
      tm_is_space c
        | c == 32 = True
        | c == 9 = True
        | c == 10 = True
        | c == 13 = True
        | otherwise = False

fn :: tm_trim_start String Int Int => Int
      tm_trim_start s      idx n
        | idx >= n = n
        | tm_is_space (str_char_at s idx) = tm_trim_start s (idx + 1) n
        | otherwise = idx

fn :: tm_trim_end String Int   Int => Int
      tm_trim_end s      start idx
        | idx <= start = start
        | tm_is_space (str_char_at s (idx - 1)) = tm_trim_end s start (idx - 1)
        | otherwise = idx

fn :: tm_trim String => String
      tm_trim s      =
        n = str_len s
        st = tm_trim_start s 0 n
        en = tm_trim_end s st n
        str_slice s st en

fn :: tm_lookup [(String, String)] String => String
      tm_lookup []                 _      =  ""
      tm_lookup ((k, v):rest)      key
        | k == key = v
        | otherwise = tm_lookup rest key

fn :: tm_val_truthy String => Bool
      tm_val_truthy val
        | val == "" = False
        | val == "false" = False
        | val == "False" = False
        | val == "0" = False
        | otherwise = True
```

### 14.4.2. Implementació interna: Public API

Fixa't en com `template.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

```ridgun
fn :: tmpl render with escape String [(String, String)] TmplEscape => String
      tmpl render with escape tmpl ctx mode = tm_scan tmpl 0 (str_len tmpl) ctx mode ""

fn :: tmpl render String [(String, String)] => String
      tmpl render tmpl   ctx                =  tmpl render with escape tmpl ctx TmplEscapeNone

fn :: tmpl render html String [(String, String)] => String
      tmpl render html tmpl   ctx                =  tmpl render with escape tmpl ctx TmplEscapeHtml

fn :: tmpl render latex String [(String, String)] => String
      tmpl render latex tmpl   ctx                =  tmpl render with escape tmpl ctx TmplEscapeLatex
```

---

## 14.5. Garanties algorísmiques, memòria `RMM1`/`RMM2` i les 5 Regles d'Or de `template`

- **Garantia algorísmica i de seguretat**: Prevenció d'XSS per defecte a `tmpl render html` (escapant `&`, `<`, `>`, `"`, `'`) mentre `{{{var}}}` permet injectar fragments de confiança de forma explícita.
- **Complexitat de pila $O(1)$ amb TCO**: Tots els bucles recursius a `src/main/ridgun/lib/template.rg` estan en posició de cua, de manera que `ridgunc` els compila a salts natius sense creixement de pila.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test template.rg`.

### Les 5 Regles d'Or en programar amb `template`

1. **Declara `import template` a l'inici del fitxer** i aprofita l'equivalència entre espais i guions baixos perquè el teu codi es llegeixi com a prosa.
2. **Alinea les teves canonades de dades amb `=`**: encadena les crides a `template` en passos amb nom propi i deixa que `stable format` alineï les columnes.
3. **Aprofita les funcions totals de `template` a les teves guardes `|`**: comprova els valors de retorn o desembolica els ADTs amb *pattern matching* en lloc d'assumir que l'entrada externa sempre és vàlida.
4. **Evita copiar grans estructures si només necessites consultar un camp**: recorda que en `RMM2` els arguments d'entrada no incrementen ni decrementen comptadors (`+0` / `-0`).
5. **Combina `template` amb `test` (`import test`)**: escriu sempre assercions amb `assert equals` o `assert true` per fixar els invariants del teu domini.

---

Al **Capítol 15** passarem a explorar en profunditat la lib **`fmt`** (La lib `fmt` — Formatador Tabular Canònic 2D i Ressaltador de Sintaxi en 9 Formats).
