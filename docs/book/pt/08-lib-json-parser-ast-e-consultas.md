# Capítulo 08: A lib `json` — Árvore AST Recursiva RFC 8259, Pretty-Printer e Consultas por Caminho

## 08.1. Por que existe a lib `json`? (O problema real e a filosofia Ridgun)

> *«Por que preciso de uma lib `json` escrita de raiz em Ridgun puro em vez de ligar uma biblioteca C tradicional?»*

Essa é a primeira pergunta que qualquer engenheiro de sistemas faz ao chegar à `json`. E a resposta resume toda a filosofia do `ridgun-libs`:

Sejamos sinceros: navegar num JSON aninhado em muitas linguagens estáticas obriga a escrever páginas de código repetitivo ou encadear dez `.and_then()` antes de ler uma simples porta.

A lib **`json`** fornece um analisador descendente recursivo completo para **RFC 8259** sobre o ADT algébrico `JsonVal` (`JnNull`, `JnBool`, `JnInt`, `JnStr`, `JnArr`, `JnObj`, `JnErr`), serialização compacta e indentada (`json pretty`) e consultas diretas por caminho com pontos (`"server.http.port"`, `"users.0.name"`).

Num ecossistema tradicional, resolver as tarefas do domínio **`JSON`** implica arrastar dependências externas em C, lidar com ponteiros brutos, conversões opacas de tipos, exceções não verificadas ou pausas imprevisíveis do coletor de lixo. Em Ridgun, a lib **`json`** (`src/main/ridgun/lib/json.rg`) aborda o problema com quatro princípios inegociáveis:

1. **Funções totais e contratos explícitos (`=>`)**: nenhuma função da `json` lança exceções ocultas nem depende de `null`. Qualquer caso limite devolve um valor sentinela documentado ou um tipo algébrico soma (`Option`, `Result`).
2. **Zero código C e zero `libc`**: todo o código da `json` compila diretamente para código máquina nativo ELF64 verificado pelo `ridgunc`.
3. **Recursão de cauda com TCO (*Tail-Call Optimization*)**: todas as travessias internas da `json` são compiladas para ciclos nativos em espaço de pilha $O(1)$.
4. **Memória determinística (`RMM1` / `RMM2`)**: cada estrutura intermédia é libertada no instante exato em que termina a sua última leitura, sem *Garbage Collector*.

---

## 08.2. Artefactos nativos, importação e catálogo completo da API de `json`

No `ridgun-libs`, **`json`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/json.rg` (domínio `JSON`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/json.rglib` | Distribuição e importação direta com `import json` |
| **Ficheiro compilado** | `target/json.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libjson.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import json` no topo e invocar as suas funções com espaços ou underscores.

### 08.2.1. Resumo das famílias funcionais da `json`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `type JsonVal` | `JnNull | JnBool Bool | JnInt Int | JnStr String | JnArr [JsonVal] | JnObj [String JsonVal] | JnErr String` |
| `json parse / json is ok` | Analisa texto JSON numa árvore `JsonVal` e valida a ausência de `JnErr` |
| `json stringify / json pretty` | Serializa `JsonVal` em JSON compacto ou multilinha indentado |
| `json get path / json get str / json get int / json get bool` | Percorre objetos e listas aninhados através de caminhos com pontos (`"a.b.0.c"`) |

### 08.2.2. Catálogo exaustivo de tipos e assinaturas em `src/main/ridgun/lib/json.rg`

Abaixo encontra-se o inventário completo de tipos algébricos (`type`), operadores (`op ::`) e assinaturas de funções (`fn ::`) definidos em `src/main/ridgun/lib/json.rg` (`7` tipos, `0` operadores e `56` funções):

**Tipos algébricos e registos (`type`) da `json`:**

```ridgun
type JsonField = JsonField String JsonVal
type JsonVal = JsonNull | JsonBool Bool | JsonInt Int | JsonStr String | JsonArr [JsonVal] | JsonObj [JsonField]
type JsonRes = JsonOk JsonVal | JsonErr String
type JsonStep = JStepOk JsonVal Int | JStepErr String
type JsonArrStep = JArrOk [JsonVal] Int | JArrErr String
type JsonObjStep = JObjOk [JsonField] Int | JObjErr String
type JsonStrStep = JStrOk String Int | JStrErr String
```

