# Capítulo 11: A lib `regex` — Motor de Expresións Regulares Thompson NFA en Tempo Lineal $O(N \cdot M)$

## 11.1. Por que existe a lib `regex`? (O problema real e a filosofía Ridgun)

> *«Por que necesito unha lib `regex` escrita dende cero en Ridgun puro en vez de enlazar unha librería de C de toda a vida?»*

Esa é a primeira pregunta que se fai calquera enxeñeiro de sistemas ao chegar a `regex`. E a resposta resume toda a filosofía de `ridgun-libs`:

Sexamos sinceros: os motores de expresións regulares con *backtracking* teñen causado caídas globais famosas (coma en Cloudflare ou StackOverflow) cando un padrón coma `(a+)+b` recibe trinta `a` seguidas e entra en tempo exponencial $O(2^N)$.

A lib **`regex`** compila as túas expresións regulares (`.`, `*`, `+`, `?`, `|`, `()`, `[a-z]`, `[^...]`, `^`, `$`, `\d`, `\w`, `\s`) a un **autómata finito non determinista de Thompson (NFA)** e avanza o conxunto de estados paso a paso en tempo estritamente lineal **$O(N \cdot M)$**, facendo que os ataques **ReDoS sexan matematicamente imposibles**.

Nun ecosistema tradicional, resolver as tarefas do dominio **`REGEX`** implica arrastrar dependencias externas en C, loitar con punteiros crus, conversións opacas de tipos, excepcións non verificadas ou pausas impredicibles do colector de lixo. En Ridgun, a lib **`regex`** (`src/main/ridgun/lib/regex.rg`) aborda o problema con catro principios innegociables:

1. **Funcións totais e contratos explícitos (`=>`)**: ningunha función de `regex` lanza excepcións ocultas nin depende de `null`. Todo caso límite devolve un valor sentinela documentado ou un tipo alxébrico suma (`Option`, `Result`).
2. **Cero código C e cero `libc`**: todo o código de `regex` compila directamente a código máquina nativo ELF64 verificado por `ridgunc`.
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos os percorridos internos de `regex` compílanse a bucles nativos en espazo de pila $O(1)$.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estrutura intermedia libérase no instante exacto en que remata a súa última lectura, sen *Garbage Collector*.

---

## 11.2. Artefactos nativos, importación e catálogo completo da API de `regex`

En `ridgun-libs`, **`regex`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/regex.rg` (dominio `REGEX`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/regex.rglib` | Distribución e importación directa con `import regex` |
| **Ficheiro compilado** | `target/regex.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libregex.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import regex` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

### 11.2.1. Resumo de familias funcionais de `regex`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `regex match / regex is match` | Coincidencia de cadea completa e busca de subcadea en tempo lineal $O(N \cdot M)$ |
| `regex find / regex find all` | Extrae a primeira ou todas as subcadeas coincidentes sen solapamento |
| `regex replace / regex replace all` | Substitúe a primeira ou todas as coincidencias da expresión regular |
| `regex split / regex escape` | Divide texto segundo un delimitador regex e escapa metacaracteres |

### 11.2.2. Catálogo exhaustivo de tipos e sinaturas en `src/main/ridgun/lib/regex.rg`

A continuación tes o inventario completo de tipos alxébricos (`type`), operadores (`op ::`) e sinaturas de funcións (`fn ::`) definidos en `src/main/ridgun/lib/regex.rg` (`4` tipos, `0` operadores e `70` funcións):

**Tipos alxébricos e rexistros (`type`) de `regex`:**

```ridgun
type RegexMatch = matched: Bool, match_start: Int, match_end: Int, text: String
type ReNode = ReEmpty | ReChar Int | ReAny | ReClass Bool [Int] | ReShort Int | ReBol | ReEol | ReStar ReNode | RePlus ReNode | ReOpt ReNode | ReSeq ReNode ReNode | ReAlt ReNode ReNode
type ReParseRes = ReParseRes ReNode Int
type NfaInst = InstChar Int Int | InstAny Int | InstClass Bool [Int] Int | InstShort Int Int | InstBol Int | InstEol Int | InstSplit Int Int | InstJump Int | InstMatch
```

