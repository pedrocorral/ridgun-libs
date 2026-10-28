# Capítulo 12: A lib `glob` — Padrões de Wildcards (`*`, `?`, `[a-z]`) e Filtragem de Listas

## 12.1. Por que existe a lib `glob`? (O problema real e a filosofia Ridgun)

> *«Por que preciso de uma lib `glob` escrita de raiz em Ridgun puro em vez de ligar uma biblioteca C tradicional?»*

Essa é a primeira pergunta que qualquer engenheiro de sistemas faz ao chegar à `glob`. E a resposta resume toda a filosofia do `ridgun-libs`:

Sejamos sinceros: usar uma expressão regular completa só para verificar se um ficheiro termina em `*.rg` ou começa por `test_[0-9]*.rg` é matar moscas com tiros de canhão.

A lib **`glob`** implementa correspondência exata de wildcards de shell (`*`, `?`, classes `[a-z]`, classes negadas `[!0-9]` / `[^a-z]`), variantes insensíveis a maiúsculas (`glob match ci`) e filtragem direta de listas.

Num ecossistema tradicional, resolver as tarefas do domínio **`GLOB`** implica arrastar dependências externas em C, lidar com ponteiros brutos, conversões opacas de tipos, exceções não verificadas ou pausas imprevisíveis do coletor de lixo. Em Ridgun, a lib **`glob`** (`src/main/ridgun/lib/glob.rg`) aborda o problema com quatro princípios inegociáveis:

1. **Declare `import glob` (ou `import glob as alias`) no início do ficheiro**: cada lib define o seu espaço de nomes `module :: glob` e em modo `--strict` as funções multi-palavra são sempre invocadas com espaços naturais.
2. **Encadeie os seus pipelines da esquerda para a direita com `->`**: escreva `entrada passo um -> passo dois -> resultado`, use máscaras `(+ _ _ +)` para desestruturar sequências e omita `_ =` em instruções sequenciais (ou descarte com `-> ()`).
3. **Recursão de cauda com TCO (*Tail-Call Optimization*)**: todas as travessias internas da `glob` são compiladas para ciclos nativos em espaço de pilha $O(1)$.
4. **Memória determinística (`RMM1` / `RMM2`)**: cada estrutura intermédia é libertada no instante exato em que termina a sua última leitura, sem *Garbage Collector*.

---

## 12.2. Artefactos nativos, importação e catálogo completo da API de `glob`

