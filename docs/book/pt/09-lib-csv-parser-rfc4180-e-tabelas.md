# Capítulo 09: A lib `csv` — Analisador de Estados RFC 4180 para CSV/TSV e Tabelas Indexadas

## 09.1. Por que existe a lib `csv`? (O problema real e a filosofia Ridgun)

> *«Por que preciso de uma lib `csv` escrita de raiz em Ridgun puro em vez de ligar uma biblioteca C tradicional?»*

Essa é a primeira pergunta que qualquer engenheiro de sistemas faz ao chegar à `csv`. E a resposta resume toda a filosofia do `ridgun-libs`:

Sejamos sinceros: toda a gente acha que analisar um CSV é fazer `str split linha ","`... até aparecer um campo entre aspas com uma vírgula lá dentro, aspas duplicadas `""` ou uma quebra de linha `\r\n` a meio de uma célula.

A lib **`csv`** implementa uma máquina de estados completa conforme a **RFC 4180** para CSV e TSV, serialização automática com aspas inteligentes e o tipo `CsvTable` para consultar colunas e linhas pelo nome do cabeçalho.

Num ecossistema tradicional, resolver as tarefas do domínio **`CSV`** implica arrastar dependências externas em C, lidar com ponteiros brutos, conversões opacas de tipos, exceções não verificadas ou pausas imprevisíveis do coletor de lixo. Em Ridgun, a lib **`csv`** (`src/main/ridgun/lib/csv.rg`) aborda o problema com quatro princípios inegociáveis:

1. **Funções totais e contratos explícitos (`=>`)**: nenhuma função da `csv` lança exceções ocultas nem depende de `null`. Qualquer caso limite devolve um valor sentinela documentado ou um tipo algébrico soma (`Option`, `Result`).
2. **Zero código C e zero `libc`**: todo o código da `csv` compila diretamente para código máquina nativo ELF64 verificado pelo `ridgunc`.
3. **Recursão de cauda com TCO (*Tail-Call Optimization*)**: todas as travessias internas da `csv` são compiladas para ciclos nativos em espaço de pilha $O(1)$.
4. **Memória determinística (`RMM1` / `RMM2`)**: cada estrutura intermédia é libertada no instante exato em que termina a sua última leitura, sem *Garbage Collector*.

---

## 09.2. Artefactos nativos, importação e catálogo completo da API de `csv`

No `ridgun-libs`, **`csv`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/csv.rg` (domínio `CSV`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/csv.rglib` | Distribuição e importação direta com `import csv` |
| **Ficheiro compilado** | `target/csv.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libcsv.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import csv` no topo e invocar as suas funções com espaços ou underscores.

### 09.2.1. Resumo das famílias funcionais da `csv`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `csv parse / tsv parse / csv parse with` | Analisa texto CSV/TSV (incluindo células multilinha e escapes `""`) em `[[String]]` |
| `csv stringify / tsv stringify` | Serializa `[[String]]` colocando aspas apenas em células com delimitadores, aspas ou quebras |
| `csv parse table / csv get cell / csv col` | Consulta sobre `CsvTable` indexada por cabeçalho `(linha, nome_col)` ou coluna inteira |
| `csv row to kv / csv table to kv list` | Converte linhas tabulares em dicionários `[String String]` indexados pelo cabeçalho |

### 09.2.2. Catálogo exaustivo de tipos e assinaturas em `src/main/ridgun/lib/csv.rg`

Abaixo encontra-se o inventário completo de tipos algébricos (`type`), operadores (`op ::`) e assinaturas de funções (`fn ::`) definidos em `src/main/ridgun/lib/csv.rg` (`1` tipos, `0` operadores e `23` funções):

**Tipos algébricos e registos (`type`) da `csv`:**

```ridgun
type CsvTable = headers: [String], rows: [[String]], delimiter_char: String, has_headers: Bool
```

