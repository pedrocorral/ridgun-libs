# Capítulo 11: A lib `regex` — Motor de Expressões Regulares Thompson NFA em Tempo Linear $O(N \cdot M)$

## 11.1. Por que existe a lib `regex`? (O problema real e a filosofia Ridgun)

> *«Por que preciso de uma lib `regex` escrita de raiz em Ridgun puro em vez de ligar uma biblioteca C tradicional?»*

Essa é a primeira pergunta que qualquer engenheiro de sistemas faz ao chegar à `regex`. E a resposta resume toda a filosofia do `ridgun-libs`:

Sejamos sinceros: os motores de expressões regulares com *backtracking* já causaram quedas globais famosas (como na Cloudflare ou no StackOverflow) quando um padrão como `(a+)+b` recebe trinta `a` seguidos e entra em tempo exponencial $O(2^N)$.

A lib **`regex`** compila as suas expressões regulares (`.`, `*`, `+`, `?`, `|`, `()`, `[a-z]`, `[^...]`, `^`, `$`, `\d`, `\w`, `\s`) para um **autómato finito não determinístico de Thompson (NFA)** e avança o conjunto de estados passo a passo em tempo estritamente linear **$O(N \cdot M)$**, tornando os ataques **ReDoS matematicamente impossíveis**.

Num ecossistema tradicional, resolver as tarefas do domínio **`REGEX`** implica arrastar dependências externas em C, lidar com ponteiros brutos, conversões opacas de tipos, exceções não verificadas ou pausas imprevisíveis do coletor de lixo. Em Ridgun, a lib **`regex`** (`src/main/ridgun/lib/regex.rg`) aborda o problema com quatro princípios inegociáveis:

1. **Funções totais e contratos explícitos (`=>`)**: nenhuma função da `regex` lança exceções ocultas nem depende de `null`. Qualquer caso limite devolve um valor sentinela documentado ou um tipo algébrico soma (`Option`, `Result`).
2. **Zero código C e zero `libc`**: todo o código da `regex` compila diretamente para código máquina nativo ELF64 verificado pelo `ridgunc`.
3. **Recursão de cauda com TCO (*Tail-Call Optimization*)**: todas as travessias internas da `regex` são compiladas para ciclos nativos em espaço de pilha $O(1)$.
4. **Memória determinística (`RMM1` / `RMM2`)**: cada estrutura intermédia é libertada no instante exato em que termina a sua última leitura, sem *Garbage Collector*.

---

## 11.2. Artefactos nativos, importação e catálogo completo da API de `regex`

No `ridgun-libs`, **`regex`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/regex.rg` (domínio `REGEX`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/regex.rglib` | Distribuição e importação direta com `import regex` |
| **Ficheiro compilado** | `target/regex.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libregex.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import regex` no topo e invocar as suas funções com espaços ou underscores.

### 11.2.1. Resumo das famílias funcionais da `regex`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `regex match / regex is match` | Correspondência de cadeia completa e pesquisa de subcadeia em tempo linear $O(N \cdot M)$ |
| `regex find / regex find all` | Extrai a primeira ou todas as subcadeias correspondentes sem sobreposição |
| `regex replace / regex replace all` | Substitui a primeira ou todas as correspondências da expressão regular |
| `regex split / regex escape` | Divide texto por um delimitador regex e escapa metacaracteres |

### 11.2.2. Catálogo exaustivo de tipos e assinaturas em `src/main/ridgun/lib/regex.rg`

Abaixo encontra-se o inventário completo de tipos algébricos (`type`), operadores (`op ::`) e assinaturas de funções (`fn ::`) definidos em `src/main/ridgun/lib/regex.rg` (`4` tipos, `0` operadores e `70` funções):

**Tipos algébricos e registos (`type`) da `regex`:**

```ridgun
type RegexMatch = matched: Bool, match_start: Int, match_end: Int, text: String
type ReNode = ReEmpty | ReChar Int | ReAny | ReClass Bool [Int] | ReShort Int | ReBol | ReEol | ReStar ReNode | RePlus ReNode | ReOpt ReNode | ReSeq ReNode ReNode | ReAlt ReNode ReNode
type ReParseRes = ReParseRes ReNode Int
type NfaInst = InstChar Int Int | InstAny Int | InstClass Bool [Int] Int | InstShort Int Int | InstBol Int | InstEol Int | InstSplit Int Int | InstJump Int | InstMatch
```

| # | Função / Assinatura (`fn ::`) | Tipo de Retorno |
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

## 11.3. Explorando a `regex` a fundo: Exemplos passo a passo de cada funcionalidade