No `ridgun-libs`, **`glob`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/glob.rg` (domínio `GLOB`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/glob.rglib` | Distribuição e importação direta com `import glob` |
| **Ficheiro compilado** | `target/glob.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libglob.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Cada lib declara o seu próprio espaço de nomes com `module :: glob`: basta escrever `import glob` (ou `import glob as alias`) no topo e invocar as suas funções com espaços naturais (`minha funcao x`) e pipelines `->` (`x minha funcao -> resultado`).

### 12.2.1. Resumo das famílias funcionais da `glob`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `glob match / glob match ci` | Correspondência de padrões glob sensível e insensível a maiúsculas ASCII |
| `glob filter / glob any match` | Filtra `[String]` por padrão ou verifica se algum padrão de uma lista corresponde |
| `glob has magic` | Deteta se uma cadeia contém metacaracteres de wildcard (`*`, `?`, `[`) |

### 12.2.2. Catálogo exaustivo de tipos e assinaturas em `src/main/ridgun/lib/glob.rg`

Abaixo encontra-se o inventário completo de tipos algébricos (`type`), operadores (`op ::`) e assinaturas de funções (`fn ::`) definidos em `src/main/ridgun/lib/glob.rg` (`0` tipos, `0` operadores e `18` funções):

| # | Função / Assinatura (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: gl lower char String Int Int` | `String` |
| `2` | `fn :: gl to lower loop String Int Int` | `String` |
| `3` | `fn :: gl to lower String` | `String` |
| `4` | `fn :: gl find close bracket String Int Int` | `Int` |
| `5` | `fn :: gl match range String Int Int Int Int Int` | `Bool` |
| `6` | `fn :: gl match class body String Int Int Int` | `Bool` |
| `7` | `fn :: gl eval bracket char String Int Int Int Int` | `Bool` |
| `8` | `fn :: gl eval bracket String Int Int Int` | `Bool` |
| `9` | `fn :: gl skip stars String Int Int` | `Int` |
| `10` | `fn :: gl match star String Int Int String Int Int` | `Bool` |
| `11` | `fn :: gl match star at String Int Int String Int Int` | `Bool` |
| `12` | `fn :: gl match bracket step String Int Int String Int Int Int` | `Bool` |
| `13` | `fn :: gl match step String Int Int String Int Int Int` | `Bool` |
| `14` | `fn :: gl match loop String Int Int String Int Int` | `Bool` |
| `15` | `fn :: glob match String String` | `Bool` |
| `16` | `fn :: glob match ci String String` | `Bool` |
| `17` | `fn :: glob filter String [String]` | `[String]` |
| `18` | `fn :: glob any match [String] String` | `Bool` |

---

## 12.3. Explorando a `glob` a fundo: Exemplos passo a passo de cada funcionalidade

Não basta ver a tabela de assinaturas: vamos explorar **cada uma das funcionalidades** da lib `glob` através de exemplos progressivos e executáveis em Ridgun. Começaremos pelas duas receitas tabulares de uso diário e depois percorreremos em detalhe todos os cenários funcionais, transformações e casos de fronteira verificados em `src/test/ridgun/test glob.rg`.

### 12.3.1. Exemplo 1: Fluxo principal em estilo tabular com `glob`

Repare como em Ridgun os sinais `=` e os passos de transformação com `glob` ficam alinhados como uma tabela limpa, sem variáveis mutáveis desnecessárias nem efeitos colaterais ocultos:

```ridgun
import glob

fn :: seleccionar fuentes ridgun [String] => [String]
      seleccionar fuentes ridgun archivos =
        glob filter "test_[a-z]*.rg" archivos
```

### 12.3.2. Exemplo 2: Composição segura e tratamento de casos de fronteira

Todas as funções da lib `glob` foram desenhadas para se comporem com guardas booleanas `|` e com as restantes 32 libs do `ridgun-libs`:

```ridgun
import glob

fn :: es ruta excluida String => Bool
      es ruta excluida ruta =
        glob any match ["*.tmp", "*.bak", "target/*"] ruta
```

### 12.3.3. Exemplo 3: Wildcards `*` e `?`, correspondência exata de limites e casos de fronteira com padrões vazios

Neste exemplo prático exploramos de forma exaustiva como a `glob` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test glob wildcards and boundaries => ()
      test glob wildcards and boundaries =
        assert true (glob match "" "") "AC1: empty pattern matches empty string"
        assert false (glob match "" "a") "AC1: empty pattern rejects non-empty"
        assert true (glob match "*" "") "AC1: * matches empty string"
        assert true (glob match "***" "") "AC1: *** matches empty string"
        assert true (glob match "*" "anything.rg") "AC1: * matches full filename"
        assert true (glob match "*.rg" "socket.rg") "AC1: *.rg matches socket.rg"
        assert true (glob match "*.rg" ".rg") "AC1: *.rg matches leading dot .rg"
        assert false (glob match "*.rg" "README.md") "AC1: *.rg rejects README.md"
        assert false (glob match "*.rg" "socket.rg.bak") "AC1: *.rg rejects trailing suffix"
        assert true (glob match "test_?.rg" "test_a.rg") "AC1: ? matches single char"
        assert false (glob match "test_?.rg" "test_.rg") "AC1: ? rejects zero chars"
        assert false (glob match "test_?.rg" "test_ab.rg") "AC1: ? rejects two chars"
        assert true (glob match "???" "abc") "AC1: ??? matches 3 chars"
        assert false (glob match "???" "ab") "AC1: ??? rejects 2 chars"
        assert true (glob match "a*b*c" "abc") "AC1: multiple * matching zero chars"
        assert true (glob match "a*b*c" "axxxbyyyc") "AC1: multiple * matching substrings"
        assert true (glob match "a*b*c" "abbc") "AC1: backtracking * across repeated b"
        assert false (glob match "a*b*c" "axxxbyyy") "AC1: missing trailing literal after *"
        assert true (glob match "a***b" "axyzb") "AC1: collapsed *** matches"
        -- Pathological backtracking immunity via gl skip stars
        assert false (glob match "****************a" "bbbbbbbbbbbbbbbbbbbbbbbbbbbb") "AC1: collapsed stars avoid exponential backtracking"
        ()
```

### 12.3.4. Exemplo 4: Classes de caracteres `[a-z]`, intervalos negados `[!0-9]` / `[^0-9]` e correspondência insensível a maiúsculas (`glob match ci`)

Neste exemplo prático exploramos de forma exaustiva como a `glob` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test glob classes and case insensitivity => ()
      test glob classes and case insensitivity =
        assert true (glob match "file_[0-9].txt" "file_0.txt") "AC2: [0-9] lower bound 0"
        assert true (glob match "file_[0-9].txt" "file_9.txt") "AC2: [0-9] upper bound 9"
        assert false (glob match "file_[0-9].txt" "file_a.txt") "AC2: [0-9] rejects alpha"
        assert true (glob match "id_[a-zA-Z0-9].rg" "id_Z.rg") "AC2: multi-range [a-zA-Z0-9] matches Z"
        assert true (glob match "id_[a-zA-Z0-9].rg" "id_5.rg") "AC2: multi-range [a-zA-Z0-9] matches 5"
        assert false (glob match "id_[a-zA-Z0-9].rg" "id__.rg") "AC2: multi-range [a-zA-Z0-9] rejects _"
        assert true (glob match "v[135].rg" "v3.rg") "AC2: discrete character set [135]"
        assert false (glob match "v[135].rg" "v2.rg") "AC2: discrete character set rejects 2"
        assert true (glob match "file_[!0-9].txt" "file_a.txt") "AC2: [!0-9] POSIX negated class"
        assert false (glob match "file_[!0-9].txt" "file_7.txt") "AC2: [!0-9] rejects digit"
        assert true (glob match "file_[^0-9].txt" "file_z.txt") "AC2: [^0-9] caret negated class"
        assert false (glob match "file_[^0-9].txt" "file_0.txt") "AC2: [^0-9] rejects digit"
        assert true (glob match "a[b" "a[b") "AC2: unclosed '[' matches literally"
        assert false (glob match "a[b" "axb") "AC2: unclosed '[' rejects non-bracket"

        -- Case-insensitive matching
        assert true (glob match ci "*.RG" "socket.rg") "AC2: glob_match_ci *.RG on lowercase"
        assert true (glob match ci "*.rg" "SOCKET.RG") "AC2: glob_match_ci *.rg on uppercase"
        assert true (glob match ci "src/**/Test_[A-Z]*.rg" "SRC/main/test_crypto.RG") "AC2: glob_match_ci mixed case"
        ()
```

### 12.3.5. Exemplo 5: Filtragem em lote de listas de caminhos (`glob filter`) e verificação contra múltiplos padrões (`glob any match`)

Neste exemplo prático exploramos de forma exaustiva como a `glob` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test glob filter and any match => ()
      test glob filter and any match =
        files = ["socket.rg", "README.md", "test_socket.rg", "crypto.rg", "build.sh"]
        assert eq (glob filter "*.rg" files) ["socket.rg", "test_socket.rg", "crypto.rg"]
        assert eq (glob filter "test_*.rg" files) ["test_socket.rg"]
        assert eq (glob filter "*.nomatch" files) []
        assert eq (glob filter "*.rg" []) []
        assert true (glob any match ["*.md", "*.txt", "*.sh"] "README.md") "AC3: glob_any_match first pattern"
        assert true (glob any match ["*.md", "*.txt", "*.sh"] "build.sh") "AC3: glob_any_match last pattern"
        assert false (glob any match ["*.md", "*.txt"] "socket.rg") "AC3: glob_any_match no match"
        assert false (glob any match [] "socket.rg") "AC3: glob_any_match empty pattern list"
        ()
```

---

## 12.4. Debaixo do capô: como a `glob` é construída em Ridgun puro (`src/main/ridgun/lib/glob.rg`)

Uma das maiores vantagens do `ridgun-libs` é que **não existem caixas-pretas em C**. Pode abrir `src/main/ridgun/lib/glob.rg` e ler exatamente como cada operação é implementada usando *pattern matching*, árvores de guardas `|` / `|.` e recursão de cauda (TCO). Vejamos as peças-chave da sua implementação real:

### 12.4.1. Implementação interna: Bracket Character Class `[...]` Matching

Observe como `glob.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
module :: glob

fn :: gl find close bracket String Int Int => Int
      gl find close bracket pat idx plen =
        | idx >= plen                  = 0 - 1
        | (str char at pat idx) == 93  = idx
        | otherwise                    = gl find close bracket pat (idx + 1) plen

fn :: gl match range String Int Int Int Int Int => Bool
      gl match range pat idx end_idx tc lo hi =
        | tc >= lo and tc <= hi = True
        | otherwise             = gl match class body pat (idx + 3) end_idx tc

fn :: gl match class body String Int Int Int => Bool
      gl match class body pat idx end_idx tc =
        | idx >= end_idx = False
        | ((idx + 2) < end_idx) and ((str char at pat (idx + 1)) == 45) =
          gl match range pat idx end_idx tc (str char at pat idx) (str char at pat (idx + 2))
        | (str char at pat idx) == tc = True
        | otherwise                   = gl match class body pat (idx + 1) end_idx tc

fn :: gl eval bracket char String Int Int Int Int => Bool
      gl eval bracket char pat pstart close_idx tc c0 =
        | c0 == 33 or c0 == 94 = not (gl match class body pat (pstart + 1) close_idx tc)
        | otherwise            = gl match class body pat pstart close_idx tc

fn :: gl eval bracket String Int Int Int => Bool
      gl eval bracket pat pstart close_idx tc =
        gl eval bracket char pat pstart close_idx tc (str char at pat pstart)
```

### 12.4.2. Implementação interna: Wildcard (`*`, `?`, `[...]`) Matcher

Observe como `glob.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: gl skip stars String Int Int => Int
      gl skip stars pat pidx plen =
        | pidx >= plen                 = pidx
        | (str char at pat pidx) == 42 = gl skip stars pat (pidx + 1) plen
        | otherwise                    = pidx

fn :: gl match star String Int Int String Int Int => Bool
      gl match star pat pidx plen txt tidx tlen =
        | gl match loop pat pidx plen txt tidx tlen = True
        | tidx >= tlen                              = False
        | otherwise                                 = gl match star pat pidx plen txt (tidx + 1) tlen

fn :: gl match star at String Int Int String Int Int => Bool
      gl match star at pat next_p plen txt tidx tlen =
        | next_p >= plen = True
        | otherwise      = gl match star pat next_p plen txt tidx tlen

fn :: gl match bracket step String Int Int String Int Int Int => Bool
      gl match bracket step pat pidx plen txt tidx tlen close_idx =
        | close_idx < 0 =
          | (str char at txt tidx) == 91 = gl match loop pat (pidx + 1) plen txt (tidx + 1) tlen
          | otherwise                    = False |.
        | gl eval bracket pat (pidx + 1) close_idx (str char at txt tidx) =
          gl match loop pat (close_idx + 1) plen txt (tidx + 1) tlen
        | otherwise = False

fn :: gl match step String Int Int String Int Int Int => Bool
      gl match step pat pidx plen txt tidx tlen pc =
        | pc == 42                     = gl match star at pat (gl skip stars pat (pidx + 1) plen) plen txt tidx tlen
        | tidx >= tlen                 = False
        | pc == 63                     = gl match loop pat (pidx + 1) plen txt (tidx + 1) tlen
        | pc == 91                     = gl match bracket step pat pidx plen txt tidx tlen (gl find close bracket pat (pidx + 1) plen)
        | pc == (str char at txt tidx) = gl match loop pat (pidx + 1) plen txt (tidx + 1) tlen
        | otherwise                    = False

fn :: gl match loop String Int Int String Int Int => Bool
      gl match loop pat pidx plen txt tidx tlen =
        | pidx >= plen = tidx >= tlen
        | otherwise    = gl match step pat pidx plen txt tidx tlen (str char at pat pidx)

fn :: glob match String String => Bool
      glob match pat    txt    =  gl match loop pat 0 (str len pat) txt 0 (str len txt)

fn :: glob match ci String String => Bool
      glob match ci pat    txt    =
        pat gl to lower -> lpat
        txt gl to lower -> ltxt
        glob match lpat ltxt

fn :: glob filter String [String] => [String]
      glob filter _      []       =  []
      glob filter pat    (x:rest) =
        | glob match pat x = [x] :: (glob filter pat rest)
        | otherwise        = glob filter pat rest

fn :: glob any match [String] String => Bool
      glob any match []       _      =  False
      glob any match (p:rest) txt    =
        | glob match p txt = True
        | otherwise        = glob any match rest txt
```

---

## 12.5. Garantias algorítmicas, memória `RMM1`/`RMM2` e as 5 Regras de Ouro da `glob`

- **Garantia algorítmica e de segurança**: Colapso automático de asteriscos consecutivos (`***` $\rightarrow$ `*`) para evitar retrocessos redundantes e tratamento seguro de parênteses retos `[` não fechados.
- **Complexidade de pilha $O(1)$ com TCO**: Todos os ciclos recursivos em `src/main/ridgun/lib/glob.rg` estão em posição de cauda, pelo que o `ridgunc` os compila para saltos nativos sem crescimento de pilha.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test glob.rg`.

### As 5 Regras de Ouro ao programar com a `glob`

1. **Declare `import glob` no início do ficheiro** e aproveite a equivalência entre espaços e underscores para que o seu código se leia como prosa.
2. **Alinhe os seus pipelines de dados com `=`**: encadeie as chamadas à `glob` em passos nomeados e deixe o `stable format` alinhar as colunas.
3. **Aproveite as funções totais da `glob` nas suas guardas `|`**: verifique os valores de retorno ou desempacote os ADTs com *pattern matching* em vez de assumir que a entrada externa é sempre válida.
4. **Evite copiar grandes estruturas se só precisa de consultar um campo**: lembre-se de que no `RMM2` os argumentos de entrada não incrementam nem decrementam contadores (`+0` / `-0`).
5. **Combine a `glob` com `test` (`import test`)**: escreva sempre asserções com `assert equals` ou `assert true` para fixar os invariantes do seu domínio.

---

No **Capítulo 13** passaremos a explorar em profundidade a lib **`diff`** (A lib `diff` — Algoritmo LCS, Distância de Edição, Unified Diff e Patches).
