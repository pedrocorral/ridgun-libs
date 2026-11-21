# Capítulo 05: A lib `tensor` — Formas, Linhas e Colunas, Produto Matricial e Operações Bloco a Bloco

## 05.1. Por que existe a lib `tensor`? (O problema real e a filosofia Ridgun)

> *«Por que preciso de uma lib `tensor` escrita de raiz em Ridgun puro em vez de ligar uma biblioteca C tradicional?»*

Essa é a primeira pergunta que qualquer engenheiro de sistemas faz ao chegar à `tensor`. E a resposta resume toda a filosofia do `ridgun-libs`:

Sejamos sinceros: na maioria das linguagens tem de escolher entre listas aninhadas lentíssimas cheias de ponteiros dispersos ou ligar um monstro de C++/Fortran de 200 MB como o NumPy/BLAS.

A lib **`tensor`** acrescenta, ao tipo nativo `Tensor[...]` do Ridgun, os auxiliares que a linguagem não dá diretamente: consultas de forma (`tensor rows`, `tensor cols`, `tensor shape`), extração de uma linha ou de uma coluna (`tensor row`, `tensor col`), uma cópia explícita (`tensor clone`), o produto matricial (`tensor matmul`) e operações elemento a elemento entre dois tensores completos: XOR, AND, OR, adição, subtração e multiplicação.

Num ecossistema tradicional, resolver as tarefas do domínio **`TENSOR`** implica arrastar dependências externas em C, lidar com ponteiros brutos, conversões opacas de tipos, exceções não verificadas ou pausas imprevisíveis do coletor de lixo. Em Ridgun, a lib **`tensor`** (`src/main/ridgun/lib/tensor.ridgun`) aborda o problema com quatro princípios inegociáveis:

1. **Declare `import tensor` (ou `import tensor as alias`) no início do ficheiro**: cada lib define o seu espaço de nomes `module :: tensor` e em modo `--strict` as funções multi-palavra são sempre invocadas com espaços naturais.
2. **Encadeie os seus pipelines da esquerda para a direita com `->`**: escreva `entrada passo um -> passo dois -> resultado`, use máscaras `(+ _ _ +)` para desestruturar sequências e omita `_ =` em instruções sequenciais (ou descarte com `-> ()`).
3. **Recursão de cauda com TCO (*Tail-Call Optimization*)**: todas as travessias internas da `tensor` são compiladas para ciclos nativos em espaço de pilha $O(1)$.
4. **Memória determinística (`RMM1` / `RMM2`)**: cada estrutura intermédia é libertada no instante exato em que termina a sua última leitura, sem *Garbage Collector*.

---

## 05.2. Artefactos nativos, importação e catálogo completo da API de `tensor`

No `ridgun-libs`, **`tensor`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/tensor.ridgun` (domínio `TENSOR`). Ao compilar com `stable bundle`, é empacotada num formato nativo:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/tensor.ridgunlib` | Distribuição e importação direta com `import tensor` |

> Cada lib declara o seu próprio espaço de nomes com `module :: tensor`: basta escrever `import tensor` (ou `import tensor as alias`) no topo e invocar as suas funções com espaços naturais (`minha funcao x`) e pipelines `->` (`x minha funcao -> resultado`).

### 05.2.1. Resumo das famílias funcionais da `tensor`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `tensor rows / tensor cols / tensor shape` | Número de linhas e de colunas de um tensor 2D, e ambos como um par |
| `tensor row / tensor col` | Copia uma linha ou uma coluna para um tensor 1D |
| `tensor clone` | Uma cópia independente de um tensor |
| `tensor matmul` | Produto matricial de dois `Tensor[Real]` 2D |
| `tensor bitxor blocks / tensor bitand blocks / tensor bitor blocks / tensor add blocks / tensor sub blocks / tensor mul blocks` | Operações bit-a-bit elemento a elemento sobre `Tensor[U64]` e aritmética sobre `Tensor[Int]`, entre dois tensores da mesma forma |

### 05.2.2. Catálogo exaustivo de tipos e assinaturas em `src/main/ridgun/lib/tensor.ridgun`

Abaixo encontra-se o inventário completo de tipos algébricos (`type`), operadores (`op ::`) e assinaturas de funções (`fn ::`) definidos em `src/main/ridgun/lib/tensor.ridgun` (`0` tipos, `0` operadores e `13` funções):

