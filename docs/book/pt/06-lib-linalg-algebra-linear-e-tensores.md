# Capítulo 06: A lib `linalg` — Álgebra Linear sobre `Tensor[Real]`, Bareiss e Ativações

## 1. Por que existe a lib `linalg`?

Sejamos sinceros: quando precisa de calcular similaridade de cosseno para embeddings, resolver $A x = b$ ou avaliar uma camada `softmax` num binário leve, não quer arrastar 400 MB de PyTorch ou LAPACK.

A lib **`linalg`** constrói álgebra linear numérica sobre `Tensor[Real]` nativo: transposição, traço, identidade, produto interno/externo, multiplicação matriz-vetor e matriz-matriz com notação de Einstein, normas ($L_1, L_2, L_\infty$, Frobenius), determinante e resolução linear $A x = b$ por **Bareiss/Gauss com pivotamento parcial**, e ativações neuronais (`relu`, `sigmoid`, `softmax`).

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`linalg`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/linalg.rg` (domínio `LINALG`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/linalg.rglib` | Distribuição e importação direta com `import linalg` |
| **Ficheiro compilado** | `target/linalg.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/liblinalg.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import linalg` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `linalg`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `linalg vec from list / linalg mat from lists` | Constrói `Tensor[Real]` 1D e 2D a partir de listas Ridgun |
| `linalg transpose / linalg trace / linalg diag / linalg identity` | Transformações estruturais de matrizes e matriz identidade |
| `linalg dot / linalg outer / linalg matvec / linalg matmul` | Einstein contraction (`a[i] * b[i]`, `a[i, k] * b[k, j]`) |
| `linalg norm l1 / linalg norm l2 / linalg cosine similarity` | Normas vetoriais/matriciais, normalização e similaridade de cosseno |
| `linalg det / linalg solve` | Determinante exato de Bareiss e resolução $A x = b$ com pivotamento parcial (`Option[Tensor[Real]]`) |
| `linalg relu / linalg sigmoid / linalg softmax` | Ativações neuronais numericamente estáveis com deslocamento pelo máximo |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `linalg`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

```ridgun
import linalg

fn :: resolver sistema lineal () => Option[Tensor[Real]]
      resolver sistema lineal =
        -- Resuelve 2x + y = 5, x + 3y = 10 -> x = 1.0, y = 3.0
        a = linalg mat from lists [[2.0, 1.0], [1.0, 3.0]]
        b = linalg vec from list [5.0, 10.0]
        linalg solve a b
```

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `linalg` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import linalg

fn :: puntuar embeddings () => (Real, Tensor[Real])
      puntuar embeddings =
        q     = linalg vec from list [1.0, 2.0, 3.0]
        d     = linalg vec from list [1.0, 2.0, 3.0]
        sim   = linalg cosine similarity q d
        probs = linalg softmax q
        (sim, probs)
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: Matrizes singulares devolvem `None` de forma limpa em `linalg solve` (sem `NaN` silenciosos), e `linalg softmax` subtrai o máximo antes de exponenciar para evitar overflow.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_linalg.rg`.