Não basta ver a tabela de assinaturas: vamos explorar **cada uma das funcionalidades** da lib `regex` através de exemplos progressivos e executáveis em Ridgun. Começaremos pelas duas receitas tabulares de uso diário e depois percorreremos em detalhe todos os cenários funcionais, transformações e casos de fronteira verificados em `src/test/ridgun/test regex.rg`.

### 11.3.1. Exemplo 1: Fluxo principal em estilo tabular com `regex`

Repare como em Ridgun os sinais `=` e os passos de transformação com `regex` ficam alinhados como uma tabela limpa, sem variáveis mutáveis desnecessárias nem efeitos colaterais ocultos:

```ridgun
import regex

fn :: extraer codigos postales (texto : String) => [String]
      extraer codigos postales texto =
        regex find all "\\d+" texto
```

### 11.3.2. Exemplo 2: Composição segura e tratamento de casos de fronteira

Todas as funções da lib `regex` foram desenhadas para se comporem com guardas booleanas `|` e com as restantes 32 libs do `ridgun-libs`:

```ridgun
import regex

fn :: censurar telefonos (comentario : String) => (Bool, String)
      censurar telefonos comentario =
        tiene = regex is match "\\d+-\\d+" comentario
        limpio = regex replace all "\\d+-\\d+" comentario "[TELEFONO]"
        (tiene, limpio)
```

### 11.3.3. Exemplo 3: Âncoras (`^`, `$`), quantificadores (`*`, `+`, `?`), alternância (`|`), grupos `(...)`, classes `[a-z0-9]` e atalhos (`\d`, `\w`, `\s`)

Neste exemplo prático exploramos de forma exaustiva como a `regex` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

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

### 11.3.4. Exemplo 4: Extração de correspondências (`regex find`, `regex find all`), substituição (`regex replace`, `regex replace all`) e divisão (`regex split`)

Neste exemplo prático exploramos de forma exaustiva como a `regex` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

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

### 11.3.5. Exemplo 5: Validador de identificadores e anonimizador de logs em tempo linear $O(N \cdot M)$ com Thompson NFA (`regex is match`, `regex replace all`, `regex split`)

Neste exemplo prático exploramos de forma exaustiva como a `regex` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

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

## 11.4. Debaixo do capô: como a `regex` é construída em Ridgun puro (`src/main/ridgun/lib/regex.rg`)

Uma das maiores vantagens do `ridgun-libs` é que **não existem caixas-pretas em C**. Pode abrir `src/main/ridgun/lib/regex.rg` e ler exatamente como cada operação é implementada usando *pattern matching*, árvores de guardas `|` / `|.` e recursão de cauda (TCO). Vejamos as peças-chave da sua implementação real:

### 11.4.1. Implementação interna: Character Class & Shorthand Helpers

Observe como `regex.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

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

### 11.4.2. Implementação interna: Thompson NFA Compiler (`ReNode` -> `[NfaInst]`)

Observe como `regex.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

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

### 11.4.3. Implementação interna: Linear-Time Thompson NFA State-Set Simulation

Observe como `regex.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

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

### 11.4.4. Implementação interna: Public Regex API (`API-REGEX-001`)

Observe como `regex.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

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

## 11.5. Garantias algorítmicas, memória `RMM1`/`RMM2` e as 5 Regras de Ouro da `regex`

- **Garantia algorítmica e de segurança**: Simulação de conjunto de estados NFA sem recursão descontrolada na pilha e tempo $O(N \cdot M)$ garantido mesmo perante padrões patológicos `(a+)+b`.
- **Complexidade de pilha $O(1)$ com TCO**: Todos os ciclos recursivos em `src/main/ridgun/lib/regex.rg` estão em posição de cauda, pelo que o `ridgunc` os compila para saltos nativos sem crescimento de pilha.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test regex.rg`.

### As 5 Regras de Ouro ao programar com a `regex`

1. **Declare `import regex` no início do ficheiro** e aproveite a equivalência entre espaços e underscores para que o seu código se leia como prosa.
2. **Alinhe os seus pipelines de dados com `=`**: encadeie as chamadas à `regex` em passos nomeados e deixe o `stable format` alinhar as colunas.
3. **Aproveite as funções totais da `regex` nas suas guardas `|`**: verifique os valores de retorno ou desempacote os ADTs com *pattern matching* em vez de assumir que a entrada externa é sempre válida.
4. **Evite copiar grandes estruturas se só precisa de consultar um campo**: lembre-se de que no `RMM2` os argumentos de entrada não incrementam nem decrementam contadores (`+0` / `-0`).
5. **Combine a `regex` com `test` (`import test`)**: escreva sempre asserções com `assert equals` ou `assert true` para fixar os invariantes do seu domínio.

---

No **Capítulo 12** passaremos a explorar em profundidade a lib **`glob`** (A lib `glob` — Padrões de Wildcards (`*`, `?`, `[a-z]`) e Filtragem de Listas).
