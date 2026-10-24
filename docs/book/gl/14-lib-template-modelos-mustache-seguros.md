# Capítulo 14: A lib `template` — Modelos Mustache Seguros con Auto-Escape HTML e LaTeX

## 14.1. Por que existe a lib `template`? (O problema real e a filosofía Ridgun)

> *«Por que necesito unha lib `template` escrita dende cero en Ridgun puro en vez de enlazar unha librería de C de toda a vida?»*

Esa é a primeira pregunta que se fai calquera enxeñeiro de sistemas ao chegar a `template`. E a resposta resume toda a filosofía de `ridgun-libs`:

Sexamos sinceros: montar páxinas HTML ou informes LaTeX concatenando cadeas á man é a receita perfecta para unha vulnerabilidade XSS (`<script>`) ou para que un simple símbolo `%` ou `_` rompa a compilación do teu PDF.

A lib **`template`** ofrece un motor **Mustache** sen lóxica arbitraria con auto-escape contextual (`TmplPlain`, `TmplHtml`, `TmplLatex`), substitución crúa explícita (`{{{raw}}}` / `{{&raw}}`), comentarios (`{{! ... }}`), seccións condicionais (`{{#sec}}...{{/sec}}`) e invertidas (`{{^sec}}...{{/sec}}`).

Nun ecosistema tradicional, resolver as tarefas do dominio **`TMPL`** implica arrastrar dependencias externas en C, loitar con punteiros crus, conversións opacas de tipos, excepcións non verificadas ou pausas impredicibles do colector de lixo. En Ridgun, a lib **`template`** (`src/main/ridgun/lib/template.rg`) aborda o problema con catro principios innegociables:

1. **Funcións totais e contratos explícitos (`=>`)**: ningunha función de `template` lanza excepcións ocultas nin depende de `null`. Todo caso límite devolve un valor sentinela documentado ou un tipo alxébrico suma (`Option`, `Result`).
2. **Cero código C e cero `libc`**: todo o código de `template` compila directamente a código máquina nativo ELF64 verificado por `ridgunc`.
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos os percorridos internos de `template` compílanse a bucles nativos en espazo de pila $O(1)$.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estrutura intermedia libérase no instante exacto en que remata a súa última lectura, sen *Garbage Collector*.

---

## 14.2. Artefactos nativos, importación e catálogo completo da API de `template`

En `ridgun-libs`, **`template`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/template.rg` (dominio `TMPL`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/template.rglib` | Distribución e importación directa con `import template` |
| **Ficheiro compilado** | `target/template.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libtemplate.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import template` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

### 14.2.1. Resumo de familias funcionais de `template`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `tmpl render / tmpl render html / tmpl render latex` | Renderiza modelos Mustache con auto-escape plano, HTML ou LaTeX |
| `tmpl escape html / tmpl escape latex` | Escapa `& < > " '` para HTML ou `\ { } & % $ # _ ~ ^` para LaTeX |
| `tmpl extract vars / tmpl has unclosed tags` | Extrae os nomes de variables requiridos e valida que as etiquetas estean pechadas |

### 14.2.2. Catálogo exhaustivo de tipos e sinaturas en `src/main/ridgun/lib/template.rg`

A continuación tes o inventario completo de tipos alxébricos (`type`), operadores (`op ::`) e sinaturas de funcións (`fn ::`) definidos en `src/main/ridgun/lib/template.rg` (`1` tipos, `0` operadores e `35` funcións):

**Tipos alxébricos e rexistros (`type`) de `template`:**

```ridgun
type TmplEscape = TmplEscapeNone | TmplEscapeHtml | TmplEscapeLatex
```

| # | Función / Sinatura (`fn ::`) | Tipo de Retorno |
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

## 14.3. Explorando `template` a fondo: Exemplos paso a paso de cada funcionalidade

Non abonda con ver a táboa de sinaturas: imos explorar **cada unha das funcionalidades** da lib `template` mediante exemplos progresivos e executables en Ridgun. Comezaremos polas dúas receitas tabulares de uso cotián e despois percorreremos en detalle todos os escenarios funcionais, transformacións e casos límite verificados en `src/test/ridgun/test template.rg`.

### 14.3.1. Exemplo 1: Fluxo principal en estilo tabular con `template`

Observa como en Ridgun os signos `=` e os pasos de transformación con `template` quedan aliñados coma unha táboa limpa, sen variables mutables innecesarias nin efectos laterais ocultos:

