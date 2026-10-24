# Capítulo 01: A lib `str` — Manipulação de Texto, Pesquisa e Formatação Tabular

## 1. Por que existe a lib `str`?

Sejamos sinceros: manipular cadeias em C com `strtok` e `strncpy` é caminhar num campo de minas de *buffer overflows* e ponteiros `NULL`, e noutras linguagens acaba a importar pacotes externos só para alinhar colunas ou repetir um separador em $O(\log N)$.

A lib **`str`** fornece todas as primitivas puras e imutáveis para pesquisar, aparar, dividir, juntar, converter maiúsculas/minúsculas, repetir por duplicação binária $O(\log N)$ e preencher cadeias.

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`str`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/str.rg` (domínio `STR`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/str.rglib` | Distribuição e importação direta com `import str` |
| **Ficheiro compilado** | `target/str.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libstr.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import str` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `str`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `str index of : String -> String -> Int` | Primeiro índice da subcadeia (`-1` se ausente / `0` se vazia) |
| `str contains / str starts with / str ends with` | Predicados `Bool` de subcadeia, prefixo e sufixo |
| `str trim / str trim left / str trim right` | Remove espaços em branco ASCII (` `, `\t`, `\n`, `\r`) |
| `str split / str lines / str words / str join` | Divide em `[String]` e junta listas com um separador |
| `str replace / str to upper / str to lower` | Substituição sem sobreposição e conversão ASCII de maiúsculas/minúsculas |
| `str repeat / str pad left / str pad right` | Repetição em $O(\log N)$ e preenchimento de colunas com largura fixa |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `str`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

```ridgun
import str

fn :: normalizar cabecera (raw : String) => String
      normalizar cabecera raw =
        limpia = str to lower (str trim raw)
        partes = str words limpia
        slug   = str join partes "-"
        str pad right slug 24 "."
```

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `str` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import str

fn :: extraer dominio (correo : String) => String
      extraer dominio correo =
        pos = str index of correo "@"
        | pos < 0   = "sin-dominio"
        | otherwise =
          partes = str split correo "@"
          str replace (str to lower correo) "@" " en "
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: Repetição em $O(\log N)$ através de duplicação binária de cadeias, predicados seguros perante agulhas vazias e zero mutação local.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_str.rg`.
