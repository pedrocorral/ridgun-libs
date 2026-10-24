# Capítulo 11: A lib `regex` — Motor de Expressões Regulares Thompson NFA em Tempo Linear $O(N \cdot M)$

## 1. Por que existe a lib `regex`?

Sejamos sinceros: os motores de expressões regulares com *backtracking* já causaram quedas globais famosas (como na Cloudflare ou no StackOverflow) quando um padrão como `(a+)+b` recebe trinta `a` seguidos e entra em tempo exponencial $O(2^N)$.

A lib **`regex`** compila as suas expressões regulares (`.`, `*`, `+`, `?`, `|`, `()`, `[a-z]`, `[^...]`, `^`, `$`, `\d`, `\w`, `\s`) para um **autómato finito não determinístico de Thompson (NFA)** e avança o conjunto de estados passo a passo em tempo estritamente linear **$O(N \cdot M)$**, tornando os ataques **ReDoS matematicamente impossíveis**.

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`regex`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/regex.rg` (domínio `REGEX`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/regex.rglib` | Distribuição e importação direta com `import regex` |
| **Ficheiro compilado** | `target/regex.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libregex.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import regex` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `regex`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `regex match / regex is match` | Correspondência de cadeia completa e pesquisa de subcadeia em tempo linear $O(N \cdot M)$ |
| `regex find / regex find all` | Extrai a primeira ou todas as subcadeias correspondentes sem sobreposição |
| `regex replace / regex replace all` | Substitui a primeira ou todas as correspondências da expressão regular |
| `regex split / regex escape` | Divide texto por um delimitador regex e escapa metacaracteres |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `regex`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

```ridgun
import regex

fn :: extraer codigos postales (texto : String) => [String]
      extraer codigos postales texto =
        regex find all "\\d+" texto
```

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `regex` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import regex

fn :: censurar telefonos (comentario : String) => (Bool, String)
      censurar telefonos comentario =
        tiene = regex is match "\\d+-\\d+" comentario
        limpio = regex replace all "\\d+-\\d+" comentario "[TELEFONO]"
        (tiene, limpio)
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: Simulação de conjunto de estados NFA sem recursão descontrolada na pilha e tempo $O(N \cdot M)$ garantido mesmo perante padrões patológicos `(a+)+b`.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_regex.rg`.
