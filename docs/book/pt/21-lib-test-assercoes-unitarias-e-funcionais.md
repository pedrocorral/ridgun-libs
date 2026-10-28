# Capítulo 21: A lib `test` — Primitivas de Asserção Unitária e Funcional (`RG-011`)

## 21.1. Por que existe a lib `test`? (O problema real e a filosofia Ridgun)

> *«Por que preciso de uma lib `test` escrita de raiz em Ridgun puro em vez de ligar uma biblioteca C tradicional?»*

Essa é a primeira pergunta que qualquer engenheiro de sistemas faz ao chegar à `test`. E a resposta resume toda a filosofia do `ridgun-libs`:

Sejamos sinceros: quando uma framework de testes exige macros mágicas, reflexão em tempo de execução ou um executor externo pesado, escrever testes deixa de ser imediato.

A lib **`test`** (`RG-011`) fornece asserções puras, polimórficas e específicas de tipo que emitem diagnósticos claros `[FAIL]` com os valores esperado e obtido e terminam com código de saída `1`.

Num ecossistema tradicional, resolver as tarefas do domínio **`TST`** implica arrastar dependências externas em C, lidar com ponteiros brutos, conversões opacas de tipos, exceções não verificadas ou pausas imprevisíveis do coletor de lixo. Em Ridgun, a lib **`test`** (`src/main/ridgun/lib/test.rg`) aborda o problema com quatro princípios inegociáveis:

1. **Declare `import test` (ou `import test as alias`) no início do ficheiro**: cada lib define o seu espaço de nomes `module :: test` e em modo `--strict` as funções multi-palavra são sempre invocadas com espaços naturais.
2. **Encadeie os seus pipelines da esquerda para a direita com `->`**: escreva `entrada passo um -> passo dois -> resultado`, use máscaras `(+ _ _ +)` para desestruturar sequências e omita `_ =` em instruções sequenciais (ou descarte com `-> ()`).
3. **Recursão de cauda com TCO (*Tail-Call Optimization*)**: todas as travessias internas da `test` são compiladas para ciclos nativos em espaço de pilha $O(1)$.
4. **Memória determinística (`RMM1` / `RMM2`)**: cada estrutura intermédia é libertada no instante exato em que termina a sua última leitura, sem *Garbage Collector*.

---

## 21.2. Artefactos nativos, importação e catálogo completo da API de `test`

No `ridgun-libs`, **`test`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/test.rg` (domínio `TST`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/test.rglib` | Distribuição e importação direta com `import test` |
| **Ficheiro compilado** | `target/test.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libtest.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Cada lib declara o seu próprio espaço de nomes com `module :: test`: basta escrever `import test` (ou `import test as alias`) no topo e invocar as suas funções com espaços naturais (`minha funcao x`) e pipelines `->` (`x minha funcao -> resultado`).

### 21.2.1. Resumo das famílias funcionais da `test`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `assert equals / assert eq : A -> A -> String -> ()` | Asserção polimórfica de igualdade com etiqueta descritiva do caso de teste |
| `assert int equals / assert str eq` | Asserções especializadas de igualdade para `Int` e `String` |
| `assert true / assert false / assert not` | Asserções de invariantes booleanas (`True` / `False`) |
| `assert ok : Int -> String -> ()` | Verifica se um código de estado do sistema ou socket é igual a `0` (`OK`) |

### 21.2.2. Catálogo exaustivo de tipos e assinaturas em `src/main/ridgun/lib/test.rg`

Abaixo encontra-se o inventário completo de tipos algébricos (`type`), operadores (`op ::`) e assinaturas de funções (`fn ::`) definidos em `src/main/ridgun/lib/test.rg` (`0` tipos, `0` operadores e `12` funções):

| # | Função / Assinatura (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: fail test String` | `()` |
| `2` | `fn :: check eq A A` | `Bool` |
| `3` | `fn :: check str eq String String` | `Bool` |
| `4` | `fn :: check true Bool` | `Bool` |
| `5` | `fn :: assert true Bool String` | `()` |
| `6` | `fn :: assert false Bool String` | `()` |
| `7` | `fn :: assert equals A A String` | `()` |
| `8` | `fn :: assert str eq String String String` | `()` |
| `9` | `fn :: assert int equals Int Int String` | `()` |
| `10` | `fn :: assert ok Bool` | `()` |
| `11` | `fn :: assert not Bool` | `()` |
| `12` | `fn :: assert eq A A` | `()` |