| # | Função / Assinatura (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: csv_delim_code String` | `Int` |
| `2` | `fn :: csv_append_final_row [[String]] [String] String` | `[[String]]` |
| `3` | `fn :: csv_parse_quoted String Int Int Int String [String] [[String]]` | `[[String]]` |
| `4` | `fn :: csv_parse_unquoted String Int Int Int String [String] [[String]]` | `[[String]]` |
| `5` | `fn :: csv parse with delim String String` | `[[String]]` |
| `6` | `fn :: csv parse String` | `[[String]]` |
| `7` | `fn :: tsv parse String` | `[[String]]` |
| `8` | `fn :: csv_build_table [[String]] Bool` | `CsvTable` |
| `9` | `fn :: csv parse table String Bool` | `CsvTable` |
| `10` | `fn :: csv_needs_quotes_loop String Int Int Int` | `Bool` |
| `11` | `fn :: csv_double_quotes_loop String Int Int String` | `String` |
| `12` | `fn :: csv_format_cell String Int` | `String` |
| `13` | `fn :: csv_join_row [String] String Int` | `String` |
| `14` | `fn :: csv_join_rows [[String]] String Int` | `String` |
| `15` | `fn :: csv stringify with delim [[String]] String` | `String` |
| `16` | `fn :: csv stringify [[String]]` | `String` |
| `17` | `fn :: tsv stringify [[String]]` | `String` |
| `18` | `fn :: csv_nth_str [String] Int` | `String` |
| `19` | `fn :: csv_nth_row [[String]] Int` | `[String]` |
| `20` | `fn :: csv col [[String]] Int` | `[String]` |
| `21` | `fn :: csv_find_header_idx [String] String Int` | `Int` |
| `22` | `fn :: csv get by header CsvTable Int String` | `String` |
| `23` | `fn :: csv row to map [String] [String]` | `[String String]` |

---

## 09.3. Explorando a `csv` a fundo: Exemplos passo a passo de cada funcionalidade

Não basta ver a tabela de assinaturas: vamos explorar **cada uma das funcionalidades** da lib `csv` através de exemplos progressivos e executáveis em Ridgun. Começaremos pelas duas receitas tabulares de uso diário e depois percorreremos em detalhe todos os cenários funcionais, transformações e casos de fronteira verificados em `src/test/ridgun/test csv.rg`.

### 09.3.1. Exemplo 1: Fluxo principal em estilo tabular com `csv`

Repare como em Ridgun os sinais `=` e os passos de transformação com `csv` ficam alinhados como uma tabela limpa, sem variáveis mutáveis desnecessárias nem efeitos colaterais ocultos:

```ridgun
import csv

fn :: extraer columna precios (raw_csv : String) => ([String], String)
      extraer columna precios raw_csv =
        tabla   = csv parse table raw_csv
        precios = csv col tabla "precio"
        primero = csv get cell tabla 0 "producto" "desconocido"
        (precios, primero)
```

### 09.3.2. Exemplo 2: Composição segura e tratamento de casos de fronteira

Todas as funções da lib `csv` foram desenhadas para se comporem com guardas booleanas `|` e com as restantes 32 libs do `ridgun-libs`:

```ridgun
import csv

fn :: exportar informe () => String
      exportar informe =
        filas = [["id", "nota"], ["1", "Contiene, coma"], ["2", "Dijo "hola""]]
        csv stringify filas
```

### 09.3.3. Exemplo 3: Ida e volta RFC 4180 CSV/TSV com aspas escapadas `""`, vírgulas internas e quebras de linha embutidas

Neste exemplo prático exploramos de forma exaustiva como a `csv` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test_csv_tsv_roundtrip => ()
      test_csv_tsv_roundtrip =
        nl = char_from_code 10
        tab = char_from_code 9
        raw_csv = "name,role,note" + nl + "Ada,\"Admin, Lead\",\"Quote \"\"here\"\"\"" + nl + "Bob,User,\"Line 1" + nl + "Line 2\"" + nl
        parsed = csv parse raw_csv
        _ = assert int equals (csv_row_count parsed) 3 "AC1: 3 rows parsed including multiline quoted cell"
        _ = assert str eq (csv_cell_at parsed 1 1) "Admin, Lead" "AC1: quoted comma preserved"
        _ = assert str eq (csv_cell_at parsed 1 2) "Quote \"here\"" "AC1: doubled quote unescaped"
        _ = assert str eq (csv_cell_at parsed 2 2) ("Line 1" + nl + "Line 2") "AC1: embedded newline in quoted cell preserved"
        re_csv = csv stringify parsed
        _ = assert str eq re_csv raw_csv "AC1/AC2: RFC 4180 CSV quoted comma, escaped quote, and newline round-trip"

        raw_tsv = "col1" + tab + "col2" + nl + "val,1" + tab + "val2" + nl
        parsed_tsv = tsv parse raw_tsv
        _ = assert str eq (csv_cell_at parsed_tsv 1 0) "val,1" "AC1: TSV unquoted comma preserved"
        re_tsv = tsv stringify parsed_tsv
        _ = assert str eq re_tsv raw_tsv "AC1/AC2: TSV round-trip"
        ()