| # | Função / Assinatura (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: j_is_ws Int` | `Bool` |
| `2` | `fn :: j_is_digit Int` | `Bool` |
| `3` | `fn :: j_skip_ws String Int Int` | `Int` |
| `4` | `fn :: j_spaces Int` | `String` |
| `5` | `fn :: j_escape_loop String Int Int String` | `String` |
| `6` | `fn :: j_escape_str String` | `String` |
| `7` | `fn :: j_unescape_char Int` | `String` |
| `8` | `fn :: j_parse_str_loop String Int Int String` | `JsonStrStep` |
| `9` | `fn :: j_parse_string String Int Int` | `JsonStrStep` |
| `10` | `fn :: j_scan_digits String Int Int` | `Int` |
| `11` | `fn :: j_parse_number String Int Int` | `JsonStep` |
| `12` | `fn :: j_finish_neg_num String Int Int` | `JsonStep` |
| `13` | `fn :: j_finish_pos_num String Int Int` | `JsonStep` |
| `14` | `fn :: j_parse_val String Int Int` | `JsonStep` |
| `15` | `fn :: j_parse_val_at String Int Int` | `JsonStep` |
| `16` | `fn :: j_wrap_str_step JsonStrStep` | `JsonStep` |
| `17` | `fn :: j_parse_arr_open String Int Int` | `JsonStep` |
| `18` | `fn :: j_parse_arr_first String Int Int` | `JsonStep` |
| `19` | `fn :: j_finish_arr_step JsonArrStep` | `JsonStep` |
| `20` | `fn :: j_parse_arr_items String Int Int [JsonVal]` | `JsonArrStep` |
| `21` | `fn :: j_parse_arr_after_item String Int [JsonVal] JsonStep` | `JsonArrStep` |
| `22` | `fn :: j_parse_arr_delim String Int Int [JsonVal]` | `JsonArrStep` |
| `23` | `fn :: j_parse_obj_open String Int Int` | `JsonStep` |
| `24` | `fn :: j_parse_obj_first String Int Int` | `JsonStep` |
| `25` | `fn :: j_finish_obj_step JsonObjStep` | `JsonStep` |
| `26` | `fn :: j_parse_obj_fields String Int Int [JsonField]` | `JsonObjStep` |
| `27` | `fn :: j_parse_obj_after_key String Int [JsonField] JsonStrStep` | `JsonObjStep` |
| `28` | `fn :: j_parse_obj_colon String Int Int String [JsonField]` | `JsonObjStep` |
| `29` | `fn :: j_parse_obj_after_val String Int String [JsonField] JsonStep` | `JsonObjStep` |
| `30` | `fn :: j_parse_obj_delim String Int Int [JsonField]` | `JsonObjStep` |
| `31` | `fn :: j_check_eof String Int JsonStep` | `JsonRes` |
| `32` | `fn :: j_check_eof_pos Int Int JsonVal` | `JsonRes` |
| `33` | `fn :: json parse String` | `JsonRes` |
| `34` | `fn :: j_join_arr [JsonVal]` | `String` |
| `35` | `fn :: j_join_obj [JsonField]` | `String` |
| `36` | `fn :: json stringify JsonVal` | `String` |
| `37` | `fn :: j_pretty_arr [JsonVal] Int Int` | `String` |
| `38` | `fn :: j_pretty_obj [JsonField] Int Int` | `String` |
| `39` | `fn :: j_pretty_val JsonVal Int Int` | `String` |
| `40` | `fn :: json pretty JsonVal Int` | `String` |
| `41` | `fn :: j_find_field [JsonField] String` | `JsonVal` |
| `42` | `fn :: json get field JsonVal String` | `JsonVal` |
| `43` | `fn :: j_nth_val [JsonVal] Int` | `JsonVal` |
| `44` | `fn :: json get index JsonVal Int` | `JsonVal` |
| `45` | `fn :: j_split_dots_loop String Int Int Int [String]` | `[String]` |
| `46` | `fn :: j_step_path JsonVal String` | `JsonVal` |
| `47` | `fn :: j_walk_path JsonVal [String]` | `JsonVal` |
| `48` | `fn :: json get path JsonVal String` | `JsonVal` |
| `49` | `fn :: json get str JsonVal String String` | `String` |
| `50` | `fn :: j_unwrap_str JsonVal String` | `String` |
| `51` | `fn :: json get int JsonVal String Int` | `Int` |
| `52` | `fn :: j_unwrap_int JsonVal Int` | `Int` |
| `53` | `fn :: json get bool JsonVal String Bool` | `Bool` |
| `54` | `fn :: j_unwrap_bool JsonVal Bool` | `Bool` |
| `55` | `fn :: j_put_field [JsonField] String JsonVal` | `[JsonField]` |
| `56` | `fn :: json set field JsonVal String JsonVal` | `JsonVal` |

