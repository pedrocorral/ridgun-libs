# Capítulo 13: A lib `diff` — Algoritmo LCS, Distância de Edição, Unified Diff e Patches

## 13.1. Por que existe a lib `diff`? (O problema real e a filosofia Ridgun)

> *«Por que preciso de uma lib `diff` escrita de raiz em Ridgun puro em vez de ligar uma biblioteca C tradicional?»*

Essa é a primeira pergunta que qualquer engenheiro de sistemas faz ao chegar à `diff`. E a resposta resume toda a filosofia do `ridgun-libs`:

Sejamos sinceros: quando um teste falha ou um ficheiro de configuração muda, um seco `"expected A, got B"` de 200 linhas obriga-o a queimar as pestanas à procura da linha exata que mudou.

A lib **`diff`** calcula a **Subsequência Comum Mais Longa (LCS)** sobre `Tensor[Int]` 2D para produzir edições mínimas (`DiffKeep`, `DiffAdd`, `DiffDel`), distância de edição, estatísticas, formato **Unified Diff** (`---`/`+++`/`@@`) e reconstrução exata com `diff apply`.

Num ecossistema tradicional, resolver as tarefas do domínio **`DIFF`** implica arrastar dependências externas em C, lidar com ponteiros brutos, conversões opacas de tipos, exceções não verificadas ou pausas imprevisíveis do coletor de lixo. Em Ridgun, a lib **`diff`** (`src/main/ridgun/lib/diff.rg`) aborda o problema com quatro princípios inegociáveis:

1. **Funções totais e contratos explícitos (`=>`)**: nenhuma função da `diff` lança exceções ocultas nem depende de `null`. Qualquer caso limite devolve um valor sentinela documentado ou um tipo algébrico soma (`Option`, `Result`).
2. **Zero código C e zero `libc`**: todo o código da `diff` compila diretamente para código máquina nativo ELF64 verificado pelo `ridgunc`.
3. **Recursão de cauda com TCO (*Tail-Call Optimization*)**: todas as travessias internas da `diff` são compiladas para ciclos nativos em espaço de pilha $O(1)$.
4. **Memória determinística (`RMM1` / `RMM2`)**: cada estrutura intermédia é libertada no instante exato em que termina a sua última leitura, sem *Garbage Collector*.

---

## 13.2. Artefactos nativos, importação e catálogo completo da API de `diff`

No `ridgun-libs`, **`diff`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/diff.rg` (domínio `DIFF`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/diff.rglib` | Distribuição e importação direta com `import diff` |
| **Ficheiro compilado** | `target/diff.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libdiff.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import diff` no topo e invocar as suas funções com espaços ou underscores.

### 13.2.1. Resumo das famílias funcionais da `diff`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `type DiffOp` | `DiffKeep String | DiffDel String | DiffAdd String` |
| `diff lines / diff text` | Calcula o script mínimo de edição LCS entre listas `[String]` ou textos multilinha |
| `diff edit distance / diff stats` | Distância mínima de inserção+remoção e contagem `(kept, added, deleted)` |
| `diff format / diff unified` | Formata linhas compactas `+ / - /  ` ou Unified Diff padrão com cabeçalhos |
| `diff apply / diff apply text` | Reconstrói o documento de destino sem perdas a partir de um script de edição |

### 13.2.2. Catálogo exaustivo de tipos e assinaturas em `src/main/ridgun/lib/diff.rg`

Abaixo encontra-se o inventário completo de tipos algébricos (`type`), operadores (`op ::`) e assinaturas de funções (`fn ::`) definidos em `src/main/ridgun/lib/diff.rg` (`2` tipos, `0` operadores e `33` funções):

**Tipos algébricos e registos (`type`) da `diff`:**

```ridgun
type DiffEdit = diff_op: String, line_text: String, old_line_no: Int, new_line_no: Int
type DiffStats = equal_count: Int, insert_count: Int, delete_count: Int
```