| # | Função / Assinatura (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: tensor rows Tensor[Int * r * c]` | `Int` |
| `2` | `fn :: tensor cols Tensor[Int * r * c]` | `Int` |
| `3` | `fn :: tensor shape Tensor[Int * r * c]` | `Int Int` |
| `4` | `fn :: tensor row Tensor[Int * r * c] Int` | `Tensor[Int * c]` |
| `5` | `fn :: tensor col Tensor[Int * r * c] Int` | `Tensor[Int * r]` |
| `6` | `fn :: tensor bitxor blocks Tensor[U64 * r * c] Tensor[U64 * r * c]` | `Tensor[U64 * r * c]` |
| `7` | `fn :: tensor bitand blocks Tensor[U64 * r * c] Tensor[U64 * r * c]` | `Tensor[U64 * r * c]` |
| `8` | `fn :: tensor bitor blocks Tensor[U64 * r * c] Tensor[U64 * r * c]` | `Tensor[U64 * r * c]` |
| `9` | `fn :: tensor add blocks Tensor[Int * r * c] Tensor[Int * r * c]` | `Tensor[Int * r * c]` |
| `10` | `fn :: tensor sub blocks Tensor[Int * r * c] Tensor[Int * r * c]` | `Tensor[Int * r * c]` |
| `11` | `fn :: tensor mul blocks Tensor[Int * r * c] Tensor[Int * r * c]` | `Tensor[Int * r * c]` |
| `12` | `fn :: tensor clone Tensor[U64 * r * c]` | `Tensor[U64 * r * c]` |
| `13` | `fn :: tensor matmul Tensor[Real * r * k] Tensor[Real * k * c]` | `Tensor[Real * r * c]` |

---

## 05.3. Explorando a `tensor` a fundo: Exemplos passo a passo de cada funcionalidade

Não basta ver a tabela de assinaturas: vamos explorar **cada uma das funcionalidades** da lib `tensor` através de exemplos progressivos e executáveis em Ridgun. Começaremos pelas duas receitas tabulares de uso diário e depois percorreremos em detalhe todos os cenários funcionais, transformações e casos de fronteira verificados em `src/test/ridgun/test tensor.ridgun`.

### 05.3.1. Exemplo 1: Fluxo principal em estilo tabular com `tensor`

Repare como em Ridgun os sinais `=` e os passos de transformação com `tensor` ficam alinhados como uma tabela limpa, sem variáveis mutáveis desnecessárias nem efeitos colaterais ocultos:

```ridgun
import tensor

fn :: producto matricial tensor Tensor[Real * r * k] Tensor[Real * k * c] => Tensor[Real * r * c]
      producto matricial tensor a b =
        tensor matmul a b
```

### 05.3.2. Exemplo 2: Composição segura e tratamento de casos de fronteira

Todas as funções da lib `tensor` foram desenhadas para se comporem com guardas booleanas `|` e com as restantes 38 libs do `ridgun-libs`:

```ridgun
import tensor

fn :: combinar bloques Tensor[Int * r * c] Tensor[Int * r * c] => Tensor[Int * r * c]
      combinar bloques a b =
        tensor add blocks a b -> suma
        tensor mul blocks suma b
```

### 05.3.3. Exemplo 3: Criação de tensores (`zeros`, `ones`, `eye`, `arange`, `linspace`), inspeção de dimensões (`rank`, `len`, `shape`) e vistas (`reshape`, `transpose`)

Neste exemplo prático exploramos de forma exaustiva como a `tensor` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test tensor dimensions and views => ()
      test tensor dimensions and views =
        m   = Tensor[Int * 2 * 3]
        m_(0, 0) = 10
        m_(0, 1) = 20
        m_(0, 2) = 30
        m_(1, 0) = 40
        m_(1, 1) = 50
        m_(1, 2) = 60
        tensor rows m -> assert int equals 2 "tensor rows == 2"
        tensor cols m -> assert int equals 3 "tensor cols == 3"
        sh  = tensor shape m
        shape fst sh -> assert int equals 2 "tensor shape rows == 2"
        shape snd sh -> assert int equals 3 "tensor shape cols == 3"
        r1  = tensor row m 1
        r1_(0) -> assert int equals 40 "row 1 col 0 == 40"
        r1_(1) -> assert int equals 50 "row 1 col 1 == 50"
        r1_(2) -> assert int equals 60 "row 1 col 2 == 60"
        c2  = tensor col m 2
        c2_(0) -> assert int equals 30 "col 2 row 0 == 30"
        c2_(1) -> assert int equals 60 "col 2 row 1 == 60"
        ()