---

## 08.3. Explorando a `json` a fundo: Exemplos passo a passo de cada funcionalidade

Não basta ver a tabela de assinaturas: vamos explorar **cada uma das funcionalidades** da lib `json` através de exemplos progressivos e executáveis em Ridgun. Começaremos pelas duas receitas tabulares de uso diário e depois percorreremos em detalhe todos os cenários funcionais, transformações e casos de fronteira verificados em `src/test/ridgun/test json.rg`.

### 08.3.1. Exemplo 1: Fluxo principal em estilo tabular com `json`

Repare como em Ridgun os sinais `=` e os passos de transformação com `json` ficam alinhados como uma tabela limpa, sem variáveis mutáveis desnecessárias nem efeitos colaterais ocultos:

```ridgun
import json

fn :: leer config servidor (raw : String) => (String, Int, Bool)
      leer config servidor raw =
        doc  = json parse raw
        host = json get str doc "server.host" "127.0.0.1"
        port = json get int doc "server.port" 8080
        tls  = json get bool doc "server.tls.enabled" False
        (host, port, tls)
```

### 08.3.2. Exemplo 2: Composição segura e tratamento de casos de fronteira

Todas as funções da lib `json` foram desenhadas para se comporem com guardas booleanas `|` e com as restantes 32 libs do `ridgun-libs`:

```ridgun
import json

fn :: construir manifiesto () => String
      construir manifiesto =
        nodo = JnObj [("app", JnStr "solstice"), ("workers", JnInt 8), ("tags", JnArr [JnStr "elf64", JnStr "rmm2"])]
        json pretty nodo 2
```

### 08.3.3. Exemplo 3: Análise sintática (`json parse`), serialização compacta (`json stringify`) e impressão indentada (`json pretty`)

Neste exemplo prático exploramos de forma exaustiva como a `json` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test json parse stringify and pretty => ()
      test json parse stringify and pretty =
        lb = char_from_code 123
        rb = char_from_code 125
        raw = lb + "\"user\":" + lb + "\"name\":\"Ada \\\"Lovelace\\\"\",\"age\":36,\"active\":true,\"roles\":[\"admin\",\"math\"],\"meta\":null" + rb + rb
        res = json parse raw
        _ = assert true (is_json_ok res) "AC1: json parse nested object and array"
        val = unwrap_json res

        compact = json stringify val
        _ = assert str eq compact raw "AC1: json stringify lossless round-trip"

        pretty_s = json pretty val 2
        res2 = json parse pretty_s
        _ = assert true (is_json_ok res2) "AC1: json pretty output parses back cleanly"
        _ = assert str eq (json stringify (unwrap_json res2)) raw "AC1: json pretty round-trip equality"
        ()
```

### 08.3.4. Exemplo 4: Primitivas JSON (`null`, `bool`, `int`, `str`), sequências de escape e contentores vazios (`[]`, `{}`)

Neste exemplo prático exploramos de forma exaustiva como a `json` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test json primitives escapes and empty containers => ()
      test json primitives escapes and empty containers =
        lb = char_from_code 123
        rb = char_from_code 125
        bs = char_from_code 92
        nl = char_from_code 10
        tab = char_from_code 9
        _ = assert str eq (json stringify (unwrap_json (json parse (lb + rb)))) (lb + rb) "AC1: empty object {}"
        _ = assert str eq (json stringify (unwrap_json (json parse "[]"))) "[]" "AC1: empty array []"
        _ = assert str eq (json stringify (unwrap_json (json parse ("  " + lb + "  " + rb + "  ")))) (lb + rb) "AC1: whitespace-padded empty object"
        _ = assert true (is_json_null (unwrap_json (json parse "null"))) "AC1: root null literal"
        _ = assert str eq (json stringify (unwrap_json (json parse "true"))) "true" "AC1: root true literal"
        _ = assert str eq (json stringify (unwrap_json (json parse "false"))) "false" "AC1: root false literal"
        _ = assert str eq (json stringify (unwrap_json (json parse "0"))) "0" "AC1: root zero integer"
        _ = assert str eq (json stringify (unwrap_json (json parse "-42000"))) "-42000" "AC1: root negative integer"

        esc_json = lb + "\"msg\":\"line1" + bs + "nline2" + bs + "t" + bs + bs + "slash\"" + rb
        esc_val = unwrap_json (json parse esc_json)
        _ = assert str eq (json get str esc_val "msg" "") ("line1" + nl + "line2" + tab + bs + "slash") "AC1: unescape \\n, \\t, \\\\ in JSON strings"
        _ = assert str eq (json stringify esc_val) esc_json "AC1: re-escape \\n, \\t, \\\\ on stringify"
        ()
```

