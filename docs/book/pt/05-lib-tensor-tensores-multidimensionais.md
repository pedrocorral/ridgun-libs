# Capítulo 05: A lib `tensor` — Tensores Multidimensionais, Vistas e Contração de Einstein

## 1. Por que existe a lib `tensor`?

Sejamos sinceros: na maioria das linguagens tem de escolher entre listas aninhadas lentíssimas cheias de ponteiros dispersos ou ligar um monstro de C++/Fortran de 200 MB como o NumPy/BLAS.

A lib **`tensor`** envolve a primitiva nativa `Tensor[...]` do Ridgun oferecendo criação tipada (`Tensor[Int]`, `Tensor[Real]`, `Tensor[U64]`), vistas sem cópia (`reshape`, `slice`), operações elemento a elemento (Hadamard), contração de Einstein e aritmética `BlaMka` de 64 bits.

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`tensor`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/tensor.rg` (domínio `TENSOR`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/tensor.rglib` | Distribuição e importação direta com `import tensor` |
| **Ficheiro compilado** | `target/tensor.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libtensor.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import tensor` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `tensor`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `tensor zeros int / tensor fill int / tensor zeros real` | Aloca blocos contíguos 1D/2D de `Tensor[Int]` e `Tensor[Real]` |
| `tensor get 1d / tensor set 1d / tensor get 2d / tensor set 2d` | Acesso e atualização funcional Copy-on-Write (`with [i] = v`) |
| `tensor reshape 1d to 2d / tensor slice 1d` | Vistas de descritor em $O(1)$ sem copiar o armazenamento do tensor |
| `tensor add int / tensor mul int / tensor scale int` | Soma, multiplicação elemento a elemento (Hadamard) e escalonamento |
| `tensor dot int / tensor matmul int` | Contração de índices de Einstein (`a[i] * b[i]`, `a[i, k] * b[k, j]`) |
| `u64 blamka g / u64 rotr` | Mistura rotacional `U64` sem sinal de 64 bits para blocos criptográficos |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `tensor`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

```ridgun
import tensor

fn :: producto matricial tensor () => Tensor[Int]
      producto matricial tensor =
        a = tensor reshape 1d to 2d (tensor from list int [1, 2, 3, 4]) 2 2
        b = tensor reshape 1d to 2d (tensor from list int [5, 6, 7, 8]) 2 2
        tensor matmul int a b
```

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `tensor` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import tensor

fn :: energia vector (xs : [Int]) => (Int, Int)
      energia vector xs =
        v   = tensor from list int xs
        dot = tensor dot int v v
        mx  = tensor max int v
        (dot, mx)
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: Memória contígua de 8 bytes por célula gerida estaticamente por RMM1/RMM2, vistas em $O(1)$ sem duplicar o buffer e semântica pura Copy-on-Write.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_tensor.rg`.