---

## 21.3. Explorando a `test` a fundo: Exemplos passo a passo de cada funcionalidade

Não basta ver a tabela de assinaturas: vamos explorar **cada uma das funcionalidades** da lib `test` através de exemplos progressivos e executáveis em Ridgun. Começaremos pelas duas receitas tabulares de uso diário e depois percorreremos em detalhe todos os cenários funcionais, transformações e casos de fronteira verificados em `src/test/ridgun/test test.rg`.

### 21.3.1. Exemplo 1: Fluxo principal em estilo tabular com `test`

Repare como em Ridgun os sinais `=` e os passos de transformação com `test` ficam alinhados como uma tabela limpa, sem variáveis mutáveis desnecessárias nem efeitos colaterais ocultos:

```ridgun
import test
import math

fn :: suite matematicas => ()
      suite matematicas =
        assert equals 12 (math gcd 36 60) "MCD de 36 y 60"
        assert true (math is prime 97) "97 es primo"
        echo "[PASS] suite matematicas"
```

### 21.3.2. Exemplo 2: Composição segura e tratamento de casos de fronteira

Todas as funções da lib `test` foram desenhadas para se comporem com guardas booleanas `|` e com as restantes 32 libs do `ridgun-libs`:

```ridgun
import test

fn :: verificar codigo sistema Int => ()
      verificar codigo sistema rc =
        assert equals rc 0 "operacion de descriptor exitosa"
```

### 21.3.3. Exemplo 3: Predicados booleanos (`check eq`, `check str eq`, `check true`) e asserções RG-011 com diagnóstico (`assert equals`, `assert str eq`, `assert int equals`)

Neste exemplo prático exploramos de forma exaustiva como a `test` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test rg011 assertions => ()
      test rg011 assertions =
        assert equals 4 4 "math int equality"
        assert equals "ok" "ok" "string equality"
        assert equals True True "bool equality"
        assert true (1 < 2) "1 < 2 holds"
        assert false (1 > 2) "1 > 2 is false"
        assert str eq "ridgun" "ridgun" "str eq helper"
        assert int equals 42 42 "int eq helper"
        assert eq 10 10
        assert ok True
        assert not False
        assert true (check eq 2 2) "check eq True"
        assert false (check eq 1 2) "check eq False"
        assert true (check str eq "a" "a") "check str eq True"
        assert false (check str eq "a" "b") "check str eq False"
        assert true (check true True) "check true True"
        assert false (check true False) "check true False"
```

### 21.3.4. Exemplo 4: Composição de suites unitárias e funcionais combinando predicados puros e asserções concisas (`assert ok`, `assert not`, `assert eq`)

Neste exemplo prático exploramos de forma exaustiva como a `test` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
import test

fn :: validar invariantes de dominio (x : Int) (nombre : String) => Bool
      validar invariantes de dominio x nombre =
        ok_num = check eq (x * 2) (x + x)
        ok_str = check str eq nombre "ridgun"
        check true (ok_num and ok_str)

fn :: ejecutar suite de ejemplo => ()
      ejecutar suite de ejemplo =
        -- 1. Predicados puros sin salida del proceso (`check_*`)
        assert true (validar invariantes de dominio 21 "ridgun") "predicado compuesto"
        -- 2. Aserciones anotadas con mensaje diagnóstico (`assert_*`)
        assert int equals (20 + 22) 42 "suma entera exacta"
        assert str eq "rglib" "rglib" "etiqueta de artefacto"
        -- 3. Aserciones concisas sin etiqueta (`assert ok`, `assert not`, `assert eq`)
        assert ok (10 > 5)
        assert not (10 < 5)
        assert eq [1, 2, 3] [1, 2, 3]
        ()
```