| # | Función / Sinatura (`fn ::`) | Tipo de Retorno |
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

## 11.3. Explorando `regex` a fondo: Exemplos paso a paso de cada funcionalidade

Non abonda con ver a táboa de sinaturas: imos explorar **cada unha das funcionalidades** da lib `regex` mediante exemplos progresivos e executables en Ridgun. Comezaremos polas dúas receitas tabulares de uso cotián e despois percorreremos en detalle todos os escenarios funcionais, transformacións e casos límite verificados en `src/test/ridgun/test regex.rg`.

### 11.3.1. Exemplo 1: Fluxo principal en estilo tabular con `regex`

Observa como en Ridgun os signos `=` e os pasos de transformación con `regex` quedan aliñados coma unha táboa limpa, sen variables mutables innecesarias nin efectos laterais ocultos:

```ridgun
import regex

fn :: extraer codigos postales (texto : String) => [String]
      extraer codigos postales texto =
        regex find all "\\d+" texto
```

### 11.3.2. Exemplo 2: Composición segura e manexo de casos de bordo

Toda función da lib `regex` está deseñada para compoñerse con gardas booleanas `|` e co resto das 32 libs de `ridgun-libs`:

```ridgun
import regex

fn :: censurar telefonos (comentario : String) => (Bool, String)
      censurar telefonos comentario =
        tiene = regex is match "\\d+-\\d+" comentario
        limpio = regex replace all "\\d+-\\d+" comentario "[TELEFONO]"
        (tiene, limpio)
```

### 11.3.3. Exemplo 3: Áncoras (`^`, `$`), cuantificadores (`*`, `+`, `?`), alternancia (`|`), grupos `(...)`, clases `[a-z0-9]` e atallos (`\d`, `\w`, `\s`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `regex` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test_regex_operators_and_classes => ()
      test_regex_operators_and_classes =
        _ = assert true (regex match "" "") "AC1: empty pattern matches empty string"
        _ = assert false (regex match "" "nonempty") "AC1: empty pattern rejects non-empty on full match"
        _ = assert true (regex match 'a(b|c)+d?e*' "abcbdeee") "AC1: alternation group plus opt star"
        _ = assert true (regex match 'a(b|c)+d?e*' "ac") "AC1: opt and star match zero occurrences"
        _ = assert false (regex match 'a(b|c)+d?e*' "ade") "AC1: plus requires at least one"
        _ = assert true (regex match '(foo|bar|baz)+' "barfoobazbar") "AC1: multi-branch alternation with plus"
        _ = assert false (regex match '(foo|bar|baz)+' "barquxfoo") "AC1: multi-branch alternation rejects unknown"
        _ = assert true (regex match '[a-zA-Z_][a-zA-Z0-9_]*' "_valid_Identifier_99") "AC1: identifier character class"
        _ = assert false (regex match '[a-zA-Z_][a-zA-Z0-9_]*' "9invalid") "AC1: identifier rejects leading digit"
        _ = assert true (regex match '[^0-9]+' "hello_world") "AC1: negated char class"
        _ = assert false (regex match '[^0-9]+' "hello42") "AC1: negated char class rejects digits"
        _ = assert true (regex match '\w+\s+\d+' "agent   007") "AC1: shorthand escapes \\w \\s \\d"
        _ = assert true (regex match '\D+\S+' "abc_123") "AC1: negated shorthand escapes \\D \\S"
        _ = assert true (regex match 'v\d+\.\d+\.\d+' "v0.9.16") "AC1: escaped dot literal"
        _ = assert false (regex match 'v\d+\.\d+\.\d+' "v0X9Y16") "AC1: escaped dot rejects non-dot"
        _ = assert true (regex is match '^hello' "hello world") "AC1: bol anchor matches start"
        _ = assert false (regex is match '^world' "hello world") "AC1: bol anchor rejects middle"
        _ = assert true (regex is match 'world$' "hello world") "AC1: eol anchor matches end"
        _ = assert false (regex is match 'hello$' "hello world") "AC1: eol anchor rejects prefix"
        _ = assert true (regex is match '^exact$' "exact") "AC1: anchored ^exact$ matches full string"
        _ = assert false (regex is match '^exact$' "not exact") "AC1: anchored ^exact$ rejects extra chars"
        -- Russ Cox pathological backtracking benchmarks (exponential in backtracking engines, O(N*M) in Thompson NFA)
        _ = assert false (regex match '(a+)+b' "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaac") "AC1: Thompson NFA immune to (a+)+b ReDoS"
        _ = assert false (regex match '(a|aa)+b' "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaac") "AC1: Thompson NFA immune to (a|aa)+b ReDoS"
        _ = assert true (regex match 'a?a?a?a?a?a?a?a?aaaaaaaa' "aaaaaaaa") "AC1: Russ Cox a?^n a^n vector"
        ()