| # | Função / Assinatura (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: df_max Int Int` | `Int` |
| `2` | `fn :: df_int_to_str_pos Int` | `String` |
| `3` | `fn :: df_int_to_str Int` | `String` |
| `4` | `fn :: df_rev [String] [String]` | `[String]` |
| `5` | `fn :: df_rev_ints [Int] [Int]` | `[Int]` |
| `6` | `fn :: df_split_lines_loop String Int Int Int [String]` | `[String]` |
| `7` | `fn :: df_split_lines String` | `[String]` |
| `8` | `fn :: df_zeros Int [Int]` | `[Int]` |
| `9` | `fn :: df_nth_int [Int] Int` | `Int` |
| `10` | `fn :: df_head_int [Int]` | `Int` |
| `11` | `fn :: df_cell_val String String Int Int Int` | `Int` |
| `12` | `fn :: df_build_row String [String] [Int] Int [Int]` | `[Int]` |
| `13` | `fn :: df_build_dp [String] [String] [[Int]]` | `[[Int]]` |
| `14` | `fn :: df_tail_rows [[Int]]` | `[[Int]]` |
| `15` | `fn :: df_head_row [[Int]]` | `[Int]` |
| `16` | `fn :: df_rev_edits [DiffEdit] [DiffEdit]` | `[DiffEdit]` |
| `17` | `fn :: df_backtrack [String] [String] [[Int]] Int Int Int [DiffEdit]` | `[DiffEdit]` |
| `18` | `fn :: df_backtrack_step String [String] String [String] [[Int]] Int Int Int [DiffEdit]` | `[DiffEdit]` |
| `19` | `fn :: df_backtrack_branch String [String] String [String] [[Int]] [[Int]] Int Int Int Int Int [DiffEdit]` | `[DiffEdit]` |
| `20` | `fn :: df_list_length [String]` | `Int` |
| `21` | `fn :: diff lines [String] [String]` | `[DiffEdit]` |
| `22` | `fn :: diff text String String` | `[DiffEdit]` |
| `23` | `fn :: df_stats_loop [DiffEdit] Int Int Int` | `DiffStats` |
| `24` | `fn :: diff stats [DiffEdit]` | `DiffStats` |
| `25` | `fn :: diff edit distance String String` | `Int` |
| `26` | `fn :: diff has changes [DiffEdit]` | `Bool` |
| `27` | `fn :: df_format_unified_lines [DiffEdit] String` | `String` |
| `28` | `fn :: df_hunk_start Int` | `Int` |
| `29` | `fn :: df_unified_header String String Int Int` | `String` |
| `30` | `fn :: diff unified String String String String` | `String` |
| `31` | `fn :: df_apply_collect [DiffEdit] [String]` | `[String]` |
| `32` | `fn :: df_join_lines [String]` | `String` |
| `33` | `fn :: diff apply [DiffEdit]` | `String` |

---

## 13.3. Explorando a `diff` a fundo: Exemplos passo a passo de cada funcionalidade

Não basta ver a tabela de assinaturas: vamos explorar **cada uma das funcionalidades** da lib `diff` através de exemplos progressivos e executáveis em Ridgun. Começaremos pelas duas receitas tabulares de uso diário e depois percorreremos em detalhe todos os cenários funcionais, transformações e casos de fronteira verificados em `src/test/ridgun/test diff.rg`.

### 13.3.1. Exemplo 1: Fluxo principal em estilo tabular com `diff`

Repare como em Ridgun os sinais `=` e os passos de transformação com `diff` ficam alinhados como uma tabela limpa, sem variáveis mutáveis desnecessárias nem efeitos colaterais ocultos:

```ridgun
import diff

fn :: auditar cambio (antes : String) (despues : String) => (Int, String)
      auditar cambio antes despues =
        dist   = diff edit distance ( ["host=localhost", "port=8080"] ) ( ["host=0.0.0.0", "port=8080"] )
        parche = diff unified "config.old" "config.new" antes despues
        (dist, parche)
```

### 13.3.2. Exemplo 2: Composição segura e tratamento de casos de fronteira

Todas as funções da lib `diff` foram desenhadas para se comporem com guardas booleanas `|` e com as restantes 32 libs do `ridgun-libs`:

```ridgun
import diff

fn :: verificar parche (orig : [String]) (nuevo : [String]) => [String]
      verificar parche orig nuevo =
        ops = diff lines orig nuevo
        diff apply ops
```