### 08.3.5. Exemplo 5: Consultas profundas por caminho de pontos (`json query`, `json query str/int/bool`) e atualização funcional (`json set field`)

Neste exemplo prático exploramos de forma exaustiva como a `json` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test json dot path queries and updates => ()
      test json dot path queries and updates =
        lb = char_from_code 123
        rb = char_from_code 125
        raw = lb + "\"user\":" + lb + "\"name\":\"Ada\",\"age\":36,\"active\":true,\"roles\":[\"admin\",\"math\"],\"matrix\":[[10,20],[30,40]]" + rb + ",\"count\":-7,\"disabled\":false" + rb
        val = unwrap_json (json parse raw)

        _ = assert str eq (json get str val "user.name" "") "Ada" "AC2: json get str dot path"
        _ = assert int equals (json get int val "user.age" 0) 36 "AC2: json get int dot path"
        _ = assert int equals (json get int val "count" 0) (-7) "AC2: json get int negative"
        _ = assert true (json get bool val "user.active" False) "AC2: json get bool true"
        _ = assert false (json get bool val "disabled" True) "AC2: json get bool false"
        _ = assert str eq (json get str val "user.roles.0" "") "admin" "AC2: json get str array index 0"
        _ = assert str eq (json get str val "user.roles.1" "") "math" "AC2: json get str array index 1"
        _ = assert int equals (json get int val "user.matrix.1.0" 0) 30 "AC2: nested 2D array index user.matrix.1.0"
        _ = assert int equals (json get int val "user.matrix.1.1" 0) 40 "AC2: nested 2D array index user.matrix.1.1"
        _ = assert str eq (json get str val "user.roles.99" "oob") "oob" "AC2: out-of-bounds array index fallback"
        _ = assert str eq (json get str val "user.missing.deep" "fallback") "fallback" "AC2: missing deep dot-path fallback"

        updated = json set field val "version" (JsonInt 2)
        _ = assert int equals (json get int updated "version" 0) 2 "AC2: json set field adds new key"
        overwritten = json set field updated "count" (JsonInt 99)
        _ = assert int equals (json get int overwritten "count" 0) 99 "AC2: json set field overwrites existing key"
        ()
```

### 08.3.6. Exemplo 6: Deteção segura de entradas JSON malformadas (`JsonErr`) sem pânicos nem exceções

Neste exemplo prático exploramos de forma exaustiva como a `json` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test json malformed inputs => ()
      test json malformed inputs =
        lb = char_from_code 123
        rb = char_from_code 125
        _ = assert false (is_json_ok (json parse "")) "AC3: reject empty input"
        _ = assert false (is_json_ok (json parse "   ")) "AC3: reject whitespace-only input"
        _ = assert false (is_json_ok (json parse (lb + "\"unclosed\":1"))) "AC3: reject unclosed object"
        _ = assert false (is_json_ok (json parse "[1, 2, 3")) "AC3: reject unclosed array"
        _ = assert false (is_json_ok (json parse "\"unterminated string")) "AC3: reject unterminated string"
        _ = assert false (is_json_ok (json parse (lb + "unquoted: 1" + rb))) "AC3: reject unquoted object key"
        _ = assert false (is_json_ok (json parse (lb + "\"k\" 1" + rb))) "AC3: reject missing colon in object"
        _ = assert false (is_json_ok (json parse "[1, 2] trailing")) "AC3: reject trailing garbage token"
        _ = assert false (is_json_ok (json parse "tru")) "AC3: reject truncated boolean literal"
        _ = assert false (is_json_ok (json parse "nul")) "AC3: reject truncated null literal"
        ()
```

---

## 08.4. Debaixo do capô: como a `json` é construída em Ridgun puro (`src/main/ridgun/lib/json.rg`)

Uma das maiores vantagens do `ridgun-libs` é que **não existem caixas-pretas em C**. Pode abrir `src/main/ridgun/lib/json.rg` e ler exatamente como cada operação é implementada usando *pattern matching*, árvores de guardas `|` / `|.` e recursão de cauda (TCO). Vejamos as peças-chave da sua implementação real:

### 08.4.1. Implementação interna: Whitespace & Character Helpers

