# Capítulo 21: A lib `test` — Primitivas de Asserção Unitária e Funcional (`RG-011`)

## 1. Por que existe a lib `test`?

Sejamos sinceros: quando uma framework de testes exige macros mágicas, reflexão em tempo de execução ou um executor externo pesado, escrever testes deixa de ser imediato.

A lib **`test`** (`RG-011`) fornece asserções puras, polimórficas e específicas de tipo que emitem diagnósticos claros `[FAIL]` com os valores esperado e obtido e terminam com código de saída `1`.

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`test`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/test.rg` (domínio `TST`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/test.rglib` | Distribuição e importação direta com `import test` |
| **Ficheiro compilado** | `target/test.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libtest.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import test` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `test`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `assert equals / assert eq : A -> A -> String -> ()` | Asserção polimórfica de igualdade com etiqueta descritiva do caso de teste |
| `assert int equals / assert str eq` | Asserções especializadas de igualdade para `Int` e `String` |
| `assert true / assert false / assert not` | Asserções de invariantes booleanas (`True` / `False`) |
| `assert ok : Int -> String -> ()` | Verifica se um código de estado do sistema ou socket é igual a `0` (`OK`) |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `test`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

```ridgun
import test
import math

fn :: suite matematicas () => ()
      suite matematicas =
        _ = assert int equals 12 (math gcd 36 60) "MCD de 36 y 60"
        _ = assert true (math is prime 97) "97 es primo"
        echo "[PASS] suite matematicas"
```

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `test` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import test

fn :: verificar codigo sistema (rc : Int) => ()
      verificar codigo sistema rc =
        assert ok rc "operacion de descriptor exitosa"
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: Todas as 30 suites de testes do `ridgun-libs` (`src/test/ridgun/test_*.rg`, mais de 4 000 linhas) são executadas com esta mesma lib através de `stable test`.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_test.rg`.