### 13.3.3. Exemplo 3: Comparação de textos vazios e idênticos: distância de edição zero e verificação de invariantes

Neste exemplo prático exploramos de forma exaustiva como a `diff` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test_diff_empty_and_identical => ()
      test_diff_empty_and_identical =
        nl = char_from_code 10
        e_empty = diff text "" ""
        _ = assert int equals (count_edits e_empty) 0 "AC1: empty diff edit count"
        _ = assert false (diff has changes e_empty) "AC1: empty diff has no changes"
        _ = assert int equals (diff edit distance "" "") 0 "AC1: empty edit distance"
        _ = assert str eq (diff apply e_empty) "" "AC3: empty diff apply"
        same_doc = "alpha" + nl + "beta" + nl + "gamma"
        e_same = diff text same_doc same_doc
        _ = assert int equals (count_edits e_same) 3 "AC1: identical 3-line count"
        _ = assert false (diff has changes e_same) "AC1: identical has no changes"
        st_same = diff stats e_same
        _ = assert int equals (equal_count st_same) 3 "AC1: equal_count == 3"
        _ = assert int equals (insert_count st_same) 0 "AC1: insert_count == 0"
        _ = assert int equals (delete_count st_same) 0 "AC1: delete_count == 0"
        _ = assert int equals (diff edit distance same_doc same_doc) 0 "AC1: identical edit distance == 0"
        _ = assert str eq (diff apply e_same) same_doc "AC3: identical diff apply"
        ()
```

### 13.3.4. Exemplo 4: Inserções puras (`DiffInsert`), remoções puras (`DiffDelete`) e aplicação direta (`diff patch`)

Neste exemplo prático exploramos de forma exaustiva como a `diff` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test_diff_pure_insert_and_delete => ()
      test_diff_pure_insert_and_delete =
        nl = char_from_code 10
        target = "line1" + nl + "line2" + nl + "line3"
        e_ins = diff text "" target
        _ = assert true (diff has changes e_ins) "AC1: pure insert has changes"
        st_ins = diff stats e_ins
        _ = assert int equals (equal_count st_ins) 0 "AC1: pure insert equal_count"
        _ = assert int equals (insert_count st_ins) 3 "AC1: pure insert insert_count"
        _ = assert int equals (delete_count st_ins) 0 "AC1: pure insert delete_count"
        _ = assert int equals (diff edit distance "" target) 3 "AC1: pure insert edit distance"
        _ = assert str eq (diff apply e_ins) target "AC3: pure insert apply"
        ins0 = nth_edit e_ins 0
        ins2 = nth_edit e_ins 2
        _ = assert str eq (diff_op ins0) "insert" "AC1: ins0 op"
        _ = assert int equals (old_line_no ins0) 0 "AC1: ins0 old_line_no"
        _ = assert int equals (new_line_no ins0) 1 "AC1: ins0 new_line_no"
        _ = assert int equals (new_line_no ins2) 3 "AC1: ins2 new_line_no"
        e_del = diff text target ""
        _ = assert true (diff has changes e_del) "AC1: pure delete has changes"
        st_del = diff stats e_del
        _ = assert int equals (equal_count st_del) 0 "AC1: pure delete equal_count"
        _ = assert int equals (insert_count st_del) 0 "AC1: pure delete insert_count"
        _ = assert int equals (delete_count st_del) 3 "AC1: pure delete delete_count"
        _ = assert int equals (diff edit distance target "") 3 "AC1: pure delete edit distance"
        _ = assert str eq (diff apply e_del) "" "AC3: pure delete apply"
        del0 = nth_edit e_del 0
        del2 = nth_edit e_del 2
        _ = assert str eq (diff_op del0) "delete" "AC1: del0 op"
        _ = assert int equals (old_line_no del0) 1 "AC1: del0 old_line_no"
        _ = assert int equals (new_line_no del0) 0 "AC1: del0 new_line_no"
        _ = assert int equals (old_line_no del2) 3 "AC1: del2 old_line_no"
        ()
```

### 13.3.5. Exemplo 5: O vetor clássico de Eugene Myers (`ABCABBA` $\rightarrow$ `CBABAC`): maior subsequência comum (LCS) e distância mínima