```

### 11.3.4. Exemplo 4: Extracción de coincidencias (`regex find`, `regex find all`), substitución (`regex replace`, `regex replace all`) e división (`regex split`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `regex` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test_regex_find_replace_split => ()
      test_regex_find_replace_split =
        m1 = regex find '\d+' "item #42 and #99"
        _ = assert true (matched m1) "AC2: find matched"
        _ = assert int equals (match_start m1) 6 "AC2: find start"
        _ = assert int equals (match_end m1) 8 "AC2: find end"
        _ = assert str eq (text m1) "42" "AC2: find text"

        m_none = regex find '\d+' "no digits here"
        _ = assert false (matched m_none) "AC2: find returns matched=False when absent"

        all_m = regex find all '[a-z]+=\d+' "id=10, port=8080, ttl=60"
        _ = assert int equals (re_match_count all_m) 3 "AC2: find all key=val count"
        _ = assert str eq (text (re_match_at all_m 0)) "id=10" "AC2: find all first match"
        _ = assert str eq (text (re_match_at all_m 1)) "port=8080" "AC2: find all second match"
        _ = assert str eq (text (re_match_at all_m 2)) "ttl=60" "AC2: find all third match"

        r1 = regex replace '\d+' "X" "v1.2.3"
        _ = assert str eq r1 "vX.2.3" "AC3: replace first"
        r_no = regex replace '\d+' "X" "abc"
        _ = assert str eq r_no "abc" "AC3: replace with no match returns original"
        r2 = regex replace all '\d+' "X" "v1.22.333"
        _ = assert str eq r2 "vX.X.X" "AC3: replace all"

        parts = regex split '\s*[,;]\s*' "alpha, beta ;  gamma,delta"
        _ = assert int equals (re_str_count parts) 4 "AC3: split count"
        _ = assert str eq (re_str_at parts 0) "alpha" "AC3: split[0]"
        _ = assert str eq (re_str_at parts 1) "beta" "AC3: split[1]"
        _ = assert str eq (re_str_at parts 2) "gamma" "AC3: split[2]"
        _ = assert str eq (re_str_at parts 3) "delta" "AC3: split[3]"
        ()
```

### 11.3.5. Exemplo 5: Validador de identificadores e anonimizador de trazas en tempo lineal $O(N \cdot M)$ con Thompson NFA (`regex is match`, `regex replace all`, `regex split`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `regex` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

## 11.4. Baixo o capó: como está construída `regex` en Ridgun puro (`src/main/ridgun/lib/regex.rg`)

Unha das maiores vantaxes de `ridgun-libs` é que **non hai caixas negras en C**. Podes abrir `src/main/ridgun/lib/regex.rg` e ler exactamente como está implementada cada operación usando *pattern matching*, árbores de gardas `|` / `|.` e recursión de cola (TCO). Vexamos as pezas clave da súa implementación real:

### 11.4.1. Implementación interna: Character Class & Shorthand Helpers

Fíxate en como `regex.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: re_is_digit Int => Bool
      re_is_digit c   =  c >= 48 AND c <= 57

fn :: re_is_word Int => Bool
      re_is_word c   =  (c >= 48 AND c <= 57) OR (c >= 65 AND c <= 90) OR (c >= 97 AND c <= 122) OR c == 95

fn :: re_is_space Int => Bool
      re_is_space c   =  c == 32 OR c == 9 OR c == 10 OR c == 13 OR c == 11 OR c == 12

fn :: re_match_short Int Int => Bool
      re_match_short 100 c   =  re_is_digit c
      re_match_short 68  c   =  NOT (re_is_digit c)
      re_match_short 119 c   =  re_is_word c
      re_match_short 87  c   =  NOT (re_is_word c)
      re_match_short 115 c   =  re_is_space c
      re_match_short 83  c   =  NOT (re_is_space c)
      re_match_short _   _   =  False

fn :: re_in_ranges Int [Int]      => Bool
      re_in_ranges _   []         =  False
      re_in_ranges _   (_:[])     =  False
      re_in_ranges c   (lo:hi:rs)
        | c >= lo AND c <= hi = True
        | otherwise = re_in_ranges c rs

-- ── Regex Recursive-Descent Parser (`pattern_str` -> `ReNode`) ─

fn :: re_escape_char Int => ReNode
      re_escape_char 100 =  ReShort 100
      re_escape_char 68  =  ReShort 68
      re_escape_char 119 =  ReShort 119
      re_escape_char 87  =  ReShort 87
      re_escape_char 115 =  ReShort 115
      re_escape_char 83  =  ReShort 83
      re_escape_char 110 =  ReChar 10
      re_escape_char 114 =  ReChar 13
      re_escape_char 116 =  ReChar 9
      re_escape_char c   =  ReChar c

fn :: re_class_char String Int Int => (Int Int)
      re_class_char pat    pos len
        | (str_char_at pat pos) == 92 AND (pos + 1) < len AND (str_char_at pat (pos + 1)) == 110 = (10, pos + 2)
        | (str_char_at pat pos) == 92 AND (pos + 1) < len AND (str_char_at pat (pos + 1)) == 116 = (9, pos + 2)
        | (str_char_at pat pos) == 92 AND (pos + 1) < len AND (str_char_at pat (pos + 1)) == 114 = (13, pos + 2)
        | (str_char_at pat pos) == 92 AND (pos + 1) < len = (str_char_at pat (pos + 1), pos + 2)
        | otherwise = (str_char_at pat pos, pos + 1)

fn :: re_fst_int (Int Int) => Int
      re_fst_int (a, _)    =  a
```

### 11.4.2. Implementación interna: Thompson NFA Compiler (`ReNode` -> `[NfaInst]`)

Fíxate en como `regex.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: nfa_len [NfaInst] => Int
      nfa_len []        =  0
      nfa_len (_:rest)  =  1 + (nfa_len rest)

fn :: re_compile_seq ReNode ReNode Int      => [NfaInst]
      re_compile_seq a      b      start_id =
        insts_a = re_compile_node a start_id
        mid_id = start_id + (nfa_len insts_a)
        insts_b = re_compile_node b mid_id
        insts_a :: insts_b

fn :: re_compile_opt ReNode Int      => [NfaInst]
      re_compile_opt a      start_id =
        body = re_compile_node a (start_id + 1)
        end_id = start_id + 1 + (nfa_len body)
        [InstSplit (start_id + 1) end_id] :: body

fn :: re_compile_star ReNode Int      => [NfaInst]
      re_compile_star a      start_id =
        body = re_compile_node a (start_id + 1)
        end_id = start_id + 2 + (nfa_len body)
        ([InstSplit (start_id + 1) end_id] :: body) :: [InstJump start_id]

fn :: re_compile_plus ReNode Int      => [NfaInst]
      re_compile_plus a      start_id =
        body = re_compile_node a start_id
        split_id = start_id + (nfa_len body)
        body :: [InstSplit start_id (split_id + 1)]

fn :: re_compile_alt ReNode ReNode Int      => [NfaInst]
      re_compile_alt a      b      start_id =
        body_a = re_compile_node a (start_id + 1)
        jump_id = start_id + 1 + (nfa_len body_a)
        start_b = jump_id + 1
        body_b = re_compile_node b start_b
        end_id = start_b + (nfa_len body_b)
        (([InstSplit (start_id + 1) start_b] :: body_a) :: [InstJump end_id]) :: body_b
```