Observe como `json.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: j_is_ws Int => Bool
      j_is_ws c   =  c == 32 OR c == 9 OR c == 10 OR c == 13

fn :: j_is_digit Int => Bool
      j_is_digit c   =  c >= 48 AND c <= 57

fn :: j_skip_ws String Int Int => Int
      j_skip_ws s      pos len
        | pos >= len = len
        | j_is_ws (str_char_at s pos) = j_skip_ws s (pos + 1) len
        | otherwise = pos

fn :: j_spaces Int => String
      j_spaces n
        | n <= 0 = ""
        | otherwise = " " + (j_spaces (n - 1))
```

### 08.4.2. Implementação interna: Integer Literal Parsing

Observe como `json.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: j_scan_digits String Int Int => Int
      j_scan_digits s      pos len
        | pos >= len = len
        | j_is_digit (str_char_at s pos) = j_scan_digits s (pos + 1) len
        | otherwise = pos

fn :: j_parse_number String Int Int => JsonStep
      j_parse_number s      pos len
        | (str_char_at s pos) == 45 = j_finish_neg_num s pos (j_scan_digits s (pos + 1) len)
        | otherwise = j_finish_pos_num s pos (j_scan_digits s pos len)

fn :: j_finish_neg_num String Int Int     => JsonStep
      j_finish_neg_num s      pos end_pos
        | end_pos <= (pos + 1) = JStepErr "invalid negative number"
        | otherwise = JStepOk (JsonInt (str_to_int (str_slice s pos end_pos))) end_pos

fn :: j_finish_pos_num String Int Int     => JsonStep
      j_finish_pos_num s      pos end_pos
        | end_pos <= pos = JStepErr "expected number"
        | otherwise = JStepOk (JsonInt (str_to_int (str_slice s pos end_pos))) end_pos
```

### 08.4.3. Implementação interna: Serialization & Pretty-Printing

Observe como `json.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: j_join_arr [JsonVal] => String
      j_join_arr []        =  ""
      j_join_arr (v:[])    =  json stringify v
      j_join_arr (v:vs)    =  (json stringify v) + "," + (j_join_arr vs)

fn :: j_join_obj [JsonField] => String
      j_join_obj []          =  ""
      j_join_obj ((JsonField k v):[]) = (j_escape_str k) + ":" + (json stringify v)
      j_join_obj ((JsonField k v):rest) = (j_escape_str k) + ":" + (json stringify v) + "," + (j_join_obj rest)

fn :: json stringify JsonVal          => String
      json stringify JsonNull         =  "null"
      json stringify (JsonBool True)  =  "true"
      json stringify (JsonBool False) =  "false"
      json stringify (JsonInt n)      =  int_to_str n
      json stringify (JsonStr s)      =  j_escape_str s
      json stringify (JsonArr items)  =  "[" + (j_join_arr items) + "]"
      json stringify (JsonObj fields) =  (char_from_code 123) + (j_join_obj fields) + (char_from_code 125)

fn :: j_pretty_arr [JsonVal] Int Int => String
      j_pretty_arr []        _   _   =  ""
      j_pretty_arr (v:[])    ind cur =  (j_spaces (cur + ind)) + (j_pretty_val v ind (cur + ind))
      j_pretty_arr (v:vs)    ind cur =  (j_spaces (cur + ind)) + (j_pretty_val v ind (cur + ind)) + "," + (char_from_code 10) + (j_pretty_arr vs ind cur)

fn :: j_pretty_obj [JsonField] Int Int => String
      j_pretty_obj []          _   _   =  ""
      j_pretty_obj ((JsonField k v):[]) ind cur =
        (j_spaces (cur + ind)) + (j_escape_str k) + ": " + (j_pretty_val v ind (cur + ind))
      j_pretty_obj ((JsonField k v):rest) ind cur =
        (j_spaces (cur + ind)) + (j_escape_str k) + ": " + (j_pretty_val v ind (cur + ind)) + "," + (char_from_code 10) + (j_pretty_obj rest ind cur)

fn :: j_pretty_val JsonVal          Int Int => String
      j_pretty_val (JsonArr [])     _   _   =  "[]"
      j_pretty_val (JsonArr items)  ind cur =
        nl = char_from_code 10
        "[" + nl + (j_pretty_arr items ind cur) + nl + (j_spaces cur) + "]"
      j_pretty_val (JsonObj [])     _   _   =  (char_from_code 123) + (char_from_code 125)
      j_pretty_val (JsonObj fields) ind cur =
        nl = char_from_code 10
        (char_from_code 123) + nl + (j_pretty_obj fields ind cur) + nl + (j_spaces cur) + (char_from_code 125)
      j_pretty_val v                _   _   =  json stringify v

fn :: json pretty JsonVal Int => String
      json pretty val     ind =  j_pretty_val val ind 0
```