Neste exemplo prático exploramos de forma exaustiva como a `diff` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test_diff_myers_classic_vector => ()
      test_diff_myers_classic_vector =
        nl = char_from_code 10
        old_lines = ["A", "B", "C", "A", "B", "B", "A"]
        new_lines = ["C", "B", "A", "B", "A", "C"]
        edits = diff lines old_lines new_lines
        st = diff stats edits
        _ = assert int equals (equal_count st) 4 "AC1: Myers LCS length 4"
        _ = assert int equals (delete_count st) 3 "AC1: Myers delete count 3"
        _ = assert int equals (insert_count st) 2 "AC1: Myers insert count 2"
        old_s = "A" + nl + "B" + nl + "C" + nl + "A" + nl + "B" + nl + "B" + nl + "A"
        new_s = "C" + nl + "B" + nl + "A" + nl + "B" + nl + "A" + nl + "C"
        _ = assert int equals (diff edit distance old_s new_s) 5 "AC1: Myers edit distance 5"
        _ = assert str eq (diff apply edits) new_s "AC3: Myers apply reproduces CBABAC"
        ()
```

### 13.3.6. Exemplo 6: Inspeção de números de linha de origem e destino (`diff old line`, `diff new line`) e reconstrução exata com `diff patch`

Neste exemplo prático exploramos de forma exaustiva como a `diff` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test_diff_code_hunks_and_line_numbers => ()
      test_diff_code_hunks_and_line_numbers =
        nl = char_from_code 10
        old_code = "fn :: add Int Int => Int" + nl + "      add a b = a + b" + nl + "" + nl + "fn :: sub Int Int => Int" + nl + "      sub a b = a - b"
        new_code = "fn :: add Int Int => Int" + nl + "      add x y = x + y" + nl + "" + nl + "fn :: mul Int Int => Int" + nl + "      mul a b = a * b" + nl + "" + nl + "fn :: sub Int Int => Int" + nl + "      sub a b = a - b"
        edits = diff text old_code new_code
        _ = assert true (diff has changes edits) "AC1: code refactoring has changes"
        _ = assert str eq (diff apply edits) new_code "AC3: code refactoring lossless apply"
        e0 = nth_edit edits 0
        _ = assert str eq (diff_op e0) "equal" "AC1: line 1 equal"
        _ = assert int equals (old_line_no e0) 1 "AC1: line 1 old_line_no"
        _ = assert int equals (new_line_no e0) 1 "AC1: line 1 new_line_no"
        e1 = nth_edit edits 1
        _ = assert str eq (diff_op e1) "delete" "AC1: line 2 deleted"
        _ = assert str eq (line_text e1) "      add a b = a + b" "AC1: deleted line text"
        _ = assert int equals (old_line_no e1) 2 "AC1: deleted old_line_no"
        _ = assert int equals (new_line_no e1) 0 "AC1: deleted new_line_no"
        e2 = nth_edit edits 2
        _ = assert str eq (diff_op e2) "insert" "AC1: line 2 inserted"
        _ = assert str eq (line_text e2) "      add x y = x + y" "AC1: inserted line text"
        _ = assert int equals (old_line_no e2) 0 "AC1: inserted old_line_no"
        _ = assert int equals (new_line_no e2) 2 "AC1: inserted new_line_no"
        ()
```

### 13.3.7. Exemplo 7: Geração de patches unificados estilo GNU (`--- old`, `+++ new`, `-`, `+`, ` `) com `diff unified` e estatísticas `(kept, deleted, inserted)`

Neste exemplo prático exploramos de forma exaustiva como a `diff` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test_diff_unified_formatting => ()
      test_diff_unified_formatting =
        nl = char_from_code 10
        old_s = "one" + nl + "two" + nl + "three"
        new_s = "one" + nl + "TWO" + nl + "three" + nl + "four"
        uni = diff unified "a/sample.txt" "b/sample.txt" old_s new_s
        expected = "--- a/sample.txt" + nl + "+++ b/sample.txt" + nl + "@@ -1,3 +1,4 @@" + nl + " one" + nl + "-two" + nl + "+TWO" + nl + " three" + nl + "+four" + nl
        _ = assert str eq uni expected "AC2: unified diff output matches standard header and hunk format"
        uni_empty = diff unified "a/empty" "b/empty" "" ""
        _ = assert str eq uni_empty ("--- a/empty" + nl + "+++ b/empty" + nl + "@@ -0,0 +0,0 @@" + nl) "AC2: unified diff empty files"
        ()