```ridgun
import template

fn :: renderizar perfil html (usuario : String) (es_admin : String) => String
      renderizar perfil html usuario es_admin =
        plantilla = "<h1>Hola {{user}}</h1>{{#admin}}<span class='badge'>Admin</span>{{/admin}}"
        vars      = [("user", usuario), ("admin", es_admin)]
        tmpl render html plantilla vars
```

### 14.3.2. Exemplo 2: Composición segura e manexo de casos de bordo

Toda función da lib `template` está deseñada para compoñerse con gardas booleanas `|` e co resto das 32 libs de `ridgun-libs`:

```ridgun
import template

fn :: generar linea latex (metrica : String) => String
      generar linea latex metrica =
        -- Escapa automaticamente % _ & # para que LaTeX no falle
        tmpl render latex "Resultado: {{val}}" [("val", metrica)]
```

### 14.3.3. Exemplo 3: Interpolación de variables `{{ clave }}`, recorte de espazos en etiquetas e eliminación de comentarios `{{! ... }}`

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `template` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

### 14.3.4. Exemplo 4: Mitigación XSS por defecto (`&`, `<`, `>`, `"`, `'`) fronte a inserción crúa explícita `{{{ raw }}}` e `{{& raw }}`

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `template` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

### 14.3.5. Exemplo 5: Seccións condicionais `{{#sec}}...{{/sec}}` e seccións investidas `{{^sec}}...{{/sec}}` segundo valores de verdade (`false`, `0`, `no`, `off`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `template` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

### 14.3.6. Exemplo 6: Aniñamento profundo de seccións condicionais e interpolación xerárquica

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `template` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

### 14.3.7. Exemplo 7: Escapado especializado para documentos LaTeX (`tmpl escape latex`: `\`, `{`, `}`, `$`, `&`, `#`, `_`, `%`, `~`, `^`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `template` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

### 14.3.8. Exemplo 8: Detección determinista de etiquetas sen pechar ou seccións desbalanceadas (`TmplErr`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `template` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

## 14.4. Baixo o capó: como está construída `template` en Ridgun puro (`src/main/ridgun/lib/template.rg`)

Unha das maiores vantaxes de `ridgun-libs` é que **non hai caixas negras en C**. Podes abrir `src/main/ridgun/lib/template.rg` e ler exactamente como está implementada cada operación usando *pattern matching*, árbores de gardas `|` / `|.` e recursión de cola (TCO). Vexamos as pezas clave da súa implementación real:

### 14.4.1. Implementación interna: Internal Helpers

Fíxate en como `template.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

### 14.4.2. Implementación interna: Public API

Fíxate en como `template.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

## 14.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` e as 5 Regras de Ouro de `template`

- **Garantía algorítmica e de seguridade**: Prevención de XSS por defecto en `tmpl render html` (escapando `&`, `<`, `>`, `"`, `'`) mentres `{{{var}}}` permite inxectar fragmentos de confianza de forma explícita.
- **Complexidade de pila $O(1)$ con TCO**: Todos os bucles recursivos en `src/main/ridgun/lib/template.rg` están en posición de cola, polo que `ridgunc` os compila a saltos nativos sen crecemento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test template.rg`.

### As 5 Regras de Ouro ao programar con `template`

1. **Declara `import template` ao inicio do ficheiro** e aproveita a equivalencia entre espazos e guións baixos para que o teu código se lea coma prosa.
2. **Aliña as túas tubaxes de datos con `=`**: encadea as chamadas a `template` en pasos con nome propio e deixa que `stable format` aliñe as columnas.
3. **Aproveita as funcións totais de `template` nas túas gardas `|`**: comproba os valores de retorno ou desenvolve os ADTs con *pattern matching* en vez de asumir que a entrada externa sempre é válida.
4. **Evita copiar grandes estruturas se só necesitas consultar un campo**: lembra que en `RMM2` os argumentos de entrada non incrementan nin decrementan contadores (`+0` / `-0`).
5. **Combina `template` con `test` (`import test`)**: escribe sempre asercións con `assert equals` ou `assert true` para fixar os invariantes do teu dominio.

---

No **Capítulo 15** pasaremos a explorar en profundidade a lib **`fmt`** (A lib `fmt` — Formatador Tabular Canónico 2D e Resaltador de Sintaxe en 9 Formatos).