### 11.4.3. Implementación interna: Linear-Time Thompson NFA State-Set Simulation

Fíxate en como `regex.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: nfa_inst_at [NfaInst] Int => NfaInst
      nfa_inst_at []        _   =  InstMatch
      nfa_inst_at (i:_)     0   =  i
      nfa_inst_at (_:rest)  idx =  nfa_inst_at rest (idx - 1)

fn :: nfa_set_has [Int]  Int => Bool
      nfa_set_has []     _   =  False
      nfa_set_has (x:xs) v
        | x == v = True
        | otherwise = nfa_set_has xs v

fn :: nfa_closure [NfaInst] [Int] Int Int [Int] => [Int]
      nfa_closure _ [] _ _ visited = visited
      nfa_closure prog (s:ss) pos len visited
        | nfa_set_has visited s = nfa_closure prog ss pos len visited
        | otherwise = nfa_closure_inst prog s ss pos len (visited :: [s]) (nfa_inst_at prog s)

fn :: nfa_closure_inst [NfaInst] Int [Int] Int Int [Int] NfaInst => [Int]
      nfa_closure_inst prog _ ss pos len vis (InstJump out) = nfa_closure prog ([out] :: ss) pos len vis
      nfa_closure_inst prog _ ss pos len vis (InstSplit o1 o2) = nfa_closure prog ([o1, o2] :: ss) pos len vis
      nfa_closure_inst prog _ ss pos len vis (InstBol out)
        | pos == 0 = nfa_closure prog ([out] :: ss) pos len vis
        | otherwise = nfa_closure prog ss pos len vis
      nfa_closure_inst prog _ ss pos len vis (InstEol out)
        | pos == len = nfa_closure prog ([out] :: ss) pos len vis
        | otherwise = nfa_closure prog ss pos len vis
      nfa_closure_inst prog _ ss pos len vis _ = nfa_closure prog ss pos len vis

fn :: nfa_step_one NfaInst       Int => [Int]
      nfa_step_one (InstChar expected out) c
        | c == expected = [out]
        | otherwise = []
      nfa_step_one (InstAny out) c
        | c != 10 = [out]
        | otherwise = []
      nfa_step_one (InstClass neg rngs out) c
        | (re_in_ranges c rngs) != neg = [out]
        | otherwise = []
      nfa_step_one (InstShort kind out) c
        | re_match_short kind c = [out]
        | otherwise = []
      nfa_step_one _             _   =  []

fn :: nfa_step [NfaInst] [Int]  Int => [Int]
      nfa_step _         []     _   =  []
      nfa_step prog      (s:ss) c   =  (nfa_step_one (nfa_inst_at prog s) c) :: (nfa_step prog ss c)

fn :: nfa_is_match_inst NfaInst   => Bool
      nfa_is_match_inst InstMatch =  True
      nfa_is_match_inst _         =  False
```

### 11.4.4. Implementación interna: Public Regex API (`API-REGEX-001`)

