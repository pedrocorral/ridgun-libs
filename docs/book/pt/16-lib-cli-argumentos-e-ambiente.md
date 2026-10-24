# Capítulo 16: A lib `cli` — Flags, Opções, Barreira `--`, Subcomandos e Variáveis de Ambiente

## 1. Por que existe a lib `cli`?

Sejamos sinceros: analisar `argv` à mão começa sempre com um ciclo inocente e acaba por quebrar quando alguém passa `-la` agrupado, `--port=9090` com sinal de igual ou `--` seguido de um ficheiro começado por hífen.

A lib **`cli`** resolve flags longas (`--verbose`), curtas (`-v`), agrupadas (`-la`), opções com valor (`--port=8080`, `--port 8080`, `-p 8080`), o separador POSIX `--`, argumentos posicionais, subcomandos e leitura tipada de variáveis de ambiente.

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`cli`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/cli.rg` (domínio `CLI`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/cli.rglib` | Distribuição e importação direta com `import cli` |
| **Ficheiro compilado** | `target/cli.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libcli.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import cli` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `cli`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `cli has flag : [String] -> String -> String -> Bool` | Deteta `--long`, `-s` ou flags agrupadas `-xyz` antes de `--` |
| `cli get opt / cli get int opt` | Extrai opção de texto ou inteira (`--k=v`, `--k v`, `-k v`) com valor padrão |
| `cli positionals / cli subcommand` | Recolhe os argumentos posicionais (incluindo tudo o que sucede a `--`) |
| `env get or / env get int or / env get bool or` | Lê variáveis de ambiente com conversão tipada e valores padrão |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `cli`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

```ridgun
import cli

fn :: analizar comando (args : [String]) => (String, Bool, Int, [String])
      analizar comando args =
        sub   = cli subcommand args
        all_f = cli has flag args "--all" "-a"
        port  = cli get int opt args "--port" "-p" 8080
        arch  = cli positionals args ["--port", "-p"]
        (sub, all_f, port, arch)
```

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `cli` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import cli

fn :: leer config entorno () => (Int, Bool)
      leer config entorno =
        workers = env get int or "SOLSTICE_WORKERS" 4
        debug   = env get bool or "SOLSTICE_DEBUG" False
        (workers, debug)
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: Respeito estrito pelo separador POSIX `--`: nenhum argumento à direita de `--` é jamais interpretado como flag.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_cli.rg`.