---

## 21.4. Debaixo do capô: como a `test` é construída em Ridgun puro (`src/main/ridgun/lib/test.rg`)

Uma das maiores vantagens do `ridgun-libs` é que **não existem caixas-pretas em C**. Pode abrir `src/main/ridgun/lib/test.rg` e ler exatamente como cada operação é implementada usando *pattern matching*, árvores de guardas `|` / `|.` e recursão de cauda (TCO). Vejamos as peças-chave da sua implementação real:

### 21.4.1. Implementação interna: Non-Exiting Predicate Helpers

Observe como `test.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
module :: test

fn :: check eq A      A        => Bool
      check eq actual expected =  actual == expected

fn :: check str eq String String   => Bool
      check str eq actual expected =  actual == expected

fn :: check true Bool => Bool
      check true cond =  cond
```

### 21.4.2. Implementação interna: RG-011 Message-Annotated Assertions

Observe como `test.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: assert true Bool String => ()
      assert true cond label  =
        | cond      = ()
        | otherwise = fail test "assert_true failed: {label}"

fn :: assert false Bool String => ()
      assert false cond label  =
        | not cond  = ()
        | otherwise = fail test "assert_false failed: {label}"

fn :: assert equals A      A        String => ()
      assert equals actual expected label  =
        | actual == expected = ()
        | otherwise          = fail test "assert_equals failed: {label}"

fn :: assert str eq String String String => ()
      assert str eq actual expected label =
        | actual == expected = ()
        | otherwise          = fail test "assert_str_eq failed ({label}): got '{actual}', expected '{expected}'"

fn :: assert int equals Int Int String => ()
      assert int equals actual expected label =
        | actual == expected = ()
        | otherwise          = fail test "assert_int_equals failed ({label}): got {actual}, expected {expected}"
```

### 21.4.3. Implementação interna: Concise Label-Free Assertion Helpers

Observe como `test.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: assert ok Bool => ()
      assert ok cond =  assert true cond "assert_ok"

fn :: assert not Bool => ()
      assert not cond =  assert false cond "assert_not"

fn :: assert eq A      A        => ()
      assert eq actual expected =  assert equals actual expected "assert_eq"
```

---

## 21.5. Garantias algorítmicas, memória `RMM1`/`RMM2` e as 5 Regras de Ouro da `test`

- **Garantia algorítmica e de segurança**: Todas as 30 suites de testes do `ridgun-libs` (`src/test/ridgun/test_*.rg`, mais de 4 000 linhas) são executadas com esta mesma lib através de `stable test`.
- **Complexidade de pilha $O(1)$ com TCO**: Todos os ciclos recursivos em `src/main/ridgun/lib/test.rg` estão em posição de cauda, pelo que o `ridgunc` os compila para saltos nativos sem crescimento de pilha.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test test.rg`.

### As 5 Regras de Ouro ao programar com a `test`

1. **Declare `import test` no início do ficheiro** e aproveite a equivalência entre espaços e underscores para que o seu código se leia como prosa.
2. **Alinhe os seus pipelines de dados com `=`**: encadeie as chamadas à `test` em passos nomeados e deixe o `stable format` alinhar as colunas.
3. **Aproveite as funções totais da `test` nas suas guardas `|`**: verifique os valores de retorno ou desempacote os ADTs com *pattern matching* em vez de assumir que a entrada externa é sempre válida.
4. **Evite copiar grandes estruturas se só precisa de consultar um campo**: lembre-se de que no `RMM2` os argumentos de entrada não incrementam nem decrementam contadores (`+0` / `-0`).
5. **Combine a `test` com `test` (`import test`)**: escreva sempre asserções com `assert equals` ou `assert true` para fixar os invariantes do seu domínio.

---

No **Capítulo 22** passaremos a explorar em profundidade a lib **`posix`** (A lib `posix` — Camada de Abstração de Plataforma (PAL), Relógios, Sinais e CSPRNG).