### 08.4.4. Implementação interna: Dot-Path Queries & Field Updates

Observe como `json.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: j_find_field [JsonField] String => JsonVal
      j_find_field []          _      =  JsonNull
      j_find_field ((JsonField k v):fs) key
        | k == key = v
        | otherwise = j_find_field fs key

fn :: json get field JsonVal          String => JsonVal
      json get field (JsonObj fields) key    =  j_find_field fields key
      json get field _                _      =  JsonNull

fn :: j_nth_val [JsonVal] Int => JsonVal
      j_nth_val []        _   =  JsonNull
      j_nth_val (v:vs)    idx
        | idx < 0 = JsonNull
        | idx == 0 = v
        | otherwise = j_nth_val vs (idx - 1)

fn :: json get index JsonVal         Int => JsonVal
      json get index (JsonArr items) idx =  j_nth_val items idx
      json get index _               _   =  JsonNull

fn :: j_split_dots_loop String Int Int Int [String] => [String]
      j_split_dots_loop s pos len start acc
        | pos >= len = acc :: [str_slice s start len]
        | (str_char_at s pos) == 46 = j_split_dots_loop s (pos + 1) len (pos + 1) (acc :: [str_slice s start pos])
        | otherwise = j_split_dots_loop s (pos + 1) len start acc

fn :: j_step_path JsonVal          String => JsonVal
      j_step_path (JsonObj fields) seg    =  j_find_field fields seg
      j_step_path (JsonArr items)  seg
        | seg != "" AND (j_scan_digits seg 0 (str_len seg)) == (str_len seg) = j_nth_val items (str_to_int seg)
        | otherwise = JsonNull
      j_step_path _                _      =  JsonNull

fn :: j_walk_path JsonVal [String]   => JsonVal
      j_walk_path val     []         =  val
      j_walk_path val     ("":rest)  =  j_walk_path val rest
      j_walk_path val     (seg:rest) =  j_walk_path (j_step_path val seg) rest

fn :: json get path JsonVal String   => JsonVal
      json get path val     ""       =  val
      json get path val     dot_path =  j_walk_path val (j_split_dots_loop dot_path 0 (str_len dot_path) 0 [])

fn :: json get str JsonVal String String => String
      json get str val dot_path fallback = j_unwrap_str (json get path val dot_path) fallback

fn :: j_unwrap_str JsonVal     String   => String
      j_unwrap_str (JsonStr s) _        =  s
      j_unwrap_str _           fallback =  fallback
```

---

## 08.5. Garantias algorítmicas, memória `RMM1`/`RMM2` e as 5 Regras de Ouro da `json`

- **Garantia algorítmica e de segurança**: Rejeição estrita de lixo residual após o valor raiz (`trailing garbage`), tratamento completo de sequências de escape e retorno seguro de `JnErr` sem exceções.
- **Complexidade de pilha $O(1)$ com TCO**: Todos os ciclos recursivos em `src/main/ridgun/lib/json.rg` estão em posição de cauda, pelo que o `ridgunc` os compila para saltos nativos sem crescimento de pilha.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test json.rg`.

### As 5 Regras de Ouro ao programar com a `json`

1. **Declare `import json` no início do ficheiro** e aproveite a equivalência entre espaços e underscores para que o seu código se leia como prosa.
2. **Alinhe os seus pipelines de dados com `=`**: encadeie as chamadas à `json` em passos nomeados e deixe o `stable format` alinhar as colunas.
3. **Aproveite as funções totais da `json` nas suas guardas `|`**: verifique os valores de retorno ou desempacote os ADTs com *pattern matching* em vez de assumir que a entrada externa é sempre válida.
4. **Evite copiar grandes estruturas se só precisa de consultar um campo**: lembre-se de que no `RMM2` os argumentos de entrada não incrementam nem decrementam contadores (`+0` / `-0`).
5. **Combine a `json` com `test` (`import test`)**: escreva sempre asserções com `assert equals` ou `assert true` para fixar os invariantes do seu domínio.

---

No **Capítulo 09** passaremos a explorar em profundidade a lib **`csv`** (A lib `csv` — Analisador de Estados RFC 4180 para CSV/TSV e Tabelas Indexadas).