```

### 13.3.8. Exemplo 8: Robustez perante ficheiros com linhas repetidas e blocos duplicados

Neste exemplo prático exploramos de forma exaustiva como a `diff` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test_diff_repetitive_lines => ()
      test_diff_repetitive_lines =
        nl = char_from_code 10
        old_rep = "x" + nl + "x" + nl + "y" + nl + "x" + nl + "x"
        new_rep = "x" + nl + "y" + nl + "y" + nl + "x"
        edits = diff text old_rep new_rep
        st = diff stats edits
        _ = assert int equals (equal_count st) 3 "AC1: repetitive LCS equal_count"
        _ = assert int equals (delete_count st) 2 "AC1: repetitive LCS delete_count"
        _ = assert int equals (insert_count st) 1 "AC1: repetitive LCS insert_count"
        _ = assert str eq (diff apply edits) new_rep "AC3: repetitive lines apply"
        ()
```

---

## 13.4. Debaixo do capô: como a `diff` é construída em Ridgun puro (`src/main/ridgun/lib/diff.rg`)

Uma das maiores vantagens do `ridgun-libs` é que **não existem caixas-pretas em C**. Pode abrir `src/main/ridgun/lib/diff.rg` e ler exatamente como cada operação é implementada usando *pattern matching*, árvores de guardas `|` / `|.` e recursão de cauda (TCO). Vejamos as peças-chave da sua implementação real:

### 13.4.1. Implementação interna: Internal Helpers

Observe como `diff.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: df_max Int Int => Int
      df_max a   b
        | a >= b = a
        | otherwise = b

fn :: df_int_to_str_pos Int => String
      df_int_to_str_pos n
        | n == 0 = ""
        | otherwise = (df_int_to_str_pos (n / 10)) + (char_from_code ((n % 10) + 48))

fn :: df_int_to_str Int => String
      df_int_to_str n
        | n == 0 = "0"
        | n < 0 = "-" + (df_int_to_str_pos (0 - n))
        | otherwise = df_int_to_str_pos n

fn :: df_rev [String] [String] => [String]
      df_rev []       acc      =  acc
      df_rev (x:xs)   acc      =  df_rev xs ([x] :: acc)

fn :: df_rev_ints [Int]  [Int] => [Int]
      df_rev_ints []     acc   =  acc
      df_rev_ints (x:xs) acc   =  df_rev_ints xs ([x] :: acc)

fn :: df_split_lines_loop String Int Int Int [String] => [String]
      df_split_lines_loop s idx n start acc
        | idx >= n = df_rev ([str_slice s start n] :: acc) []
        | (str_char_at s idx) == 10 = df_split_lines_loop s (idx + 1) n (idx + 1) ([str_slice s start idx] :: acc)
        | otherwise = df_split_lines_loop s (idx + 1) n start acc

fn :: df_split_lines String => [String]
      df_split_lines s
        | (str_len s) == 0 = []
        | otherwise = df_split_lines_loop s 0 (str_len s) 0 []

fn :: df_zeros Int [Int] => [Int]
      df_zeros n   acc
        | n <= 0 = acc
        | otherwise = df_zeros (n - 1) ([0] :: acc)

fn :: df_nth_int [Int]  Int => Int
      df_nth_int []     _   =  0
      df_nth_int (x:xs) idx
        | idx <= 0 = x
        | otherwise = df_nth_int xs (idx - 1)

fn :: df_head_int [Int] => Int
      df_head_int []    =  0
      df_head_int (x:_) =  x
```

### 13.4.2. Implementação interna: Public API