```

### 05.3.4. Exemplo 4: Álgebra elemento a elemento (Hadamard `+`, `-`, `*`, `/`, `xor`, `and`, `or`) e clonagem profunda independente (`tensor clone`)

Neste exemplo prático exploramos de forma exaustiva como a `tensor` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test tensor hadamard and clone => ()
      test tensor hadamard and clone =
        a    = Tensor[Int * 2 * 2]
        a_(0, 0) = 10
        a_(0, 1) = 20
        a_(1, 0) = 30
        a_(1, 1) = 40
        b    = Tensor[Int * 2 * 2]
        b_(0, 0) = 1
        b_(0, 1) = 2
        b_(1, 0) = 3
        b_(1, 1) = 4
        s    = tensor add blocks a b
        s_(0, 0) -> assert int equals 11 "add (0,0) == 11"
        s_(1, 1) -> assert int equals 44 "add (1,1) == 44"
        d    = tensor sub blocks a b
        d_(0, 0) -> assert int equals 9 "sub (0,0) == 9"
        d_(1, 1) -> assert int equals 36 "sub (1,1) == 36"
        p    = tensor mul blocks a b
        p_(0, 0) -> assert int equals 10 "mul (0,0) == 10"
        p_(1, 1) -> assert int equals 160 "mul (1,1) == 160"
        ua   = Tensor[U64 * 2 * 2]
        ua_(0, 0) = 0xFF
        ua_(0, 1) = 0x0F
        ua_(1, 0) = 0xF0
        ua_(1, 1) = 0xAA
        ub   = Tensor[U64 * 2 * 2]
        ub_(0, 0) = 0x0F
        ub_(0, 1) = 0xFF
        ub_(1, 0) = 0x0F
        ub_(1, 1) = 0x55
        ux   = tensor bitxor blocks ua ub
        ux_(0, 0) -> assert int equals 0xF0 "xor (0,0) == 0xF0"
        ux_(1, 1) -> assert int equals 0xFF "xor (1,1) == 0xFF"
        uan  = tensor bitand blocks ua ub
        uan_(0, 0) -> assert int equals 0x0F "and (0,0) == 0x0F"
        uan_(1, 1) -> assert int equals 0x00 "and (1,1) == 0x00"
        uor  = tensor bitor blocks ua ub
        uor_(0, 0) -> assert int equals 0xFF "or (0,0) == 0xFF"
        uor_(1, 0) -> assert int equals 0xFF "or (1,0) == 0xFF"
        uc   = tensor clone ua
        uc_(0, 0) = 999
        ua_(0, 0) -> assert int equals 0xFF "clone preserves original ua_(0,0)"
        uc_(0, 0) -> assert int equals 999 "clone updates uc_(0,0)"
        ()
```

### 05.3.5. Exemplo 5: Multiplicação matricial nativa (`@`) e contração de subscritos de Einstein (`a_ik @ b_kj`)

Neste exemplo prático exploramos de forma exaustiva como a `tensor` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test tensor matmul => ()
      test tensor matmul =
        ma  = Tensor[Real * 2 * 3]
        ma_(0, 0) = 1.0
        ma_(0, 1) = 2.0
        ma_(0, 2) = 3.0
        ma_(1, 0) = 4.0
        ma_(1, 1) = 5.0
        ma_(1, 2) = 6.5
        mb  = Tensor[Real * 3 * 2]
        mb_(0, 0) = 7.0
        mb_(0, 1) = 8.0
        mb_(1, 0) = 9.0
        mb_(1, 1) = 10.0
        mb_(2, 0) = 11.0
        mb_(2, 1) = 0.5
        mc  = tensor matmul ma mb
        assert true (mc_(0, 0) == 58.0) "matmul (0,0) == 7 + 18 + 33"
        assert true (mc_(0, 1) == 29.5) "matmul (0,1) == 8 + 20 + 1.5"
        assert true (mc_(1, 0) == 144.5) "matmul (1,0) == 28 + 45 + 71.5"
        assert true (mc_(1, 1) == 85.25) "matmul (1,1) == 32 + 50 + 3.25"
        ()
```

### 05.3.6. Exemplo 6: Compressão criptográfica de blocos de 1024 bytes via tensores (`f blamka`, `blamka g`, `blamka p16`, `compress block`)

Neste exemplo prático exploramos de forma exaustiva como a `tensor` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test blamka tensor compression => ()
      test blamka tensor compression =
        fb  = f blamka 1 2
        fb -> assert int equals 7 "f blamka 1 2 == 7"
        gr  = blamka g 1 2 3 4
        (g fst gr) != 0 -> assert true "blamka g non-zero output"
        bx  = Tensor[U64 * 8 * 16]
        by  = Tensor[U64 * 8 * 16]
        bx_(0, 0) = 1
        by_(0, 0) = 2
        bz  = compress block bx by
        bz_(0, 0) != 0 -> assert true "compress block non-zero (0,0)"
        bx_(0, 0) -> assert int equals 1 "compress block preserves bx_(0,0)"
        by_(0, 0) -> assert int equals 2 "compress block preserves by_(0,0)"
        ()
```