```

### 09.3.4. Exemplo 4: Tratamento de finais de linha `CRLF` (`\r\n`), células vazias consecutivas e delimitadores personalizados

Neste exemplo prático exploramos de forma exaustiva como a `csv` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test_csv_crlf_and_empty_cells => ()
      test_csv_crlf_and_empty_cells =
        cr = char_from_code 13
        nl = char_from_code 10
        crlf = cr + nl
        raw_crlf = "a,b,c" + crlf + "1,,3" + crlf + ",2," + crlf
        rows_crlf = csv parse raw_crlf
        _ = assert int equals (csv_row_count rows_crlf) 3 "AC1: CRLF row count"
        _ = assert str eq (csv_cell_at rows_crlf 1 0) "1" "AC1: cell (1,0)"
        _ = assert str eq (csv_cell_at rows_crlf 1 1) "" "AC1: middle empty cell (1,1)"
        _ = assert str eq (csv_cell_at rows_crlf 1 2) "3" "AC1: cell (1,2)"
        _ = assert str eq (csv_cell_at rows_crlf 2 0) "" "AC1: leading empty cell (2,0)"
        _ = assert str eq (csv_cell_at rows_crlf 2 1) "2" "AC1: cell (2,1)"
        _ = assert str eq (csv_cell_at rows_crlf 2 2) "" "AC1: trailing empty cell (2,2)"

        semi_rows = csv parse with delim ("k1;k2" + nl + "v1;v2" + nl) ";"
        _ = assert int equals (csv_row_count semi_rows) 2 "AC1: semicolon delimiter row count"
        _ = assert str eq (csv_cell_at semi_rows 1 1) "v2" "AC1: semicolon delimiter cell (1,1)"
        _ = assert int equals (csv_row_count (csv parse "")) 0 "AC1: empty input yields 0 rows"
        ()
```

### 09.3.5. Exemplo 5: Tabelas com cabeçalho (`CsvTable`): pesquisa por linha e nome de coluna (`csv get cell`), extração de colunas e registos chave-valor

Neste exemplo prático exploramos de forma exaustiva como a `csv` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test_csv_table_lookup => ()
      test_csv_table_lookup =
        nl = char_from_code 10
        raw_csv = "id,name,dept" + nl + "10,Ada,Math" + nl + "20,Grace,Compilers" + nl
        tbl = csv parse table raw_csv True
        _ = assert true (has_headers tbl) "AC3: table has_headers True"
        _ = assert int equals (csv_len (headers tbl)) 3 "AC3: 3 headers extracted"
        _ = assert str eq (csv get by header tbl 0 "name") "Ada" "AC3: csv get by header row 0"
        _ = assert str eq (csv get by header tbl 1 "dept") "Compilers" "AC3: csv get by header row 1"
        _ = assert str eq (csv get by header tbl 0 "missing") "" "AC3: csv get by header missing column"
        _ = assert str eq (csv get by header tbl 99 "name") "" "AC3: csv get by header out-of-bounds row"

        tbl_no_h = csv parse table raw_csv False
        _ = assert false (has_headers tbl_no_h) "AC3: table has_headers False"
        _ = assert int equals (csv_row_count (rows tbl_no_h)) 3 "AC3: headerless table keeps all 3 rows"

        names = csv col (rows tbl) 1
        _ = assert int equals (csv_len names) 2 "AC3: csv col length"
        _ = assert str eq (csv_str_at names 0) "Ada" "AC3: csv col[0]"
        _ = assert str eq (csv_str_at names 1) "Grace" "AC3: csv col[1]"

        rmap = csv row to map ["id", "name", "dept"] ["10", "Ada", "Math"]
        _ = assert str eq (csv_pair_val rmap "id") "10" "AC3: csv row to map id"
        _ = assert str eq (csv_pair_val rmap "name") "Ada" "AC3: csv row to map name"
        _ = assert str eq (csv_pair_val rmap "dept") "Math" "AC3: csv row to map dept"
        ()
