# Capítulo 02: A lib `math` — Aritmética Segura, Teoria dos Números e Estatística

## 1. Por que existe a lib `math`?

Sejamos sinceros: uma divisão por zero inesperada em produção ou o operador `%` a devolver restos negativos em C ou Java já derrubaram mais serviços do que gostamos de admitir.

A lib **`math`** oferece divisões totais à prova de `d == 0` (`div ceil`, `div floor`, `div euclid`, `mod euclid`), exponenciação e inverso modular em $O(\log E)$, raízes e logaritmos inteiros exatos, combinatória, primalidade e o operador mixfix `clamp x between lo and hi`.

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`math`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/math.rg` (domínio `MATH`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/math.rglib` | Distribuição e importação direta com `import math` |
| **Ficheiro compilado** | `target/math.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libmath.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import math` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `math`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `math abs / math sign / math min / math max` | Magnitude absoluta, sinal (`-1, 0, 1`) e extremos |
| `clamp x between lo and hi` | Operador mixfix (`op ::`) que limita `x` ao intervalo `[lo, hi]` |
| `math div ceil / math div floor / math div euclid / math mod euclid` | Arredondamento seguro contra divisão por zero e resto euclidiano não negativo |
| `math pow / math isqrt / math ilog2 / math ilog10` | Potência em $O(\log E)$, raiz quadrada inteira de Newton e logaritmos inteiros |
| `math gcd / math lcm / math mod pow / math mod inv / math is prime` | MDC/MMC de Euclides, aritmética modular e teste de primalidade $6k \pm 1$ |
| `math sum / math mean floor / math median floor / math variance floor` | Combinatória (`nCr`) sem overflow e estatística inteira sobre listas |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `math`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

```ridgun
import math

fn :: verificar clave modular (base : Int) (primo : Int) => (Int, Int, Bool)
      verificar clave modular base primo =
        es_p = math is prime primo
        pot  = math mod pow base (primo - 1) primo
        inv  = math mod inv base primo
        (pot, inv, es_p)
```

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `math` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import math

fn :: calcular paginas y cuota (items : Int) (por_pag : Int) (uso : Int) => (Int, Int)
      calcular paginas y cuota items por_pag uso =
        pags  = math div ceil items por_pag
        cuota = clamp uso between 0 and 100
        (pags, cuota)
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: Funções totais (devolvem `0` quando o divisor é `<= 0` em vez de abortar com `SIGFPE`), sem imprecisão de vírgula flutuante.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_math.rg`.