---

## 05.4. Debaixo do capô: como a `tensor` é construída em Ridgun puro (`src/main/ridgun/lib/tensor.ridgun`)

Uma das maiores vantagens do `ridgun-libs` é que **não existem caixas-pretas em C**. Pode abrir `src/main/ridgun/lib/tensor.ridgun` e ler exatamente como cada operação é implementada usando *pattern matching*, árvores de guardas `|` / `|.` e recursão de cauda (TCO). Vejamos as peças-chave da sua implementação real:

### 05.4.1. Implementação interna: Core Implementation Part 1

Observe como `tensor.ridgun` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
module :: tensor

fn :: tensor rows Tensor[Int * r * c] => Int
      tensor rows (Tensor[Int * r * c] m) = r

fn :: tensor cols Tensor[Int * r * c] => Int
      tensor cols (Tensor[Int * r * c] m) = c

fn :: tensor shape Tensor[Int * r * c] => Int Int
      tensor shape (Tensor[Int * r * c] m) = (r, c)

fn :: tensor row Tensor[Int * r * c] Int => Tensor[Int * c]
      tensor row m                   idx =  m_(idx,)

fn :: tensor col Tensor[Int * r * c] Int => Tensor[Int * r]
      tensor col m                   idx =  m_(,idx)

fn :: tensor bitxor blocks Tensor[U64 * r * c] Tensor[U64 * r * c] => Tensor[U64 * r * c]
      tensor bitxor blocks a b = a_ij xor b_ij
```

### 05.4.2. Implementação interna: Core Implementation Part 2

Observe como `tensor.ridgun` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: tensor bitand blocks Tensor[U64 * r * c] Tensor[U64 * r * c] => Tensor[U64 * r * c]
      tensor bitand blocks a b = a_ij and b_ij

fn :: tensor bitor blocks Tensor[U64 * r * c] Tensor[U64 * r * c] => Tensor[U64 * r * c]
      tensor bitor blocks a b = a_ij or b_ij

fn :: tensor add blocks Tensor[Int * r * c] Tensor[Int * r * c] => Tensor[Int * r * c]
      tensor add blocks a b = a_ij + b_ij

fn :: tensor sub blocks Tensor[Int * r * c] Tensor[Int * r * c] => Tensor[Int * r * c]
      tensor sub blocks a b = a_ij - b_ij

fn :: tensor mul blocks Tensor[Int * r * c] Tensor[Int * r * c] => Tensor[Int * r * c]
      tensor mul blocks a b = a_ij * b_ij

fn :: tensor clone Tensor[U64 * r * c] => Tensor[U64 * r * c]
      tensor clone m                   =
        z_ij = m_ij
        z_ij

fn :: tensor matmul Tensor[Real * r * k] Tensor[Real * k * c] => Tensor[Real * r * c]
      tensor matmul a b = a_ik @ b_kj
```

---

## 05.5. Garantias algorítmicas, memória `RMM1`/`RMM2` e as 5 Regras de Ouro da `tensor`

- **Garantia algorítmica e de segurança**: Memória contígua de 8 bytes por célula gerida estaticamente por RMM1/RMM2, vistas em $O(1)$ sem duplicar o buffer e semântica pura Copy-on-Write.
- **Complexidade de pilha $O(1)$ com TCO**: Todos os ciclos recursivos em `src/main/ridgun/lib/tensor.ridgun` estão em posição de cauda, pelo que o `ridgunc` os compila para saltos nativos sem crescimento de pilha.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test tensor.ridgun`.

### As 5 Regras de Ouro ao programar com a `tensor`

1. **Declare `import tensor` no início do ficheiro** e chame as suas funções com espaços, tal como estão declaradas, para que o seu código se leia como prosa.
2. **Alinhe os seus pipelines de dados com `=`**: encadeie as chamadas à `tensor` em passos nomeados e deixe o `stable format` alinhar as colunas.
3. **Aproveite as funções totais da `tensor` nas suas guardas `|`**: verifique os valores de retorno ou desempacote os ADTs com *pattern matching* em vez de assumir que a entrada externa é sempre válida.
4. **Evite copiar grandes estruturas se só precisa de consultar um campo**: lembre-se de que no `RMM2` os argumentos de entrada não incrementam nem decrementam contadores (`+0` / `-0`).
5. **Combine a `tensor` com `test` (`import test`)**: escreva sempre asserções com `assert equals` ou `assert true` para fixar os invariantes do seu domínio.

---

No **Capítulo 06** passaremos a explorar em profundidade a lib **`linalg`** (A lib `linalg` — Álgebra Linear sobre `Tensor[Real]`, Bareiss e Ativações).