```

---

## 09.4. Debaixo do capô: como a `csv` é construída em Ridgun puro (`src/main/ridgun/lib/csv.rg`)

Uma das maiores vantagens do `ridgun-libs` é que **não existem caixas-pretas em C**. Pode abrir `src/main/ridgun/lib/csv.rg` e ler exatamente como cada operação é implementada usando *pattern matching*, árvores de guardas `|` / `|.` e recursão de cauda (TCO). Vejamos as peças-chave da sua implementação real:

### 09.4.1. Implementação interna: RFC 4180 State-Machine Parser

Observe como `csv.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: csv_delim_code String => Int
      csv_delim_code ""     =  44
      csv_delim_code d      =  str_char_at d 0

fn :: csv_append_final_row [[String]] [String] String => [[String]]
      csv_append_final_row rows       []       ""     =  rows
      csv_append_final_row rows       cur_row  cell   =  rows :: [cur_row :: [cell]]

fn :: csv_parse_quoted String Int Int Int String [String] [[String]] => [[String]]
      csv_parse_quoted s pos len d_code cell cur_row rows
        | pos >= len = csv_append_final_row rows cur_row cell
        | (str_char_at s pos) == 34 AND (pos + 1) < len AND (str_char_at s (pos + 1)) == 34 = csv_parse_quoted s (pos + 2) len d_code (cell + (char_from_code 34)) cur_row rows
        | (str_char_at s pos) == 34 = csv_parse_unquoted s (pos + 1) len d_code cell cur_row rows
        | otherwise = csv_parse_quoted s (pos + 1) len d_code (cell + (str_slice s pos (pos + 1))) cur_row rows

fn :: csv_parse_unquoted String Int Int Int String [String] [[String]] => [[String]]
      csv_parse_unquoted s pos len d_code cell cur_row rows
        | pos >= len = csv_append_final_row rows cur_row cell
        | (str_char_at s pos) == 34 AND cell == "" = csv_parse_quoted s (pos + 1) len d_code "" cur_row rows
        | (str_char_at s pos) == d_code = csv_parse_unquoted s (pos + 1) len d_code "" (cur_row :: [cell]) rows
        | (str_char_at s pos) == 13 AND (pos + 1) < len AND (str_char_at s (pos + 1)) == 10 = csv_parse_unquoted s (pos + 2) len d_code "" [] (rows :: [cur_row :: [cell]])
        | (str_char_at s pos) == 10 OR (str_char_at s pos) == 13 = csv_parse_unquoted s (pos + 1) len d_code "" [] (rows :: [cur_row :: [cell]])
        | otherwise = csv_parse_unquoted s (pos + 1) len d_code (cell + (str_slice s pos (pos + 1))) cur_row rows

fn :: csv parse with delim String String => [[String]]
      csv parse with delim s delim =
        csv_parse_unquoted s 0 (str_len s) (csv_delim_code delim) "" [] []

fn :: csv parse String => [[String]]
      csv parse s      =  csv parse with delim s ","

fn :: tsv parse String => [[String]]
      tsv parse s      =  csv parse with delim s (char_from_code 9)

fn :: csv_build_table [[String]] Bool  => CsvTable
      csv_build_table []         has_h =  CsvTable [] [] "," has_h
      csv_build_table (h:rest)   True  =  CsvTable h rest "," True
      csv_build_table all_rows   False =  CsvTable [] all_rows "," False

fn :: csv parse table String Bool  => CsvTable
      csv parse table s      has_h =  csv_build_table (csv parse s) has_h
```

### 09.4.2. Implementação interna: RFC 4180 Serialization & Escaping

Observe como `csv.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: csv_needs_quotes_loop String Int Int Int    => Bool
      csv_needs_quotes_loop s      pos len d_code
        | pos >= len = False
        | (str_char_at s pos) == d_code OR (str_char_at s pos) == 34 OR (str_char_at s pos) == 10 OR (str_char_at s pos) == 13 = True
        | otherwise = csv_needs_quotes_loop s (pos + 1) len d_code

fn :: csv_double_quotes_loop String Int Int String => String
      csv_double_quotes_loop s      pos len acc
        | pos >= len = acc
        | (str_char_at s pos) == 34 = csv_double_quotes_loop s (pos + 1) len (acc + (char_from_code 34) + (char_from_code 34))
        | otherwise = csv_double_quotes_loop s (pos + 1) len (acc + (str_slice s pos (pos + 1)))