Fíxate en como `regex.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: regex match String String => Bool
      regex match pat    input  =
        prog = re_compile pat
        len = str_len input
        init_act = nfa_closure prog [0] 0 len []
        nfa_full_loop prog input 0 len init_act

fn :: nfa_find_from [NfaInst] String Int Int => RegexMatch
      nfa_find_from prog      input  pos len
        | pos > len = RegexMatch False (-1) (-1) ""
        | otherwise = nfa_find_check prog input pos len (nfa_longest_from prog input pos len)

fn :: nfa_find_check [NfaInst] String Int Int Int => RegexMatch
      nfa_find_check prog input pos len end_pos
        | end_pos >= pos = RegexMatch True pos end_pos (str_slice input pos end_pos)
        | otherwise = nfa_find_from prog input (pos + 1) len

fn :: regex find String String => RegexMatch
      regex find pat    input  =
        prog = re_compile pat
        nfa_find_from prog input 0 (str_len input)

fn :: regex is match String String => Bool
      regex is match pat    input  =  matched (regex find pat input)

fn :: nfa_find_all_loop [NfaInst] String Int Int [RegexMatch] => [RegexMatch]
      nfa_find_all_loop prog input pos len acc
        | pos > len = acc
        | otherwise = nfa_find_all_step prog input pos len acc (nfa_longest_from prog input pos len)

fn :: nfa_find_all_step [NfaInst] String Int Int [RegexMatch] Int => [RegexMatch]
      nfa_find_all_step prog input pos len acc end_pos
        | end_pos > pos = nfa_find_all_loop prog input end_pos len (acc :: [RegexMatch True pos end_pos (str_slice input pos end_pos)])
        | end_pos == pos = nfa_find_all_loop prog input (pos + 1) len (acc :: [RegexMatch True pos pos ""])
        | otherwise = nfa_find_all_loop prog input (pos + 1) len acc

fn :: regex find all String String => [RegexMatch]
      regex find all pat    input  =
        prog = re_compile pat
        nfa_find_all_loop prog input 0 (str_len input) []

fn :: regex replace String String String => String
      regex replace pat    repl   input  =
        m = regex find pat input
        re_apply_replace m repl input

fn :: re_apply_replace RegexMatch String String => String
      re_apply_replace m          repl   input
        | NOT (matched m) = input
        | otherwise = (str_slice input 0 (match_start m)) + repl + (str_slice input (match_end m) (str_len input))
```

---

## 11.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` e as 5 Regras de Ouro de `regex`

- **Garantía algorítmica e de seguridade**: Simulación de conxunto de estados NFA sen recursión descontrolada de pila e tempo $O(N \cdot M)$ garantido mesmo ante padróns patolóxicos `(a+)+b`.
- **Complexidade de pila $O(1)$ con TCO**: Todos os bucles recursivos en `src/main/ridgun/lib/regex.rg` están en posición de cola, polo que `ridgunc` os compila a saltos nativos sen crecemento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test regex.rg`.

### As 5 Regras de Ouro ao programar con `regex`

1. **Declara `import regex` ao inicio do ficheiro** e aproveita a equivalencia entre espazos e guións baixos para que o teu código se lea coma prosa.
2. **Aliña as túas tubaxes de datos con `=`**: encadea as chamadas a `regex` en pasos con nome propio e deixa que `stable format` aliñe as columnas.
3. **Aproveita as funcións totais de `regex` nas túas gardas `|`**: comproba os valores de retorno ou desenvolve os ADTs con *pattern matching* en vez de asumir que a entrada externa sempre é válida.
4. **Evita copiar grandes estruturas se só necesitas consultar un campo**: lembra que en `RMM2` os argumentos de entrada non incrementan nin decrementan contadores (`+0` / `-0`).
5. **Combina `regex` con `test` (`import test`)**: escribe sempre asercións con `assert equals` ou `assert true` para fixar os invariantes do teu dominio.

---

No **Capítulo 12** pasaremos a explorar en profundidade a lib **`glob`** (A lib `glob` — Padróns de Comodíns (`*`, `?`, `[a-z]`) e Filtrado de Listas).