Observe como `diff.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: diff lines [String]  [String]  => [DiffEdit]
      diff lines old_lines new_lines =
        rev_old = df_rev old_lines []
        rev_new = df_rev new_lines []
        zero_row = df_zeros ((df_list_length new_lines) + 1) []
        dp_rows = df_build_dp rev_old rev_new [zero_row]
        df_backtrack old_lines new_lines dp_rows 0 1 1 []

fn :: diff text String String => [DiffEdit]
      diff text old_s  new_s  =  diff lines (df_split_lines old_s) (df_split_lines new_s)

fn :: df_stats_loop [DiffEdit] Int Int Int => DiffStats
      df_stats_loop []         eq  ins del =  DiffStats eq ins del
      df_stats_loop (e:es)     eq  ins del
        | (diff_op e) == "equal" = df_stats_loop es (eq + 1) ins del
        | (diff_op e) == "insert" = df_stats_loop es eq (ins + 1) del
        | otherwise = df_stats_loop es eq ins (del + 1)

fn :: diff stats [DiffEdit] => DiffStats
      diff stats edits      =  df_stats_loop edits 0 0 0

fn :: diff edit distance String String => Int
      diff edit distance old_s  new_s  =
        st = diff stats (diff text old_s new_s)
        (insert_count st) + (delete_count st)

fn :: diff has changes [DiffEdit] => Bool
      diff has changes []         =  False
      diff has changes (e:es)
        | (diff_op e) == "equal" = diff has changes es
        | otherwise = True

fn :: df_format_unified_lines [DiffEdit] String => String
      df_format_unified_lines []         acc    =  acc
      df_format_unified_lines (e:es)     acc
        | (diff_op e) == "equal" = df_format_unified_lines es (acc + " " + (line_text e) + (char_from_code 10))
        | (diff_op e) == "delete" = df_format_unified_lines es (acc + "-" + (line_text e) + (char_from_code 10))
        | otherwise = df_format_unified_lines es (acc + "+" + (line_text e) + (char_from_code 10))

fn :: df_hunk_start Int => Int
      df_hunk_start cnt
        | cnt == 0 = 0
        | otherwise = 1

fn :: df_unified_header String    String    Int     Int     => String
      df_unified_header old_label new_label old_cnt new_cnt =
        old_start = df_hunk_start old_cnt
        new_start = df_hunk_start new_cnt
        nl = char_from_code 10
        "--- " + old_label + nl + "+++ " + new_label + nl + "@@ -" + (df_int_to_str old_start) + "," + (df_int_to_str old_cnt) + " +" + (df_int_to_str new_start) + "," + (df_int_to_str new_cnt) + " @@" + nl
```

---

## 13.5. Garantias algorítmicas, memória `RMM1`/`RMM2` e as 5 Regras de Ouro da `diff`

- **Garantia algorítmica e de segurança**: Identidade matemática garantida $diff\_edit\_distance(a, b) == |a| + |b| - 2 \cdot LCS(a, b)$ e reconstrução sem perdas `diff apply (diff lines a b) == b`.
- **Complexidade de pilha $O(1)$ com TCO**: Todos os ciclos recursivos em `src/main/ridgun/lib/diff.rg` estão em posição de cauda, pelo que o `ridgunc` os compila para saltos nativos sem crescimento de pilha.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test diff.rg`.

### As 5 Regras de Ouro ao programar com a `diff`

1. **Declare `import diff` no início do ficheiro** e aproveite a equivalência entre espaços e underscores para que o seu código se leia como prosa.
2. **Alinhe os seus pipelines de dados com `=`**: encadeie as chamadas à `diff` em passos nomeados e deixe o `stable format` alinhar as colunas.
3. **Aproveite as funções totais da `diff` nas suas guardas `|`**: verifique os valores de retorno ou desempacote os ADTs com *pattern matching* em vez de assumir que a entrada externa é sempre válida.
4. **Evite copiar grandes estruturas se só precisa de consultar um campo**: lembre-se de que no `RMM2` os argumentos de entrada não incrementam nem decrementam contadores (`+0` / `-0`).
5. **Combine a `diff` com `test` (`import test`)**: escreva sempre asserções com `assert equals` ou `assert true` para fixar os invariantes do seu domínio.

---

No **Capítulo 14** passaremos a explorar em profundidade a lib **`template`** (A lib `template` — Templates Mustache Seguros com Auto-Escape HTML e LaTeX).