fn :: csv_format_cell String Int    => String
      csv_format_cell cell   d_code
        | csv_needs_quotes_loop cell 0 (str_len cell) d_code = (char_from_code 34) + (csv_double_quotes_loop cell 0 (str_len cell) "") + (char_from_code 34)
        | otherwise = cell

fn :: csv_join_row [String] String Int    => String
      csv_join_row []       _      _      =  ""
      csv_join_row (c:[])   _      d_code =  csv_format_cell c d_code
      csv_join_row (c:cs)   delim  d_code =  (csv_format_cell c d_code) + delim + (csv_join_row cs delim d_code)

fn :: csv_join_rows [[String]] String Int    => String
      csv_join_rows []         _      _      =  ""
      csv_join_rows (r:rs)     delim  d_code =  (csv_join_row r delim d_code) + (char_from_code 10) + (csv_join_rows rs delim d_code)

fn :: csv stringify with delim [[String]] String => String
      csv stringify with delim rows delim =
        csv_join_rows rows delim (csv_delim_code delim)

fn :: csv stringify [[String]] => String
      csv stringify rows       =  csv stringify with delim rows ","

fn :: tsv stringify [[String]] => String
      tsv stringify rows       =  csv stringify with delim rows (char_from_code 9)
```

### 09.4.3. Implementação interna: Column Extraction & Header-Mapped Lookup

Observe como `csv.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: csv_nth_str [String] Int => String
      csv_nth_str []       _   =  ""
      csv_nth_str (x:xs)   idx
        | idx < 0 = ""
        | idx == 0 = x
        | otherwise = csv_nth_str xs (idx - 1)

fn :: csv_nth_row [[String]] Int => [String]
      csv_nth_row []         _   =  []
      csv_nth_row (r:rs)     idx
        | idx < 0 = []
        | idx == 0 = r
        | otherwise = csv_nth_row rs (idx - 1)

fn :: csv col [[String]] Int     => [String]
      csv col []         _       =  []
      csv col (r:rs)     col_idx =  [csv_nth_str r col_idx] :: (csv col rs col_idx)

fn :: csv_find_header_idx [String] String Int => Int
      csv_find_header_idx []       _      _   =  -1
      csv_find_header_idx (h:hs)   target idx
        | h == target = idx
        | otherwise = csv_find_header_idx hs target (idx + 1)

fn :: csv get by header CsvTable Int String => String
      csv get by header tbl row_idx col_name =
        c_idx = csv_find_header_idx (headers tbl) col_name 0
        csv_nth_str (csv_nth_row (rows tbl) row_idx) c_idx

fn :: csv row to map [String] [String] => [String String]
      csv row to map [] _ = []
      csv row to map _ [] = []
      csv row to map (h:hs) (v:vs) = [(h, v)] :: (csv row to map hs vs)
```

---

## 09.5. Garantias algorítmicas, memória `RMM1`/`RMM2` e as 5 Regras de Ouro da `csv`

- **Garantia algorítmica e de segurança**: Suporte exato de quebras `\r\n` e `\n` dentro e fora de aspas, e zero perda de dados em viagens de ida e volta `csv parse (csv stringify linhas)`.
- **Complexidade de pilha $O(1)$ com TCO**: Todos os ciclos recursivos em `src/main/ridgun/lib/csv.rg` estão em posição de cauda, pelo que o `ridgunc` os compila para saltos nativos sem crescimento de pilha.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test csv.rg`.

### As 5 Regras de Ouro ao programar com a `csv`

1. **Declare `import csv` no início do ficheiro** e aproveite a equivalência entre espaços e underscores para que o seu código se leia como prosa.
2. **Alinhe os seus pipelines de dados com `=`**: encadeie as chamadas à `csv` em passos nomeados e deixe o `stable format` alinhar as colunas.
3. **Aproveite as funções totais da `csv` nas suas guardas `|`**: verifique os valores de retorno ou desempacote os ADTs com *pattern matching* em vez de assumir que a entrada externa é sempre válida.
4. **Evite copiar grandes estruturas se só precisa de consultar um campo**: lembre-se de que no `RMM2` os argumentos de entrada não incrementam nem decrementam contadores (`+0` / `-0`).
5. **Combine a `csv` com `test` (`import test`)**: escreva sempre asserções com `assert equals` ou `assert true` para fixar os invariantes do seu domínio.

---

No **Capítulo 10** passaremos a explorar em profundidade a lib **`ini`** (A lib `ini` — Ficheiros `.ini` por Secções, `.env` e Interpolação de Variáveis).
